import { prisma } from "./lib/prisma";

async function checkTicket() {
    try {
        const ticket = await prisma.ticket.findFirst({
            include: {
                trip: {
                    include: {
                        route: true
                    }
                },
                //@ts-ignore
                refund: true
            }
        });
        console.log("Success! Ticket found:", ticket?.ticketId);
        console.log("Refund field value:", ticket && 'refund' in ticket ? (ticket as any).refund : "Field missing on object");
    } catch (e: any) {
        console.log("Prisma Error Message:\n", e.message);
    } finally {
        await prisma.$disconnect();
    }
}

checkTicket().catch(console.error);
