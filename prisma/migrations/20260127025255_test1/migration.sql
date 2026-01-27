-- CreateEnum
CREATE TYPE "shift_type" AS ENUM ('morning', 'day', 'evening', 'night');

-- AlterTable
ALTER TABLE "Trip" ADD COLUMN     "Price" DECIMAL(8,2) NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "Vehicle" ALTER COLUMN "LicensePlate" SET DATA TYPE VARCHAR(30);

-- CreateTable
CREATE TABLE "DriverVehicleAssignment" (
    "AssignmentID" SERIAL NOT NULL,
    "DriverID" INTEGER NOT NULL,
    "VehicleID" INTEGER NOT NULL,
    "AssignedAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DriverVehicleAssignment_pkey" PRIMARY KEY ("AssignmentID")
);

-- CreateTable
CREATE TABLE "DriverShiftAssignment" (
    "AssignmentID" SERIAL NOT NULL,
    "DriverID" INTEGER NOT NULL,
    "VehicleID" INTEGER NOT NULL,
    "AssignDate" DATE NOT NULL,
    "Shift" "shift_type" NOT NULL,
    "AssignedAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UnassignedAt" TIMESTAMP(6),

    CONSTRAINT "DriverShiftAssignment_pkey" PRIMARY KEY ("AssignmentID")
);

-- CreateTable
CREATE TABLE "DriverShiftAssignmentHistory" (
    "HistoryID" SERIAL NOT NULL,
    "AssignDate" DATE NOT NULL,
    "Shift" "shift_type" NOT NULL,
    "Action" VARCHAR(20) NOT NULL,
    "DriverID" INTEGER,
    "VehicleID" INTEGER,
    "PrevDriverID" INTEGER,
    "PrevVehicleID" INTEGER,
    "ChangedAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "Note" TEXT,

    CONSTRAINT "DriverShiftAssignmentHistory_pkey" PRIMARY KEY ("HistoryID")
);

-- CreateIndex
CREATE UNIQUE INDEX "DriverVehicleAssignment_DriverID_key" ON "DriverVehicleAssignment"("DriverID");

-- CreateIndex
CREATE UNIQUE INDEX "DriverVehicleAssignment_VehicleID_key" ON "DriverVehicleAssignment"("VehicleID");

-- CreateIndex
CREATE INDEX "idx_assign_driver" ON "DriverVehicleAssignment"("DriverID");

-- CreateIndex
CREATE INDEX "idx_assign_vehicle" ON "DriverVehicleAssignment"("VehicleID");

-- CreateIndex
CREATE INDEX "idx_dsa_date_shift" ON "DriverShiftAssignment"("AssignDate", "Shift");

-- CreateIndex
CREATE INDEX "idx_dsa_hist_date_shift" ON "DriverShiftAssignmentHistory"("AssignDate", "Shift");

-- CreateIndex
CREATE INDEX "idx_dsa_hist_changedat" ON "DriverShiftAssignmentHistory"("ChangedAt");

-- AddForeignKey
ALTER TABLE "DriverVehicleAssignment" ADD CONSTRAINT "fk_assign_driver" FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverVehicleAssignment" ADD CONSTRAINT "fk_assign_vehicle" FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverShiftAssignment" ADD CONSTRAINT "fk_dsa_driver" FOREIGN KEY ("DriverID") REFERENCES "Driver"("DriverID") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverShiftAssignment" ADD CONSTRAINT "fk_dsa_vehicle" FOREIGN KEY ("VehicleID") REFERENCES "Vehicle"("VehicleID") ON DELETE CASCADE ON UPDATE CASCADE;
