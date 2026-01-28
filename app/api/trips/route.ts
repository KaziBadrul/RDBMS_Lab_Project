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
    },
  });

  const payload = trips.map((t) => ({
    id: t.tripId,
    departureTime: t.departureTime.toISOString(),
    price: Number(t.price),
    driver: t.driver.name,
    route: { start: t.route.startLocation, end: t.route.endLocation },
    vehicle: { capacity: t.vehicle.capacity },
  }));

  //   console.log("Trip: " + payload[0].driver.name);

  return Response.json(payload);
}
