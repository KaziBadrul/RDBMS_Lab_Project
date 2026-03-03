--
-- PostgreSQL database dump
--

\restrict naetBf2cHOozC064K56XKE3pIygwBNL8xXcgiQeJgDoeSz9GcdLFcuoZi6NoIvu

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: IncidentSeverity; Type: TYPE; Schema: public; Owner: transport_user
--

CREATE TYPE public."IncidentSeverity" AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);


ALTER TYPE public."IncidentSeverity" OWNER TO transport_user;

--
-- Name: PaymentMethod; Type: TYPE; Schema: public; Owner: transport_user
--

CREATE TYPE public."PaymentMethod" AS ENUM (
    'cash',
    'card',
    'mobile',
    'other'
);


ALTER TYPE public."PaymentMethod" OWNER TO transport_user;

--
-- Name: SeatStatus; Type: TYPE; Schema: public; Owner: transport_user
--

CREATE TYPE public."SeatStatus" AS ENUM (
    'available',
    'held',
    'sold'
);


ALTER TYPE public."SeatStatus" OWNER TO transport_user;

--
-- Name: UserRoleType; Type: TYPE; Schema: public; Owner: transport_user
--

CREATE TYPE public."UserRoleType" AS ENUM (
    'admin',
    'passenger',
    'driver',
    'mechanic'
);


ALTER TYPE public."UserRoleType" OWNER TO transport_user;

--
-- Name: VehicleStatus; Type: TYPE; Schema: public; Owner: transport_user
--

CREATE TYPE public."VehicleStatus" AS ENUM (
    'active',
    'inactive',
    'maintenance'
);


ALTER TYPE public."VehicleStatus" OWNER TO transport_user;

--
-- Name: shift_type; Type: TYPE; Schema: public; Owner: transport_user
--

CREATE TYPE public.shift_type AS ENUM (
    'morning',
    'day',
    'evening',
    'night'
);


ALTER TYPE public.shift_type OWNER TO transport_user;

--
-- Name: assign_driver_to_trip(integer, integer); Type: PROCEDURE; Schema: public; Owner: transport_user
--

