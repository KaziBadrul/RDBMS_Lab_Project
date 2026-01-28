# Postgre Commands

## Schema

```
-- =========================
-- ENUM TYPES
-- =========================
DO $$ BEGIN
  CREATE TYPE "VehicleStatus" AS ENUM ('active', 'inactive', 'maintenance');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "SeatStatus" AS ENUM ('available', 'held', 'sold');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "UserRoleType" AS ENUM ('admin', 'passenger', 'driver', 'mechanic');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "IncidentSeverity" AS ENUM ('low', 'medium', 'high', 'critical');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PaymentMethod" AS ENUM ('cash', 'card', 'mobile', 'other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "shift_type" AS ENUM ('morning', 'day', 'evening', 'night');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =========================
-- TABLES
-- =========================

-- Route
CREATE TABLE IF NOT EXISTS "Route" (
  "RouteID"        SERIAL PRIMARY KEY,
  "StartLocation"  VARCHAR(100) NOT NULL,
  "EndLocation"    VARCHAR(100) NOT NULL,
  "Distance"       NUMERIC(6,2) NOT NULL
);

-- Driver
CREATE TABLE IF NOT EXISTS "Driver" (
  "DriverID"       SERIAL PRIMARY KEY,
  "Name"           VARCHAR(100) NOT NULL,
  "LicenseNumber"  VARCHAR(50)  NOT NULL UNIQUE,
  "ContactInfo"    VARCHAR(150)
);

-- Vehicle
CREATE TABLE IF NOT EXISTS "Vehicle" (
  "VehicleID"      SERIAL PRIMARY KEY,
  "LicensePlate"   VARCHAR(30) NOT NULL UNIQUE,
  "Capacity"       INTEGER     NOT NULL,
  "Status"         "VehicleStatus" NOT NULL DEFAULT 'active'
);

-- Passenger
CREATE TABLE IF NOT EXISTS "Passenger" (
  "PassengerID"  SERIAL PRIMARY KEY,
  "Name"         VARCHAR(100) NOT NULL,
  "ContactInfo"  VARCHAR(150)
);

-- UserRole
CREATE TABLE IF NOT EXISTS "UserRole" (
  "UserID"    SERIAL PRIMARY KEY,
  "Username"  VARCHAR(50) NOT NULL UNIQUE,
  "Role"      "UserRoleType" NOT NULL DEFAULT 'passenger'
);

-- Trip
CREATE TABLE IF NOT EXISTS "Trip" (
  "TripID"          SERIAL PRIMARY KEY,
  "ArrivalTime"     TIMESTAMP,
  "DepartureTime"   TIMESTAMP NOT NULL,
  "DriverID"        INTEGER   NOT NULL,
  "RouteID"         INTEGER   NOT NULL,
  "VehicleID"       INTEGER   NOT NULL,
  "Price"           NUMERIC(8,2) NOT NULL DEFAULT 0,

  CONSTRAINT "fk_trip_driver"
    FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID")
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT "fk_trip_route"
    FOREIGN KEY ("RouteID") REFERENCES "Route"("RouteID")
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT "fk_trip_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_trip_departure" ON "Trip" ("DepartureTime");
CREATE INDEX IF NOT EXISTS "idx_trip_vehicle"    ON "Trip" ("VehicleID");
CREATE INDEX IF NOT EXISTS "idx_trip_driver"     ON "Trip" ("DriverID");

-- Seat (composite PK)
CREATE TABLE IF NOT EXISTS "Seat" (
  "SeatNumber"  INTEGER NOT NULL,
  "Status"      "SeatStatus" NOT NULL DEFAULT 'available',
  "TripID"      INTEGER NOT NULL,

  PRIMARY KEY ("TripID", "SeatNumber"),

  CONSTRAINT "fk_seat_trip"
    FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_seat_trip_status" ON "Seat" ("TripID", "Status");

-- Ticket
CREATE TABLE IF NOT EXISTS "Ticket" (
  "TicketID"       SERIAL PRIMARY KEY,
  "PassengerID"    INTEGER NOT NULL,
  "Price"          NUMERIC(8,2) NOT NULL,
  "PurchaseDate"   TIMESTAMP NOT NULL DEFAULT now(),
  "SeatNumber"     INTEGER NOT NULL,
  "TripID"         INTEGER NOT NULL,

  CONSTRAINT "uq_trip_seat"
    UNIQUE ("TripID", "SeatNumber"),

  CONSTRAINT "fk_ticket_passenger"
    FOREIGN KEY ("PassengerID") REFERENCES "Passenger"("PassengerID")
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT "fk_ticket_seat"
    FOREIGN KEY ("TripID", "SeatNumber") REFERENCES "Seat"("TripID", "SeatNumber")
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT "fk_ticket_trip"
    FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID")
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_ticket_trip"      ON "Ticket" ("TripID");
CREATE INDEX IF NOT EXISTS "idx_ticket_passenger" ON "Ticket" ("PassengerID");

-- Payment (1-1 with Ticket via unique TicketID)
CREATE TABLE IF NOT EXISTS "Payment" (
  "PaymentID"      SERIAL PRIMARY KEY,
  "TicketID"       INTEGER NOT NULL UNIQUE,
  "Amount"         NUMERIC(8,2) NOT NULL,
  "PaymentMethod"  "PaymentMethod" NOT NULL DEFAULT 'other',
  "PaymentDate"    TIMESTAMP NOT NULL DEFAULT now(),

  CONSTRAINT "fk_payment_ticket"
    FOREIGN KEY ("TicketID") REFERENCES "Ticket"("TicketID")
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- MaintenanceRecord
CREATE TABLE IF NOT EXISTS "MaintenanceRecord" (
  "RecordID"      SERIAL PRIMARY KEY,
  "VehicleID"     INTEGER NOT NULL,
  "Date"          DATE    NOT NULL,
  "Description"   TEXT,
  "Cost"          NUMERIC(10,2),

  CONSTRAINT "fk_maintenance_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_maintenance_vehicle_date"
  ON "MaintenanceRecord" ("VehicleID", "Date");

-- FuelRecord
CREATE TABLE IF NOT EXISTS "FuelRecord" (
  "FuelRecordID"  SERIAL PRIMARY KEY,
  "VehicleID"     INTEGER NOT NULL,
  "Date"          DATE    NOT NULL,
  "FuelAmount"    NUMERIC(8,2) NOT NULL,
  "Cost"          NUMERIC(10,2),

  CONSTRAINT "fk_fuel_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_fuel_vehicle_date"
  ON "FuelRecord" ("VehicleID", "Date");

-- ScheduledMaintenance
CREATE TABLE IF NOT EXISTS "ScheduledMaintenance" (
  "ScheduleID"     SERIAL PRIMARY KEY,
  "VehicleID"      INTEGER NOT NULL,
  "ScheduledDate"  DATE    NOT NULL,
  "Description"    TEXT,

  CONSTRAINT "fk_sched_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_sched_vehicle_date"
  ON "ScheduledMaintenance" ("VehicleID", "ScheduledDate");

-- IncidentReport
CREATE TABLE IF NOT EXISTS "IncidentReport" (
  "IncidentID"     SERIAL PRIMARY KEY,
  "VehicleID"      INTEGER,
  "TripID"         INTEGER,
  "IncidentDate"   TIMESTAMP NOT NULL,
  "Description"    TEXT NOT NULL,
  "Severity"       "IncidentSeverity" NOT NULL DEFAULT 'low',

  CONSTRAINT "fk_incident_trip"
    FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID")
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT "fk_incident_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_incident_date" ON "IncidentReport" ("IncidentDate");

-- AuditLog
CREATE TABLE IF NOT EXISTS "AuditLog" (
  "LogID"      SERIAL PRIMARY KEY,
  "Action"     VARCHAR(50) NOT NULL,
  "TableName"  VARCHAR(50) NOT NULL,
  "RecordID"   INTEGER     NOT NULL,
  "Timestamp"  TIMESTAMP  NOT NULL DEFAULT now(),
  "UserID"     INTEGER,
  "Details"    JSONB,

  CONSTRAINT "fk_audit_user"
    FOREIGN KEY ("UserID") REFERENCES "UserRole"("UserID")
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_audit_timestamp" ON "AuditLog" ("Timestamp");
CREATE INDEX IF NOT EXISTS "idx_audit_table_record" ON "AuditLog" ("TableName", "RecordID");

-- DailySummary
CREATE TABLE IF NOT EXISTS "DailySummary" (
  "SummaryDate"      DATE PRIMARY KEY,
  "TotalTrips"       INTEGER NOT NULL,
  "TotalTicketsSold" INTEGER NOT NULL,
  "TotalRevenue"     NUMERIC(12,2) NOT NULL
);

-- DriverVehicleAssignment (1-1 driver<->vehicle enforced by unique constraints)
CREATE TABLE IF NOT EXISTS "DriverVehicleAssignment" (
  "AssignmentID"  SERIAL PRIMARY KEY,
  "DriverID"      INTEGER NOT NULL UNIQUE,
  "VehicleID"     INTEGER NOT NULL UNIQUE,
  "AssignedAt"    TIMESTAMP(6) NOT NULL DEFAULT now(),

  CONSTRAINT "fk_assign_driver"
    FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID")
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT "fk_assign_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_assign_driver"  ON "DriverVehicleAssignment" ("DriverID");
CREATE INDEX IF NOT EXISTS "idx_assign_vehicle" ON "DriverVehicleAssignment" ("VehicleID");

-- DriverShiftAssignment
CREATE TABLE IF NOT EXISTS "DriverShiftAssignment" (
  "AssignmentID"  SERIAL PRIMARY KEY,
  "DriverID"      INTEGER NOT NULL,
  "VehicleID"     INTEGER NOT NULL,
  "AssignDate"    DATE    NOT NULL,
  "Shift"         "shift_type" NOT NULL,
  "AssignedAt"    TIMESTAMP(6) NOT NULL DEFAULT now(),
  "UnassignedAt"  TIMESTAMP(6),

  CONSTRAINT "fk_dsa_driver"
    FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID")
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT "fk_dsa_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_dsa_date_shift"
  ON "DriverShiftAssignment" ("AssignDate", "Shift");

-- DriverShiftAssignmentHistory
CREATE TABLE IF NOT EXISTS "DriverShiftAssignmentHistory" (
  "HistoryID"      SERIAL PRIMARY KEY,
  "AssignDate"     DATE NOT NULL,
  "Shift"          "shift_type" NOT NULL,
  "Action"         VARCHAR(20) NOT NULL,
  "DriverID"       INTEGER,
  "VehicleID"      INTEGER,
  "PrevDriverID"   INTEGER,
  "PrevVehicleID"  INTEGER,
  "ChangedAt"      TIMESTAMP(6) NOT NULL DEFAULT now(),
  "Note"           TEXT
);

CREATE INDEX IF NOT EXISTS "idx_dsa_hist_date_shift"
  ON "DriverShiftAssignmentHistory" ("AssignDate", "Shift");
CREATE INDEX IF NOT EXISTS "idx_dsa_hist_changedat"
  ON "DriverShiftAssignmentHistory" ("ChangedAt");

```

