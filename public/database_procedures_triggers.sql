-- ===========================================================================
-- DATABASE PROCEDURES & TRIGGERS
-- ===========================================================================

-- 1. PROCEDURE: assign_driver_to_trip
-- Purpose: Assigns a driver to a specific trip after validating availability.
-- Logic: Checks if the driver has any other trips assigned on the same date
--        to prevent scheduling conflicts at the database level.
CREATE OR REPLACE PROCEDURE assign_driver_to_trip(
    p_driver_id INT,
    p_trip_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_trip_count INT;
BEGIN
    -- Check if driver is already assigned to another trip at the same time
    SELECT COUNT(*)
    INTO v_existing_trip_count
    FROM "Trip" t
    WHERE "DriverID" = p_driver_id
    AND "TripID" != p_trip_id
    AND (
        ("DepartureTime"::DATE = (SELECT "DepartureTime"::DATE FROM "Trip" WHERE "TripID" = p_trip_id))
    );

    IF v_existing_trip_count > 0 THEN
        RAISE EXCEPTION 'Driver is already assigned to another trip on this date';
    END IF;

    -- Assign driver to trip
    UPDATE "Trip"
    SET "DriverID" = p_driver_id
    WHERE "TripID" = p_trip_id;

    RAISE NOTICE 'Driver % assigned to trip %', p_driver_id, p_trip_id;
END;
$$;

-- 2. PROCEDURE: generate_daily_trip_summary
-- Purpose: Aggregates daily metrics (trips, revenue, passengers) into a summary table.
-- Logic: Uses an UPSERT (INSERT ... ON CONFLICT) to update existing rows or insert new ones
--        for the specified date.
CREATE OR REPLACE PROCEDURE generate_daily_trip_summary(
    p_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_trips INT;
    v_total_revenue DECIMAL;
    v_total_passengers INT;
BEGIN
    -- Calculate daily metrics by joining Trip and Ticket tables
    SELECT 
        COUNT(DISTINCT t."TripID"),
        COALESCE(SUM(tk."Price"), 0),
        COUNT(DISTINCT tk."PassengerID")
    INTO v_total_trips, v_total_revenue, v_total_passengers
    FROM "Trip" t
    LEFT JOIN "Ticket" tk ON t."TripID" = tk."TripID"
    WHERE DATE(t."DepartureTime") = p_date;

    -- Insert or update daily summary records
    INSERT INTO "DailySummary" ("SummaryDate", "TotalTrips", "TotalTicketsSold", "TotalRevenue")
    VALUES (p_date, v_total_trips, v_total_passengers, v_total_revenue)
    ON CONFLICT ("SummaryDate") DO UPDATE
    SET "TotalTrips" = v_total_trips,
        "TotalTicketsSold" = v_total_passengers,
        "TotalRevenue" = v_total_revenue;

    RAISE NOTICE 'Daily summary generated for %: % trips, % revenue, % passengers', 
        p_date, v_total_trips, v_total_revenue, v_total_passengers;
END;
$$;

-- 3. PROCEDURE: record_ticket_purchase
-- Purpose: Handles seat booking, ticket insertion, and seat status updates in one atomic operation.
-- Logic: Uses 'FOR UPDATE' row-level locking on the Seat table to prevent race conditions
--        during concurrent booking attempts.
CREATE OR REPLACE PROCEDURE record_ticket_purchase(
    p_trip_id INT,
    p_passenger_id INT,
    p_seat_number INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_seat_status "SeatStatus";
    v_ticket_price DECIMAL;
BEGIN
    -- Check seat availability with row-level locking
    SELECT "Status"
    INTO v_seat_status
    FROM "Seat"
    WHERE "TripID" = p_trip_id
    AND "SeatNumber" = p_seat_number
    FOR UPDATE;

    IF v_seat_status IS NULL THEN
        RAISE EXCEPTION 'Seat does not exist for this trip';
    ELSIF v_seat_status != 'available' THEN
        RAISE EXCEPTION 'Seat is not available';
    END IF;

    -- Calculate ticket price dynamically based on route distance
    SELECT ("Distance" * 5)::DECIMAL
    INTO v_ticket_price
    FROM "Route" r
    JOIN "Trip" t ON r."RouteID" = t."RouteID"
    WHERE t."TripID" = p_trip_id;

    -- Insert ticket record
    INSERT INTO "Ticket" ("TripID", "PassengerID", "SeatNumber", "Price")
    VALUES (p_trip_id, p_passenger_id, p_seat_number, v_ticket_price);

    -- Mark seat as sold to prevent further booking
    UPDATE "Seat"
    SET "Status" = 'sold'
    WHERE "TripID" = p_trip_id
    AND "SeatNumber" = p_seat_number;

    RAISE NOTICE 'Ticket purchased for passenger % on seat % of trip %', 
        p_passenger_id, p_seat_number, p_trip_id;
END;
$$;

-- 4. FUNCTION: calculate_trip_revenue
-- Returns the total sum of ticket prices for a specific trip.
CREATE OR REPLACE FUNCTION calculate_trip_revenue(p_trip_id INT)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
DECLARE
    v_revenue DECIMAL;
BEGIN
    SELECT COALESCE(SUM("Price"), 0)
    INTO v_revenue
    FROM "Ticket"
    WHERE "TripID" = p_trip_id;

    RETURN v_revenue;
END;
$$;

-- 5. FUNCTION: get_available_seats
-- Returns a set of available seats for a trip, ordered by seat number.
CREATE OR REPLACE FUNCTION get_available_seats(p_trip_id INT)
RETURNS TABLE(seat_number INT, status TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s."SeatNumber"::INT,
        s."Status"::TEXT
    FROM "Seat" s
    WHERE s."TripID" = p_trip_id
    AND s."Status" = 'available'
    ORDER BY s."SeatNumber";
END;
$$;

-- 6. FUNCTION: next_maintenance_due
-- Purpose: Projects the next maintenance date.
-- Logic: Adds a 30-day interval to the last recorded maintenance date.
CREATE OR REPLACE FUNCTION next_maintenance_due(p_vehicle_id INT)
RETURNS DATE
LANGUAGE plpgsql
AS $$
DECLARE
    v_last_maintenance DATE;
    v_next_due DATE;
    v_maintenance_interval INT := 30;
BEGIN
    -- Find the date of the most recent maintenance
    SELECT MAX("Date")
    INTO v_last_maintenance
    FROM "MaintenanceRecord"
    WHERE "VehicleID" = p_vehicle_id;

    IF v_last_maintenance IS NULL THEN
        -- If no record exists, assume maintenance is due today
        v_next_due := CURRENT_DATE;
    ELSE
        -- Calculate 30 days from last service
        v_next_due := v_last_maintenance + (v_maintenance_interval || ' days')::INTERVAL;
    END IF;

    RETURN v_next_due;
END;
$$;

-- 7. TRIGGER FUNCTION: prevent_duplicate_seats
-- Applied BEFORE INSERT on Ticket. Validates that the seat isn't already booked.
CREATE OR REPLACE FUNCTION prevent_duplicate_seats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_ticket INT;
BEGIN
    SELECT COUNT(*)
    INTO v_existing_ticket
    FROM "Ticket"
    WHERE "TripID" = NEW."TripID"
    AND "SeatNumber" = NEW."SeatNumber";

    IF v_existing_ticket > 0 THEN
        RAISE EXCEPTION 'This seat is already booked';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_before_insert_ticket ON "Ticket";
CREATE TRIGGER trg_before_insert_ticket
BEFORE INSERT ON "Ticket"
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_seats();

-- 8. TRIGGER FUNCTION: update_trip_available_seats
-- Applied AFTER INSERT on Ticket. Can be used for real-time occupancy monitoring.
CREATE OR REPLACE FUNCTION update_trip_available_seats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_available_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_available_count
    FROM "Seat"
    WHERE "TripID" = NEW."TripID"
    AND "Status" = 'available';

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_insert_ticket ON "Ticket";
CREATE TRIGGER trg_after_insert_ticket
AFTER INSERT ON "Ticket"
FOR EACH ROW
EXECUTE FUNCTION update_trip_available_seats();


-- 9. TRIGGER FUNCTION: log_trip_update
-- Purpose: Logs occupancy metrics to the AuditLog whenever a Trip record is updated.
-- Logic: Calculates percentage of seats sold vs total capacity.
CREATE OR REPLACE FUNCTION log_trip_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_occupancy_percentage DECIMAL;
    v_available_seats INT;
    v_total_seats INT;
BEGIN
    -- Calculate occupancy metrics
    SELECT COUNT(*) INTO v_total_seats
    FROM "Seat" WHERE "TripID" = NEW."TripID";

    SELECT COUNT(*) INTO v_available_seats
    FROM "Seat" WHERE "TripID" = NEW."TripID" AND "Status" = 'available';

    IF v_total_seats > 0 THEN
        v_occupancy_percentage := ((v_total_seats - v_available_seats)::DECIMAL / v_total_seats::DECIMAL) * 100;
    END IF;

    -- Store metrics in AuditLog using JSONB for flexible detail storage
    INSERT INTO "AuditLog" ("Action", "TableName", "RecordID", "Details")
    VALUES (
        'UPDATE',
        'Trip',
        NEW."TripID",
        jsonb_build_object(
            'occupancy_percentage', v_occupancy_percentage,
            'available_seats', v_available_seats,
            'total_seats', v_total_seats
        )
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_update_trip ON "Trip";
CREATE TRIGGER trg_after_update_trip
AFTER UPDATE ON "Trip"
FOR EACH ROW
EXECUTE FUNCTION log_trip_update();


-- 10. TRIGGER FUNCTION: validate_maintenance_interval
-- Purpose: Business rule enforcement: maintenance must be at least 7 days apart.
CREATE OR REPLACE FUNCTION validate_maintenance_interval()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_last_maintenance DATE;
    v_days_since_last INT;
BEGIN
    SELECT MAX("Date")
    INTO v_last_maintenance
    FROM "MaintenanceRecord"
    WHERE "VehicleID" = NEW."VehicleID"
    AND "Date" < NEW."Date";

    IF v_last_maintenance IS NOT NULL THEN
        v_days_since_last := NEW."Date" - v_last_maintenance;
        IF v_days_since_last < 7 THEN
            RAISE EXCEPTION 'Maintenance records must be at least 7 days apart';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_before_insert_maintenance ON "MaintenanceRecord";
CREATE TRIGGER trg_before_insert_maintenance
BEFORE INSERT ON "MaintenanceRecord"
FOR EACH ROW
EXECUTE FUNCTION validate_maintenance_interval();

-- 11. AUDIT TRIGGERS: Generic loggers for vehicle, trip, and driver insertions.
CREATE OR REPLACE FUNCTION audit_insert_vehicle()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "AuditLog" ("Action", "TableName", "RecordID", "Details")
    VALUES ('INSERT', 'Vehicle', NEW."VehicleID", jsonb_build_object('license_plate', NEW."LicensePlate"));
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION audit_insert_trip()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "AuditLog" ("Action", "TableName", "RecordID", "Details")
    VALUES ('INSERT', 'Trip', NEW."TripID", jsonb_build_object('route_id', NEW."RouteID", 'vehicle_id', NEW."VehicleID"));
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION audit_insert_driver()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO "AuditLog" ("Action", "TableName", "RecordID", "Details")
    VALUES ('INSERT', 'Driver', NEW."DriverID", jsonb_build_object('name', NEW."Name"));
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_insert_vehicle ON "Vehicle";
CREATE TRIGGER trg_after_insert_vehicle
AFTER INSERT ON "Vehicle"
FOR EACH ROW
EXECUTE FUNCTION audit_insert_vehicle();

DROP TRIGGER IF EXISTS trg_after_insert_trip ON "Trip";
CREATE TRIGGER trg_after_insert_trip
AFTER INSERT ON "Trip"
FOR EACH ROW
EXECUTE FUNCTION audit_insert_trip();

DROP TRIGGER IF EXISTS trg_after_insert_driver ON "Driver";
CREATE TRIGGER trg_after_insert_driver
AFTER INSERT ON "Driver"
FOR EACH ROW
EXECUTE FUNCTION audit_insert_driver();

-- ===========================================================================
-- COMPLEX SQL QUERIES (ANALYTICAL & REPORTING)
-- ===========================================================================

-- Q1. NESTED SUBQUERY: Find the most profitable route.
-- Logic: Aggregates revenue per route, then selects the one(s) matching the MAX value.
SELECT 
    r."RouteID",
    r."StartLocation",
    r."EndLocation",
    SUM(tk."Price") as total_revenue,
    COUNT(DISTINCT t."TripID") as trip_count
FROM "Route" r
JOIN "Trip" t ON r."RouteID" = t."RouteID"
LEFT JOIN "Ticket" tk ON t."TripID" = tk."TripID"
GROUP BY r."RouteID", r."StartLocation", r."EndLocation"
HAVING SUM(tk."Price") = (
    SELECT MAX(route_revenue)
    FROM (
        SELECT SUM(tk2."Price") as route_revenue
        FROM "Ticket" tk2
        JOIN "Trip" t2 ON tk2."TripID" = t2."TripID"
        GROUP BY t2."RouteID"
    ) subq
);

-- Q2. MULTI-TABLE JOIN: Comprehensive trip occupancy report.
-- Logic: Joins 5 tables to provide a status overview of all trips including real-time occupancy %.
SELECT 
    t."TripID",
    d."Name" as driver_name,
    r."StartLocation",
    r."EndLocation",
    v."LicensePlate",
    t."DepartureTime",
    COUNT(DISTINCT tk."TicketID") as booked_seats,
    COUNT(DISTINCT s."SeatNumber") as total_seats,
    ROUND(
        (COUNT(DISTINCT tk."TicketID")::DECIMAL / COUNT(DISTINCT s."SeatNumber") * 100)::NUMERIC,
        2
    ) as occupancy_percentage
FROM "Trip" t
JOIN "Driver" d ON t."DriverID" = d."DriverID"
JOIN "Route" r ON t."RouteID" = r."RouteID"
JOIN "Vehicle" v ON t."VehicleID" = v."VehicleID"
LEFT JOIN "Ticket" tk ON t."TripID" = tk."TripID"
LEFT JOIN "Seat" s ON t."TripID" = s."TripID"
GROUP BY t."TripID", d."Name", r."StartLocation", r."EndLocation", v."LicensePlate", t."DepartureTime"
ORDER BY occupancy_percentage DESC;

-- Q3. WINDOW FUNCTIONS: Monthly revenue ranking for vehicles.
-- Logic: Ranks vehicles within each month based on ticket sales using RANK() OVER.
SELECT 
    v."VehicleID",
    v."LicensePlate",
    DATE_TRUNC('month', t."DepartureTime")::DATE as month,
    SUM(tk."Price") as monthly_revenue,
    RANK() OVER (PARTITION BY DATE_TRUNC('month', t."DepartureTime") ORDER BY SUM(tk."Price") DESC) as rank
FROM "Vehicle" v
JOIN "Trip" t ON v."VehicleID" = t."VehicleID"
LEFT JOIN "Ticket" tk ON t."TripID" = tk."TripID"
GROUP BY v."VehicleID", v."LicensePlate", DATE_TRUNC('month', t."DepartureTime")
ORDER BY month DESC, rank;

-- Q4. ANALYTICAL QUERY: 7-day rolling average of passengers per route.
-- Logic: Uses ROWS BETWEEN 6 PRECEDING AND CURRENT ROW to calculate trends and smooth fluctuations.
SELECT 
    r."RouteID",
    r."StartLocation",
    DATE(t."DepartureTime") as trip_date,
    COUNT(DISTINCT tk."PassengerID") as daily_passengers,
    AVG(COUNT(DISTINCT tk."PassengerID")) OVER (
        PARTITION BY r."RouteID" 
        ORDER BY DATE(t."DepartureTime") 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as rolling_avg_7_days
FROM "Route" r
JOIN "Trip" t ON r."RouteID" = t."RouteID"
LEFT JOIN "Ticket" tk ON t."TripID" = tk."TripID"
GROUP BY r."RouteID", r."StartLocation", DATE(t."DepartureTime")
ORDER BY r."RouteID", trip_date;

-- Q5. CUBE / GROUPING SETS: Multi-dimensional revenue summary.
-- Logic: Generates sub-totals for every combination of Route, Vehicle, and Date in one pass.
SELECT 
    r."RouteID",
    v."VehicleID",
    DATE(t."DepartureTime")::DATE as trip_date,
    SUM(tk."Price") as total_revenue,
    COUNT(DISTINCT tk."TicketID") as ticket_count
FROM "Route" r
JOIN "Trip" t ON r."RouteID" = t."RouteID"
JOIN "Vehicle" v ON t."VehicleID" = v."VehicleID"
LEFT JOIN "Ticket" tk ON t."TripID" = tk."TripID"
GROUP BY CUBE (r."RouteID", v."VehicleID", DATE(t."DepartureTime")::DATE)
ORDER BY r."RouteID", v."VehicleID", trip_date;

-- Q6. REPORTING QUERY: Last 30-day operation health summary.
SELECT 
    COUNT(DISTINCT t."TripID") as total_trips,
    -- Calculates cancellations by checking null arrival times
    COUNT(DISTINCT t."TripID") - COUNT(DISTINCT CASE WHEN t."ArrivalTime" IS NOT NULL THEN t."TripID" END) as cancelled_trips,
    COALESCE(SUM(tk."Price"), 0) as total_revenue,
    COUNT(DISTINCT tk."TicketID") as total_tickets_sold,
    ROUND(
        COALESCE(SUM(tk."Price"), 0) / NULLIF(COUNT(DISTINCT t."TripID"), 0),
        2
    ) as avg_revenue_per_trip
FROM "Trip" t
LEFT JOIN "Ticket" tk ON t."TripID" = tk."TripID"
WHERE DATE(t."DepartureTime") >= CURRENT_DATE - INTERVAL '30 days';

-- Q7. JSON EXTRACTION: Fetch and format audit details.
-- Logic: Efficient access to JSONB 'details' fields for reporting and debugging.
SELECT 
    v."VehicleID",
    v."LicensePlate",
    m."RecordID",
    m."Date",
    m."Description",
    m."Cost"
FROM "Vehicle" v
LEFT JOIN "MaintenanceRecord" m ON v."VehicleID" = m."VehicleID"
WHERE m."Date" IS NOT NULL
ORDER BY v."VehicleID", m."Date" DESC;

-- Q8. INDEX OPTIMIZATION: High-performance trip lookups.
-- Logic: Specifically filtered by Route and Date to demonstrate use of B-Tree indexes on DepartureTime.
SELECT 
    t."TripID",
    r."StartLocation",
    r."EndLocation",
    t."DepartureTime"
FROM "Trip" t
JOIN "Route" r ON t."RouteID" = r."RouteID"
WHERE t."RouteID" = 1
AND DATE(t."DepartureTime") = CURRENT_DATE
ORDER BY t."DepartureTime";
