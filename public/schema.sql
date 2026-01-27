-- =========================================
-- CITY TRANSPORT DATABASE SCHEMA (PostgreSQL)
-- =========================================

-- Optional: clean rebuild
-- DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;

-- =====================
-- ENUM TYPES
-- =====================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'vehicle_status') THEN
    CREATE TYPE vehicle_status AS ENUM ('active', 'inactive', 'maintenance');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'seat_status') THEN
    CREATE TYPE seat_status AS ENUM ('available', 'held', 'sold');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('admin', 'passenger', 'driver', 'mechanic');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'incident_severity') THEN
    CREATE TYPE incident_severity AS ENUM ('low', 'medium', 'high', 'critical');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
    CREATE TYPE payment_method AS ENUM ('cash', 'card', 'mobile', 'other');
  END IF;
END $$;

-- =====================
-- ROUTE
-- =====================
CREATE TABLE IF NOT EXISTS "Route" (
  "RouteID"       SERIAL PRIMARY KEY,
  "StartLocation" VARCHAR(100) NOT NULL,
  "EndLocation"   VARCHAR(100) NOT NULL,
  "Distance"      NUMERIC(6,2) NOT NULL CHECK ("Distance" > 0)
);

-- =====================
-- DRIVER
-- =====================
CREATE TABLE IF NOT EXISTS "Driver" (
  "DriverID"      SERIAL PRIMARY KEY,
  "Name"          VARCHAR(100) NOT NULL,
  "LicenseNumber" VARCHAR(50) UNIQUE NOT NULL,
  "ContactInfo"   VARCHAR(150)
);

-- =====================
-- VEHICLE
-- =====================
CREATE TABLE IF NOT EXISTS "Vehicle" (
  "VehicleID"     SERIAL PRIMARY KEY,
  "LicensePlate"  VARCHAR(20) UNIQUE NOT NULL,
  "Capacity"      INT NOT NULL CHECK ("Capacity" > 0),
  "Status"        vehicle_status NOT NULL DEFAULT 'active'
);

-- =====================
-- PASSENGER
-- =====================
CREATE TABLE IF NOT EXISTS "Passenger" (
  "PassengerID"  SERIAL PRIMARY KEY,
  "Name"         VARCHAR(100) NOT NULL,
  "ContactInfo"  VARCHAR(150)
);

-- =====================
-- USER ROLE (system users)
-- =====================
CREATE TABLE IF NOT EXISTS "UserRole" (
  "UserID"    SERIAL PRIMARY KEY,
  "Username"  VARCHAR(50) UNIQUE NOT NULL,
  "Role"      user_role NOT NULL DEFAULT 'passenger'
);

