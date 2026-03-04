import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";

export async function POST(
    req: Request,
    { params }: { params: Promise<{ id: string }> }
) {
    const { id: ticketIdStr } = await params;
    const ticketId = parseInt(ticketIdStr);

    if (isNaN(ticketId)) {
        return Response.json({ error: "Invalid ticket ID" }, { status: 400 });
    }

    const user = await getCurrentUser();
    if (!user) {
        return Response.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { reason } = await req.json();

    try {
        // Call the stored procedure
        // We use $executeRaw because procedures don't return values directly in Prisma easily
        // but they can be called with CALL
        await prisma.$executeRawUnsafe(
            `CALL cancel_ticket($1, $2, $3)`,
            ticketId,
            user.userId,
            reason || "Cancelled by user"
        );

        // Fetch the refund details to return to the UI
        const refund = await prisma.refundTransaction.findUnique({
            where: { ticketId },
        });

        return Response.json({
            ok: true,
            message: "Ticket cancelled successfully",
            refundAmount: refund?.amount,
        });
    } catch (error: any) {
        console.error("Cancellation error:", error);
        return Response.json(
            { error: error.message || "Failed to cancel ticket" },
            { status: 500 }
        );
    }
}