# APIs

## Fetch Trips

```
CREATE OR REPLACE FUNCTION get_trips_by_day(p_day date DEFAULT CURRENT_DATE)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', t."TripID",
        'departureTime', to_char(t."DepartureTime" AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
        'price', (t."Price")::float8,
        'driver', d."Name",
        'route', jsonb_build_object(
          'start', r."StartLocation",
          'end',   r."EndLocation"
        ),
        'vehicle', jsonb_build_object(
          'capacity', v."Capacity"
        )
      )
      ORDER BY t."DepartureTime"
    ),
    '[]'::jsonb
  )
  FROM "Trip" t
  JOIN "Driver" d ON d."DriverID" = t."DriverID"
  JOIN "Route"  r ON r."RouteID"  = t."RouteID"
  JOIN "Vehicle" v ON v."VehicleID" = t."VehicleID"
  WHERE t."DepartureTime" >= (p_day::timestamp)
    AND t."DepartureTime" <  ((p_day + INTERVAL '1 day')::timestamp);
$$;

-- Usage:
-- SELECT get_trips_by_day('2026-01-28'::date);
-- SELECT get_trips_by_day();  -- today

```

## Fetch a single trip

```
CREATE OR REPLACE FUNCTION get_trip_seats(p_trip_id integer)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'seatNo', s."SeatNumber",
        'status', s."Status"::text
      )
      ORDER BY s."SeatNumber" ASC
    ),
    '[]'::jsonb
  )
  FROM "Seat" s
  WHERE s."TripID" = p_trip_id;
$$;

-- Usage:
-- SELECT get_trip_seats(123);
```

