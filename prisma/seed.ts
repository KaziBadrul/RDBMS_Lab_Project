import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }),
});

// Safe modulo for negative numbers
function mod(n: number, m: number) {
  return ((n % m) + m) % m;
}

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

  // ---- Vehicles
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

  // Sanity checks (fail early with helpful output)
  if (!routes.length) throw new Error("No routes created.");
  if (!vehicles.length) throw new Error("No vehicles created.");
  if (!drivers.length) throw new Error("No drivers created.");

  // Helper: create a trip and auto-generate seats 1..capacity
  async function createTripWithSeats(opts: {
    routeId: number;
    vehicleId: number;
    driverId: number;
    departureTime: Date;
    arrivalTime?: Date | null;
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
      if (cap <= 0) return trip.tripId;

      const seats = Array.from({ length: cap }, (_, i) => ({
        tripId: trip.tripId,
        seatNumber: i + 1,
        status: "available" as const,
      }));

      await tx.seat.createMany({ data: seats });
      return trip.tripId;
    });
  }

  // ---- Trips (multi-day schedule)
  const DAYS_AHEAD = 14;
  const DAYS_BACK = 3;

  const tripIds: number[] = [];

  // Date helpers
  function startOfDay(dt: Date) {
    const x = new Date(dt);
    x.setHours(0, 0, 0, 0);
    return x;
  }
  function addDays(dt: Date, days: number) {
    const x = new Date(dt);
    x.setDate(x.getDate() + days);
    return x;
  }
  function atTime(day: Date, hh: number, mm: number) {
    const x = new Date(day);
    x.setHours(hh, mm, 0, 0);
    return x;
  }

  // Price heuristic
  function calcPrice(distance: number) {
    const raw = 20 + distance * 2.2;
    return Math.round(raw / 5) * 5;
  }

  const departures = [
    { hh: 7, mm: 30 },
    { hh: 9, mm: 0 },
    { hh: 11, mm: 0 },
    { hh: 13, mm: 30 },
    { hh: 16, mm: 0 },
    { hh: 18, mm: 30 },
    { hh: 20, mm: 30 },
  ];

  const baseDay = startOfDay(new Date());

  for (let dayOffset = -DAYS_BACK; dayOffset <= DAYS_AHEAD; dayOffset++) {
    const day = addDays(baseDay, dayOffset);

    for (let slot = 0; slot < departures.length; slot++) {
      const dep = departures[slot];
      const departureTime = atTime(day, dep.hh, dep.mm);

      // deterministic rotation
      const routeIndex = mod(dayOffset * 3 + slot, routes.length);
      const vehicleIndex = mod(dayOffset * 2 + slot, vehicles.length);
      const driverIndex = mod(dayOffset + slot, drivers.length);

      const route = routes[routeIndex];
      const vehicle = vehicles[vehicleIndex];
      const driver = drivers[driverIndex];

      // extra safety in case DB/Prisma returns unexpected shapes
      if (!route?.routeId)
        throw new Error(`Route missing routeId at index ${routeIndex}`);
      if (!vehicle?.vehicleId)
        throw new Error(`Vehicle missing vehicleId at index ${vehicleIndex}`);
      if (!driver?.driverId)
        throw new Error(`Driver missing driverId at index ${driverIndex}`);

      const avgSpeed = 18; // km/h
      const mins = Math.max(
        20,
        Math.round((Number(route.distance) / avgSpeed) * 60),
      );
      const arrivalTime = new Date(departureTime.getTime() + mins * 60 * 1000);

      const price = calcPrice(Number(route.distance));

      tripIds.push(
        await createTripWithSeats({
          routeId: route.routeId,
          vehicleId: vehicle.vehicleId,
          driverId: driver.driverId,
          departureTime,
          arrivalTime,
          price,
        }),
      );
    }
  }

  console.log("✅ Seed complete.");
  console.log("Trips created:", tripIds.length);
  console.log("Example trip IDs:", tripIds.slice(0, 10));
}

seed()
  .catch((e) => {
    console.error("❌ Seed failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
