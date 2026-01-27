import { prisma } from "@/lib/prisma";

type Body = {
  driverId: number;
  vehicleId: number;
  date: string; // YYYY-MM-DD
  shift: "morning" | "day" | "evening" | "night";
};

export async function POST(req: Request) {
  const body = (await req.json()) as Body;
  const driverId = Number(body.driverId);
  const vehicleId = Number(body.vehicleId);

  if (
    !Number.isFinite(driverId) ||
    !Number.isFinite(vehicleId) ||
    !body.date ||
    !body.shift
  ) {
    return new Response("Invalid request", { status: 400 });
  }

  const assignDate = new Date(body.date);
  assignDate.setHours(0, 0, 0, 0);

  // ✅ Prevent assigning to maintenance vehicles
  const vehicle = await prisma.vehicle.findUnique({
    where: { vehicleId },
    select: { status: true },
  });
  if (!vehicle) return new Response("Vehicle not found", { status: 404 });
  if (vehicle.status === "maintenance") {
    return new Response("Cannot assign driver to a vehicle in maintenance.", {
      status: 409,
    });
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
      // find existing active assignments that conflict (same date+shift)
      const existingForDriver = await tx.driverShiftAssignment.findFirst({
        where: {
          driverId,
          assignDate,
          shift: body.shift as any,
          unassignedAt: null,
        },
      });
      const existingForVehicle = await tx.driverShiftAssignment.findFirst({
        where: {
          vehicleId,
          assignDate,
          shift: body.shift as any,
          unassignedAt: null,
        },
      });

      // close them (history)
      if (existingForDriver) {
        await tx.driverShiftAssignment.update({
          where: { assignmentId: existingForDriver.assignmentId },
          data: { unassignedAt: new Date() },
        });

        await tx.driverShiftAssignmentHistory.create({
          data: {
            assignDate,
            shift: body.shift as any,
            action: "UNASSIGN",
            driverId: existingForDriver.driverId,
            vehicleId: existingForDriver.vehicleId,
            note: "Auto-unassign: driver reassigned",
          },
        });
      }

      if (existingForVehicle) {
        await tx.driverShiftAssignment.update({
          where: { assignmentId: existingForVehicle.assignmentId },
          data: { unassignedAt: new Date() },
        });

        await tx.driverShiftAssignmentHistory.create({
          data: {
            assignDate,
            shift: body.shift as any,
            action: "UNASSIGN",
            driverId: existingForVehicle.driverId,
            vehicleId: existingForVehicle.vehicleId,
            note: "Auto-unassign: vehicle reassigned",
          },
        });
      }

      // create new assignment
      const created = await tx.driverShiftAssignment.create({
        data: { driverId, vehicleId, assignDate, shift: body.shift as any },
      });

      // write history (ASSIGN or REASSIGN)
      await tx.driverShiftAssignmentHistory.create({
        data: {
          assignDate,
          shift: body.shift as any,
          action:
            existingForDriver || existingForVehicle ? "REASSIGN" : "ASSIGN",
          driverId,
          vehicleId,
          prevDriverId: existingForVehicle?.driverId ?? null,
          prevVehicleId: existingForDriver?.vehicleId ?? null,
          note: "Assigned from /driver page",
        },
      });

      return created.assignmentId;
    });

    return Response.json({ ok: true, assignmentId: result });
  } catch (e: any) {
    return new Response(e?.message ?? "Assign failed", { status: 500 });
  }
}
