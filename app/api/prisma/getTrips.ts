import { prisma } from "@/lib/prisma";

export async function GET() {
  const trips = await prisma.trip.findMany();
  return Response.json(trips);
}
