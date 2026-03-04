import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { licensePlate, maintenanceType, serviceDate, notes, cost, odometer, interval } = body;

    // Validate required fields
    if (!licensePlate || !maintenanceType || !serviceDate) {
      return NextResponse.json(
        { error: "Missing required fields" },
        { status: 400 }
      );
    }

    // Find vehicle by license plate
    const vehicle = await prisma.vehicle.findUnique({
      where: { licensePlate },
    });

    if (!vehicle) {
      return NextResponse.json(
        { error: "Vehicle not found" },
        { status: 404 }
      );
    }

    // Create maintenance record
    const maintenanceRecord = await prisma.maintenanceRecord.create({
      data: {
        vehicleId: vehicle.vehicleId,
        date: new Date(serviceDate),
        description: `${maintenanceType}${notes ? ` - ${notes}` : ""}`,
        cost: cost ? parseFloat(cost) : null,
        // @ts-expect-error: odometer exists in DB but Prisma types might be stale in IDE cache
        odometer: odometer ? parseInt(odometer) : null,
        interval: interval ? parseInt(interval) : null,
      },
      include: { vehicle: true },
    });

    return NextResponse.json(maintenanceRecord, { status: 201 });
  } catch (error) {
    console.error("Error creating maintenance record:", error);
    return NextResponse.json(
      { error: "Failed to create maintenance record" },
      { status: 500 }
    );
  }
}

export async function GET() {
  try {
    const maintenanceRecords = await prisma.maintenanceRecord.findMany({
      include: {
        vehicle: true,
      },
      orderBy: {
        date: "desc",
      },
    });

    return NextResponse.json(maintenanceRecords);
  } catch (error) {
    console.error("Error fetching maintenance records:", error);
    return NextResponse.json(
      { error: "Failed to fetch maintenance records" },
      { status: 500 }
    );
  }
}