## Get vehicles with shift assignment

```
CREATE OR REPLACE FUNCTION get_vehicles_with_shift_assignments(
  p_date  date DEFAULT CURRENT_DATE,
  p_shift shift_type DEFAULT 'morning'
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  WITH current_assignments AS (
    SELECT DISTINCT ON (dsa."VehicleID")
      dsa."VehicleID",
      dsa."DriverID",
      d."Name" AS driver_name
    FROM "DriverShiftAssignment" dsa
    JOIN "Driver" d ON d."DriverID" = dsa."DriverID"
    WHERE dsa."AssignDate" = p_date
      AND dsa."Shift" = p_shift
      AND dsa."UnassignedAt" IS NULL
    ORDER BY dsa."VehicleID", dsa."AssignedAt" DESC
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'vehicleId', v."VehicleID",
        'licensePlate', v."LicensePlate",
        'capacity', v."Capacity",
        'status', v."Status"::text,
        'assignedDriver',
          CASE
            WHEN ca."DriverID" IS NULL THEN NULL
            ELSE jsonb_build_object('driverId', ca."DriverID", 'name', ca.driver_name)
          END
      )
      ORDER BY v."VehicleID" ASC
    ),
    '[]'::jsonb
  )
  FROM "Vehicle" v
  LEFT JOIN current_assignments ca
    ON ca."VehicleID" = v."VehicleID";
$$;

-- Usage:
-- SELECT get_vehicles_with_shift_assignments('2026-01-28', 'morning');
-- SELECT get_vehicles_with_shift_assignments(); -- today + morning
```