-- =====================
-- TRIP
-- =====================
CREATE TABLE IF NOT EXISTS "Trip" (
  "TripID"         SERIAL PRIMARY KEY,
  "RouteID"        INT NOT NULL,
  "VehicleID"      INT NOT NULL,
  "DriverID"       INT NOT NULL,
  "DepartureTime"  TIMESTAMP NOT NULL,
  "ArrivalTime"    TIMESTAMP,

  CONSTRAINT "fk_trip_route"
    FOREIGN KEY ("RouteID") REFERENCES "Route"("RouteID")
    ON UPDATE CASCADE ON DELETE RESTRICT,

  CONSTRAINT "fk_trip_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON UPDATE CASCADE ON DELETE RESTRICT,

  CONSTRAINT "fk_trip_driver"
    FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID")
    ON UPDATE CASCADE ON DELETE RESTRICT,

  CONSTRAINT "chk_trip_time"
    CHECK ("ArrivalTime" IS NULL OR "ArrivalTime" > "DepartureTime")
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS "idx_trip_departure" ON "Trip"("DepartureTime");
CREATE INDEX IF NOT EXISTS "idx_trip_vehicle" ON "Trip"("VehicleID");
CREATE INDEX IF NOT EXISTS "idx_trip_driver"  ON "Trip"("DriverID");

-- =====================
-- SEAT (per trip seat inventory)
-- =====================
CREATE TABLE IF NOT EXISTS "Seat" (
  "TripID"      INT NOT NULL,
  "SeatNumber"  INT NOT NULL,
  "Status"      seat_status NOT NULL DEFAULT 'available',

  PRIMARY KEY ("TripID", "SeatNumber"),

  CONSTRAINT "fk_seat_trip"
    FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID")
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_seat_trip_status" ON "Seat"("TripID", "Status");

-- =====================
-- TICKET
-- =====================
CREATE TABLE IF NOT EXISTS "Ticket" (
  "TicketID"      SERIAL PRIMARY KEY,
  "TripID"        INT NOT NULL,
  "PassengerID"   INT NOT NULL,
  "SeatNumber"    INT NOT NULL,
  "Price"         NUMERIC(8,2) NOT NULL CHECK ("Price" >= 0),
  "PurchaseDate"  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "fk_ticket_trip"
    FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID")
    ON UPDATE CASCADE ON DELETE RESTRICT,

  CONSTRAINT "fk_ticket_passenger"
    FOREIGN KEY ("PassengerID") REFERENCES "Passenger"("PassengerID")
    ON UPDATE CASCADE ON DELETE RESTRICT,

  -- Prevent selling same seat twice
  CONSTRAINT "uq_trip_seat"
    UNIQUE ("TripID", "SeatNumber"),

  -- Ensure seat exists in Seat inventory (composite FK)
  CONSTRAINT "fk_ticket_seat"
    FOREIGN KEY ("TripID", "SeatNumber")
    REFERENCES "Seat"("TripID", "SeatNumber")
    ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "idx_ticket_trip" ON "Ticket"("TripID");
CREATE INDEX IF NOT EXISTS "idx_ticket_passenger" ON "Ticket"("PassengerID");

-- =====================
-- PAYMENT (1 payment per ticket here)
-- =====================
CREATE TABLE IF NOT EXISTS "Payment" (
  "PaymentID"     SERIAL PRIMARY KEY,
  "TicketID"      INT NOT NULL UNIQUE,
  "Amount"        NUMERIC(8,2) NOT NULL CHECK ("Amount" >= 0),
  "PaymentMethod" payment_method NOT NULL DEFAULT 'other',
  "PaymentDate"   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "fk_payment_ticket"
    FOREIGN KEY ("TicketID") REFERENCES "Ticket"("TicketID")
    ON UPDATE CASCADE ON DELETE CASCADE
);

-- =====================
-- MAINTENANCE RECORD
-- =====================
CREATE TABLE IF NOT EXISTS "MaintenanceRecord" (
  "RecordID"     SERIAL PRIMARY KEY,
  "VehicleID"    INT NOT NULL,
  "Date"         DATE NOT NULL,
  "Description"  TEXT,
  "Cost"         NUMERIC(10,2) CHECK ("Cost" >= 0),

  CONSTRAINT "fk_maintenance_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_maintenance_vehicle_date"
  ON "MaintenanceRecord"("VehicleID", "Date");

-- =====================
-- FUEL RECORD
-- =====================
CREATE TABLE IF NOT EXISTS "FuelRecord" (
  "FuelRecordID"  SERIAL PRIMARY KEY,
  "VehicleID"     INT NOT NULL,
  "Date"          DATE NOT NULL,
  "FuelAmount"    NUMERIC(8,2) NOT NULL CHECK ("FuelAmount" > 0),
  "Cost"          NUMERIC(10,2) CHECK ("Cost" >= 0),

  CONSTRAINT "fk_fuel_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_fuel_vehicle_date"
  ON "FuelRecord"("VehicleID", "Date");

-- =====================
-- SCHEDULED MAINTENANCE
-- =====================
CREATE TABLE IF NOT EXISTS "ScheduledMaintenance" (
  "ScheduleID"     SERIAL PRIMARY KEY,
  "VehicleID"      INT NOT NULL,
  "ScheduledDate"  DATE NOT NULL,
  "Description"    TEXT,

  CONSTRAINT "fk_sched_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_sched_vehicle_date"
  ON "ScheduledMaintenance"("VehicleID", "ScheduledDate");

-- =====================
-- INCIDENT REPORT
-- =====================
CREATE TABLE IF NOT EXISTS "IncidentReport" (
  "IncidentID"     SERIAL PRIMARY KEY,
  "VehicleID"      INT,
  "TripID"         INT,
  "IncidentDate"   TIMESTAMP NOT NULL,
  "Description"    TEXT NOT NULL,
  "Severity"       incident_severity NOT NULL DEFAULT 'low',

  CONSTRAINT "fk_incident_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON UPDATE CASCADE ON DELETE SET NULL,

  CONSTRAINT "fk_incident_trip"
    FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID")
    ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "idx_incident_date"
  ON "IncidentReport"("IncidentDate");

-- =====================
-- AUDIT LOG
-- =====================
CREATE TABLE IF NOT EXISTS "AuditLog" (
  "LogID"      SERIAL PRIMARY KEY,
  "Action"     VARCHAR(50) NOT NULL,
  "TableName"  VARCHAR(50) NOT NULL,
  "RecordID"   INT NOT NULL,
  "Timestamp"  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "UserID"     INT,
  "Details"    JSONB,

  CONSTRAINT "fk_audit_user"
    FOREIGN KEY ("UserID") REFERENCES "UserRole"("UserID")
    ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "idx_audit_timestamp" ON "AuditLog"("Timestamp");
CREATE INDEX IF NOT EXISTS "idx_audit_table_record" ON "AuditLog"("TableName", "RecordID");

-- =====================
-- DAILY SUMMARY
-- =====================
CREATE TABLE IF NOT EXISTS "DailySummary" (
  "SummaryDate"      DATE PRIMARY KEY,
  "TotalTrips"       INT NOT NULL CHECK ("TotalTrips" >= 0),
  "TotalTicketsSold" INT NOT NULL CHECK ("TotalTicketsSold" >= 0),
  "TotalRevenue"     NUMERIC(12,2) NOT NULL CHECK ("TotalRevenue" >= 0)
);

CREATE TABLE IF NOT EXISTS "DriverVehicleAssignment" (
  "AssignmentID" SERIAL PRIMARY KEY,
  "DriverID" INT NOT NULL UNIQUE,
  "VehicleID" INT NOT NULL UNIQUE,
  "AssignedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "fk_assign_driver"
    FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID")
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT "fk_assign_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_assign_driver" ON "DriverVehicleAssignment"("DriverID");
CREATE INDEX IF NOT EXISTS "idx_assign_vehicle" ON "DriverVehicleAssignment"("VehicleID");

-- DRIVER SHIFT ASSIGNMENT AND HISTORY CREATION
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shift_type') THEN
    CREATE TYPE shift_type AS ENUM ('morning', 'day', 'evening', 'night');
  END IF;
END $$;

-- Current assignment per day+shift
CREATE TABLE IF NOT EXISTS "DriverShiftAssignment" (
  "AssignmentID" SERIAL PRIMARY KEY,
  "DriverID" INT NOT NULL,
  "VehicleID" INT NOT NULL,
  "AssignDate" DATE NOT NULL,
  "Shift" shift_type NOT NULL,
  "AssignedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "UnassignedAt" TIMESTAMP NULL,

  CONSTRAINT "fk_dsa_driver"
    FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID")
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT "fk_dsa_vehicle"
    FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID")
    ON UPDATE CASCADE ON DELETE CASCADE
);

-- Enforce 1 driver ↔ 1 vehicle per day+shift
CREATE UNIQUE INDEX IF NOT EXISTS "uq_dsa_driver_date_shift"
  ON "DriverShiftAssignment"("DriverID","AssignDate","Shift")
  WHERE "UnassignedAt" IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "uq_dsa_vehicle_date_shift"
  ON "DriverShiftAssignment"("VehicleID","AssignDate","Shift")
  WHERE "UnassignedAt" IS NULL;

CREATE INDEX IF NOT EXISTS "idx_dsa_date_shift" ON "DriverShiftAssignment"("AssignDate","Shift");

-- History table: every change logged
CREATE TABLE IF NOT EXISTS "DriverShiftAssignmentHistory" (
  "HistoryID" SERIAL PRIMARY KEY,
  "AssignDate" DATE NOT NULL,
  "Shift" shift_type NOT NULL,
  "Action" VARCHAR(20) NOT NULL, -- ASSIGN / UNASSIGN / REASSIGN
  "DriverID" INT,
  "VehicleID" INT,
  "PrevDriverID" INT,
  "PrevVehicleID" INT,
  "ChangedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "Note" TEXT
);

CREATE INDEX IF NOT EXISTS "idx_dsa_hist_date_shift" ON "DriverShiftAssignmentHistory"("AssignDate","Shift");
CREATE INDEX IF NOT EXISTS "idx_dsa_hist_changedat" ON "DriverShiftAssignmentHistory"("ChangedAt");
