/*
  Warnings:

  - The primary key for the `Seat` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `id` on the `Seat` table. All the data in the column will be lost.
  - You are about to drop the column `number` on the `Seat` table. All the data in the column will be lost.
  - You are about to drop the column `status` on the `Seat` table. All the data in the column will be lost.
  - You are about to drop the column `tripId` on the `Seat` table. All the data in the column will be lost.
  - The primary key for the `Ticket` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `createdAt` on the `Ticket` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `Ticket` table. All the data in the column will be lost.
  - You are about to drop the column `passenger` on the `Ticket` table. All the data in the column will be lost.
  - You are about to drop the column `tripId` on the `Ticket` table. All the data in the column will be lost.
  - The primary key for the `Trip` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `capacity` on the `Trip` table. All the data in the column will be lost.
  - You are about to drop the column `code` on the `Trip` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `Trip` table. All the data in the column will be lost.
  - You are about to drop the column `price` on the `Trip` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[TripID,SeatNumber]` on the table `Ticket` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `SeatNumber` to the `Seat` table without a default value. This is not possible if the table is not empty.
  - Added the required column `TripID` to the `Seat` table without a default value. This is not possible if the table is not empty.
  - Added the required column `PassengerID` to the `Ticket` table without a default value. This is not possible if the table is not empty.
  - Added the required column `Price` to the `Ticket` table without a default value. This is not possible if the table is not empty.
  - Added the required column `SeatNumber` to the `Ticket` table without a default value. This is not possible if the table is not empty.
  - Added the required column `TripID` to the `Ticket` table without a default value. This is not possible if the table is not empty.
  - Added the required column `DepartureTime` to the `Trip` table without a default value. This is not possible if the table is not empty.
  - Added the required column `DriverID` to the `Trip` table without a default value. This is not possible if the table is not empty.
  - Added the required column `RouteID` to the `Trip` table without a default value. This is not possible if the table is not empty.
  - Added the required column `VehicleID` to the `Trip` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "VehicleStatus" AS ENUM ('active', 'inactive', 'maintenance');

-- CreateEnum
CREATE TYPE "SeatStatus" AS ENUM ('available', 'held', 'sold');

-- CreateEnum
CREATE TYPE "UserRoleType" AS ENUM ('admin', 'passenger', 'driver', 'mechanic');

-- CreateEnum
CREATE TYPE "IncidentSeverity" AS ENUM ('low', 'medium', 'high', 'critical');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('cash', 'card', 'mobile', 'other');

-- DropForeignKey
ALTER TABLE "Seat" DROP CONSTRAINT "Seat_tripId_fkey";

-- DropForeignKey
ALTER TABLE "Ticket" DROP CONSTRAINT "Ticket_tripId_fkey";

-- DropIndex
DROP INDEX "Seat_tripId_number_key";

-- DropIndex
DROP INDEX "Trip_code_key";

-- AlterTable
ALTER TABLE "Seat" DROP CONSTRAINT "Seat_pkey",
DROP COLUMN "id",
DROP COLUMN "number",
DROP COLUMN "status",
DROP COLUMN "tripId",
ADD COLUMN     "SeatNumber" INTEGER NOT NULL,
ADD COLUMN     "Status" "SeatStatus" NOT NULL DEFAULT 'available',
ADD COLUMN     "TripID" INTEGER NOT NULL,
ADD CONSTRAINT "Seat_pkey" PRIMARY KEY ("TripID", "SeatNumber");

-- AlterTable
ALTER TABLE "Ticket" DROP CONSTRAINT "Ticket_pkey",
DROP COLUMN "createdAt",
DROP COLUMN "id",
DROP COLUMN "passenger",
DROP COLUMN "tripId",
ADD COLUMN     "PassengerID" INTEGER NOT NULL,
ADD COLUMN     "Price" DECIMAL(8,2) NOT NULL,
ADD COLUMN     "PurchaseDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "SeatNumber" INTEGER NOT NULL,
ADD COLUMN     "TicketID" SERIAL NOT NULL,
ADD COLUMN     "TripID" INTEGER NOT NULL,
ADD CONSTRAINT "Ticket_pkey" PRIMARY KEY ("TicketID");

-- AlterTable
ALTER TABLE "Trip" DROP CONSTRAINT "Trip_pkey",
DROP COLUMN "capacity",
DROP COLUMN "code",
DROP COLUMN "id",
DROP COLUMN "price",
ADD COLUMN     "ArrivalTime" TIMESTAMP(3),
ADD COLUMN     "DepartureTime" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "DriverID" INTEGER NOT NULL,
ADD COLUMN     "RouteID" INTEGER NOT NULL,
ADD COLUMN     "TripID" SERIAL NOT NULL,
ADD COLUMN     "VehicleID" INTEGER NOT NULL,
ADD CONSTRAINT "Trip_pkey" PRIMARY KEY ("TripID");

-- CreateTable
CREATE TABLE "Route" (
    "RouteID" SERIAL NOT NULL,
    "StartLocation" VARCHAR(100) NOT NULL,
    "EndLocation" VARCHAR(100) NOT NULL,
    "Distance" DECIMAL(6,2) NOT NULL,

    CONSTRAINT "Route_pkey" PRIMARY KEY ("RouteID")
);

-- CreateTable
CREATE TABLE "Driver" (
    "DriverID" SERIAL NOT NULL,
    "Name" VARCHAR(100) NOT NULL,
    "LicenseNumber" VARCHAR(50) NOT NULL,
    "ContactInfo" VARCHAR(150),

    CONSTRAINT "Driver_pkey" PRIMARY KEY ("DriverID")
);

-- CreateTable
CREATE TABLE "Vehicle" (
    "VehicleID" SERIAL NOT NULL,
    "LicensePlate" VARCHAR(20) NOT NULL,
    "Capacity" INTEGER NOT NULL,
    "Status" "VehicleStatus" NOT NULL DEFAULT 'active',

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("VehicleID")
);

-- CreateTable
CREATE TABLE "Passenger" (
    "PassengerID" SERIAL NOT NULL,
    "Name" VARCHAR(100) NOT NULL,
    "ContactInfo" VARCHAR(150),

    CONSTRAINT "Passenger_pkey" PRIMARY KEY ("PassengerID")
);

-- CreateTable
CREATE TABLE "UserRole" (
    "UserID" SERIAL NOT NULL,
    "Username" VARCHAR(50) NOT NULL,
    "Role" "UserRoleType" NOT NULL DEFAULT 'passenger',

    CONSTRAINT "UserRole_pkey" PRIMARY KEY ("UserID")
);

-- CreateTable
CREATE TABLE "Payment" (
    "PaymentID" SERIAL NOT NULL,
    "TicketID" INTEGER NOT NULL,
    "Amount" DECIMAL(8,2) NOT NULL,
    "PaymentMethod" "PaymentMethod" NOT NULL DEFAULT 'other',
    "PaymentDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("PaymentID")
);

-- CreateTable
CREATE TABLE "MaintenanceRecord" (
    "RecordID" SERIAL NOT NULL,
    "VehicleID" INTEGER NOT NULL,
    "Date" DATE NOT NULL,
    "Description" TEXT,
    "Cost" DECIMAL(10,2),

    CONSTRAINT "MaintenanceRecord_pkey" PRIMARY KEY ("RecordID")
);

-- CreateTable
CREATE TABLE "FuelRecord" (
    "FuelRecordID" SERIAL NOT NULL,
    "VehicleID" INTEGER NOT NULL,
    "Date" DATE NOT NULL,
    "FuelAmount" DECIMAL(8,2) NOT NULL,
    "Cost" DECIMAL(10,2),

    CONSTRAINT "FuelRecord_pkey" PRIMARY KEY ("FuelRecordID")
);

-- CreateTable
CREATE TABLE "ScheduledMaintenance" (
    "ScheduleID" SERIAL NOT NULL,
    "VehicleID" INTEGER NOT NULL,
    "ScheduledDate" DATE NOT NULL,
    "Description" TEXT,

    CONSTRAINT "ScheduledMaintenance_pkey" PRIMARY KEY ("ScheduleID")
);

-- CreateTable
CREATE TABLE "IncidentReport" (
    "IncidentID" SERIAL NOT NULL,
    "VehicleID" INTEGER,
    "TripID" INTEGER,
    "IncidentDate" TIMESTAMP(3) NOT NULL,
    "Description" TEXT NOT NULL,
    "Severity" "IncidentSeverity" NOT NULL DEFAULT 'low',

    CONSTRAINT "IncidentReport_pkey" PRIMARY KEY ("IncidentID")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "LogID" SERIAL NOT NULL,
    "Action" VARCHAR(50) NOT NULL,
    "TableName" VARCHAR(50) NOT NULL,
    "RecordID" INTEGER NOT NULL,
    "Timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UserID" INTEGER,
    "Details" JSONB,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("LogID")
);

-- CreateTable
CREATE TABLE "DailySummary" (
    "SummaryDate" DATE NOT NULL,
    "TotalTrips" INTEGER NOT NULL,
    "TotalTicketsSold" INTEGER NOT NULL,
    "TotalRevenue" DECIMAL(12,2) NOT NULL,

    CONSTRAINT "DailySummary_pkey" PRIMARY KEY ("SummaryDate")
);

-- CreateIndex
CREATE UNIQUE INDEX "Driver_LicenseNumber_key" ON "Driver"("LicenseNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_LicensePlate_key" ON "Vehicle"("LicensePlate");

-- CreateIndex
CREATE UNIQUE INDEX "UserRole_Username_key" ON "UserRole"("Username");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_TicketID_key" ON "Payment"("TicketID");

-- CreateIndex
CREATE INDEX "idx_maintenance_vehicle_date" ON "MaintenanceRecord"("VehicleID", "Date");

-- CreateIndex
CREATE INDEX "idx_fuel_vehicle_date" ON "FuelRecord"("VehicleID", "Date");

-- CreateIndex
CREATE INDEX "idx_sched_vehicle_date" ON "ScheduledMaintenance"("VehicleID", "ScheduledDate");

-- CreateIndex
CREATE INDEX "idx_incident_date" ON "IncidentReport"("IncidentDate");

-- CreateIndex
CREATE INDEX "idx_audit_timestamp" ON "AuditLog"("Timestamp");

-- CreateIndex
CREATE INDEX "idx_audit_table_record" ON "AuditLog"("TableName", "RecordID");

-- CreateIndex
CREATE INDEX "idx_seat_trip_status" ON "Seat"("TripID", "Status");

-- CreateIndex
CREATE INDEX "idx_ticket_trip" ON "Ticket"("TripID");

-- CreateIndex
CREATE INDEX "idx_ticket_passenger" ON "Ticket"("PassengerID");

-- CreateIndex
CREATE UNIQUE INDEX "uq_trip_seat" ON "Ticket"("TripID", "SeatNumber");

-- CreateIndex
CREATE INDEX "idx_trip_departure" ON "Trip"("DepartureTime");

-- CreateIndex
CREATE INDEX "idx_trip_vehicle" ON "Trip"("VehicleID");

-- CreateIndex
CREATE INDEX "idx_trip_driver" ON "Trip"("DriverID");

-- AddForeignKey
ALTER TABLE "Trip" ADD CONSTRAINT "Trip_RouteID_fkey" FOREIGN KEY ("RouteID") REFERENCES "Route"("RouteID") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Trip" ADD CONSTRAINT "Trip_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Trip" ADD CONSTRAINT "Trip_DriverID_fkey" FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Seat" ADD CONSTRAINT "Seat_TripID_fkey" FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Ticket" ADD CONSTRAINT "Ticket_TripID_fkey" FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Ticket" ADD CONSTRAINT "Ticket_PassengerID_fkey" FOREIGN KEY ("PassengerID") REFERENCES "Passenger"("PassengerID") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Ticket" ADD CONSTRAINT "Ticket_TripID_SeatNumber_fkey" FOREIGN KEY ("TripID", "SeatNumber") REFERENCES "Seat"("TripID", "SeatNumber") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_TicketID_fkey" FOREIGN KEY ("TicketID") REFERENCES "Ticket"("TicketID") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MaintenanceRecord" ADD CONSTRAINT "MaintenanceRecord_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FuelRecord" ADD CONSTRAINT "FuelRecord_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduledMaintenance" ADD CONSTRAINT "ScheduledMaintenance_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "IncidentReport" ADD CONSTRAINT "IncidentReport_VehicleID_fkey" FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "IncidentReport" ADD CONSTRAINT "IncidentReport_TripID_fkey" FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_UserID_fkey" FOREIGN KEY ("UserID") REFERENCES "UserRole"("UserID") ON DELETE SET NULL ON UPDATE CASCADE;
