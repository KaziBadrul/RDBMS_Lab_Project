import { prisma } from "@/lib/prisma";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);

  const dateParam = searchParams.get("date"); // YYYY-MM-DD
  const shift = searchParams.get("shift"); // morning/day/evening/night

  const where: any = {};

  if (dateParam) {
    const d = new Date(dateParam);
    d.setHours(0, 0, 0, 0);
    where.assignDate = d;
  }

  if (shift) {
    where.shift = shift;
  }

  const history = await prisma.driverShiftAssignmentHistory.findMany({
    where,
    orderBy: { changedAt: "desc" },
    take: 200, // safety limit
  });

  return Response.json(
    history.map((h) => ({
      historyId: h.historyId,
      assignDate: h.assignDate.toISOString().slice(0, 10),
      shift: h.shift,
      action: h.action,
      driverId: h.driverId,
      vehicleId: h.vehicleId,
      prevDriverId: h.prevDriverId,
      prevVehicleId: h.prevVehicleId,
      changedAt: h.changedAt.toISOString(),
      note: h.note,
    })),
  );
}
