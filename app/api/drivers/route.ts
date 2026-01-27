import { prisma } from "@/lib/prisma";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const date = searchParams.get("date"); // YYYY-MM-DD
  const shift = searchParams.get("shift") ?? "morning";

  const assignDate = date ? new Date(date) : new Date();
  assignDate.setHours(0, 0, 0, 0);

  const drivers = await prisma.driver.findMany({
    orderBy: { driverId: "asc" },
  });

  const assignments = await prisma.driverShiftAssignment.findMany({
    where: { assignDate, shift: shift as any, unassignedAt: null },
    include: { vehicle: true },
  });

  const byDriver = new Map<
    number,
    { vehicleId: number; licensePlate: string }
  >();
  for (const a of assignments) {
    byDriver.set(a.driverId, {
      vehicleId: a.vehicleId,
      licensePlate: a.vehicle.licensePlate,
    });
  }

  return Response.json(
    drivers.map((d) => ({
      driverId: d.driverId,
      name: d.name,
      licenseNumber: d.licenseNumber,
      contactInfo: d.contactInfo,
      assignedVehicle: byDriver.get(d.driverId) ?? null,
    })),
  );
}
