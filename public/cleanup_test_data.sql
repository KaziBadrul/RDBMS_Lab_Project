-- ============================
-- CLEANUP TEST DATA
-- ============================

BEGIN;

-- Order matters because of foreign keys

DELETE FROM "AuditLog";
DELETE FROM "DailySummary";
DELETE FROM "Payment";
DELETE FROM "Ticket";
DELETE FROM "Seat";
DELETE FROM "IncidentReport";
DELETE FROM "FuelRecord";
DELETE FROM "ScheduledMaintenance";
DELETE FROM "MaintenanceRecord";
DELETE FROM "Trip";
DELETE FROM "Passenger";
DELETE FROM "Driver";
DELETE FROM "Vehicle";
DELETE FROM "Route";
DELETE FROM "UserRole";

-- Reset sequences (important for predictable IDs)
ALTER SEQUENCE IF EXISTS "Route_RouteID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "Driver_DriverID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "Vehicle_VehicleID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "Passenger_PassengerID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "Trip_TripID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "Ticket_TicketID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "Payment_PaymentID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "MaintenanceRecord_RecordID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "FuelRecord_FuelRecordID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "ScheduledMaintenance_ScheduleID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "IncidentReport_IncidentID_seq" RESTART WITH 1;
ALTER SEQUENCE IF EXISTS "AuditLog_LogID_seq" RESTART WITH 1;

COMMIT;