## Get drivers

```
CREATE OR REPLACE FUNCTION get_drivers_with_shift_assignments(
  p_date  date DEFAULT CURRENT_DATE,
  p_shift shift_type DEFAULT 'morning'
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  WITH current_assignments AS (
    SELECT DISTINCT ON (dsa."DriverID")
      dsa."DriverID",
      dsa."VehicleID",
      v."LicensePlate" AS license_plate
    FROM "DriverShiftAssignment" dsa
    JOIN "Vehicle" v ON v."VehicleID" = dsa."VehicleID"
    WHERE dsa."AssignDate" = p_date
      AND dsa."Shift" = p_shift
      AND dsa."UnassignedAt" IS NULL
    ORDER BY dsa."DriverID", dsa."AssignedAt" DESC
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'driverId', d."DriverID",
        'name', d."Name",
        'licenseNumber', d."LicenseNumber",
        'contactInfo', d."ContactInfo",
        'assignedVehicle',
          CASE
            WHEN ca."VehicleID" IS NULL THEN NULL
            ELSE jsonb_build_object(
              'vehicleId', ca."VehicleID",
              'licensePlate', ca.license_plate
            )
          END
      )
      ORDER BY d."DriverID" ASC
    ),
    '[]'::jsonb
  )
  FROM "Driver" d
  LEFT JOIN current_assignments ca
    ON ca."DriverID" = d."DriverID";
$$;

-- Usage:
-- SELECT get_drivers_with_shift_assignments('2026-01-28', 'morning');
-- SELECT get_drivers_with_shift_assignments(); -- today + morning
```

## Assign driver to vehicle

