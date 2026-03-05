import { prisma } from "@/lib/prisma";

function startOfDay(d: Date) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

function addDays(d: Date, days: number) {
  const x = new Date(d);
  x.setDate(x.getDate() + days);
  return x;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const dateParam = searchParams.get("date"); // expected: YYYY-MM-DD

  // Default: today (server local time)
  const base = dateParam ? new Date(dateParam) : new Date();

  // Validate date (avoid Invalid Date)
  if (Number.isNaN(base.getTime())) {
    return new Response("Invalid date. Use YYYY-MM-DD", { status: 400 });
  }

  const start = startOfDay(base);
  const end = addDays(start, 1);

  const trips = await prisma.trip.findMany({
    where: {
      departureTime: {
        gte: start,
        lt: end,
      },
    },
    orderBy: { departureTime: "asc" },
    include: {
      route: true,
      vehicle: true,
      driver: true,
      tickets: true,
    },
  });

  const payload = trips.map((t: any) => {
    const ticketsSold = t.tickets.length;
    const revenue = t.tickets.reduce((sum: number, ticket: any) => sum + Number(ticket.price), 0);

    return {
      id: t.tripId,
      departureTime: t.departureTime.toISOString(),
      price: Number(t.price),
      driver: t.driver.name,
      route: { start: t.route.startLocation, end: t.route.endLocation },
      vehicle: {
        capacity: t.vehicle.capacity,
        licensePlate: t.vehicle.licensePlate
      },
      ticketsSold,
      revenue
    };
  });

  return Response.json(payload);
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { routeId, vehicleId, driverId, departureTime, price } = body;

    if (!routeId || !vehicleId || !driverId || !departureTime || !price) {
      return new Response("Missing required fields", { status: 400 });
    }

    const trip = await prisma.$transaction(async (tx: any) => {
      const newTrip = await tx.trip.create({
        data: {
          routeId: Number(routeId),
          vehicleId: Number(vehicleId),
          driverId: Number(driverId),
          departureTime: new Date(departureTime),
          price: Number(price),
          basePrice: Number(price),
        },
      });

      // Create seats for the trip based on vehicle capacity
      const vehicle = await tx.vehicle.findUnique({
        where: { vehicleId: Number(vehicleId) }
      });

      if (vehicle) {
        const seats = Array.from({ length: vehicle.capacity }, (_, i) => ({
          tripId: newTrip.tripId,
          seatNumber: i + 1,
          status: "available" as const,
        }));

        await tx.seat.createMany({
          data: seats
        });
      }

      return newTrip;
    });

    return Response.json(trip, { status: 201 });
  } catch (error: any) {
    console.error("Error creating trip:", error);
    return new Response(error.message || "Failed to create trip", { status: 500 });
  }
}
