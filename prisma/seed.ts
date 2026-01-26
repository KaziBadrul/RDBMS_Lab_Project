import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }),
});

async function seed() {
  console.log("🌱 Seeding Dhaka bus demo data...");

  // Clean (order matters because of FK constraints)
  await prisma.payment.deleteMany();
  await prisma.ticket.deleteMany();
  await prisma.seat.deleteMany();
  await prisma.trip.deleteMany();
  await prisma.driver.deleteMany();
  await prisma.vehicle.deleteMany();
  await prisma.route.deleteMany();
  await prisma.passenger.deleteMany();
  await prisma.auditLog.deleteMany();
  await prisma.maintenanceRecord.deleteMany();
  await prisma.fuelRecord.deleteMany();
  await prisma.scheduledMaintenance.deleteMany();
  await prisma.incidentReport.deleteMany();
  // Keep UserRole if you want; or clear it:
  // await prisma.userRole.deleteMany();

  // ---- Routes (Dhaka-ish)
  const routes = await prisma.route.createManyAndReturn({
    data: [
      { startLocation: "Mirpur 10", endLocation: "Motijheel", distance: 18.5 },
      {
        startLocation: "Uttara Sector 10",
        endLocation: "Farmgate",
        distance: 16.2,
      },
      { startLocation: "Jatrabari", endLocation: "Mohakhali", distance: 15.0 },
      { startLocation: "Gabtoli", endLocation: "Sadarghat", distance: 20.3 },
      { startLocation: "Gulistan", endLocation: "Dhanmondi 27", distance: 8.1 },
      { startLocation: "Kamalapur", endLocation: "Banani", distance: 11.4 },
    ],
  });

  // ---- Vehicles (bus related)
  const vehicles = await prisma.vehicle.createManyAndReturn({
    data: [
      {
        licensePlate: "DHAKA-METRO-BA-11-2345",
        capacity: 40,
        status: "active",
      },
      {
        licensePlate: "DHAKA-METRO-BA-12-6789",
        capacity: 36,
        status: "active",
      },
      {
        licensePlate: "DHAKA-METRO-BA-13-1122",
        capacity: 45,
        status: "active",
      },
      {
        licensePlate: "DHAKA-METRO-BA-14-3344",
        capacity: 30,
        status: "active",
      },
      {
        licensePlate: "DHAKA-METRO-BA-15-5566",
        capacity: 50,
        status: "active",
      },
    ],
  });

  // ---- Drivers
  const drivers = await prisma.driver.createManyAndReturn({
    data: [
      {
        name: "Abdul Karim",
        licenseNumber: "DL-DHK-1001",
        contactInfo: "01711-111111",
      },
      {
        name: "Shafiqul Islam",
        licenseNumber: "DL-DHK-1002",
        contactInfo: "01722-222222",
      },
      {
        name: "Monir Hossain",
        licenseNumber: "DL-DHK-1003",
        contactInfo: "01811-333333",
      },
      {
        name: "Rafiqul Hasan",
        licenseNumber: "DL-DHK-1004",
        contactInfo: "01911-444444",
      },
    ],
  });

  // Helper: create a trip and auto-generate seats 1..capacity
  async function createTripWithSeats(opts: {
    routeId: number;
    vehicleId: number;
    driverId: number;
    departureTime: Date;
    arrivalTime?: Date;
    price: number;
  }) {
    return prisma.$transaction(async (tx) => {
      const trip = await tx.trip.create({
        data: {
          routeId: opts.routeId,
          vehicleId: opts.vehicleId,
          driverId: opts.driverId,
          departureTime: opts.departureTime,
          arrivalTime: opts.arrivalTime ?? null,
          price: opts.price,
        },
        select: { tripId: true, vehicleId: true },
      });

      const vehicle = await tx.vehicle.findUnique({
        where: { vehicleId: trip.vehicleId },
        select: { capacity: true },
      });

      const cap = vehicle?.capacity ?? 0;
      const seats = Array.from({ length: cap }, (_, i) => ({
        tripId: trip.tripId,
        seatNumber: i + 1,
        status: "available" as const,
      }));

      if (seats.length) await tx.seat.createMany({ data: seats });

      return trip.tripId;
    });
  }

  // ---- Trips (today-ish schedule; adjust as you want)
  const now = new Date();
  const today9 = new Date(now);
  today9.setHours(9, 0, 0, 0);
  const today12 = new Date(now);
  today12.setHours(12, 0, 0, 0);
  const today15 = new Date(now);
  today15.setHours(15, 30, 0, 0);
  const today18 = new Date(now);
  today18.setHours(18, 0, 0, 0);

  // Map IDs easily
  const r = (i: number) => routes[i].routeId;
  const v = (i: number) => vehicles[i].vehicleId;
  const d = (i: number) => drivers[i].driverId;

  const tripIds: number[] = [];
  tripIds.push(
    await createTripWithSeats({
      routeId: r(0),
      vehicleId: v(0),
      driverId: d(0),
      departureTime: today9,
      price: 60,
    }),
  );
  tripIds.push(
    await createTripWithSeats({
      routeId: r(1),
      vehicleId: v(1),
      driverId: d(1),
      departureTime: today12,
      price: 50,
    }),
  );
  tripIds.push(
    await createTripWithSeats({
      routeId: r(2),
      vehicleId: v(2),
      driverId: d(2),
      departureTime: today15,
      price: 55,
    }),
  );
  tripIds.push(
    await createTripWithSeats({
      routeId: r(3),
      vehicleId: v(3),
      driverId: d(3),
      departureTime: today18,
      price: 70,
    }),
  );
  tripIds.push(
    await createTripWithSeats({
      routeId: r(4),
      vehicleId: v(4),
      driverId: d(0),
      departureTime: new Date(today9.getTime() + 60 * 60 * 1000),
      price: 35,
    }),
  );

  console.log("✅ Seed complete.");
  console.log("Trips created:", tripIds);
}

seed()
  .catch((e) => {
    console.error("❌ Seed failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