```
CREATE OR REPLACE FUNCTION assign_driver_to_vehicle_shift(
  p_driver_id  integer,
  p_vehicle_id integer,
  p_date       date,        -- YYYY-MM-DD
  p_shift      shift_type    -- morning/day/evening/night
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_vehicle_status "VehicleStatus";
  v_existing_for_driver record;
  v_existing_for_vehicle record;
  v_now timestamptz := now();
  v_new_assignment_id integer;
  v_action text;
BEGIN
  -- Basic validation
  IF p_driver_id IS NULL OR p_driver_id <= 0
     OR p_vehicle_id IS NULL OR p_vehicle_id <= 0
     OR p_date IS NULL
     OR p_shift IS NULL THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE = '22023';
  END IF;

  -- Prevent assigning to maintenance vehicles
  SELECT v."Status"
  INTO v_vehicle_status
  FROM "Vehicle" v
  WHERE v."VehicleID" = p_vehicle_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Vehicle not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_vehicle_status = 'maintenance'::"VehicleStatus" THEN
    RAISE EXCEPTION 'Cannot assign driver to a vehicle in maintenance.'
      USING ERRCODE = 'P0001';
  END IF;

  -- Lock conflicting active rows to avoid race conditions.
  -- (Locks all active assignments for that date+shift for this driver or vehicle)
  PERFORM 1
  FROM "DriverShiftAssignment" dsa
  WHERE dsa."AssignDate" = p_date
    AND dsa."Shift" = p_shift
    AND dsa."UnassignedAt" IS NULL
    AND (dsa."DriverID" = p_driver_id OR dsa."VehicleID" = p_vehicle_id)
  FOR UPDATE;

  -- Find existing active assignment for driver (same date+shift)
  SELECT
    dsa."AssignmentID"  AS assignment_id,
    dsa."DriverID"      AS driver_id,
    dsa."VehicleID"     AS vehicle_id
  INTO v_existing_for_driver
  FROM "DriverShiftAssignment" dsa
  WHERE dsa."DriverID" = p_driver_id
    AND dsa."AssignDate" = p_date
    AND dsa."Shift" = p_shift
    AND dsa."UnassignedAt" IS NULL
  ORDER BY dsa."AssignedAt" DESC
  LIMIT 1;

  -- Find existing active assignment for vehicle (same date+shift)
  SELECT
    dsa."AssignmentID"  AS assignment_id,
    dsa."DriverID"      AS driver_id,
    dsa."VehicleID"     AS vehicle_id
  INTO v_existing_for_vehicle
  FROM "DriverShiftAssignment" dsa
  WHERE dsa."VehicleID" = p_vehicle_id
    AND dsa."AssignDate" = p_date
    AND dsa."Shift" = p_shift
    AND dsa."UnassignedAt" IS NULL
  ORDER BY dsa."AssignedAt" DESC
  LIMIT 1;

  -- Close existing driver assignment (if any) and write UNASSIGN history
  IF v_existing_for_driver.assignment_id IS NOT NULL THEN
    UPDATE "DriverShiftAssignment"
    SET "UnassignedAt" = v_now
    WHERE "AssignmentID" = v_existing_for_driver.assignment_id;

    INSERT INTO "DriverShiftAssignmentHistory"
      ("AssignDate","Shift","Action","DriverID","VehicleID","Note")
    VALUES
      (p_date, p_shift, 'UNASSIGN',
       v_existing_for_driver.driver_id,
       v_existing_for_driver.vehicle_id,
       'Auto-unassign: driver reassigned');
  END IF;

  -- Close existing vehicle assignment (if any) and write UNASSIGN history
  IF v_existing_for_vehicle.assignment_id IS NOT NULL THEN
    -- Avoid double-unassign if it's the exact same row already closed above
    IF v_existing_for_driver.assignment_id IS NULL
       OR v_existing_for_vehicle.assignment_id <> v_existing_for_driver.assignment_id THEN

      UPDATE "DriverShiftAssignment"
      SET "UnassignedAt" = v_now
      WHERE "AssignmentID" = v_existing_for_vehicle.assignment_id;

      INSERT INTO "DriverShiftAssignmentHistory"
        ("AssignDate","Shift","Action","DriverID","VehicleID","Note")
      VALUES
        (p_date, p_shift, 'UNASSIGN',
         v_existing_for_vehicle.driver_id,
         v_existing_for_vehicle.vehicle_id,
         'Auto-unassign: vehicle reassigned');
    END IF;
  END IF;

  -- Create new assignment
  INSERT INTO "DriverShiftAssignment"
    ("DriverID","VehicleID","AssignDate","Shift","AssignedAt","UnassignedAt")
  VALUES
    (p_driver_id, p_vehicle_id, p_date, p_shift, v_now, NULL)
  RETURNING "AssignmentID" INTO v_new_assignment_id;

  -- ASSIGN or REASSIGN
  v_action := CASE
    WHEN v_existing_for_driver.assignment_id IS NOT NULL
      OR v_existing_for_vehicle.assignment_id IS NOT NULL
    THEN 'REASSIGN'
    ELSE 'ASSIGN'
  END;

  -- Write history entry
  INSERT INTO "DriverShiftAssignmentHistory"
    ("AssignDate","Shift","Action","DriverID","VehicleID",
     "PrevDriverID","PrevVehicleID","Note")
  VALUES
    (p_date, p_shift, v_action,
     p_driver_id, p_vehicle_id,
     COALESCE(v_existing_for_vehicle.driver_id, NULL),
     COALESCE(v_existing_for_driver.vehicle_id, NULL),
     'Assigned from /driver page');

  RETURN jsonb_build_object('ok', true, 'assignmentId', v_new_assignment_id);
END;
$$;
```

