import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { format } from "date-fns";
import CancelButtonClient from "@/components/ticketing/CancelButtonClient";

export default async function MyTicketsPage() {
    const user = await getCurrentUser();

    if (!user) {
        redirect("/login");
    }

    const tickets = await prisma.ticket.findMany({
        where: {
            passenger: {
                name: user.username
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
        <main className="min-h-screen bg-gradient-to-br from-white to-rose-50/40 py-12 px-6">
            <div className="max-w-6xl mx-auto">

                {/* Header */}
                <div className="mb-12">
                    <Link
                        href="/"
                        className="inline-flex items-center text-sm text-gray-500 hover:text-darkRed transition-colors"
                    >
                        &larr; Back to Dashboard
                    </Link>

                    <h1 className="text-4xl md:text-5xl font-extrabold text-navy mt-4 tracking-tight">
                        My Bookings
                    </h1>

                    <p className="text-gray-500 mt-3 text-lg">
                        Manage your tickets and request refunds easily.
                    </p>
                </div>

                {/* Tickets */}
                <div className="space-y-8">
                    {tickets.length === 0 ? (
                        <div className="bg-white/80 backdrop-blur rounded-2xl border border-gray-200 p-16 text-center shadow-sm">
                            <div className="text-5xl mb-6">🎫</div>
                            <p className="text-gray-600 text-lg">
                                You haven't booked any tickets yet.
                            </p>
                            <Link
                                href="/ticketing"
                                className="mt-6 inline-block bg-darkRed text-white px-6 py-3 rounded-xl font-semibold hover:scale-105 hover:shadow-lg transition-all duration-300"
                            >
                                Book your first trip →
                            </Link>
                        </div>
                    ) : (
                        tickets.map((ticket) => (
                            <div
                                key={ticket.ticketId}
                                className={`group bg-white rounded-2xl shadow-sm hover:shadow-xl transition-all duration-300 border ${
                                    ticket.status === "cancelled"
                                        ? "border-gray-200 opacity-80"
                                        : "border-darkRed/10 hover:border-darkRed/30"
                                } overflow-hidden`}
                            >
                                <div className="p-8 flex flex-col lg:flex-row lg:items-center justify-between gap-8">

                                    {/* Left Section */}
                                    <div>
                                        <div className="flex items-center gap-4 mb-3">

                                            <span
                                                className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide ${
                                                    ticket.status === "cancelled"
                                                        ? "bg-gray-100 text-gray-500"
                                                        : "bg-emerald-100 text-emerald-700"
                                                }`}
                                            >
                                                {ticket.status}
                                            </span>

                                            <span className="text-sm text-gray-400">
                                                Booking ID #{ticket.ticketId}
                                            </span>
                                        </div>

                                        <h3 className="text-2xl font-bold text-navy group-hover:text-darkRed transition-colors">
                                            {ticket.trip.route.startLocation} →{" "}
                                            {ticket.trip.route.endLocation}
                                        </h3>

                                        <p className="text-gray-500 mt-2">
                                            Departure:{" "}
                                            {format(
                                                new Date(ticket.trip.departureTime),
                                                "PPP p"
                                            )}
                                        </p>

                                        <p className="mt-2 text-sm font-medium text-gray-700 bg-gray-100 inline-block px-3 py-1 rounded-lg">
                                            Seat {ticket.seatNumber}
                                        </p>
                                    </div>

                                    {/* Right Section */}
                                    <div className="flex flex-col items-start lg:items-end gap-4">

                                        <div className="text-3xl font-extrabold text-navy">
                                            ৳{Number(ticket.price)}
                                        </div>

                                        {ticket.status === "booked" ? (
                                            <CancelTicketButton
                                                ticketId={ticket.ticketId}
                                                departureTime={ticket.trip.departureTime}
                                                price={Number(ticket.price)}
                                            />
                                        ) : (
                                            <div className="text-sm text-right">
                                                {ticket.refund && (
                                                    <p className="text-darkRed font-semibold">
                                                        Refunded: ৳
                                                        {Number(ticket.refund.amount)}
                                                    </p>
                                                )}
                                                <p className="text-gray-400 italic mt-1">
                                                    Cancelled on{" "}
                                                    {ticket.refund
                                                        ? format(
                                                              new Date(
                                                                  ticket.refund.refundDate
                                                              ),
                                                              "PP"
                                                          )
                                                        : "N/A"}
                                                </p>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        ))
                    )}
                </div>

                {/* Refund Policy */}
                <div className="mt-16 bg-white rounded-2xl shadow-sm border border-darkRed/10 p-8">
                    <h4 className="text-xl font-bold text-navy mb-6">
                        Refund Policy
                    </h4>

                    <div className="grid md:grid-cols-3 gap-6 text-sm">
                        <div className="p-5 rounded-xl bg-emerald-50 border border-emerald-100">
                            <p className="font-bold text-emerald-700 mb-2">
                                100% Refund
                            </p>
                            <p className="text-gray-600">
                                Cancellations made more than 24 hours before departure.
                            </p>
                        </div>

                        <div className="p-5 rounded-xl bg-yellow-50 border border-yellow-100">
                            <p className="font-bold text-yellow-700 mb-2">
                                75% Refund
                            </p>
                            <p className="text-gray-600">
                                Cancellations made between 12–24 hours before departure.
                            </p>
                        </div>

                        <div className="p-5 rounded-xl bg-rose-50 border border-rose-100">
                            <p className="font-bold text-rose-700 mb-2">
                                50% Refund
                            </p>
                            <p className="text-gray-600">
                                Cancellations made less than 12 hours before departure.
                            </p>
                        </div>
                    </div>
                </div>

            </div>
        </main>
    );
}

// Do NOT change functionality
function CancelTicketButton({
    ticketId,
    departureTime,
    price
}: {
    ticketId: number;
    departureTime: Date;
    price: number;
}) {
    return (
        <CancelButtonClient
            ticketId={ticketId}
            departureTime={departureTime.toISOString()}
            price={price}
        />
    );
}