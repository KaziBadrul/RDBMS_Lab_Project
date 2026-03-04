import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { format } from "date-fns";

export default async function MyTicketsPage() {
    const user = await getCurrentUser();

    if (!user) {
        redirect("/login");
    }

    // Fetch tickets for the current user
    // In a real app, Ticket would be linked to UserRole via PassengerID or UserID.
    // For this lab, we'll assume the logged in username matches the passenger name or we just show all for demo if not linked.
    // Let's try to find tickets where passenger name matches username or some logic.
    // Actually, let's just fetch all tickets for now to demonstrate the cancellation UI, 
    // or filter if we had a proper User -> Passenger link.

    const tickets = await prisma.ticket.findMany({
        where: {
            passenger: {
                name: user.username // Simple link for the lab demo
            }
        },
        include: {
            trip: {
                include: {
                    route: true
                }
            },
            refund: true
        },
        orderBy: {
            purchaseDate: "desc"
        }
    });

    return (
        <main className="p-8 max-w-5xl mx-auto">
            <div className="mb-8">
                <Link href="/" className="text-darkRed hover:underline text-sm mb-2 block">
                    &larr; Back to Dashboard
                </Link>
                <h1 className="text-4xl font-bold text-navy">My Bookings</h1>
                <p className="text-gray-600 mt-2">Manage your tickets and request refunds.</p>
            </div>

            <div className="space-y-6">
                {tickets.length === 0 ? (
                    <div className="bg-white p-12 rounded-xl border border-gray-200 text-center">
                        <p className="text-gray-500">You haven't booked any tickets yet.</p>
                        <Link href="/ticketing" className="text-darkRed font-bold mt-4 inline-block hover:underline">
                            Book your first trip &rarr;
                        </Link>
                    </div>
                ) : (
                    tickets.map((ticket) => (
                        <div key={ticket.ticketId} className={`bg-white rounded-xl shadow-sm border ${ticket.status === 'cancelled' ? 'border-gray-200 opacity-75' : 'border-darkRed/10'} overflow-hidden`}>
                            <div className="p-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
                                <div>
                                    <div className="flex items-center gap-3 mb-2">
                                        <span className={`px-2 py-0.5 rounded text-xs font-bold uppercase ${ticket.status === 'cancelled' ? 'bg-gray-100 text-gray-500' : 'bg-green-100 text-green-700'
                                            }`}>
                                            {ticket.status}
                                        </span>
                                        <span className="text-sm text-gray-400">ID: #{ticket.ticketId}</span>
                                    </div>
                                    <h3 className="text-xl font-bold text-navy">
                                        {ticket.trip.route.startLocation} &rarr; {ticket.trip.route.endLocation}
                                    </h3>
                                    <p className="text-sm text-gray-600 mt-1">
                                        Departure: {format(new Date(ticket.trip.departureTime), "PPP p")}
                                    </p>
                                    <p className="text-sm font-medium mt-1">Seat {ticket.seatNumber}</p>
                                </div>

                                <div className="flex flex-col items-end gap-2 text-right">
                                    <div className="text-2xl font-bold text-navy">৳{Number(ticket.price)}</div>
                                    {ticket.status === 'booked' ? (
                                        <CancelTicketButton ticketId={ticket.ticketId} departureTime={ticket.trip.departureTime} price={Number(ticket.price)} />
                                    ) : (
                                        <div className="text-sm">
                                            {ticket.refund && (
                                                <p className="text-darkRed font-medium">Refunded: ৳{Number(ticket.refund.amount)}</p>
                                            )}
                                            <p className="text-gray-500 italic text-xs mt-1">Cancelled on {ticket.refund ? format(new Date(ticket.refund.refundDate), "PP") : 'N/A'}</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))
                )}
            </div>

            <div className="mt-12 bg-cream p-6 rounded-xl border border-darkRed/20">
                <h4 className="font-bold text-navy mb-3">Refund Policy</h4>
                <ul className="text-sm space-y-2 text-gray-700">
                    <li className="flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-darkRed" />
                        <span><strong>100% Refund:</strong> Cancellations made more than 24 hours before departure.</span>
                    </li>
                    <li className="flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-darkRed" />
                        <span><strong>75% Refund:</strong> Cancellations made between 12 and 24 hours before departure.</span>
                    </li>
                    <li className="flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-darkRed" />
                        <span><strong>50% Refund:</strong> Cancellations made less than 12 hours before departure.</span>
                    </li>
                </ul>
            </div>
        </main>
    );
}

// Client component for the button
function CancelTicketButton({ ticketId, departureTime, price }: { ticketId: number, departureTime: Date, price: number }) {
    return (
        <CancelButtonClient ticketId={ticketId} departureTime={departureTime.toISOString()} price={price} />
    );
}

// Separate client component file would be better, but for brevity we'll use a dynamic component or just a separate file next.
// I'll create the client component in a separate file to follow Next.js patterns.
import CancelButtonClient from "@/components/ticketing/CancelButtonClient";
