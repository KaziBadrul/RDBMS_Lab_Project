import { prisma } from "@/lib/prisma";

export async function GET(
  _req: Request,
  { params }: { params: { tripId: string } },
) {
  const tripId = Number(params.tripId);
  if (!Number.isFinite(tripId))
    return new Response("Invalid tripId", { status: 400 });

  const seats = await prisma.seat.findMany({
    where: { tripId },
    orderBy: { seatNumber: "asc" },
    select: { seatNumber: true, status: true },
  });

  // UI expects seatNo + status
  const payload = seats.map((s) => ({
    seatNo: s.seatNumber,
    status: s.status,
  }));
  return Response.json(payload);
}
