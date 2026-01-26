-- CreateTable
CREATE TABLE "Trip" (
    "id" SERIAL NOT NULL,
    "code" TEXT NOT NULL,
    "price" INTEGER NOT NULL,
    "capacity" INTEGER NOT NULL,

    CONSTRAINT "Trip_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Seat" (
    "id" SERIAL NOT NULL,
    "tripId" INTEGER NOT NULL,
    "number" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'available',

    CONSTRAINT "Seat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Ticket" (
    "id" SERIAL NOT NULL,
    "tripId" INTEGER NOT NULL,
    "passenger" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Ticket_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Trip_code_key" ON "Trip"("code");

-- CreateIndex
CREATE UNIQUE INDEX "Seat_tripId_number_key" ON "Seat"("tripId", "number");

-- AddForeignKey
ALTER TABLE "Seat" ADD CONSTRAINT "Seat_tripId_fkey" FOREIGN KEY ("tripId") REFERENCES "Trip"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Ticket" ADD CONSTRAINT "Ticket_tripId_fkey" FOREIGN KEY ("tripId") REFERENCES "Trip"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
