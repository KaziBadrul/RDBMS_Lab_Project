import { prisma } from "@/lib/prisma";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const date = searchParams.get("date");
  const shift = searchParams.get("shift") ?? "morning";

  const assignDate = date ? new Date(date) : new Date();
  assignDate.setHours(0, 0, 0, 0);

  const vehicles = await prisma.vehicle.findMany({
    orderBy: { vehicleId: "asc" },
  });

  const assignments = await prisma.driverShiftAssignment.findMany({
    where: { assignDate, shift: shift as any, unassignedAt: null },
    include: { driver: true },
  });

  const byVehicle = new Map<number, { driverId: number; name: string }>();
  for (const a of assignments) {
    byVehicle.set(a.vehicleId, { driverId: a.driverId, name: a.driver.name });
  }

  return Response.json(
    vehicles.map((v) => ({
      vehicleId: v.vehicleId,
      licensePlate: v.licensePlate,
      capacity: v.capacity,
      status: v.status, // active/inactive/maintenance
      assignedDriver: byVehicle.get(v.vehicleId) ?? null,
    })),
  );
}