CREATE PROCEDURE public.assign_driver_to_trip(IN p_driver_id integer, IN p_trip_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_existing_trip_count INT;
BEGIN
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

    UPDATE "Trip"
    SET "DriverID" = p_driver_id
    WHERE "TripID" = p_trip_id;

    RAISE NOTICE 'Driver % assigned to trip %', p_driver_id, p_trip_id;
END;
$$;


ALTER PROCEDURE public.assign_driver_to_trip(IN p_driver_id integer, IN p_trip_id integer) OWNER TO transport_user;

--
-- Name: audit_insert_driver(); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.audit_insert_driver() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO "AuditLog" ("Action", "TableName", "RecordID", "Details")
    VALUES ('INSERT', 'Driver', NEW."DriverID", jsonb_build_object('name', NEW."Name"));
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.audit_insert_driver() OWNER TO transport_user;

--
-- Name: audit_insert_trip(); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.audit_insert_trip() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO "AuditLog" ("Action", "TableName", "RecordID", "Details")
    VALUES ('INSERT', 'Trip', NEW."TripID", jsonb_build_object('route_id', NEW."RouteID", 'vehicle_id', NEW."VehicleID"));
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.audit_insert_trip() OWNER TO transport_user;

--
-- Name: audit_insert_vehicle(); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.audit_insert_vehicle() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO "AuditLog" ("Action", "TableName", "RecordID", "Details")
    VALUES ('INSERT', 'Vehicle', NEW."VehicleID", jsonb_build_object('license_plate', NEW."LicensePlate"));
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.audit_insert_vehicle() OWNER TO transport_user;

--
-- Name: calculate_trip_revenue(integer); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.calculate_trip_revenue(p_trip_id integer) RETURNS numeric
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


ALTER FUNCTION public.calculate_trip_revenue(p_trip_id integer) OWNER TO transport_user;

--
-- Name: generate_daily_trip_summary(date); Type: PROCEDURE; Schema: public; Owner: transport_user
--

CREATE PROCEDURE public.generate_daily_trip_summary(IN p_date date)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_trips INT;
    v_total_revenue DECIMAL;
    v_total_passengers INT;
BEGIN
    -- Calculate daily metrics
    SELECT 
        COUNT(DISTINCT t."TripID"),
        COALESCE(SUM(tk."Price"), 0),
        COUNT(DISTINCT tk."PassengerID")
    INTO v_total_trips, v_total_revenue, v_total_passengers
    FROM "Trip" t
    LEFT JOIN "Ticket" tk ON t."TripID" = tk."TripID"
    WHERE DATE(t."DepartureTime") = p_date;

    -- Insert or update daily summary
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


ALTER PROCEDURE public.generate_daily_trip_summary(IN p_date date) OWNER TO transport_user;

--
-- Name: get_available_seats(integer); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.get_available_seats(p_trip_id integer) RETURNS TABLE(seat_number integer, status text)
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


ALTER FUNCTION public.get_available_seats(p_trip_id integer) OWNER TO transport_user;

--
-- Name: log_trip_update(); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.log_trip_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_occupancy_percentage DECIMAL;
    v_available_seats INT;
    v_total_seats INT;
BEGIN
    -- Calculate occupancy
    SELECT COUNT(*) INTO v_total_seats
    FROM "Seat" WHERE "TripID" = NEW."TripID";

    SELECT COUNT(*) INTO v_available_seats
    FROM "Seat" WHERE "TripID" = NEW."TripID" AND "Status" = 'available';

    IF v_total_seats > 0 THEN
        v_occupancy_percentage := ((v_total_seats - v_available_seats)::DECIMAL / v_total_seats::DECIMAL) * 100;
    END IF;

    -- Log to AuditLog
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


ALTER FUNCTION public.log_trip_update() OWNER TO transport_user;

--
-- Name: next_maintenance_due(integer); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.next_maintenance_due(p_vehicle_id integer) RETURNS date
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_last_maintenance DATE;
    v_next_due DATE;
    v_maintenance_interval INT := 30;
BEGIN
    SELECT MAX("Date")
    INTO v_last_maintenance
    FROM "MaintenanceRecord"
    WHERE "VehicleID" = p_vehicle_id;

    IF v_last_maintenance IS NULL THEN
        v_next_due := CURRENT_DATE;
    ELSE
        v_next_due := v_last_maintenance + (v_maintenance_interval || ' days')::INTERVAL;
    END IF;

    RETURN v_next_due;
END;
$$;


ALTER FUNCTION public.next_maintenance_due(p_vehicle_id integer) OWNER TO transport_user;

--
-- Name: prevent_duplicate_seats(); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.prevent_duplicate_seats() RETURNS trigger
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


ALTER FUNCTION public.prevent_duplicate_seats() OWNER TO transport_user;

--
-- Name: record_ticket_purchase(integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: transport_user
--

CREATE PROCEDURE public.record_ticket_purchase(IN p_trip_id integer, IN p_passenger_id integer, IN p_seat_number integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_seat_status "SeatStatus";
    v_ticket_price DECIMAL;
BEGIN
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

    SELECT ("Price")::DECIMAL
    INTO v_ticket_price
    FROM "Trip"
    WHERE "TripID" = p_trip_id;

    INSERT INTO "Ticket" ("TripID", "PassengerID", "SeatNumber", "Price")
    VALUES (p_trip_id, p_passenger_id, p_seat_number, v_ticket_price);

    UPDATE "Seat"
    SET "Status" = 'sold'
    WHERE "TripID" = p_trip_id
    AND "SeatNumber" = p_seat_number;

    RAISE NOTICE 'Ticket purchased for passenger % on seat % of trip %', 
        p_passenger_id, p_seat_number, p_trip_id;
END;
$$;


ALTER PROCEDURE public.record_ticket_purchase(IN p_trip_id integer, IN p_passenger_id integer, IN p_seat_number integer) OWNER TO transport_user;

--
-- Name: update_trip_available_seats(); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.update_trip_available_seats() RETURNS trigger
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


ALTER FUNCTION public.update_trip_available_seats() OWNER TO transport_user;

--
-- Name: validate_maintenance_interval(); Type: FUNCTION; Schema: public; Owner: transport_user
--

CREATE FUNCTION public.validate_maintenance_interval() RETURNS trigger
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


ALTER FUNCTION public.validate_maintenance_interval() OWNER TO transport_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: AuditLog; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."AuditLog" (
    "LogID" integer NOT NULL,
    "Action" character varying(50) NOT NULL,
    "TableName" character varying(50) NOT NULL,
    "RecordID" integer NOT NULL,
    "Timestamp" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UserID" integer,
    "Details" jsonb
);


ALTER TABLE public."AuditLog" OWNER TO transport_user;

--
-- Name: AuditLog_LogID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."AuditLog_LogID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."AuditLog_LogID_seq" OWNER TO transport_user;

--
-- Name: AuditLog_LogID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."AuditLog_LogID_seq" OWNED BY public."AuditLog"."LogID";


--
-- Name: DailySummary; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."DailySummary" (
    "SummaryDate" date NOT NULL,
    "TotalTrips" integer NOT NULL,
    "TotalTicketsSold" integer NOT NULL,
    "TotalRevenue" numeric(12,2) NOT NULL
);


ALTER TABLE public."DailySummary" OWNER TO transport_user;

--
-- Name: Driver; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."Driver" (
    "DriverID" integer NOT NULL,
    "Name" character varying(100) NOT NULL,
    "LicenseNumber" character varying(50) NOT NULL,
    "ContactInfo" character varying(150)
);


ALTER TABLE public."Driver" OWNER TO transport_user;

--
-- Name: DriverShiftAssignment; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."DriverShiftAssignment" (
    "AssignmentID" integer NOT NULL,
    "DriverID" integer NOT NULL,
    "VehicleID" integer NOT NULL,
    "AssignDate" date NOT NULL,
    "Shift" public.shift_type NOT NULL,
    "AssignedAt" timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UnassignedAt" timestamp(6) without time zone
);


ALTER TABLE public."DriverShiftAssignment" OWNER TO transport_user;

--
-- Name: DriverShiftAssignmentHistory; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."DriverShiftAssignmentHistory" (
    "HistoryID" integer NOT NULL,
    "AssignDate" date NOT NULL,
    "Shift" public.shift_type NOT NULL,
    "Action" character varying(20) NOT NULL,
    "DriverID" integer,
    "VehicleID" integer,
    "PrevDriverID" integer,
    "PrevVehicleID" integer,
    "ChangedAt" timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "Note" text
);


ALTER TABLE public."DriverShiftAssignmentHistory" OWNER TO transport_user;

--
-- Name: DriverShiftAssignmentHistory_HistoryID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."DriverShiftAssignmentHistory_HistoryID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."DriverShiftAssignmentHistory_HistoryID_seq" OWNER TO transport_user;

--
-- Name: DriverShiftAssignmentHistory_HistoryID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."DriverShiftAssignmentHistory_HistoryID_seq" OWNED BY public."DriverShiftAssignmentHistory"."HistoryID";


--
-- Name: DriverShiftAssignment_AssignmentID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."DriverShiftAssignment_AssignmentID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."DriverShiftAssignment_AssignmentID_seq" OWNER TO transport_user;

--
-- Name: DriverShiftAssignment_AssignmentID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."DriverShiftAssignment_AssignmentID_seq" OWNED BY public."DriverShiftAssignment"."AssignmentID";


--
-- Name: DriverVehicleAssignment; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."DriverVehicleAssignment" (
    "AssignmentID" integer NOT NULL,
    "DriverID" integer NOT NULL,
    "VehicleID" integer NOT NULL,
    "AssignedAt" timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."DriverVehicleAssignment" OWNER TO transport_user;

--
-- Name: DriverVehicleAssignment_AssignmentID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."DriverVehicleAssignment_AssignmentID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."DriverVehicleAssignment_AssignmentID_seq" OWNER TO transport_user;

--
-- Name: DriverVehicleAssignment_AssignmentID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."DriverVehicleAssignment_AssignmentID_seq" OWNED BY public."DriverVehicleAssignment"."AssignmentID";


--
-- Name: Driver_DriverID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."Driver_DriverID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Driver_DriverID_seq" OWNER TO transport_user;

--
-- Name: Driver_DriverID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."Driver_DriverID_seq" OWNED BY public."Driver"."DriverID";


--
-- Name: FuelRecord; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."FuelRecord" (
    "FuelRecordID" integer NOT NULL,
    "VehicleID" integer NOT NULL,
    "Date" date NOT NULL,
    "FuelAmount" numeric(8,2) NOT NULL,
    "Cost" numeric(10,2)
);


ALTER TABLE public."FuelRecord" OWNER TO transport_user;

--
-- Name: FuelRecord_FuelRecordID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."FuelRecord_FuelRecordID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."FuelRecord_FuelRecordID_seq" OWNER TO transport_user;

--
-- Name: FuelRecord_FuelRecordID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."FuelRecord_FuelRecordID_seq" OWNED BY public."FuelRecord"."FuelRecordID";


--
-- Name: IncidentReport; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."IncidentReport" (
    "IncidentID" integer NOT NULL,
    "VehicleID" integer,
    "TripID" integer,
    "IncidentDate" timestamp(3) without time zone NOT NULL,
    "Description" text NOT NULL,
    "Severity" public."IncidentSeverity" DEFAULT 'low'::public."IncidentSeverity" NOT NULL
);


ALTER TABLE public."IncidentReport" OWNER TO transport_user;

--
-- Name: IncidentReport_IncidentID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."IncidentReport_IncidentID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."IncidentReport_IncidentID_seq" OWNER TO transport_user;

--
-- Name: IncidentReport_IncidentID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."IncidentReport_IncidentID_seq" OWNED BY public."IncidentReport"."IncidentID";


--
-- Name: MaintenanceRecord; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."MaintenanceRecord" (
    "RecordID" integer NOT NULL,
    "VehicleID" integer NOT NULL,
    "Date" date NOT NULL,
    "Description" text,
    "Cost" numeric(10,2)
);


ALTER TABLE public."MaintenanceRecord" OWNER TO transport_user;

--
-- Name: MaintenanceRecord_RecordID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."MaintenanceRecord_RecordID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."MaintenanceRecord_RecordID_seq" OWNER TO transport_user;

--
-- Name: MaintenanceRecord_RecordID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."MaintenanceRecord_RecordID_seq" OWNED BY public."MaintenanceRecord"."RecordID";


--
-- Name: Passenger; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."Passenger" (
    "PassengerID" integer NOT NULL,
    "Name" character varying(100) NOT NULL,
    "ContactInfo" character varying(150)
);


ALTER TABLE public."Passenger" OWNER TO transport_user;

--
-- Name: Passenger_PassengerID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."Passenger_PassengerID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Passenger_PassengerID_seq" OWNER TO transport_user;

--
-- Name: Passenger_PassengerID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."Passenger_PassengerID_seq" OWNED BY public."Passenger"."PassengerID";


--
-- Name: Payment; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."Payment" (
    "PaymentID" integer NOT NULL,
    "TicketID" integer NOT NULL,
    "Amount" numeric(8,2) NOT NULL,
    "PaymentMethod" public."PaymentMethod" DEFAULT 'other'::public."PaymentMethod" NOT NULL,
    "PaymentDate" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."Payment" OWNER TO transport_user;

--
-- Name: Payment_PaymentID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."Payment_PaymentID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Payment_PaymentID_seq" OWNER TO transport_user;

--
-- Name: Payment_PaymentID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."Payment_PaymentID_seq" OWNED BY public."Payment"."PaymentID";


--
-- Name: Route; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."Route" (
    "RouteID" integer NOT NULL,
    "StartLocation" character varying(100) NOT NULL,
    "EndLocation" character varying(100) NOT NULL,
    "Distance" numeric(6,2) NOT NULL
);


ALTER TABLE public."Route" OWNER TO transport_user;

--
-- Name: Route_RouteID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."Route_RouteID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Route_RouteID_seq" OWNER TO transport_user;

--
-- Name: Route_RouteID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."Route_RouteID_seq" OWNED BY public."Route"."RouteID";


--
-- Name: ScheduledMaintenance; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."ScheduledMaintenance" (
    "ScheduleID" integer NOT NULL,
    "VehicleID" integer NOT NULL,
    "ScheduledDate" date NOT NULL,
    "Description" text
);


ALTER TABLE public."ScheduledMaintenance" OWNER TO transport_user;

--
-- Name: ScheduledMaintenance_ScheduleID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."ScheduledMaintenance_ScheduleID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ScheduledMaintenance_ScheduleID_seq" OWNER TO transport_user;

--
-- Name: ScheduledMaintenance_ScheduleID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."ScheduledMaintenance_ScheduleID_seq" OWNED BY public."ScheduledMaintenance"."ScheduleID";


--
-- Name: Seat; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."Seat" (
    "SeatNumber" integer NOT NULL,
    "Status" public."SeatStatus" DEFAULT 'available'::public."SeatStatus" NOT NULL,
    "TripID" integer NOT NULL
);


ALTER TABLE public."Seat" OWNER TO transport_user;

--
-- Name: Ticket; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."Ticket" (
    "PassengerID" integer NOT NULL,
    "Price" numeric(8,2) NOT NULL,
    "PurchaseDate" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "SeatNumber" integer NOT NULL,
    "TicketID" integer NOT NULL,
    "TripID" integer NOT NULL
);


ALTER TABLE public."Ticket" OWNER TO transport_user;

--
-- Name: Ticket_TicketID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."Ticket_TicketID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Ticket_TicketID_seq" OWNER TO transport_user;

--
-- Name: Ticket_TicketID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."Ticket_TicketID_seq" OWNED BY public."Ticket"."TicketID";


--
-- Name: Trip; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."Trip" (
    "ArrivalTime" timestamp(3) without time zone,
    "DepartureTime" timestamp(3) without time zone NOT NULL,
    "DriverID" integer NOT NULL,
    "RouteID" integer NOT NULL,
    "TripID" integer NOT NULL,
    "VehicleID" integer NOT NULL,
    "Price" numeric(8,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public."Trip" OWNER TO transport_user;

--
-- Name: Trip_TripID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."Trip_TripID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Trip_TripID_seq" OWNER TO transport_user;

--
-- Name: Trip_TripID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."Trip_TripID_seq" OWNED BY public."Trip"."TripID";


--
-- Name: UserRole; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."UserRole" (
    "UserID" integer NOT NULL,
    "Username" character varying(50) NOT NULL,
    "Role" public."UserRoleType" DEFAULT 'passenger'::public."UserRoleType" NOT NULL
);


ALTER TABLE public."UserRole" OWNER TO transport_user;

--
-- Name: UserRole_UserID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."UserRole_UserID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."UserRole_UserID_seq" OWNER TO transport_user;

--
-- Name: UserRole_UserID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."UserRole_UserID_seq" OWNED BY public."UserRole"."UserID";


--
-- Name: Vehicle; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public."Vehicle" (
    "VehicleID" integer NOT NULL,
    "LicensePlate" character varying(30) NOT NULL,
    "Capacity" integer NOT NULL,
    "Status" public."VehicleStatus" DEFAULT 'active'::public."VehicleStatus" NOT NULL
);


ALTER TABLE public."Vehicle" OWNER TO transport_user;

--
-- Name: Vehicle_VehicleID_seq; Type: SEQUENCE; Schema: public; Owner: transport_user
--

CREATE SEQUENCE public."Vehicle_VehicleID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Vehicle_VehicleID_seq" OWNER TO transport_user;

--
-- Name: Vehicle_VehicleID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: transport_user
--

ALTER SEQUENCE public."Vehicle_VehicleID_seq" OWNED BY public."Vehicle"."VehicleID";


--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: transport_user
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public._prisma_migrations OWNER TO transport_user;

--
-- Name: AuditLog LogID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."AuditLog" ALTER COLUMN "LogID" SET DEFAULT nextval('public."AuditLog_LogID_seq"'::regclass);


--
-- Name: Driver DriverID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Driver" ALTER COLUMN "DriverID" SET DEFAULT nextval('public."Driver_DriverID_seq"'::regclass);


--
-- Name: DriverShiftAssignment AssignmentID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverShiftAssignment" ALTER COLUMN "AssignmentID" SET DEFAULT nextval('public."DriverShiftAssignment_AssignmentID_seq"'::regclass);


--
-- Name: DriverShiftAssignmentHistory HistoryID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverShiftAssignmentHistory" ALTER COLUMN "HistoryID" SET DEFAULT nextval('public."DriverShiftAssignmentHistory_HistoryID_seq"'::regclass);


--
-- Name: DriverVehicleAssignment AssignmentID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverVehicleAssignment" ALTER COLUMN "AssignmentID" SET DEFAULT nextval('public."DriverVehicleAssignment_AssignmentID_seq"'::regclass);


--
-- Name: FuelRecord FuelRecordID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."FuelRecord" ALTER COLUMN "FuelRecordID" SET DEFAULT nextval('public."FuelRecord_FuelRecordID_seq"'::regclass);


--
-- Name: IncidentReport IncidentID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."IncidentReport" ALTER COLUMN "IncidentID" SET DEFAULT nextval('public."IncidentReport_IncidentID_seq"'::regclass);


--
-- Name: MaintenanceRecord RecordID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."MaintenanceRecord" ALTER COLUMN "RecordID" SET DEFAULT nextval('public."MaintenanceRecord_RecordID_seq"'::regclass);


--
-- Name: Passenger PassengerID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Passenger" ALTER COLUMN "PassengerID" SET DEFAULT nextval('public."Passenger_PassengerID_seq"'::regclass);


--
-- Name: Payment PaymentID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Payment" ALTER COLUMN "PaymentID" SET DEFAULT nextval('public."Payment_PaymentID_seq"'::regclass);


--
-- Name: Route RouteID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Route" ALTER COLUMN "RouteID" SET DEFAULT nextval('public."Route_RouteID_seq"'::regclass);


--
-- Name: ScheduledMaintenance ScheduleID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."ScheduledMaintenance" ALTER COLUMN "ScheduleID" SET DEFAULT nextval('public."ScheduledMaintenance_ScheduleID_seq"'::regclass);


--
-- Name: Ticket TicketID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Ticket" ALTER COLUMN "TicketID" SET DEFAULT nextval('public."Ticket_TicketID_seq"'::regclass);


--
-- Name: Trip TripID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Trip" ALTER COLUMN "TripID" SET DEFAULT nextval('public."Trip_TripID_seq"'::regclass);


--
-- Name: UserRole UserID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."UserRole" ALTER COLUMN "UserID" SET DEFAULT nextval('public."UserRole_UserID_seq"'::regclass);


--
-- Name: Vehicle VehicleID; Type: DEFAULT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Vehicle" ALTER COLUMN "VehicleID" SET DEFAULT nextval('public."Vehicle_VehicleID_seq"'::regclass);


--
-- Data for Name: AuditLog; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."AuditLog" ("LogID", "Action", "TableName", "RecordID", "Timestamp", "UserID", "Details") FROM stdin;
\.


--
-- Data for Name: DailySummary; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."DailySummary" ("SummaryDate", "TotalTrips", "TotalTicketsSold", "TotalRevenue") FROM stdin;
\.


--
-- Data for Name: Driver; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."Driver" ("DriverID", "Name", "LicenseNumber", "ContactInfo") FROM stdin;
9	Abdul Karim	DL-DHK-1001	01711-111111
10	Shafiqul Islam	DL-DHK-1002	01722-222222
11	Monir Hossain	DL-DHK-1003	01811-333333
12	Rafiqul Hasan	DL-DHK-1004	01911-444444
\.


--
-- Data for Name: DriverShiftAssignment; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."DriverShiftAssignment" ("AssignmentID", "DriverID", "VehicleID", "AssignDate", "Shift", "AssignedAt", "UnassignedAt") FROM stdin;
\.


--
-- Data for Name: DriverShiftAssignmentHistory; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."DriverShiftAssignmentHistory" ("HistoryID", "AssignDate", "Shift", "Action", "DriverID", "VehicleID", "PrevDriverID", "PrevVehicleID", "ChangedAt", "Note") FROM stdin;
1	2026-01-28	morning	ASSIGN	5	6	\N	\N	2026-01-29 02:30:49.295	Assigned from /driver page
2	2026-01-28	morning	ASSIGN	6	8	\N	\N	2026-01-29 02:30:52.594	Assigned from /driver page
\.


--
-- Data for Name: DriverVehicleAssignment; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."DriverVehicleAssignment" ("AssignmentID", "DriverID", "VehicleID", "AssignedAt") FROM stdin;
\.


--
-- Data for Name: FuelRecord; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."FuelRecord" ("FuelRecordID", "VehicleID", "Date", "FuelAmount", "Cost") FROM stdin;
\.


--
-- Data for Name: IncidentReport; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."IncidentReport" ("IncidentID", "VehicleID", "TripID", "IncidentDate", "Description", "Severity") FROM stdin;
\.


--
-- Data for Name: MaintenanceRecord; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."MaintenanceRecord" ("RecordID", "VehicleID", "Date", "Description", "Cost") FROM stdin;
\.


--
-- Data for Name: Passenger; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."Passenger" ("PassengerID", "Name", "ContactInfo") FROM stdin;
\.


--
-- Data for Name: Payment; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."Payment" ("PaymentID", "TicketID", "Amount", "PaymentMethod", "PaymentDate") FROM stdin;
\.


--
-- Data for Name: Route; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."Route" ("RouteID", "StartLocation", "EndLocation", "Distance") FROM stdin;
13	Mirpur 10	Motijheel	18.50
14	Uttara Sector 10	Farmgate	16.20
15	Jatrabari	Mohakhali	15.00
16	Gabtoli	Sadarghat	20.30
17	Gulistan	Dhanmondi 27	8.10
18	Kamalapur	Banani	11.40
\.


--
-- Data for Name: ScheduledMaintenance; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."ScheduledMaintenance" ("ScheduleID", "VehicleID", "ScheduledDate", "Description") FROM stdin;
\.


--
-- Data for Name: Seat; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."Seat" ("SeatNumber", "Status", "TripID") FROM stdin;
1	available	132
2	available	132
3	available	132
4	available	132
5	available	132
6	available	132
7	available	132
8	available	132
9	available	132
10	available	132
11	available	132
12	available	132
13	available	132
14	available	132
15	available	132
16	available	132
17	available	132
18	available	132
19	available	132
20	available	132
21	available	132
22	available	132
23	available	132
24	available	132
25	available	132
26	available	132
27	available	132
28	available	132
29	available	132
30	available	132
31	available	132
32	available	132
33	available	132
34	available	132
35	available	132
36	available	132
37	available	132
38	available	132
39	available	132
40	available	132
41	available	132
42	available	132
43	available	132
44	available	132
45	available	132
46	available	132
47	available	132
48	available	132
49	available	132
50	available	132
1	available	133
2	available	133
3	available	133
4	available	133
5	available	133
6	available	133
7	available	133
8	available	133
9	available	133
10	available	133
11	available	133
12	available	133
13	available	133
14	available	133
15	available	133
16	available	133
17	available	133
18	available	133
19	available	133
20	available	133
21	available	133
22	available	133
23	available	133
24	available	133
25	available	133
26	available	133
27	available	133
28	available	133
29	available	133
30	available	133
31	available	133
32	available	133
33	available	133
34	available	133
35	available	133
36	available	133
37	available	133
38	available	133
39	available	133
40	available	133
1	available	134
2	available	134
3	available	134
4	available	134
5	available	134
6	available	134
7	available	134
8	available	134
9	available	134
10	available	134
11	available	134
12	available	134
13	available	134
14	available	134
15	available	134
16	available	134
17	available	134
18	available	134
19	available	134
20	available	134
21	available	134
22	available	134
23	available	134
24	available	134
25	available	134
26	available	134
27	available	134
28	available	134
29	available	134
30	available	134
31	available	134
32	available	134
33	available	134
34	available	134
35	available	134
36	available	134
1	available	135
2	available	135
3	available	135
4	available	135
5	available	135
6	available	135
7	available	135
8	available	135
9	available	135
10	available	135
11	available	135
12	available	135
13	available	135
14	available	135
15	available	135
16	available	135
17	available	135
18	available	135
19	available	135
20	available	135
21	available	135
22	available	135
23	available	135
24	available	135
25	available	135
26	available	135
27	available	135
28	available	135
29	available	135
30	available	135
31	available	135
32	available	135
33	available	135
34	available	135
35	available	135
36	available	135
37	available	135
38	available	135
39	available	135
40	available	135
41	available	135
42	available	135
43	available	135
44	available	135
45	available	135
1	available	136
2	available	136
3	available	136
4	available	136
5	available	136
6	available	136
7	available	136
8	available	136
9	available	136
10	available	136
11	available	136
12	available	136
13	available	136
14	available	136
15	available	136
16	available	136
17	available	136
18	available	136
19	available	136
20	available	136
21	available	136
22	available	136
23	available	136
24	available	136
25	available	136
26	available	136
27	available	136
28	available	136
29	available	136
30	available	136
1	available	137
2	available	137
3	available	137
4	available	137
5	available	137
6	available	137
7	available	137
8	available	137
9	available	137
10	available	137
11	available	137
12	available	137
13	available	137
14	available	137
15	available	137
16	available	137
17	available	137
18	available	137
19	available	137
20	available	137
21	available	137
22	available	137
23	available	137
24	available	137
25	available	137
26	available	137
27	available	137
28	available	137
29	available	137
30	available	137
31	available	137
32	available	137
33	available	137
34	available	137
35	available	137
36	available	137
37	available	137
38	available	137
39	available	137
40	available	137
41	available	137
42	available	137
43	available	137
44	available	137
45	available	137
46	available	137
47	available	137
48	available	137
49	available	137
50	available	137
1	available	138
2	available	138
3	available	138
4	available	138
5	available	138
6	available	138
7	available	138
8	available	138
9	available	138
10	available	138
11	available	138
12	available	138
13	available	138
14	available	138
15	available	138
16	available	138
17	available	138
18	available	138
19	available	138
20	available	138
21	available	138
22	available	138
23	available	138
24	available	138
25	available	138
26	available	138
27	available	138
28	available	138
29	available	138
30	available	138
31	available	138
32	available	138
33	available	138
34	available	138
35	available	138
36	available	138
37	available	138
38	available	138
39	available	138
40	available	138
1	available	139
2	available	139
3	available	139
4	available	139
5	available	139
6	available	139
7	available	139
8	available	139
9	available	139
10	available	139
11	available	139
12	available	139
13	available	139
14	available	139
15	available	139
16	available	139
17	available	139
18	available	139
19	available	139
20	available	139
21	available	139
22	available	139
23	available	139
24	available	139
25	available	139
26	available	139
27	available	139
28	available	139
29	available	139
30	available	139
31	available	139
32	available	139
33	available	139
34	available	139
35	available	139
36	available	139
1	available	140
2	available	140
3	available	140
4	available	140
5	available	140
6	available	140
7	available	140
8	available	140
9	available	140
10	available	140
11	available	140
12	available	140
13	available	140
14	available	140
15	available	140
16	available	140
17	available	140
18	available	140
19	available	140
20	available	140
21	available	140
22	available	140
23	available	140
24	available	140
25	available	140
26	available	140
27	available	140
28	available	140
29	available	140
30	available	140
31	available	140
32	available	140
33	available	140
34	available	140
35	available	140
36	available	140
37	available	140
38	available	140
39	available	140
40	available	140
41	available	140
42	available	140
43	available	140
44	available	140
45	available	140
1	available	141
2	available	141
3	available	141
4	available	141
5	available	141
6	available	141
7	available	141
8	available	141
9	available	141
10	available	141
11	available	141
12	available	141
13	available	141
14	available	141
15	available	141
16	available	141
17	available	141
18	available	141
19	available	141
20	available	141
21	available	141
22	available	141
23	available	141
24	available	141
25	available	141
26	available	141
27	available	141
28	available	141
29	available	141
30	available	141
1	available	142
2	available	142
3	available	142
4	available	142
5	available	142
6	available	142
7	available	142
8	available	142
9	available	142
10	available	142
11	available	142
12	available	142
13	available	142
14	available	142
15	available	142
16	available	142
17	available	142
18	available	142
19	available	142
20	available	142
21	available	142
22	available	142
23	available	142
24	available	142
25	available	142
26	available	142
27	available	142
28	available	142
29	available	142
30	available	142
31	available	142
32	available	142
33	available	142
34	available	142
35	available	142
36	available	142
37	available	142
38	available	142
39	available	142
40	available	142
41	available	142
42	available	142
43	available	142
44	available	142
45	available	142
46	available	142
47	available	142
48	available	142
49	available	142
50	available	142
1	available	143
2	available	143
3	available	143
4	available	143
5	available	143
6	available	143
7	available	143
8	available	143
9	available	143
10	available	143
11	available	143
12	available	143
13	available	143
14	available	143
15	available	143
16	available	143
17	available	143
18	available	143
19	available	143
20	available	143
21	available	143
22	available	143
23	available	143
24	available	143
25	available	143
26	available	143
27	available	143
28	available	143
29	available	143
30	available	143
31	available	143
32	available	143
33	available	143
34	available	143
35	available	143
36	available	143
37	available	143
38	available	143
39	available	143
40	available	143
1	available	144
2	available	144
3	available	144
4	available	144
5	available	144
6	available	144
7	available	144
8	available	144
9	available	144
10	available	144
11	available	144
12	available	144
13	available	144
14	available	144
15	available	144
16	available	144
17	available	144
18	available	144
19	available	144
20	available	144
21	available	144
22	available	144
23	available	144
24	available	144
25	available	144
26	available	144
27	available	144
28	available	144
29	available	144
30	available	144
31	available	144
32	available	144
33	available	144
34	available	144
35	available	144
36	available	144
1	available	145
2	available	145
3	available	145
4	available	145
5	available	145
6	available	145
7	available	145
8	available	145
9	available	145
10	available	145
11	available	145
12	available	145
13	available	145
14	available	145
15	available	145
16	available	145
17	available	145
18	available	145
19	available	145
20	available	145
21	available	145
22	available	145
23	available	145
24	available	145
25	available	145
26	available	145
27	available	145
28	available	145
29	available	145
30	available	145
31	available	145
32	available	145
33	available	145
34	available	145
35	available	145
36	available	145
37	available	145
38	available	145
39	available	145
40	available	145
41	available	145
42	available	145
43	available	145
44	available	145
45	available	145
1	available	146
2	available	146
3	available	146
4	available	146
5	available	146
6	available	146
7	available	146
8	available	146
9	available	146
10	available	146
11	available	146
12	available	146
13	available	146
14	available	146
15	available	146
16	available	146
17	available	146
18	available	146
19	available	146
20	available	146
21	available	146
22	available	146
23	available	146
24	available	146
25	available	146
26	available	146
27	available	146
28	available	146
29	available	146
30	available	146
1	available	147
2	available	147
3	available	147
4	available	147
5	available	147
6	available	147
7	available	147
8	available	147
9	available	147
10	available	147
11	available	147
12	available	147
13	available	147
14	available	147
15	available	147
16	available	147
17	available	147
18	available	147
19	available	147
20	available	147
21	available	147
22	available	147
23	available	147
24	available	147
25	available	147
26	available	147
27	available	147
28	available	147
29	available	147
30	available	147
31	available	147
32	available	147
33	available	147
34	available	147
35	available	147
36	available	147
37	available	147
38	available	147
39	available	147
40	available	147
41	available	147
42	available	147
43	available	147
44	available	147
45	available	147
46	available	147
47	available	147
48	available	147
49	available	147
50	available	147
1	available	148
2	available	148
3	available	148
4	available	148
5	available	148
6	available	148
7	available	148
8	available	148
9	available	148
10	available	148
11	available	148
12	available	148
13	available	148
14	available	148
15	available	148
16	available	148
17	available	148
18	available	148
19	available	148
20	available	148
21	available	148
22	available	148
23	available	148
24	available	148
25	available	148
26	available	148
27	available	148
28	available	148
29	available	148
30	available	148
31	available	148
32	available	148
33	available	148
34	available	148
35	available	148
36	available	148
37	available	148
38	available	148
39	available	148
40	available	148
1	available	149
2	available	149
3	available	149
4	available	149
5	available	149
6	available	149
7	available	149
8	available	149
9	available	149
10	available	149
11	available	149
12	available	149
13	available	149
14	available	149
15	available	149
16	available	149
17	available	149
18	available	149
19	available	149
20	available	149
21	available	149
22	available	149
23	available	149
24	available	149
25	available	149
26	available	149
27	available	149
28	available	149
29	available	149
30	available	149
31	available	149
32	available	149
33	available	149
34	available	149
35	available	149
36	available	149
1	available	150
2	available	150
3	available	150
4	available	150
5	available	150
6	available	150
7	available	150
8	available	150
9	available	150
10	available	150
11	available	150
12	available	150
13	available	150
14	available	150
15	available	150
16	available	150
17	available	150
18	available	150
19	available	150
20	available	150
21	available	150
22	available	150
23	available	150
24	available	150
25	available	150
26	available	150
27	available	150
28	available	150
29	available	150
30	available	150
31	available	150
32	available	150
33	available	150
34	available	150
35	available	150
36	available	150
37	available	150
38	available	150
39	available	150
40	available	150
41	available	150
42	available	150
43	available	150
44	available	150
45	available	150
1	available	151
2	available	151
3	available	151
4	available	151
5	available	151
6	available	151
7	available	151
8	available	151
9	available	151
10	available	151
11	available	151
12	available	151
13	available	151
14	available	151
15	available	151
16	available	151
17	available	151
18	available	151
19	available	151
20	available	151
21	available	151
22	available	151
23	available	151
24	available	151
25	available	151
26	available	151
27	available	151
28	available	151
29	available	151
30	available	151
1	available	152
2	available	152
3	available	152
4	available	152
5	available	152
6	available	152
7	available	152
8	available	152
9	available	152
10	available	152
11	available	152
12	available	152
13	available	152
14	available	152
15	available	152
16	available	152
17	available	152
18	available	152
19	available	152
20	available	152
21	available	152
22	available	152
23	available	152
24	available	152
25	available	152
26	available	152
27	available	152
28	available	152
29	available	152
30	available	152
31	available	152
32	available	152
33	available	152
34	available	152
35	available	152
36	available	152
37	available	152
38	available	152
39	available	152
40	available	152
41	available	152
42	available	152
43	available	152
44	available	152
45	available	152
46	available	152
47	available	152
48	available	152
49	available	152
50	available	152
1	available	153
2	available	153
3	available	153
4	available	153
5	available	153
6	available	153
7	available	153
8	available	153
9	available	153
10	available	153
11	available	153
12	available	153
13	available	153
14	available	153
15	available	153
16	available	153
17	available	153
18	available	153
19	available	153
20	available	153
21	available	153
22	available	153
23	available	153
24	available	153
25	available	153
26	available	153
27	available	153
28	available	153
29	available	153
30	available	153
31	available	153
32	available	153
33	available	153
34	available	153
35	available	153
36	available	153
37	available	153
38	available	153
39	available	153
40	available	153
1	available	154
2	available	154
3	available	154
4	available	154
5	available	154
6	available	154
7	available	154
8	available	154
9	available	154
10	available	154
11	available	154
12	available	154
13	available	154
14	available	154
15	available	154
16	available	154
17	available	154
18	available	154
19	available	154
20	available	154
21	available	154
22	available	154
23	available	154
24	available	154
25	available	154
26	available	154
27	available	154
28	available	154
29	available	154
30	available	154
31	available	154
32	available	154
33	available	154
34	available	154
35	available	154
36	available	154
1	available	155
2	available	155
3	available	155
4	available	155
5	available	155
6	available	155
7	available	155
8	available	155
9	available	155
10	available	155
11	available	155
12	available	155
13	available	155
14	available	155
15	available	155
16	available	155
17	available	155
18	available	155
19	available	155
20	available	155
21	available	155
22	available	155
23	available	155
24	available	155
25	available	155
26	available	155
27	available	155
28	available	155
29	available	155
30	available	155
31	available	155
32	available	155
33	available	155
34	available	155
35	available	155
36	available	155
37	available	155
38	available	155
39	available	155
40	available	155
41	available	155
42	available	155
43	available	155
44	available	155
45	available	155
1	available	156
2	available	156
3	available	156
4	available	156
5	available	156
6	available	156
7	available	156
8	available	156
9	available	156
10	available	156
11	available	156
12	available	156
13	available	156
14	available	156
15	available	156
16	available	156
17	available	156
18	available	156
19	available	156
20	available	156
21	available	156
22	available	156
23	available	156
24	available	156
25	available	156
26	available	156
27	available	156
28	available	156
29	available	156
30	available	156
1	available	157
2	available	157
3	available	157
4	available	157
5	available	157
6	available	157
7	available	157
8	available	157
9	available	157
10	available	157
11	available	157
12	available	157
13	available	157
14	available	157
15	available	157
16	available	157
17	available	157
18	available	157
19	available	157
20	available	157
21	available	157
22	available	157
23	available	157
24	available	157
25	available	157
26	available	157
27	available	157
28	available	157
29	available	157
30	available	157
31	available	157
32	available	157
33	available	157
34	available	157
35	available	157
36	available	157
37	available	157
38	available	157
39	available	157
40	available	157
41	available	157
42	available	157
43	available	157
44	available	157
45	available	157
46	available	157
47	available	157
48	available	157
49	available	157
50	available	157
1	available	158
2	available	158
3	available	158
4	available	158
5	available	158
6	available	158
7	available	158
8	available	158
9	available	158
10	available	158
11	available	158
12	available	158
13	available	158
14	available	158
15	available	158
16	available	158
17	available	158
18	available	158
19	available	158
20	available	158
21	available	158
22	available	158
23	available	158
24	available	158
25	available	158
26	available	158
27	available	158
28	available	158
29	available	158
30	available	158
31	available	158
32	available	158
33	available	158
34	available	158
35	available	158
36	available	158
37	available	158
38	available	158
39	available	158
40	available	158
1	available	159
2	available	159
3	available	159
4	available	159
5	available	159
6	available	159
7	available	159
8	available	159
9	available	159
10	available	159
11	available	159
12	available	159
13	available	159
14	available	159
15	available	159
16	available	159
17	available	159
18	available	159
19	available	159
20	available	159
21	available	159
22	available	159
23	available	159
24	available	159
25	available	159
26	available	159
27	available	159
28	available	159
29	available	159
30	available	159
31	available	159
32	available	159
33	available	159
34	available	159
35	available	159
36	available	159
1	available	160
2	available	160
3	available	160
4	available	160
5	available	160
6	available	160
7	available	160
8	available	160
9	available	160
10	available	160
11	available	160
12	available	160
13	available	160
14	available	160
15	available	160
16	available	160
17	available	160
18	available	160
19	available	160
20	available	160
21	available	160
22	available	160
23	available	160
24	available	160
25	available	160
26	available	160
27	available	160
28	available	160
29	available	160
30	available	160
31	available	160
32	available	160
33	available	160
34	available	160
35	available	160
36	available	160
37	available	160
38	available	160
39	available	160
40	available	160
41	available	160
42	available	160
43	available	160
44	available	160
45	available	160
1	available	161
2	available	161
3	available	161
4	available	161
5	available	161
6	available	161
7	available	161
8	available	161
9	available	161
10	available	161
11	available	161
12	available	161
13	available	161
14	available	161
15	available	161
16	available	161
17	available	161
18	available	161
19	available	161
20	available	161
21	available	161
22	available	161
23	available	161
24	available	161
25	available	161
26	available	161
27	available	161
28	available	161
29	available	161
30	available	161
1	available	162
2	available	162
3	available	162
4	available	162
5	available	162
6	available	162
7	available	162
8	available	162
9	available	162
10	available	162
11	available	162
12	available	162
13	available	162
14	available	162
15	available	162
16	available	162
17	available	162
18	available	162
19	available	162
20	available	162
21	available	162
22	available	162
23	available	162
24	available	162
25	available	162
26	available	162
27	available	162
28	available	162
29	available	162
30	available	162
31	available	162
32	available	162
33	available	162
34	available	162
35	available	162
36	available	162
37	available	162
38	available	162
39	available	162
40	available	162
41	available	162
42	available	162
43	available	162
44	available	162
45	available	162
46	available	162
47	available	162
48	available	162
49	available	162
50	available	162
1	available	163
2	available	163
3	available	163
4	available	163
5	available	163
6	available	163
7	available	163
8	available	163
9	available	163
10	available	163
11	available	163
12	available	163
13	available	163
14	available	163
15	available	163
16	available	163
17	available	163
18	available	163
19	available	163
20	available	163
21	available	163
22	available	163
23	available	163
24	available	163
25	available	163
26	available	163
27	available	163
28	available	163
29	available	163
30	available	163
31	available	163
32	available	163
33	available	163
34	available	163
35	available	163
36	available	163
37	available	163
38	available	163
39	available	163
40	available	163
1	available	164
2	available	164
3	available	164
4	available	164
5	available	164
6	available	164
7	available	164
8	available	164
9	available	164
10	available	164
11	available	164
12	available	164
13	available	164
14	available	164
15	available	164
16	available	164
17	available	164
18	available	164
19	available	164
20	available	164
21	available	164
22	available	164
23	available	164
24	available	164
25	available	164
26	available	164
27	available	164
28	available	164
29	available	164
30	available	164
31	available	164
32	available	164
33	available	164
34	available	164
35	available	164
36	available	164
1	available	165
2	available	165
3	available	165
4	available	165
5	available	165
6	available	165
7	available	165
8	available	165
9	available	165
10	available	165
11	available	165
12	available	165
13	available	165
14	available	165
15	available	165
16	available	165
17	available	165
18	available	165
19	available	165
20	available	165
21	available	165
22	available	165
23	available	165
24	available	165
25	available	165
26	available	165
27	available	165
28	available	165
29	available	165
30	available	165
31	available	165
32	available	165
33	available	165
34	available	165
35	available	165
36	available	165
37	available	165
38	available	165
39	available	165
40	available	165
41	available	165
42	available	165
43	available	165
44	available	165
45	available	165
1	available	166
2	available	166
3	available	166
4	available	166
5	available	166
6	available	166
7	available	166
8	available	166
9	available	166
10	available	166
11	available	166
12	available	166
13	available	166
14	available	166
15	available	166
16	available	166
17	available	166
18	available	166
19	available	166
20	available	166
21	available	166
22	available	166
23	available	166
24	available	166
25	available	166
26	available	166
27	available	166
28	available	166
29	available	166
30	available	166
1	available	167
2	available	167
3	available	167
4	available	167
5	available	167
6	available	167
7	available	167
8	available	167
9	available	167
10	available	167
11	available	167
12	available	167
13	available	167
14	available	167
15	available	167
16	available	167
17	available	167
18	available	167
19	available	167
20	available	167
21	available	167
22	available	167
23	available	167
24	available	167
25	available	167
26	available	167
27	available	167
28	available	167
29	available	167
30	available	167
31	available	167
32	available	167
33	available	167
34	available	167
35	available	167
36	available	167
37	available	167
38	available	167
39	available	167
40	available	167
41	available	167
42	available	167
43	available	167
44	available	167
45	available	167
46	available	167
47	available	167
48	available	167
49	available	167
50	available	167
1	available	168
2	available	168
3	available	168
4	available	168
5	available	168
6	available	168
7	available	168
8	available	168
9	available	168
10	available	168
11	available	168
12	available	168
13	available	168
14	available	168
15	available	168
16	available	168
17	available	168
18	available	168
19	available	168
20	available	168
21	available	168
22	available	168
23	available	168
24	available	168
25	available	168
26	available	168
27	available	168
28	available	168
29	available	168
30	available	168
31	available	168
32	available	168
33	available	168
34	available	168
35	available	168
36	available	168
37	available	168
38	available	168
39	available	168
40	available	168
1	available	169
2	available	169
3	available	169
4	available	169
5	available	169
6	available	169
7	available	169
8	available	169
9	available	169
10	available	169
11	available	169
12	available	169
13	available	169
14	available	169
15	available	169
16	available	169
17	available	169
18	available	169
19	available	169
20	available	169
21	available	169
22	available	169
23	available	169
24	available	169
25	available	169
26	available	169
27	available	169
28	available	169
29	available	169
30	available	169
31	available	169
32	available	169
33	available	169
34	available	169
35	available	169
36	available	169
1	available	170
2	available	170
3	available	170
4	available	170
5	available	170
6	available	170
7	available	170
8	available	170
9	available	170
10	available	170
11	available	170
12	available	170
13	available	170
14	available	170
15	available	170
16	available	170
17	available	170
18	available	170
19	available	170
20	available	170
21	available	170
22	available	170
23	available	170
24	available	170
25	available	170
26	available	170
27	available	170
28	available	170
29	available	170
30	available	170
31	available	170
32	available	170
33	available	170
34	available	170
35	available	170
36	available	170
37	available	170
38	available	170
39	available	170
40	available	170
41	available	170
42	available	170
43	available	170
44	available	170
45	available	170
1	available	171
2	available	171
3	available	171
4	available	171
5	available	171
6	available	171
7	available	171
8	available	171
9	available	171
10	available	171
11	available	171
12	available	171
13	available	171
14	available	171
15	available	171
16	available	171
17	available	171
18	available	171
19	available	171
20	available	171
21	available	171
22	available	171
23	available	171
24	available	171
25	available	171
26	available	171
27	available	171
28	available	171
29	available	171
30	available	171
1	available	172
2	available	172
3	available	172
4	available	172
5	available	172
6	available	172
7	available	172
8	available	172
9	available	172
10	available	172
11	available	172
12	available	172
13	available	172
14	available	172
15	available	172
16	available	172
17	available	172
18	available	172
19	available	172
20	available	172
21	available	172
22	available	172
23	available	172
24	available	172
25	available	172
26	available	172
27	available	172
28	available	172
29	available	172
30	available	172
31	available	172
32	available	172
33	available	172
34	available	172
35	available	172
36	available	172
37	available	172
38	available	172
39	available	172
40	available	172
41	available	172
42	available	172
43	available	172
44	available	172
45	available	172
46	available	172
47	available	172
48	available	172
49	available	172
50	available	172
1	available	173
2	available	173
3	available	173
4	available	173
5	available	173
6	available	173
7	available	173
8	available	173
9	available	173
10	available	173
11	available	173
12	available	173
13	available	173
14	available	173
15	available	173
16	available	173
17	available	173
18	available	173
19	available	173
20	available	173
21	available	173
22	available	173
23	available	173
24	available	173
25	available	173
26	available	173
27	available	173
28	available	173
29	available	173
30	available	173
31	available	173
32	available	173
33	available	173
34	available	173
35	available	173
36	available	173
37	available	173
38	available	173
39	available	173
40	available	173
1	available	174
2	available	174
3	available	174
4	available	174
5	available	174
6	available	174
7	available	174
8	available	174
9	available	174
10	available	174
11	available	174
12	available	174
13	available	174
14	available	174
15	available	174
16	available	174
17	available	174
18	available	174
19	available	174
20	available	174
21	available	174
22	available	174
23	available	174
24	available	174
25	available	174
26	available	174
27	available	174
28	available	174
29	available	174
30	available	174
31	available	174
32	available	174
33	available	174
34	available	174
35	available	174
36	available	174
1	available	175
2	available	175
3	available	175
4	available	175
5	available	175
6	available	175
7	available	175
8	available	175
9	available	175
10	available	175
11	available	175
12	available	175
13	available	175
14	available	175
15	available	175
16	available	175
17	available	175
18	available	175
19	available	175
20	available	175
21	available	175
22	available	175
23	available	175
24	available	175
25	available	175
26	available	175
27	available	175
28	available	175
29	available	175
30	available	175
31	available	175
32	available	175
33	available	175
34	available	175
35	available	175
36	available	175
37	available	175
38	available	175
39	available	175
40	available	175
41	available	175
42	available	175
43	available	175
44	available	175
45	available	175
1	available	176
2	available	176
3	available	176
4	available	176
5	available	176
6	available	176
7	available	176
8	available	176
9	available	176
10	available	176
11	available	176
12	available	176
13	available	176
14	available	176
15	available	176
16	available	176
17	available	176
18	available	176
19	available	176
20	available	176
21	available	176
22	available	176
23	available	176
24	available	176
25	available	176
26	available	176
27	available	176
28	available	176
29	available	176
30	available	176
1	available	177
2	available	177
3	available	177
4	available	177
5	available	177
6	available	177
7	available	177
8	available	177
9	available	177
10	available	177
11	available	177
12	available	177
13	available	177
14	available	177
15	available	177
16	available	177
17	available	177
18	available	177
19	available	177
20	available	177
21	available	177
22	available	177
23	available	177
24	available	177
25	available	177
26	available	177
27	available	177
28	available	177
29	available	177
30	available	177
31	available	177
32	available	177
33	available	177
34	available	177
35	available	177
36	available	177
37	available	177
38	available	177
39	available	177
40	available	177
41	available	177
42	available	177
43	available	177
44	available	177
45	available	177
46	available	177
47	available	177
48	available	177
49	available	177
50	available	177
1	available	178
2	available	178
3	available	178
4	available	178
5	available	178
6	available	178
7	available	178
8	available	178
9	available	178
10	available	178
11	available	178
12	available	178
13	available	178
14	available	178
15	available	178
16	available	178
17	available	178
18	available	178
19	available	178
20	available	178
21	available	178
22	available	178
23	available	178
24	available	178
25	available	178
26	available	178
27	available	178
28	available	178
29	available	178
30	available	178
31	available	178
32	available	178
33	available	178
34	available	178
35	available	178
36	available	178
37	available	178
38	available	178
39	available	178
40	available	178
1	available	179
2	available	179
3	available	179
4	available	179
5	available	179
6	available	179
7	available	179
8	available	179
9	available	179
10	available	179
11	available	179
12	available	179
13	available	179
14	available	179
15	available	179
16	available	179
17	available	179
18	available	179
19	available	179
20	available	179
21	available	179
22	available	179
23	available	179
24	available	179
25	available	179
26	available	179
27	available	179
28	available	179
29	available	179
30	available	179
31	available	179
32	available	179
33	available	179
34	available	179
35	available	179
36	available	179
1	available	180
2	available	180
3	available	180
4	available	180
5	available	180
6	available	180
7	available	180
8	available	180
9	available	180
10	available	180
11	available	180
12	available	180
13	available	180
14	available	180
15	available	180
16	available	180
17	available	180
18	available	180
19	available	180
20	available	180
21	available	180
22	available	180
23	available	180
24	available	180
25	available	180
26	available	180
27	available	180
28	available	180
29	available	180
30	available	180
31	available	180
32	available	180
33	available	180
34	available	180
35	available	180
36	available	180
37	available	180
38	available	180
39	available	180
40	available	180
41	available	180
42	available	180
43	available	180
44	available	180
45	available	180
1	available	181
2	available	181
3	available	181
4	available	181
5	available	181
6	available	181
7	available	181
8	available	181
9	available	181
10	available	181
11	available	181
12	available	181
13	available	181
14	available	181
15	available	181
16	available	181
17	available	181
18	available	181
19	available	181
20	available	181
21	available	181
22	available	181
23	available	181
24	available	181
25	available	181
26	available	181
27	available	181
28	available	181
29	available	181
30	available	181
1	available	182
2	available	182
3	available	182
4	available	182
5	available	182
6	available	182
7	available	182
8	available	182
9	available	182
10	available	182
11	available	182
12	available	182
13	available	182
14	available	182
15	available	182
16	available	182
17	available	182
18	available	182
19	available	182
20	available	182
21	available	182
22	available	182
23	available	182
24	available	182
25	available	182
26	available	182
27	available	182
28	available	182
29	available	182
30	available	182
31	available	182
32	available	182
33	available	182
34	available	182
35	available	182
36	available	182
37	available	182
38	available	182
39	available	182
40	available	182
41	available	182
42	available	182
43	available	182
44	available	182
45	available	182
46	available	182
47	available	182
48	available	182
49	available	182
50	available	182
1	available	183
2	available	183
3	available	183
4	available	183
5	available	183
6	available	183
7	available	183
8	available	183
9	available	183
10	available	183
11	available	183
12	available	183
13	available	183
14	available	183
15	available	183
16	available	183
17	available	183
18	available	183
19	available	183
20	available	183
21	available	183
22	available	183
23	available	183
24	available	183
25	available	183
26	available	183
27	available	183
28	available	183
29	available	183
30	available	183
31	available	183
32	available	183
33	available	183
34	available	183
35	available	183
36	available	183
37	available	183
38	available	183
39	available	183
40	available	183
1	available	184
2	available	184
3	available	184
4	available	184
5	available	184
6	available	184
7	available	184
8	available	184
9	available	184
10	available	184
11	available	184
12	available	184
13	available	184
14	available	184
15	available	184
16	available	184
17	available	184
18	available	184
19	available	184
20	available	184
21	available	184
22	available	184
23	available	184
24	available	184
25	available	184
26	available	184
27	available	184
28	available	184
29	available	184
30	available	184
31	available	184
32	available	184
33	available	184
34	available	184
35	available	184
36	available	184
1	available	185
2	available	185
3	available	185
4	available	185
5	available	185
6	available	185
7	available	185
8	available	185
9	available	185
10	available	185
11	available	185
12	available	185
13	available	185
14	available	185
15	available	185
16	available	185
17	available	185
18	available	185
19	available	185
20	available	185
21	available	185
22	available	185
23	available	185
24	available	185
25	available	185
26	available	185
27	available	185
28	available	185
29	available	185
30	available	185
31	available	185
32	available	185
33	available	185
34	available	185
35	available	185
36	available	185
37	available	185
38	available	185
39	available	185
40	available	185
41	available	185
42	available	185
43	available	185
44	available	185
45	available	185
1	available	186
2	available	186
3	available	186
4	available	186
5	available	186
6	available	186
7	available	186
8	available	186
9	available	186
10	available	186
11	available	186
12	available	186
13	available	186
14	available	186
15	available	186
16	available	186
17	available	186
18	available	186
19	available	186
20	available	186
21	available	186
22	available	186
23	available	186
24	available	186
25	available	186
26	available	186
27	available	186
28	available	186
29	available	186
30	available	186
1	available	187
2	available	187
3	available	187
4	available	187
5	available	187
6	available	187
7	available	187
8	available	187
9	available	187
10	available	187
11	available	187
12	available	187
13	available	187
14	available	187
15	available	187
16	available	187
17	available	187
18	available	187
19	available	187
20	available	187
21	available	187
22	available	187
23	available	187
24	available	187
25	available	187
26	available	187
27	available	187
28	available	187
29	available	187
30	available	187
31	available	187
32	available	187
33	available	187
34	available	187
35	available	187
36	available	187
37	available	187
38	available	187
39	available	187
40	available	187
41	available	187
42	available	187
43	available	187
44	available	187
45	available	187
46	available	187
47	available	187
48	available	187
49	available	187
50	available	187
1	available	188
2	available	188
3	available	188
4	available	188
5	available	188
6	available	188
7	available	188
8	available	188
9	available	188
10	available	188
11	available	188
12	available	188
13	available	188
14	available	188
15	available	188
16	available	188
17	available	188
18	available	188
19	available	188
20	available	188
21	available	188
22	available	188
23	available	188
24	available	188
25	available	188
26	available	188
27	available	188
28	available	188
29	available	188
30	available	188
31	available	188
32	available	188
33	available	188
34	available	188
35	available	188
36	available	188
37	available	188
38	available	188
39	available	188
40	available	188
1	available	189
2	available	189
3	available	189
4	available	189
5	available	189
6	available	189
7	available	189
8	available	189
9	available	189
10	available	189
11	available	189
12	available	189
13	available	189
14	available	189
15	available	189
16	available	189
17	available	189
18	available	189
19	available	189
20	available	189
21	available	189
22	available	189
23	available	189
24	available	189
25	available	189
26	available	189
27	available	189
28	available	189
29	available	189
30	available	189
31	available	189
32	available	189
33	available	189
34	available	189
35	available	189
36	available	189
1	available	190
2	available	190
3	available	190
4	available	190
5	available	190
6	available	190
7	available	190
8	available	190
9	available	190
10	available	190
11	available	190
12	available	190
13	available	190
14	available	190
15	available	190
16	available	190
17	available	190
18	available	190
19	available	190
20	available	190
21	available	190
22	available	190
23	available	190
24	available	190
25	available	190
26	available	190
27	available	190
28	available	190
29	available	190
30	available	190
31	available	190
32	available	190
33	available	190
34	available	190
35	available	190
36	available	190
37	available	190
38	available	190
39	available	190
40	available	190
41	available	190
42	available	190
43	available	190
44	available	190
45	available	190
1	available	191
2	available	191
3	available	191
4	available	191
5	available	191
6	available	191
7	available	191
8	available	191
9	available	191
10	available	191
11	available	191
12	available	191
13	available	191
14	available	191
15	available	191
16	available	191
17	available	191
18	available	191
19	available	191
20	available	191
21	available	191
22	available	191
23	available	191
24	available	191
25	available	191
26	available	191
27	available	191
28	available	191
29	available	191
30	available	191
1	available	192
2	available	192
3	available	192
4	available	192
5	available	192
6	available	192
7	available	192
8	available	192
9	available	192
10	available	192
11	available	192
12	available	192
13	available	192
14	available	192
15	available	192
16	available	192
17	available	192
18	available	192
19	available	192
20	available	192
21	available	192
22	available	192
23	available	192
24	available	192
25	available	192
26	available	192
27	available	192
28	available	192
29	available	192
30	available	192
31	available	192
32	available	192
33	available	192
34	available	192
35	available	192
36	available	192
37	available	192
38	available	192
39	available	192
40	available	192
41	available	192
42	available	192
43	available	192
44	available	192
45	available	192
46	available	192
47	available	192
48	available	192
49	available	192
50	available	192
1	available	193
2	available	193
3	available	193
4	available	193
5	available	193
6	available	193
7	available	193
8	available	193
9	available	193
10	available	193
11	available	193
12	available	193
13	available	193
14	available	193
15	available	193
16	available	193
17	available	193
18	available	193
19	available	193
20	available	193
21	available	193
22	available	193
23	available	193
24	available	193
25	available	193
26	available	193
27	available	193
28	available	193
29	available	193
30	available	193
31	available	193
32	available	193
33	available	193
34	available	193
35	available	193
36	available	193
37	available	193
38	available	193
39	available	193
40	available	193
1	available	194
2	available	194
3	available	194
4	available	194
5	available	194
6	available	194
7	available	194
8	available	194
9	available	194
10	available	194
11	available	194
12	available	194
13	available	194
14	available	194
15	available	194
16	available	194
17	available	194
18	available	194
19	available	194
20	available	194
21	available	194
22	available	194
23	available	194
24	available	194
25	available	194
26	available	194
27	available	194
28	available	194
29	available	194
30	available	194
31	available	194
32	available	194
33	available	194
34	available	194
35	available	194
36	available	194
1	available	195
2	available	195
3	available	195
4	available	195
5	available	195
6	available	195
7	available	195
8	available	195
9	available	195
10	available	195
11	available	195
12	available	195
13	available	195
14	available	195
15	available	195
16	available	195
17	available	195
18	available	195
19	available	195
20	available	195
21	available	195
22	available	195
23	available	195
24	available	195
25	available	195
26	available	195
27	available	195
28	available	195
29	available	195
30	available	195
31	available	195
32	available	195
33	available	195
34	available	195
35	available	195
36	available	195
37	available	195
38	available	195
39	available	195
40	available	195
41	available	195
42	available	195
43	available	195
44	available	195
45	available	195
1	available	196
2	available	196
3	available	196
4	available	196
5	available	196
6	available	196
7	available	196
8	available	196
9	available	196
10	available	196
11	available	196
12	available	196
13	available	196
14	available	196
15	available	196
16	available	196
17	available	196
18	available	196
19	available	196
20	available	196
21	available	196
22	available	196
23	available	196
24	available	196
25	available	196
26	available	196
27	available	196
28	available	196
29	available	196
30	available	196
1	available	197
2	available	197
3	available	197
4	available	197
5	available	197
6	available	197
7	available	197
8	available	197
9	available	197
10	available	197
11	available	197
12	available	197
13	available	197
14	available	197
15	available	197
16	available	197
17	available	197
18	available	197
19	available	197
20	available	197
21	available	197
22	available	197
23	available	197
24	available	197
25	available	197
26	available	197
27	available	197
28	available	197
29	available	197
30	available	197
31	available	197
32	available	197
33	available	197
34	available	197
35	available	197
36	available	197
37	available	197
38	available	197
39	available	197
40	available	197
41	available	197
42	available	197
43	available	197
44	available	197
45	available	197
46	available	197
47	available	197
48	available	197
49	available	197
50	available	197
1	available	198
2	available	198
3	available	198
4	available	198
5	available	198
6	available	198
7	available	198
8	available	198
9	available	198
10	available	198
11	available	198
12	available	198
13	available	198
14	available	198
15	available	198
16	available	198
17	available	198
18	available	198
19	available	198
20	available	198
21	available	198
22	available	198
23	available	198
24	available	198
25	available	198
26	available	198
27	available	198
28	available	198
29	available	198
30	available	198
31	available	198
32	available	198
33	available	198
34	available	198
35	available	198
36	available	198
37	available	198
38	available	198
39	available	198
40	available	198
1	available	199
2	available	199
3	available	199
4	available	199
5	available	199
6	available	199
7	available	199
8	available	199
9	available	199
10	available	199
11	available	199
12	available	199
13	available	199
14	available	199
15	available	199
16	available	199
17	available	199
18	available	199
19	available	199
20	available	199
21	available	199
22	available	199
23	available	199
24	available	199
25	available	199
26	available	199
27	available	199
28	available	199
29	available	199
30	available	199
31	available	199
32	available	199
33	available	199
34	available	199
35	available	199
36	available	199
1	available	200
2	available	200
3	available	200
4	available	200
5	available	200
6	available	200
7	available	200
8	available	200
9	available	200
10	available	200
11	available	200
12	available	200
13	available	200
14	available	200
15	available	200
16	available	200
17	available	200
18	available	200
19	available	200
20	available	200
21	available	200
22	available	200
23	available	200
24	available	200
25	available	200
26	available	200
27	available	200
28	available	200
29	available	200
30	available	200
31	available	200
32	available	200
33	available	200
34	available	200
35	available	200
36	available	200
37	available	200
38	available	200
39	available	200
40	available	200
41	available	200
42	available	200
43	available	200
44	available	200
45	available	200
1	available	201
2	available	201
3	available	201
4	available	201
5	available	201
6	available	201
7	available	201
8	available	201
9	available	201
10	available	201
11	available	201
12	available	201
13	available	201
14	available	201
15	available	201
16	available	201
17	available	201
18	available	201
19	available	201
20	available	201
21	available	201
22	available	201
23	available	201
24	available	201
25	available	201
26	available	201
27	available	201
28	available	201
29	available	201
30	available	201
1	available	202
2	available	202
3	available	202
4	available	202
5	available	202
6	available	202
7	available	202
8	available	202
9	available	202
10	available	202
11	available	202
12	available	202
13	available	202
14	available	202
15	available	202
16	available	202
17	available	202
18	available	202
19	available	202
20	available	202
21	available	202
22	available	202
23	available	202
24	available	202
25	available	202
26	available	202
27	available	202
28	available	202
29	available	202
30	available	202
31	available	202
32	available	202
33	available	202
34	available	202
35	available	202
36	available	202
37	available	202
38	available	202
39	available	202
40	available	202
41	available	202
42	available	202
43	available	202
44	available	202
45	available	202
46	available	202
47	available	202
48	available	202
49	available	202
50	available	202
1	available	203
2	available	203
3	available	203
4	available	203
5	available	203
6	available	203
7	available	203
8	available	203
9	available	203
10	available	203
11	available	203
12	available	203
13	available	203
14	available	203
15	available	203
16	available	203
17	available	203
18	available	203
19	available	203
20	available	203
21	available	203
22	available	203
23	available	203
24	available	203
25	available	203
26	available	203
27	available	203
28	available	203
29	available	203
30	available	203
31	available	203
32	available	203
33	available	203
34	available	203
35	available	203
36	available	203
37	available	203
38	available	203
39	available	203
40	available	203
1	available	204
2	available	204
3	available	204
4	available	204
5	available	204
6	available	204
7	available	204
8	available	204
9	available	204
10	available	204
11	available	204
12	available	204
13	available	204
14	available	204
15	available	204
16	available	204
17	available	204
18	available	204
19	available	204
20	available	204
21	available	204
22	available	204
23	available	204
24	available	204
25	available	204
26	available	204
27	available	204
28	available	204
29	available	204
30	available	204
31	available	204
32	available	204
33	available	204
34	available	204
35	available	204
36	available	204
1	available	205
2	available	205
3	available	205
4	available	205
5	available	205
6	available	205
7	available	205
8	available	205
9	available	205
10	available	205
11	available	205
12	available	205
13	available	205
14	available	205
15	available	205
16	available	205
17	available	205
18	available	205
19	available	205
20	available	205
21	available	205
22	available	205
23	available	205
24	available	205
25	available	205
26	available	205
27	available	205
28	available	205
29	available	205
30	available	205
31	available	205
32	available	205
33	available	205
34	available	205
35	available	205
36	available	205
37	available	205
38	available	205
39	available	205
40	available	205
41	available	205
42	available	205
43	available	205
44	available	205
45	available	205
1	available	206
2	available	206
3	available	206
4	available	206
5	available	206
6	available	206
7	available	206
8	available	206
9	available	206
10	available	206
11	available	206
12	available	206
13	available	206
14	available	206
15	available	206
16	available	206
17	available	206
18	available	206
19	available	206
20	available	206
21	available	206
22	available	206
23	available	206
24	available	206
25	available	206
26	available	206
27	available	206
28	available	206
29	available	206
30	available	206
1	available	207
2	available	207
3	available	207
4	available	207
5	available	207
6	available	207
7	available	207
8	available	207
9	available	207
10	available	207
11	available	207
12	available	207
13	available	207
14	available	207
15	available	207
16	available	207
17	available	207
18	available	207
19	available	207
20	available	207
21	available	207
22	available	207
23	available	207
24	available	207
25	available	207
26	available	207
27	available	207
28	available	207
29	available	207
30	available	207
31	available	207
32	available	207
33	available	207
34	available	207
35	available	207
36	available	207
37	available	207
38	available	207
39	available	207
40	available	207
41	available	207
42	available	207
43	available	207
44	available	207
45	available	207
46	available	207
47	available	207
48	available	207
49	available	207
50	available	207
1	available	208
2	available	208
3	available	208
4	available	208
5	available	208
6	available	208
7	available	208
8	available	208
9	available	208
10	available	208
11	available	208
12	available	208
13	available	208
14	available	208
15	available	208
16	available	208
17	available	208
18	available	208
19	available	208
20	available	208
21	available	208
22	available	208
23	available	208
24	available	208
25	available	208
26	available	208
27	available	208
28	available	208
29	available	208
30	available	208
31	available	208
32	available	208
33	available	208
34	available	208
35	available	208
36	available	208
37	available	208
38	available	208
39	available	208
40	available	208
1	available	209
2	available	209
3	available	209
4	available	209
5	available	209
6	available	209
7	available	209
8	available	209
9	available	209
10	available	209
11	available	209
12	available	209
13	available	209
14	available	209
15	available	209
16	available	209
17	available	209
18	available	209
19	available	209
20	available	209
21	available	209
22	available	209
23	available	209
24	available	209
25	available	209
26	available	209
27	available	209
28	available	209
29	available	209
30	available	209
31	available	209
32	available	209
33	available	209
34	available	209
35	available	209
36	available	209
1	available	210
2	available	210
3	available	210
4	available	210
5	available	210
6	available	210
7	available	210
8	available	210
9	available	210
10	available	210
11	available	210
12	available	210
13	available	210
14	available	210
15	available	210
16	available	210
17	available	210
18	available	210
19	available	210
20	available	210
21	available	210
22	available	210
23	available	210
24	available	210
25	available	210
26	available	210
27	available	210
28	available	210
29	available	210
30	available	210
31	available	210
32	available	210
33	available	210
34	available	210
35	available	210
36	available	210
37	available	210
38	available	210
39	available	210
40	available	210
41	available	210
42	available	210
43	available	210
44	available	210
45	available	210
1	available	211
2	available	211
3	available	211
4	available	211
5	available	211
6	available	211
7	available	211
8	available	211
9	available	211
10	available	211
11	available	211
12	available	211
13	available	211
14	available	211
15	available	211
16	available	211
17	available	211
18	available	211
19	available	211
20	available	211
21	available	211
22	available	211
23	available	211
24	available	211
25	available	211
26	available	211
27	available	211
28	available	211
29	available	211
30	available	211
1	available	212
2	available	212
3	available	212
4	available	212
5	available	212
6	available	212
7	available	212
8	available	212
9	available	212
10	available	212
11	available	212
12	available	212
13	available	212
14	available	212
15	available	212
16	available	212
17	available	212
18	available	212
19	available	212
20	available	212
21	available	212
22	available	212
23	available	212
24	available	212
25	available	212
26	available	212
27	available	212
28	available	212
29	available	212
30	available	212
31	available	212
32	available	212
33	available	212
34	available	212
35	available	212
36	available	212
37	available	212
38	available	212
39	available	212
40	available	212
41	available	212
42	available	212
43	available	212
44	available	212
45	available	212
46	available	212
47	available	212
48	available	212
49	available	212
50	available	212
1	available	213
2	available	213
3	available	213
4	available	213
5	available	213
6	available	213
7	available	213
8	available	213
9	available	213
10	available	213
11	available	213
12	available	213
13	available	213
14	available	213
15	available	213
16	available	213
17	available	213
18	available	213
19	available	213
20	available	213
21	available	213
22	available	213
23	available	213
24	available	213
25	available	213
26	available	213
27	available	213
28	available	213
29	available	213
30	available	213
31	available	213
32	available	213
33	available	213
34	available	213
35	available	213
36	available	213
37	available	213
38	available	213
39	available	213
40	available	213
1	available	214
2	available	214
3	available	214
4	available	214
5	available	214
6	available	214
7	available	214
8	available	214
9	available	214
10	available	214
11	available	214
12	available	214
13	available	214
14	available	214
15	available	214
16	available	214
17	available	214
18	available	214
19	available	214
20	available	214
21	available	214
22	available	214
23	available	214
24	available	214
25	available	214
26	available	214
27	available	214
28	available	214
29	available	214
30	available	214
31	available	214
32	available	214
33	available	214
34	available	214
35	available	214
36	available	214
1	available	215
2	available	215
3	available	215
4	available	215
5	available	215
6	available	215
7	available	215
8	available	215
9	available	215
10	available	215
11	available	215
12	available	215
13	available	215
14	available	215
15	available	215
16	available	215
17	available	215
18	available	215
19	available	215
20	available	215
21	available	215
22	available	215
23	available	215
24	available	215
25	available	215
26	available	215
27	available	215
28	available	215
29	available	215
30	available	215
31	available	215
32	available	215
33	available	215
34	available	215
35	available	215
36	available	215
37	available	215
38	available	215
39	available	215
40	available	215
41	available	215
42	available	215
43	available	215
44	available	215
45	available	215
1	available	216
2	available	216
3	available	216
4	available	216
5	available	216
6	available	216
7	available	216
8	available	216
9	available	216
10	available	216
11	available	216
12	available	216
13	available	216
14	available	216
15	available	216
16	available	216
17	available	216
18	available	216
19	available	216
20	available	216
21	available	216
22	available	216
23	available	216
24	available	216
25	available	216
26	available	216
27	available	216
28	available	216
29	available	216
30	available	216
1	available	217
2	available	217
3	available	217
4	available	217
5	available	217
6	available	217
7	available	217
8	available	217
9	available	217
10	available	217
11	available	217
12	available	217
13	available	217
14	available	217
15	available	217
16	available	217
17	available	217
18	available	217
19	available	217
20	available	217
21	available	217
22	available	217
23	available	217
24	available	217
25	available	217
26	available	217
27	available	217
28	available	217
29	available	217
30	available	217
31	available	217
32	available	217
33	available	217
34	available	217
35	available	217
36	available	217
37	available	217
38	available	217
39	available	217
40	available	217
41	available	217
42	available	217
43	available	217
44	available	217
45	available	217
46	available	217
47	available	217
48	available	217
49	available	217
50	available	217
1	available	218
2	available	218
3	available	218
4	available	218
5	available	218
6	available	218
7	available	218
8	available	218
9	available	218
10	available	218
11	available	218
12	available	218
13	available	218
14	available	218
15	available	218
16	available	218
17	available	218
18	available	218
19	available	218
20	available	218
21	available	218
22	available	218
23	available	218
24	available	218
25	available	218
26	available	218
27	available	218
28	available	218
29	available	218
30	available	218
31	available	218
32	available	218
33	available	218
34	available	218
35	available	218
36	available	218
37	available	218
38	available	218
39	available	218
40	available	218
1	available	219
2	available	219
3	available	219
4	available	219
5	available	219
6	available	219
7	available	219
8	available	219
9	available	219
10	available	219
11	available	219
12	available	219
13	available	219
14	available	219
15	available	219
16	available	219
17	available	219
18	available	219
19	available	219
20	available	219
21	available	219
22	available	219
23	available	219
24	available	219
25	available	219
26	available	219
27	available	219
28	available	219
29	available	219
30	available	219
31	available	219
32	available	219
33	available	219
34	available	219
35	available	219
36	available	219
1	available	220
2	available	220
3	available	220
4	available	220
5	available	220
6	available	220
7	available	220
8	available	220
9	available	220
10	available	220
11	available	220
12	available	220
13	available	220
14	available	220
15	available	220
16	available	220
17	available	220
18	available	220
19	available	220
20	available	220
21	available	220
22	available	220
23	available	220
24	available	220
25	available	220
26	available	220
27	available	220
28	available	220
29	available	220
30	available	220
31	available	220
32	available	220
33	available	220
34	available	220
35	available	220
36	available	220
37	available	220
38	available	220
39	available	220
40	available	220
41	available	220
42	available	220
43	available	220
44	available	220
45	available	220
1	available	221
2	available	221
3	available	221
4	available	221
5	available	221
6	available	221
7	available	221
8	available	221
9	available	221
10	available	221
11	available	221
12	available	221
13	available	221
14	available	221
15	available	221
16	available	221
17	available	221
18	available	221
19	available	221
20	available	221
21	available	221
22	available	221
23	available	221
24	available	221
25	available	221
26	available	221
27	available	221
28	available	221
29	available	221
30	available	221
1	available	222
2	available	222
3	available	222
4	available	222
5	available	222
6	available	222
7	available	222
8	available	222
9	available	222
10	available	222
11	available	222
12	available	222
13	available	222
14	available	222
15	available	222
16	available	222
17	available	222
18	available	222
19	available	222
20	available	222
21	available	222
22	available	222
23	available	222
24	available	222
25	available	222
26	available	222
27	available	222
28	available	222
29	available	222
30	available	222
31	available	222
32	available	222
33	available	222
34	available	222
35	available	222
36	available	222
37	available	222
38	available	222
39	available	222
40	available	222
41	available	222
42	available	222
43	available	222
44	available	222
45	available	222
46	available	222
47	available	222
48	available	222
49	available	222
50	available	222
1	available	223
2	available	223
3	available	223
4	available	223
5	available	223
6	available	223
7	available	223
8	available	223
9	available	223
10	available	223
11	available	223
12	available	223
13	available	223
14	available	223
15	available	223
16	available	223
17	available	223
18	available	223
19	available	223
20	available	223
21	available	223
22	available	223
23	available	223
24	available	223
25	available	223
26	available	223
27	available	223
28	available	223
29	available	223
30	available	223
31	available	223
32	available	223
33	available	223
34	available	223
35	available	223
36	available	223
37	available	223
38	available	223
39	available	223
40	available	223
1	available	224
2	available	224
3	available	224
4	available	224
5	available	224
6	available	224
7	available	224
8	available	224
9	available	224
10	available	224
11	available	224
12	available	224
13	available	224
14	available	224
15	available	224
16	available	224
17	available	224
18	available	224
19	available	224
20	available	224
21	available	224
22	available	224
23	available	224
24	available	224
25	available	224
26	available	224
27	available	224
28	available	224
29	available	224
30	available	224
31	available	224
32	available	224
33	available	224
34	available	224
35	available	224
36	available	224
1	available	225
2	available	225
3	available	225
4	available	225
5	available	225
6	available	225
7	available	225
8	available	225
9	available	225
10	available	225
11	available	225
12	available	225
13	available	225
14	available	225
15	available	225
16	available	225
17	available	225
18	available	225
19	available	225
20	available	225
21	available	225
22	available	225
23	available	225
24	available	225
25	available	225
26	available	225
27	available	225
28	available	225
29	available	225
30	available	225
31	available	225
32	available	225
33	available	225
34	available	225
35	available	225
36	available	225
37	available	225
38	available	225
39	available	225
40	available	225
41	available	225
42	available	225
43	available	225
44	available	225
45	available	225
1	available	226
2	available	226
3	available	226
4	available	226
5	available	226
6	available	226
7	available	226
8	available	226
9	available	226
10	available	226
11	available	226
12	available	226
13	available	226
14	available	226
15	available	226
16	available	226
17	available	226
18	available	226
19	available	226
20	available	226
21	available	226
22	available	226
23	available	226
24	available	226
25	available	226
26	available	226
27	available	226
28	available	226
29	available	226
30	available	226
1	available	227
2	available	227
3	available	227
4	available	227
5	available	227
6	available	227
7	available	227
8	available	227
9	available	227
10	available	227
11	available	227
12	available	227
13	available	227
14	available	227
15	available	227
16	available	227
17	available	227
18	available	227
19	available	227
20	available	227
21	available	227
22	available	227
23	available	227
24	available	227
25	available	227
26	available	227
27	available	227
28	available	227
29	available	227
30	available	227
31	available	227
32	available	227
33	available	227
34	available	227
35	available	227
36	available	227
37	available	227
38	available	227
39	available	227
40	available	227
41	available	227
42	available	227
43	available	227
44	available	227
45	available	227
46	available	227
47	available	227
48	available	227
49	available	227
50	available	227
1	available	228
2	available	228
3	available	228
4	available	228
5	available	228
6	available	228
7	available	228
8	available	228
9	available	228
10	available	228
11	available	228
12	available	228
13	available	228
14	available	228
15	available	228
16	available	228
17	available	228
18	available	228
19	available	228
20	available	228
21	available	228
22	available	228
23	available	228
24	available	228
25	available	228
26	available	228
27	available	228
28	available	228
29	available	228
30	available	228
31	available	228
32	available	228
33	available	228
34	available	228
35	available	228
36	available	228
37	available	228
38	available	228
39	available	228
40	available	228
1	available	229
2	available	229
3	available	229
4	available	229
5	available	229
6	available	229
7	available	229
8	available	229
9	available	229
10	available	229
11	available	229
12	available	229
13	available	229
14	available	229
15	available	229
16	available	229
17	available	229
18	available	229
19	available	229
20	available	229
21	available	229
22	available	229
23	available	229
24	available	229
25	available	229
26	available	229
27	available	229
28	available	229
29	available	229
30	available	229
31	available	229
32	available	229
33	available	229
34	available	229
35	available	229
36	available	229
1	available	230
2	available	230
3	available	230
4	available	230
5	available	230
6	available	230
7	available	230
8	available	230
9	available	230
10	available	230
11	available	230
12	available	230
13	available	230
14	available	230
15	available	230
16	available	230
17	available	230
18	available	230
19	available	230
20	available	230
21	available	230
22	available	230
23	available	230
24	available	230
25	available	230
26	available	230
27	available	230
28	available	230
29	available	230
30	available	230
31	available	230
32	available	230
33	available	230
34	available	230
35	available	230
36	available	230
37	available	230
38	available	230
39	available	230
40	available	230
41	available	230
42	available	230
43	available	230
44	available	230
45	available	230
1	available	231
2	available	231
3	available	231
4	available	231
5	available	231
6	available	231
7	available	231
8	available	231
9	available	231
10	available	231
11	available	231
12	available	231
13	available	231
14	available	231
15	available	231
16	available	231
17	available	231
18	available	231
19	available	231
20	available	231
21	available	231
22	available	231
23	available	231
24	available	231
25	available	231
26	available	231
27	available	231
28	available	231
29	available	231
30	available	231
1	available	232
2	available	232
3	available	232
4	available	232
5	available	232
6	available	232
7	available	232
8	available	232
9	available	232
10	available	232
11	available	232
12	available	232
13	available	232
14	available	232
15	available	232
16	available	232
17	available	232
18	available	232
19	available	232
20	available	232
21	available	232
22	available	232
23	available	232
24	available	232
25	available	232
26	available	232
27	available	232
28	available	232
29	available	232
30	available	232
31	available	232
32	available	232
33	available	232
34	available	232
35	available	232
36	available	232
37	available	232
38	available	232
39	available	232
40	available	232
41	available	232
42	available	232
43	available	232
44	available	232
45	available	232
46	available	232
47	available	232
48	available	232
49	available	232
50	available	232
1	available	233
2	available	233
3	available	233
4	available	233
5	available	233
6	available	233
7	available	233
8	available	233
9	available	233
10	available	233
11	available	233
12	available	233
13	available	233
14	available	233
15	available	233
16	available	233
17	available	233
18	available	233
19	available	233
20	available	233
21	available	233
22	available	233
23	available	233
24	available	233
25	available	233
26	available	233
27	available	233
28	available	233
29	available	233
30	available	233
31	available	233
32	available	233
33	available	233
34	available	233
35	available	233
36	available	233
37	available	233
38	available	233
39	available	233
40	available	233
1	available	234
2	available	234
3	available	234
4	available	234
5	available	234
6	available	234
7	available	234
8	available	234
9	available	234
10	available	234
11	available	234
12	available	234
13	available	234
14	available	234
15	available	234
16	available	234
17	available	234
18	available	234
19	available	234
20	available	234
21	available	234
22	available	234
23	available	234
24	available	234
25	available	234
26	available	234
27	available	234
28	available	234
29	available	234
30	available	234
31	available	234
32	available	234
33	available	234
34	available	234
35	available	234
36	available	234
1	available	235
2	available	235
3	available	235
4	available	235
5	available	235
6	available	235
7	available	235
8	available	235
9	available	235
10	available	235
11	available	235
12	available	235
13	available	235
14	available	235
15	available	235
16	available	235
17	available	235
18	available	235
19	available	235
20	available	235
21	available	235
22	available	235
23	available	235
24	available	235
25	available	235
26	available	235
27	available	235
28	available	235
29	available	235
30	available	235
31	available	235
32	available	235
33	available	235
34	available	235
35	available	235
36	available	235
37	available	235
38	available	235
39	available	235
40	available	235
41	available	235
42	available	235
43	available	235
44	available	235
45	available	235
1	available	236
2	available	236
3	available	236
4	available	236
5	available	236
6	available	236
7	available	236
8	available	236
9	available	236
10	available	236
11	available	236
12	available	236
13	available	236
14	available	236
15	available	236
16	available	236
17	available	236
18	available	236
19	available	236
20	available	236
21	available	236
22	available	236
23	available	236
24	available	236
25	available	236
26	available	236
27	available	236
28	available	236
29	available	236
30	available	236
1	available	237
2	available	237
3	available	237
4	available	237
5	available	237
6	available	237
7	available	237
8	available	237
9	available	237
10	available	237
11	available	237
12	available	237
13	available	237
14	available	237
15	available	237
16	available	237
17	available	237
18	available	237
19	available	237
20	available	237
21	available	237
22	available	237
23	available	237
24	available	237
25	available	237
26	available	237
27	available	237
28	available	237
29	available	237
30	available	237
31	available	237
32	available	237
33	available	237
34	available	237
35	available	237
36	available	237
37	available	237
38	available	237
39	available	237
40	available	237
41	available	237
42	available	237
43	available	237
44	available	237
45	available	237
46	available	237
47	available	237
48	available	237
49	available	237
50	available	237
1	available	238
2	available	238
3	available	238
4	available	238
5	available	238
6	available	238
7	available	238
8	available	238
9	available	238
10	available	238
11	available	238
12	available	238
13	available	238
14	available	238
15	available	238
16	available	238
17	available	238
18	available	238
19	available	238
20	available	238
21	available	238
22	available	238
23	available	238
24	available	238
25	available	238
26	available	238
27	available	238
28	available	238
29	available	238
30	available	238
31	available	238
32	available	238
33	available	238
34	available	238
35	available	238
36	available	238
37	available	238
38	available	238
39	available	238
40	available	238
1	available	239
2	available	239
3	available	239
4	available	239
5	available	239
6	available	239
7	available	239
8	available	239
9	available	239
10	available	239
11	available	239
12	available	239
13	available	239
14	available	239
15	available	239
16	available	239
17	available	239
18	available	239
19	available	239
20	available	239
21	available	239
22	available	239
23	available	239
24	available	239
25	available	239
26	available	239
27	available	239
28	available	239
29	available	239
30	available	239
31	available	239
32	available	239
33	available	239
34	available	239
35	available	239
36	available	239
1	available	240
2	available	240
3	available	240
4	available	240
5	available	240
6	available	240
7	available	240
8	available	240
9	available	240
10	available	240
11	available	240
12	available	240
13	available	240
14	available	240
15	available	240
16	available	240
17	available	240
18	available	240
19	available	240
20	available	240
21	available	240
22	available	240
23	available	240
24	available	240
25	available	240
26	available	240
27	available	240
28	available	240
29	available	240
30	available	240
31	available	240
32	available	240
33	available	240
34	available	240
35	available	240
36	available	240
37	available	240
38	available	240
39	available	240
40	available	240
41	available	240
42	available	240
43	available	240
44	available	240
45	available	240
1	available	241
2	available	241
3	available	241
4	available	241
5	available	241
6	available	241
7	available	241
8	available	241
9	available	241
10	available	241
11	available	241
12	available	241
13	available	241
14	available	241
15	available	241
16	available	241
17	available	241
18	available	241
19	available	241
20	available	241
21	available	241
22	available	241
23	available	241
24	available	241
25	available	241
26	available	241
27	available	241
28	available	241
29	available	241
30	available	241
1	available	242
2	available	242
3	available	242
4	available	242
5	available	242
6	available	242
7	available	242
8	available	242
9	available	242
10	available	242
11	available	242
12	available	242
13	available	242
14	available	242
15	available	242
16	available	242
17	available	242
18	available	242
19	available	242
20	available	242
21	available	242
22	available	242
23	available	242
24	available	242
25	available	242
26	available	242
27	available	242
28	available	242
29	available	242
30	available	242
31	available	242
32	available	242
33	available	242
34	available	242
35	available	242
36	available	242
37	available	242
38	available	242
39	available	242
40	available	242
41	available	242
42	available	242
43	available	242
44	available	242
45	available	242
46	available	242
47	available	242
48	available	242
49	available	242
50	available	242
1	available	243
2	available	243
3	available	243
4	available	243
5	available	243
6	available	243
7	available	243
8	available	243
9	available	243
10	available	243
11	available	243
12	available	243
13	available	243
14	available	243
15	available	243
16	available	243
17	available	243
18	available	243
19	available	243
20	available	243
21	available	243
22	available	243
23	available	243
24	available	243
25	available	243
26	available	243
27	available	243
28	available	243
29	available	243
30	available	243
31	available	243
32	available	243
33	available	243
34	available	243
35	available	243
36	available	243
37	available	243
38	available	243
39	available	243
40	available	243
1	available	244
2	available	244
3	available	244
4	available	244
5	available	244
6	available	244
7	available	244
8	available	244
9	available	244
10	available	244
11	available	244
12	available	244
13	available	244
14	available	244
15	available	244
16	available	244
17	available	244
18	available	244
19	available	244
20	available	244
21	available	244
22	available	244
23	available	244
24	available	244
25	available	244
26	available	244
27	available	244
28	available	244
29	available	244
30	available	244
31	available	244
32	available	244
33	available	244
34	available	244
35	available	244
36	available	244
1	available	245
2	available	245
3	available	245
4	available	245
5	available	245
6	available	245
7	available	245
8	available	245
9	available	245
10	available	245
11	available	245
12	available	245
13	available	245
14	available	245
15	available	245
16	available	245
17	available	245
18	available	245
19	available	245
20	available	245
21	available	245
22	available	245
23	available	245
24	available	245
25	available	245
26	available	245
27	available	245
28	available	245
29	available	245
30	available	245
31	available	245
32	available	245
33	available	245
34	available	245
35	available	245
36	available	245
37	available	245
38	available	245
39	available	245
40	available	245
41	available	245
42	available	245
43	available	245
44	available	245
45	available	245
1	available	246
2	available	246
3	available	246
4	available	246
5	available	246
6	available	246
7	available	246
8	available	246
9	available	246
10	available	246
11	available	246
12	available	246
13	available	246
14	available	246
15	available	246
16	available	246
17	available	246
18	available	246
19	available	246
20	available	246
21	available	246
22	available	246
23	available	246
24	available	246
25	available	246
26	available	246
27	available	246
28	available	246
29	available	246
30	available	246
1	available	247
2	available	247
3	available	247
4	available	247
5	available	247
6	available	247
7	available	247
8	available	247
9	available	247
10	available	247
11	available	247
12	available	247
13	available	247
14	available	247
15	available	247
16	available	247
17	available	247
18	available	247
19	available	247
20	available	247
21	available	247
22	available	247
23	available	247
24	available	247
25	available	247
26	available	247
27	available	247
28	available	247
29	available	247
30	available	247
31	available	247
32	available	247
33	available	247
34	available	247
35	available	247
36	available	247
37	available	247
38	available	247
39	available	247
40	available	247
41	available	247
42	available	247
43	available	247
44	available	247
45	available	247
46	available	247
47	available	247
48	available	247
49	available	247
50	available	247
1	available	248
2	available	248
3	available	248
4	available	248
5	available	248
6	available	248
7	available	248
8	available	248
9	available	248
10	available	248
11	available	248
12	available	248
13	available	248
14	available	248
15	available	248
16	available	248
17	available	248
18	available	248
19	available	248
20	available	248
21	available	248
22	available	248
23	available	248
24	available	248
25	available	248
26	available	248
27	available	248
28	available	248
29	available	248
30	available	248
31	available	248
32	available	248
33	available	248
34	available	248
35	available	248
36	available	248
37	available	248
38	available	248
39	available	248
40	available	248
1	available	249
2	available	249
3	available	249
4	available	249
5	available	249
6	available	249
7	available	249
8	available	249
9	available	249
10	available	249
11	available	249
12	available	249
13	available	249
14	available	249
15	available	249
16	available	249
17	available	249
18	available	249
19	available	249
20	available	249
21	available	249
22	available	249
23	available	249
24	available	249
25	available	249
26	available	249
27	available	249
28	available	249
29	available	249
30	available	249
31	available	249
32	available	249
33	available	249
34	available	249
35	available	249
36	available	249
1	available	250
2	available	250
3	available	250
4	available	250
5	available	250
6	available	250
7	available	250
8	available	250
9	available	250
10	available	250
11	available	250
12	available	250
13	available	250
14	available	250
15	available	250
16	available	250
17	available	250
18	available	250
19	available	250
20	available	250
21	available	250
22	available	250
23	available	250
24	available	250
25	available	250
26	available	250
27	available	250
28	available	250
29	available	250
30	available	250
31	available	250
32	available	250
33	available	250
34	available	250
35	available	250
36	available	250
37	available	250
38	available	250
39	available	250
40	available	250
41	available	250
42	available	250
43	available	250
44	available	250
45	available	250
1	available	251
2	available	251
3	available	251
4	available	251
5	available	251
6	available	251
7	available	251
8	available	251
9	available	251
10	available	251
11	available	251
12	available	251
13	available	251
14	available	251
15	available	251
16	available	251
17	available	251
18	available	251
19	available	251
20	available	251
21	available	251
22	available	251
23	available	251
24	available	251
25	available	251
26	available	251
27	available	251
28	available	251
29	available	251
30	available	251
1	available	252
2	available	252
3	available	252
4	available	252
5	available	252
6	available	252
7	available	252
8	available	252
9	available	252
10	available	252
11	available	252
12	available	252
13	available	252
14	available	252
15	available	252
16	available	252
17	available	252
18	available	252
19	available	252
20	available	252
21	available	252
22	available	252
23	available	252
24	available	252
25	available	252
26	available	252
27	available	252
28	available	252
29	available	252
30	available	252
31	available	252
32	available	252
33	available	252
34	available	252
35	available	252
36	available	252
37	available	252
38	available	252
39	available	252
40	available	252
41	available	252
42	available	252
43	available	252
44	available	252
45	available	252
46	available	252
47	available	252
48	available	252
49	available	252
50	available	252
1	available	253
2	available	253
3	available	253
4	available	253
5	available	253
6	available	253
7	available	253
8	available	253
9	available	253
10	available	253
11	available	253
12	available	253
13	available	253
14	available	253
15	available	253
16	available	253
17	available	253
18	available	253
19	available	253
20	available	253
21	available	253
22	available	253
23	available	253
24	available	253
25	available	253
26	available	253
27	available	253
28	available	253
29	available	253
30	available	253
31	available	253
32	available	253
33	available	253
34	available	253
35	available	253
36	available	253
37	available	253
38	available	253
39	available	253
40	available	253
1	available	254
2	available	254
3	available	254
4	available	254
5	available	254
6	available	254
7	available	254
8	available	254
9	available	254
10	available	254
11	available	254
12	available	254
13	available	254
14	available	254
15	available	254
16	available	254
17	available	254
18	available	254
19	available	254
20	available	254
21	available	254
22	available	254
23	available	254
24	available	254
25	available	254
26	available	254
27	available	254
28	available	254
29	available	254
30	available	254
31	available	254
32	available	254
33	available	254
34	available	254
35	available	254
36	available	254
1	available	255
2	available	255
3	available	255
4	available	255
5	available	255
6	available	255
7	available	255
8	available	255
9	available	255
10	available	255
11	available	255
12	available	255
13	available	255
14	available	255
15	available	255
16	available	255
17	available	255
18	available	255
19	available	255
20	available	255
21	available	255
22	available	255
23	available	255
24	available	255
25	available	255
26	available	255
27	available	255
28	available	255
29	available	255
30	available	255
31	available	255
32	available	255
33	available	255
34	available	255
35	available	255
36	available	255
37	available	255
38	available	255
39	available	255
40	available	255
41	available	255
42	available	255
43	available	255
44	available	255
45	available	255
1	available	256
2	available	256
3	available	256
4	available	256
5	available	256
6	available	256
7	available	256
8	available	256
9	available	256
10	available	256
11	available	256
12	available	256
13	available	256
14	available	256
15	available	256
16	available	256
17	available	256
18	available	256
19	available	256
20	available	256
21	available	256
22	available	256
23	available	256
24	available	256
25	available	256
26	available	256
27	available	256
28	available	256
29	available	256
30	available	256
1	available	257
2	available	257
3	available	257
4	available	257
5	available	257
6	available	257
7	available	257
8	available	257
9	available	257
10	available	257
11	available	257
12	available	257
13	available	257
14	available	257
15	available	257
16	available	257
17	available	257
18	available	257
19	available	257
20	available	257
21	available	257
22	available	257
23	available	257
24	available	257
25	available	257
26	available	257
27	available	257
28	available	257
29	available	257
30	available	257
31	available	257
32	available	257
33	available	257
34	available	257
35	available	257
36	available	257
37	available	257
38	available	257
39	available	257
40	available	257
41	available	257
42	available	257
43	available	257
44	available	257
45	available	257
46	available	257
47	available	257
48	available	257
49	available	257
50	available	257
\.


--
-- Data for Name: Ticket; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."Ticket" ("PassengerID", "Price", "PurchaseDate", "SeatNumber", "TicketID", "TripID") FROM stdin;
\.


--
-- Data for Name: Trip; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."Trip" ("ArrivalTime", "DepartureTime", "DriverID", "RouteID", "TripID", "VehicleID", "Price") FROM stdin;
2026-02-28 02:38:00	2026-02-28 01:30:00	10	16	132	15	65.00
2026-02-28 03:27:00	2026-02-28 03:00:00	11	17	133	11	40.00
2026-02-28 05:38:00	2026-02-28 05:00:00	12	18	134	12	45.00
2026-02-28 08:32:00	2026-02-28 07:30:00	9	13	135	13	60.00
2026-02-28 10:54:00	2026-02-28 10:00:00	10	14	136	14	55.00
2026-02-28 13:20:00	2026-02-28 12:30:00	11	15	137	15	55.00
2026-02-28 15:38:00	2026-02-28 14:30:00	12	16	138	11	65.00
2026-03-01 02:32:00	2026-03-01 01:30:00	11	13	139	12	60.00
2026-03-01 03:54:00	2026-03-01 03:00:00	12	14	140	13	55.00
2026-03-01 05:50:00	2026-03-01 05:00:00	9	15	141	14	55.00
2026-03-01 08:38:00	2026-03-01 07:30:00	10	16	142	15	65.00
2026-03-01 10:27:00	2026-03-01 10:00:00	11	17	143	11	40.00
2026-03-01 13:08:00	2026-03-01 12:30:00	12	18	144	12	45.00
2026-03-01 15:32:00	2026-03-01 14:30:00	9	13	145	13	60.00
2026-03-02 02:38:00	2026-03-02 01:30:00	12	16	146	14	65.00
2026-03-02 03:27:00	2026-03-02 03:00:00	9	17	147	15	40.00
2026-03-02 05:38:00	2026-03-02 05:00:00	10	18	148	11	45.00
2026-03-02 08:32:00	2026-03-02 07:30:00	11	13	149	12	60.00
2026-03-02 10:54:00	2026-03-02 10:00:00	12	14	150	13	55.00
2026-03-02 13:20:00	2026-03-02 12:30:00	9	15	151	14	55.00
2026-03-02 15:38:00	2026-03-02 14:30:00	10	16	152	15	65.00
2026-03-03 02:32:00	2026-03-03 01:30:00	9	13	153	11	60.00
2026-03-03 03:54:00	2026-03-03 03:00:00	10	14	154	12	55.00
2026-03-03 05:50:00	2026-03-03 05:00:00	11	15	155	13	55.00
2026-03-03 08:38:00	2026-03-03 07:30:00	12	16	156	14	65.00
2026-03-03 10:27:00	2026-03-03 10:00:00	9	17	157	15	40.00
2026-03-03 13:08:00	2026-03-03 12:30:00	10	18	158	11	45.00
2026-03-03 15:32:00	2026-03-03 14:30:00	11	13	159	12	60.00
2026-03-04 02:38:00	2026-03-04 01:30:00	10	16	160	13	65.00
2026-03-04 03:27:00	2026-03-04 03:00:00	11	17	161	14	40.00
2026-03-04 05:38:00	2026-03-04 05:00:00	12	18	162	15	45.00
2026-03-04 08:32:00	2026-03-04 07:30:00	9	13	163	11	60.00
2026-03-04 10:54:00	2026-03-04 10:00:00	10	14	164	12	55.00
2026-03-04 13:20:00	2026-03-04 12:30:00	11	15	165	13	55.00
2026-03-04 15:38:00	2026-03-04 14:30:00	12	16	166	14	65.00
2026-03-05 02:32:00	2026-03-05 01:30:00	11	13	167	15	60.00
2026-03-05 03:54:00	2026-03-05 03:00:00	12	14	168	11	55.00
2026-03-05 05:50:00	2026-03-05 05:00:00	9	15	169	12	55.00
2026-03-05 08:38:00	2026-03-05 07:30:00	10	16	170	13	65.00
2026-03-05 10:27:00	2026-03-05 10:00:00	11	17	171	14	40.00
2026-03-05 13:08:00	2026-03-05 12:30:00	12	18	172	15	45.00
2026-03-05 15:32:00	2026-03-05 14:30:00	9	13	173	11	60.00
2026-03-06 02:38:00	2026-03-06 01:30:00	12	16	174	12	65.00
2026-03-06 03:27:00	2026-03-06 03:00:00	9	17	175	13	40.00
2026-03-06 05:38:00	2026-03-06 05:00:00	10	18	176	14	45.00
2026-03-06 08:32:00	2026-03-06 07:30:00	11	13	177	15	60.00
2026-03-06 10:54:00	2026-03-06 10:00:00	12	14	178	11	55.00
2026-03-06 13:20:00	2026-03-06 12:30:00	9	15	179	12	55.00
2026-03-06 15:38:00	2026-03-06 14:30:00	10	16	180	13	65.00
2026-03-07 02:32:00	2026-03-07 01:30:00	9	13	181	14	60.00
2026-03-07 03:54:00	2026-03-07 03:00:00	10	14	182	15	55.00
2026-03-07 05:50:00	2026-03-07 05:00:00	11	15	183	11	55.00
2026-03-07 08:38:00	2026-03-07 07:30:00	12	16	184	12	65.00
2026-03-07 10:27:00	2026-03-07 10:00:00	9	17	185	13	40.00
2026-03-07 13:08:00	2026-03-07 12:30:00	10	18	186	14	45.00
2026-03-07 15:32:00	2026-03-07 14:30:00	11	13	187	15	60.00
2026-03-08 02:38:00	2026-03-08 01:30:00	10	16	188	11	65.00
2026-03-08 03:27:00	2026-03-08 03:00:00	11	17	189	12	40.00
2026-03-08 05:38:00	2026-03-08 05:00:00	12	18	190	13	45.00
2026-03-08 08:32:00	2026-03-08 07:30:00	9	13	191	14	60.00
2026-03-08 10:54:00	2026-03-08 10:00:00	10	14	192	15	55.00
2026-03-08 13:20:00	2026-03-08 12:30:00	11	15	193	11	55.00
2026-03-08 15:38:00	2026-03-08 14:30:00	12	16	194	12	65.00
2026-03-09 02:32:00	2026-03-09 01:30:00	11	13	195	13	60.00
2026-03-09 03:54:00	2026-03-09 03:00:00	12	14	196	14	55.00
2026-03-09 05:50:00	2026-03-09 05:00:00	9	15	197	15	55.00
2026-03-09 08:38:00	2026-03-09 07:30:00	10	16	198	11	65.00
2026-03-09 10:27:00	2026-03-09 10:00:00	11	17	199	12	40.00
2026-03-09 13:08:00	2026-03-09 12:30:00	12	18	200	13	45.00
2026-03-09 15:32:00	2026-03-09 14:30:00	9	13	201	14	60.00
2026-03-10 02:38:00	2026-03-10 01:30:00	12	16	202	15	65.00
2026-03-10 03:27:00	2026-03-10 03:00:00	9	17	203	11	40.00
2026-03-10 05:38:00	2026-03-10 05:00:00	10	18	204	12	45.00
2026-03-10 08:32:00	2026-03-10 07:30:00	11	13	205	13	60.00
2026-03-10 10:54:00	2026-03-10 10:00:00	12	14	206	14	55.00
2026-03-10 13:20:00	2026-03-10 12:30:00	9	15	207	15	55.00
2026-03-10 15:38:00	2026-03-10 14:30:00	10	16	208	11	65.00
2026-03-11 02:32:00	2026-03-11 01:30:00	9	13	209	12	60.00
2026-03-11 03:54:00	2026-03-11 03:00:00	10	14	210	13	55.00
2026-03-11 05:50:00	2026-03-11 05:00:00	11	15	211	14	55.00
2026-03-11 08:38:00	2026-03-11 07:30:00	12	16	212	15	65.00
2026-03-11 10:27:00	2026-03-11 10:00:00	9	17	213	11	40.00
2026-03-11 13:08:00	2026-03-11 12:30:00	10	18	214	12	45.00
2026-03-11 15:32:00	2026-03-11 14:30:00	11	13	215	13	60.00
2026-03-12 02:38:00	2026-03-12 01:30:00	10	16	216	14	65.00
2026-03-12 03:27:00	2026-03-12 03:00:00	11	17	217	15	40.00
2026-03-12 05:38:00	2026-03-12 05:00:00	12	18	218	11	45.00
2026-03-12 08:32:00	2026-03-12 07:30:00	9	13	219	12	60.00
2026-03-12 10:54:00	2026-03-12 10:00:00	10	14	220	13	55.00
2026-03-12 13:20:00	2026-03-12 12:30:00	11	15	221	14	55.00
2026-03-12 15:38:00	2026-03-12 14:30:00	12	16	222	15	65.00
2026-03-13 02:32:00	2026-03-13 01:30:00	11	13	223	11	60.00
2026-03-13 03:54:00	2026-03-13 03:00:00	12	14	224	12	55.00
2026-03-13 05:50:00	2026-03-13 05:00:00	9	15	225	13	55.00
2026-03-13 08:38:00	2026-03-13 07:30:00	10	16	226	14	65.00
2026-03-13 10:27:00	2026-03-13 10:00:00	11	17	227	15	40.00
2026-03-13 13:08:00	2026-03-13 12:30:00	12	18	228	11	45.00
2026-03-13 15:32:00	2026-03-13 14:30:00	9	13	229	12	60.00
2026-03-14 02:38:00	2026-03-14 01:30:00	12	16	230	13	65.00
2026-03-14 03:27:00	2026-03-14 03:00:00	9	17	231	14	40.00
2026-03-14 05:38:00	2026-03-14 05:00:00	10	18	232	15	45.00
2026-03-14 08:32:00	2026-03-14 07:30:00	11	13	233	11	60.00
2026-03-14 10:54:00	2026-03-14 10:00:00	12	14	234	12	55.00
2026-03-14 13:20:00	2026-03-14 12:30:00	9	15	235	13	55.00
2026-03-14 15:38:00	2026-03-14 14:30:00	10	16	236	14	65.00
2026-03-15 02:32:00	2026-03-15 01:30:00	9	13	237	15	60.00
2026-03-15 03:54:00	2026-03-15 03:00:00	10	14	238	11	55.00
2026-03-15 05:50:00	2026-03-15 05:00:00	11	15	239	12	55.00
2026-03-15 08:38:00	2026-03-15 07:30:00	12	16	240	13	65.00
2026-03-15 10:27:00	2026-03-15 10:00:00	9	17	241	14	40.00
2026-03-15 13:08:00	2026-03-15 12:30:00	10	18	242	15	45.00
2026-03-15 15:32:00	2026-03-15 14:30:00	11	13	243	11	60.00
2026-03-16 02:38:00	2026-03-16 01:30:00	10	16	244	12	65.00
2026-03-16 03:27:00	2026-03-16 03:00:00	11	17	245	13	40.00
2026-03-16 05:38:00	2026-03-16 05:00:00	12	18	246	14	45.00
2026-03-16 08:32:00	2026-03-16 07:30:00	9	13	247	15	60.00
2026-03-16 10:54:00	2026-03-16 10:00:00	10	14	248	11	55.00
2026-03-16 13:20:00	2026-03-16 12:30:00	11	15	249	12	55.00
2026-03-16 15:38:00	2026-03-16 14:30:00	12	16	250	13	65.00
2026-03-17 02:32:00	2026-03-17 01:30:00	11	13	251	14	60.00
2026-03-17 03:54:00	2026-03-17 03:00:00	12	14	252	15	55.00
2026-03-17 05:50:00	2026-03-17 05:00:00	9	15	253	11	55.00
2026-03-17 08:38:00	2026-03-17 07:30:00	10	16	254	12	65.00
2026-03-17 10:27:00	2026-03-17 10:00:00	11	17	255	13	40.00
2026-03-17 13:08:00	2026-03-17 12:30:00	12	18	256	14	45.00
2026-03-17 15:32:00	2026-03-17 14:30:00	9	13	257	15	60.00
\.


--
-- Data for Name: UserRole; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."UserRole" ("UserID", "Username", "Role") FROM stdin;
1	admin	admin
2	passenger_test	passenger
3	driver_test	driver
4	mechanic_test	mechanic
\.


--
-- Data for Name: Vehicle; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public."Vehicle" ("VehicleID", "LicensePlate", "Capacity", "Status") FROM stdin;
11	DHAKA-METRO-BA-11-2345	40	active
12	DHAKA-METRO-BA-12-6789	36	active
13	DHAKA-METRO-BA-13-1122	45	active
14	DHAKA-METRO-BA-14-3344	30	active
15	DHAKA-METRO-BA-15-5566	50	active
\.


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: transport_user
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
5706a349-85a8-4174-9a31-9bceb98cbdcc	5d95982a7006f476f0e7de0d8cd8c14c59d42b8465f3c9a506854c2be5c0272a	2026-01-27 09:03:52.6363+06	20260126153705_city_transport	\N	\N	2026-01-27 09:03:52.599307+06	1
2ae7f629-30d9-4f4c-b4c8-c042749185a8	d6c58fabd7784e08fe18541676f863b1517ca0f082513d60e71ece11378e7318	2026-01-27 09:03:52.8043+06	20260126155623_init	\N	\N	2026-01-27 09:03:52.637379+06	1
d3b51718-f825-4973-9279-a667d080445d	b7ab5433bbf201fe2cc725a70d30177213a8525272b3b8b0c0ab7bb0f4942646	2026-01-27 09:03:52.851672+06	20260127025255_test1	\N	\N	2026-01-27 09:03:52.805216+06	1
2facb3d6-f1a2-492c-a9ab-7dfa1730cf11	d974cc0794baee868ad3bb2cd2ca3739380d82c7eb32068c9b3c66f5d4974397	\N	20260303151856_add_password_to_user_role	A migration failed to apply. New migrations cannot be applied before the error is recovered from. Read more about how to resolve migration issues in a production database: https://pris.ly/d/migrate-resolve\n\nMigration name: 20260303151856_add_password_to_user_role\n\nDatabase error code: 23502\n\nDatabase error:\nERROR: column "PasswordHash" of relation "UserRole" contains null values\n\nDbError { severity: "ERROR", parsed_severity: Some(Error), code: SqlState(E23502), message: "column \\"PasswordHash\\" of relation \\"UserRole\\" contains null values", detail: None, hint: None, position: None, where_: None, schema: Some("public"), table: Some("UserRole"), column: Some("PasswordHash"), datatype: None, constraint: None, file: Some("tablecmds.c"), line: Some(6451), routine: Some("ATRewriteTable") }\n\n   0: sql_schema_connector::apply_migration::apply_script\n           with migration_name="20260303151856_add_password_to_user_role"\n             at schema-engine\\connectors\\sql-schema-connector\\src\\apply_migration.rs:113\n   1: schema_commands::commands::apply_migrations::Applying migration\n           with migration_name="20260303151856_add_password_to_user_role"\n             at schema-engine\\commands\\src\\commands\\apply_migrations.rs:95\n   2: schema_core::state::ApplyMigrations\n             at schema-engine\\core\\src\\state.rs:246	\N	2026-03-03 21:19:12.781544+06	0
\.


--
-- Name: AuditLog_LogID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."AuditLog_LogID_seq"', 1, false);


--
-- Name: DriverShiftAssignmentHistory_HistoryID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."DriverShiftAssignmentHistory_HistoryID_seq"', 2, true);


--
-- Name: DriverShiftAssignment_AssignmentID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."DriverShiftAssignment_AssignmentID_seq"', 2, true);


--
-- Name: DriverVehicleAssignment_AssignmentID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."DriverVehicleAssignment_AssignmentID_seq"', 1, false);


--
-- Name: Driver_DriverID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."Driver_DriverID_seq"', 12, true);


--
-- Name: FuelRecord_FuelRecordID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."FuelRecord_FuelRecordID_seq"', 1, false);


--
-- Name: IncidentReport_IncidentID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."IncidentReport_IncidentID_seq"', 1, false);


--
-- Name: MaintenanceRecord_RecordID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."MaintenanceRecord_RecordID_seq"', 1, false);


--
-- Name: Passenger_PassengerID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."Passenger_PassengerID_seq"', 1, true);


--
-- Name: Payment_PaymentID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."Payment_PaymentID_seq"', 1, false);


--
-- Name: Route_RouteID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."Route_RouteID_seq"', 18, true);


--
-- Name: ScheduledMaintenance_ScheduleID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."ScheduledMaintenance_ScheduleID_seq"', 1, false);


--
-- Name: Ticket_TicketID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."Ticket_TicketID_seq"', 3, true);


--
-- Name: Trip_TripID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."Trip_TripID_seq"', 257, true);


--
-- Name: UserRole_UserID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."UserRole_UserID_seq"', 4, true);


--
-- Name: Vehicle_VehicleID_seq; Type: SEQUENCE SET; Schema: public; Owner: transport_user
--

SELECT pg_catalog.setval('public."Vehicle_VehicleID_seq"', 15, true);


--
-- Name: AuditLog AuditLog_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("LogID");


--
-- Name: DailySummary DailySummary_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DailySummary"
    ADD CONSTRAINT "DailySummary_pkey" PRIMARY KEY ("SummaryDate");


--
-- Name: DriverShiftAssignmentHistory DriverShiftAssignmentHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverShiftAssignmentHistory"
    ADD CONSTRAINT "DriverShiftAssignmentHistory_pkey" PRIMARY KEY ("HistoryID");


--
-- Name: DriverShiftAssignment DriverShiftAssignment_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverShiftAssignment"
    ADD CONSTRAINT "DriverShiftAssignment_pkey" PRIMARY KEY ("AssignmentID");


--
-- Name: DriverVehicleAssignment DriverVehicleAssignment_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverVehicleAssignment"
    ADD CONSTRAINT "DriverVehicleAssignment_pkey" PRIMARY KEY ("AssignmentID");


--
-- Name: Driver Driver_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Driver"
    ADD CONSTRAINT "Driver_pkey" PRIMARY KEY ("DriverID");


--
-- Name: FuelRecord FuelRecord_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."FuelRecord"
    ADD CONSTRAINT "FuelRecord_pkey" PRIMARY KEY ("FuelRecordID");


--
-- Name: IncidentReport IncidentReport_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."IncidentReport"
    ADD CONSTRAINT "IncidentReport_pkey" PRIMARY KEY ("IncidentID");


--
-- Name: MaintenanceRecord MaintenanceRecord_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."MaintenanceRecord"
    ADD CONSTRAINT "MaintenanceRecord_pkey" PRIMARY KEY ("RecordID");


--
-- Name: Passenger Passenger_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Passenger"
    ADD CONSTRAINT "Passenger_pkey" PRIMARY KEY ("PassengerID");


--
-- Name: Payment Payment_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_pkey" PRIMARY KEY ("PaymentID");


--
-- Name: Route Route_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Route"
    ADD CONSTRAINT "Route_pkey" PRIMARY KEY ("RouteID");


--
-- Name: ScheduledMaintenance ScheduledMaintenance_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."ScheduledMaintenance"
    ADD CONSTRAINT "ScheduledMaintenance_pkey" PRIMARY KEY ("ScheduleID");


--
-- Name: Seat Seat_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Seat"
    ADD CONSTRAINT "Seat_pkey" PRIMARY KEY ("TripID", "SeatNumber");


--
-- Name: Ticket Ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Ticket"
    ADD CONSTRAINT "Ticket_pkey" PRIMARY KEY ("TicketID");


--
-- Name: Trip Trip_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Trip"
    ADD CONSTRAINT "Trip_pkey" PRIMARY KEY ("TripID");


--
-- Name: UserRole UserRole_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_pkey" PRIMARY KEY ("UserID");


--
-- Name: Vehicle Vehicle_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Vehicle"
    ADD CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("VehicleID");


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: DriverVehicleAssignment_DriverID_key; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE UNIQUE INDEX "DriverVehicleAssignment_DriverID_key" ON public."DriverVehicleAssignment" USING btree ("DriverID");


--
-- Name: DriverVehicleAssignment_VehicleID_key; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE UNIQUE INDEX "DriverVehicleAssignment_VehicleID_key" ON public."DriverVehicleAssignment" USING btree ("VehicleID");


--
-- Name: Driver_LicenseNumber_key; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE UNIQUE INDEX "Driver_LicenseNumber_key" ON public."Driver" USING btree ("LicenseNumber");


--
-- Name: Payment_TicketID_key; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE UNIQUE INDEX "Payment_TicketID_key" ON public."Payment" USING btree ("TicketID");


--
-- Name: UserRole_Username_key; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE UNIQUE INDEX "UserRole_Username_key" ON public."UserRole" USING btree ("Username");


--
-- Name: Vehicle_LicensePlate_key; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE UNIQUE INDEX "Vehicle_LicensePlate_key" ON public."Vehicle" USING btree ("LicensePlate");


--
-- Name: idx_assign_driver; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_assign_driver ON public."DriverVehicleAssignment" USING btree ("DriverID");


--
-- Name: idx_assign_vehicle; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_assign_vehicle ON public."DriverVehicleAssignment" USING btree ("VehicleID");


--
-- Name: idx_audit_table_record; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_audit_table_record ON public."AuditLog" USING btree ("TableName", "RecordID");


--
-- Name: idx_audit_timestamp; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_audit_timestamp ON public."AuditLog" USING btree ("Timestamp");


--
-- Name: idx_dsa_date_shift; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_dsa_date_shift ON public."DriverShiftAssignment" USING btree ("AssignDate", "Shift");


--
-- Name: idx_dsa_hist_changedat; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_dsa_hist_changedat ON public."DriverShiftAssignmentHistory" USING btree ("ChangedAt");


--
-- Name: idx_dsa_hist_date_shift; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_dsa_hist_date_shift ON public."DriverShiftAssignmentHistory" USING btree ("AssignDate", "Shift");


--
-- Name: idx_fuel_vehicle_date; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_fuel_vehicle_date ON public."FuelRecord" USING btree ("VehicleID", "Date");


--
-- Name: idx_incident_date; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_incident_date ON public."IncidentReport" USING btree ("IncidentDate");


--
-- Name: idx_maintenance_vehicle_date; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_maintenance_vehicle_date ON public."MaintenanceRecord" USING btree ("VehicleID", "Date");


--
-- Name: idx_sched_vehicle_date; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_sched_vehicle_date ON public."ScheduledMaintenance" USING btree ("VehicleID", "ScheduledDate");


--
-- Name: idx_seat_trip_status; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_seat_trip_status ON public."Seat" USING btree ("TripID", "Status");


--
-- Name: idx_ticket_passenger; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_ticket_passenger ON public."Ticket" USING btree ("PassengerID");


--
-- Name: idx_ticket_trip; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_ticket_trip ON public."Ticket" USING btree ("TripID");


--
-- Name: idx_trip_departure; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_trip_departure ON public."Trip" USING btree ("DepartureTime");


--
-- Name: idx_trip_driver; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_trip_driver ON public."Trip" USING btree ("DriverID");


--
-- Name: idx_trip_vehicle; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE INDEX idx_trip_vehicle ON public."Trip" USING btree ("VehicleID");


--
-- Name: uq_trip_seat; Type: INDEX; Schema: public; Owner: transport_user
--

CREATE UNIQUE INDEX uq_trip_seat ON public."Ticket" USING btree ("TripID", "SeatNumber");


--
-- Name: AuditLog AuditLog_UserID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_UserID_fkey" FOREIGN KEY ("UserID") REFERENCES public."UserRole"("UserID") ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: FuelRecord FuelRecord_VehicleID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."FuelRecord"
    ADD CONSTRAINT "FuelRecord_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES public."Vehicle"("VehicleID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: IncidentReport IncidentReport_TripID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."IncidentReport"
    ADD CONSTRAINT "IncidentReport_TripID_fkey" FOREIGN KEY ("TripID") REFERENCES public."Trip"("TripID") ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: IncidentReport IncidentReport_VehicleID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."IncidentReport"
    ADD CONSTRAINT "IncidentReport_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES public."Vehicle"("VehicleID") ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: MaintenanceRecord MaintenanceRecord_VehicleID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."MaintenanceRecord"
    ADD CONSTRAINT "MaintenanceRecord_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES public."Vehicle"("VehicleID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Payment Payment_TicketID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_TicketID_fkey" FOREIGN KEY ("TicketID") REFERENCES public."Ticket"("TicketID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ScheduledMaintenance ScheduledMaintenance_VehicleID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."ScheduledMaintenance"
    ADD CONSTRAINT "ScheduledMaintenance_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES public."Vehicle"("VehicleID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Seat Seat_TripID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Seat"
    ADD CONSTRAINT "Seat_TripID_fkey" FOREIGN KEY ("TripID") REFERENCES public."Trip"("TripID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Ticket Ticket_PassengerID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Ticket"
    ADD CONSTRAINT "Ticket_PassengerID_fkey" FOREIGN KEY ("PassengerID") REFERENCES public."Passenger"("PassengerID") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Ticket Ticket_TripID_SeatNumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Ticket"
    ADD CONSTRAINT "Ticket_TripID_SeatNumber_fkey" FOREIGN KEY ("TripID", "SeatNumber") REFERENCES public."Seat"("TripID", "SeatNumber") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Ticket Ticket_TripID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Ticket"
    ADD CONSTRAINT "Ticket_TripID_fkey" FOREIGN KEY ("TripID") REFERENCES public."Trip"("TripID") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Trip Trip_DriverID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Trip"
    ADD CONSTRAINT "Trip_DriverID_fkey" FOREIGN KEY ("DriverID") REFERENCES public."Driver"("DriverID") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Trip Trip_RouteID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Trip"
    ADD CONSTRAINT "Trip_RouteID_fkey" FOREIGN KEY ("RouteID") REFERENCES public."Route"("RouteID") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Trip Trip_VehicleID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."Trip"
    ADD CONSTRAINT "Trip_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES public."Vehicle"("VehicleID") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: DriverVehicleAssignment fk_assign_driver; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverVehicleAssignment"
    ADD CONSTRAINT fk_assign_driver FOREIGN KEY ("DriverID") REFERENCES public."Driver"("DriverID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DriverVehicleAssignment fk_assign_vehicle; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverVehicleAssignment"
    ADD CONSTRAINT fk_assign_vehicle FOREIGN KEY ("VehicleID") REFERENCES public."Vehicle"("VehicleID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DriverShiftAssignment fk_dsa_driver; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverShiftAssignment"
    ADD CONSTRAINT fk_dsa_driver FOREIGN KEY ("DriverID") REFERENCES public."Driver"("DriverID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DriverShiftAssignment fk_dsa_vehicle; Type: FK CONSTRAINT; Schema: public; Owner: transport_user
--

ALTER TABLE ONLY public."DriverShiftAssignment"
    ADD CONSTRAINT fk_dsa_vehicle FOREIGN KEY ("VehicleID") REFERENCES public."Vehicle"("VehicleID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO transport_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO transport_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO transport_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO transport_user;


--
-- PostgreSQL database dump complete
--

\unrestrict naetBf2cHOozC064K56XKE3pIygwBNL8xXcgiQeJgDoeSz9GcdLFcuoZi6NoIvu

