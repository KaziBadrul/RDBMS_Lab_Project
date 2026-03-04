-- AlterTable
ALTER TABLE "Trip" ADD COLUMN     "BasePrice" DECIMAL(8,2) NOT NULL DEFAULT 0,
ADD COLUMN     "LastPriceUpdateAt" TIMESTAMP(3),
ADD COLUMN     "PricingVersion" INTEGER NOT NULL DEFAULT 1;

-- AlterTable
ALTER TABLE "UserRole" ADD COLUMN     "PasswordHash" VARCHAR(255) NOT NULL DEFAULT 'password123';

-- CreateTable
CREATE TABLE "PriceChangeLog" (
    "LogID" SERIAL NOT NULL,
    "TripID" INTEGER NOT NULL,
    "OldPrice" DECIMAL(8,2) NOT NULL,
    "NewPrice" DECIMAL(8,2) NOT NULL,
    "Reason" VARCHAR(255) NOT NULL,
    "ChangedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PriceChangeLog_pkey" PRIMARY KEY ("LogID")
);

-- CreateIndex
CREATE INDEX "idx_price_log_trip" ON "PriceChangeLog"("TripID");

-- AddForeignKey
ALTER TABLE "PriceChangeLog" ADD CONSTRAINT "PriceChangeLog_TripID_fkey" FOREIGN KEY ("TripID") REFERENCES "Trip"("TripID") ON DELETE CASCADE ON UPDATE CASCADE;
