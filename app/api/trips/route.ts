import { prisma } from "@/lib/prisma";

export async function GET() {
  const trips = await prisma.trip.findMany({
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
    route: { start: t.route.startLocation, end: t.route.endLocation },
    vehicle: { capacity: t.vehicle.capacity },
  }));

  return Response.json(payload);
}
