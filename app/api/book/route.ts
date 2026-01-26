import { prisma } from "@/lib/prisma";

type Body = {
  tripId: number;
  seatNumbers: number[];
  passenger: {
    name: string;
    contactInfo?: string;
  };
};

export async function POST(req: Request) {
  const body = (await req.json()) as Body;

  const tripId = Number(body.tripId);
  const seatNumbers = (body.seatNumbers ?? []).map(Number);

  if (!Number.isFinite(tripId) || seatNumbers.length === 0) {
    return new Response("Invalid request", { status: 400 });
  }

  // optional: dedupe
  const uniqueSeatNumbers = Array.from(new Set(seatNumbers));

  try {
    const result = await prisma.$transaction(async (tx) => {
      // 1) Ensure all seats exist and are available
      const availableSeats = await tx.seat.findMany({
        where: {
          tripId,
          seatNumber: { in: uniqueSeatNumbers },
          status: "available",
        },
        select: { seatNumber: true },
      });

      if (availableSeats.length !== uniqueSeatNumbers.length) {
        // someone already booked at least one seat
        throw new Error("Seat already booked");
      }

      // 2) Mark them sold (guarded update)
      const updated = await tx.seat.updateMany({
        where: {
          tripId,
          seatNumber: { in: uniqueSeatNumbers },
          status: "available",
        },
        data: { status: "sold" },
      });

      if (updated.count !== uniqueSeatNumbers.length) {
        throw new Error("Seat already booked");
      }

      // 3) Create passenger (or you can look up existing passenger by contactInfo)
      const passenger = await tx.passenger.create({
        data: {
          name: body.passenger.name,
          contactInfo: body.passenger.contactInfo ?? null,
        },
      });

      // 4) Create tickets (one per seat)
      const tickets = await Promise.all(
        uniqueSeatNumbers.map((sn) =>
          tx.ticket.create({
            data: {
              tripId,
              passengerId: passenger.passengerId,
              seatNumber: sn,
              price: 0, // replace if you store price
            },
            select: { ticketId: true, seatNumber: true },
          }),
        ),
      );

      return { passengerId: passenger.passengerId, tickets };
    });

    return Response.json({ ok: true, ...result });
  } catch (e: any) {
    const msg = typeof e?.message === "string" ? e.message : "Booking failed";
    const status = msg.includes("Seat already booked") ? 409 : 500;
    return new Response(msg, { status });
  }
}
