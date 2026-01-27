import { prisma } from "@/lib/prisma";

type Body = {
  driverId: number;
  date: string; // YYYY-MM-DD
  shift: "morning" | "day" | "evening" | "night";
};

export async function POST(req: Request) {
  const body = (await req.json()) as Body;
  const driverId = Number(body.driverId);
  if (!Number.isFinite(driverId) || !body.date || !body.shift) {
    return new Response("Invalid request", { status: 400 });
  }

  const assignDate = new Date(body.date);
  assignDate.setHours(0, 0, 0, 0);

  const existing = await prisma.driverShiftAssignment.findFirst({
    where: {
      driverId,
      assignDate,
      shift: body.shift as any,
      unassignedAt: null,
    },
  });

  if (!existing) return Response.json({ ok: true }); // nothing to do

  await prisma.$transaction(async (tx) => {
    await tx.driverShiftAssignment.update({
      where: { assignmentId: existing.assignmentId },
      data: { unassignedAt: new Date() },
    });

    await tx.driverShiftAssignmentHistory.create({
      data: {
        assignDate,
        shift: body.shift as any,
        action: "UNASSIGN",
        driverId: existing.driverId,
        vehicleId: existing.vehicleId,
        note: "Unassigned from /driver page",
      },
    });
  });

  return Response.json({ ok: true });
}
