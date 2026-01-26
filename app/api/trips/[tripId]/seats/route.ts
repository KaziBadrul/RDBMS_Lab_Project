import { prisma } from "@/lib/prisma";

export async function GET(
  _req: Request,
  context: { params: Promise<{ tripId: string }> },
) {
  const { tripId } = await context.params; // ✅ await params
  const id = Number(tripId);

  if (!Number.isFinite(id)) {
    return new Response("Invalid tripId", { status: 400 });
  }

  const seats = await prisma.seat.findMany({
    where: { tripId: id },
    orderBy: { seatNumber: "asc" },
    select: {
      seatNumber: true,
      status: true,
    },
  });

  return Response.json(
    seats.map((s) => ({
      seatNo: s.seatNumber,
      status: s.status,
    })),
  );
}
