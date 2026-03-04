import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { redirect } from "next/navigation";
import PriceLogTable from "@/components/PriceLogTable";
import Link from "next/link";

export default async function AdminPricingPage() {
    const user = await getCurrentUser();

    // Role-based protection: only allow 'admin'
    if (!user || user.role !== "admin") {
        redirect("/");
    }

    // Fetch logs with trip and route details
    const logs = await prisma.priceChangeLog.findMany({
        orderBy: { changedAt: "desc" },
        include: {
            trip: {
                include: {
                    route: true,
                    vehicle: true,
                },
            },
        },
    });

    return (
        <main className="p-8 max-w-7xl mx-auto">
            <div className="flex items-center justify-between mb-8">
                <div>
                    <Link href="/" className="text-darkRed hover:underline text-sm mb-2 block">
                        &larr; Back to Dashboard
                    </Link>
                    <h1 className="text-4xl font-bold text-navy">Dynamic Pricing Logs</h1>
                    <p className="text-gray-600 mt-2">Monitor all automated fare adjustments triggered by occupancy surge rules.</p>
                </div>
                <div className="bg-cream border border-darkRed/20 p-4 rounded-lg">
                    <p className="text-xs text-gray-500 uppercase font-semibold">Current Rule</p>
                    <p className="text-sm font-bold text-darkRed">Occupancy ≥ 80% → +25% Surge</p>
                </div>
            </div>

            <PriceLogTable logs={logs} />
        </main>
    );
}