### How to call

```
SELECT assign_driver_to_vehicle_shift(
  5,                 -- driverId
  12,                -- vehicleId
  '2026-01-28'::date,
  'morning'::shift_type
);
```

## Unassign driver from vehicle

```
CREATE OR REPLACE FUNCTION unassign_driver_shift(
  p_driver_id integer,
  p_date      date,       -- YYYY-MM-DD
  p_shift     shift_type   -- morning/day/evening/night
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_existing record;
  v_now timestamptz := now();
BEGIN
  -- Validate input (matches your API validation intent)
  IF p_driver_id IS NULL OR p_driver_id <= 0
     OR p_date IS NULL
     OR p_shift IS NULL THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE = '22023';
  END IF;

  -- Find existing active assignment (lock it to avoid races)
  SELECT
    dsa."AssignmentID" AS assignment_id,
    dsa."DriverID"     AS driver_id,
    dsa."VehicleID"    AS vehicle_id
  INTO v_existing
  FROM "DriverShiftAssignment" dsa
  WHERE dsa."DriverID" = p_driver_id
    AND dsa."AssignDate" = p_date
    AND dsa."Shift" = p_shift
    AND dsa."UnassignedAt" IS NULL
  ORDER BY dsa."AssignedAt" DESC
  LIMIT 1
  FOR UPDATE;

  -- If nothing to do, return ok:true
  IF v_existing.assignment_id IS NULL THEN
    RETURN jsonb_build_object('ok', true);
  END IF;

  -- Close the assignment
  UPDATE "DriverShiftAssignment"
  SET "UnassignedAt" = v_now
  WHERE "AssignmentID" = v_existing.assignment_id;

  -- Write history
  INSERT INTO "DriverShiftAssignmentHistory"
    ("AssignDate","Shift","Action","DriverID","VehicleID","Note")
  VALUES
    (p_date, p_shift, 'UNASSIGN',
     v_existing.driver_id, v_existing.vehicle_id,
     'Unassigned from /driver page');

  RETURN jsonb_build_object('ok', true);
END;
$$;
```

### How to call

```
SELECT unassign_driver_shift(
  7,
  '2026-01-28'::date,
  'morning'::shift_type
);
```

## Get driver assignment history

```
CREATE OR REPLACE FUNCTION get_shift_assignment_history(
  p_date  date DEFAULT NULL,
  p_shift shift_type DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'historyId', h."HistoryID",
        'assignDate', to_char(h."AssignDate", 'YYYY-MM-DD'),
        'shift', h."Shift"::text,
        'action', h."Action",
        'driverId', h."DriverID",
        'vehicleId', h."VehicleID",
        'prevDriverId', h."PrevDriverID",
        'prevVehicleId', h."PrevVehicleID",
        'changedAt', to_char(h."ChangedAt" AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
        'note', h."Note"
      )
      ORDER BY h."ChangedAt" DESC
    ),
    '[]'::jsonb
  )
  FROM "DriverShiftAssignmentHistory" h
  WHERE (p_date IS NULL OR h."AssignDate" = p_date)
    AND (p_shift IS NULL OR h."Shift" = p_shift)
  LIMIT 200;
$$;

-- Usage:
-- SELECT get_shift_assignment_history('2026-01-28', 'morning');
-- SELECT get_shift_assignment_history(NULL, 'night');
-- SELECT get_shift_assignment_history('2026-01-28', NULL);
-- SELECT get_shift_assignment_history();
```

## Book a ticket

```
CREATE OR REPLACE FUNCTION book_seats(
  p_trip_id      integer,
  p_seat_numbers integer[],
  p_name         text,
  p_contact_info text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_seats           integer[];
  v_requested_count integer;
  v_available_count integer;
  v_updated_count   integer;
  v_passenger_id    integer;
  v_tickets         jsonb;
BEGIN
  -- Basic validation (similar to your JS checks)
  IF p_trip_id IS NULL OR p_trip_id <= 0 THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE = '22023';
  END IF;

  IF p_seat_numbers IS NULL OR array_length(p_seat_numbers, 1) IS NULL THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE = '22023';
  END IF;

  -- Deduplicate seat numbers (like Set() in JS)
  SELECT array_agg(DISTINCT s ORDER BY s)
  INTO v_seats
  FROM unnest(p_seat_numbers) AS s
  WHERE s IS NOT NULL;

  v_requested_count := COALESCE(array_length(v_seats, 1), 0);

  IF v_requested_count = 0 THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE = '22023';
  END IF;

  IF p_name IS NULL OR btrim(p_name) = '' THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE = '22023';
  END IF;

  -- 1) Ensure all seats exist and are available
  -- Lock matching seat rows so concurrent bookings serialize correctly.
  SELECT count(*)
  INTO v_available_count
  FROM "Seat" s
  WHERE s."TripID" = p_trip_id
    AND s."SeatNumber" = ANY (v_seats)
    AND s."Status" = 'available'::"SeatStatus"
  FOR UPDATE;

  IF v_available_count <> v_requested_count THEN
    RAISE EXCEPTION 'Seat already booked' USING ERRCODE = 'P0001';
  END IF;

  -- 2) Mark them sold (guarded update)
  UPDATE "Seat" s
  SET "Status" = 'sold'::"SeatStatus"
  WHERE s."TripID" = p_trip_id
    AND s."SeatNumber" = ANY (v_seats)
    AND s."Status" = 'available'::"SeatStatus";

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  IF v_updated_count <> v_requested_count THEN
    RAISE EXCEPTION 'Seat already booked' USING ERRCODE = 'P0001';
  END IF;

  -- 3) Create passenger
  INSERT INTO "Passenger" ("Name", "ContactInfo")
  VALUES (p_name, p_contact_info)
  RETURNING "PassengerID" INTO v_passenger_id;

  -- 4) Create tickets (one per seat)
  -- (Price is set to 0 like your code; replace as needed)
  WITH ins AS (
    INSERT INTO "Ticket" ("PassengerID", "Price", "SeatNumber", "TripID")
    SELECT
      v_passenger_id,
      0::numeric(8,2),
      sn,
      p_trip_id
    FROM unnest(v_seats) AS sn
    RETURNING "TicketID", "SeatNumber"
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'ticketId', "TicketID",
        'seatNumber', "SeatNumber"
      )
      ORDER BY "SeatNumber"
    ),
    '[]'::jsonb
  )
  INTO v_tickets
  FROM ins;

  RETURN jsonb_build_object(
    'ok', true,
    'passengerId', v_passenger_id,
    'tickets', v_tickets
  );
END;
$$;
```

### How to call it

```
SELECT book_seats(
  12,
  ARRAY[1,2,2,3],   -- duplicates are fine; function dedupes
  'Kazi Badrul Hasan',
  '0123456789'
);
```
