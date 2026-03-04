import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { redirect } from "next/navigation";
import PriceLogTable from "@/components/PriceLogTable";
import Link from "next/link";

export default async function AdminPricingPage() {
    const user = await getCurrentUser();

    if (!user || user.role !== "admin") {
        redirect("/");
    }

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
        <main className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100/40 py-14 px-6">
            <div className="max-w-6xl mx-auto">

                {/* Header Section */}
                <div className="mb-14">

                    {/* Top Navigation */}
                    <Link
                        href="/"
                        className="inline-flex items-center text-sm text-gray-500 hover:text-darkRed transition-colors"
                    >
                        &larr; Back to Dashboard
                    </Link>

                    {/* Title + Rule Layout */}
                    <div className="mt-6 flex flex-col xl:flex-row xl:items-end xl:justify-between gap-10">

                        {/* Left Content */}
                        <div className="max-w-2xl">
                            <h1 className="text-4xl md:text-5xl font-extrabold text-navy tracking-tight leading-tight">
                                Dynamic Pricing Logs
                            </h1>

                            <p className="text-gray-500 mt-4 text-lg leading-relaxed">
                                Monitor automated fare adjustments triggered by occupancy-based surge rules.
                            </p>
                        </div>

                        {/* Surge Rule Card */}
                        <div className="bg-white border border-gray-200 shadow-sm rounded-2xl px-6 py-5 min-w-[280px]">
                            <p className="text-xs font-semibold tracking-widest text-gray-400 uppercase mb-3">
                                Active Surge Rule
                            </p>

                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-lg font-bold text-navy">
                                        Occupancy ≥ 80%
                                    </p>
                                    <p className="text-sm text-gray-500 mt-1">
                                        Applies a 25% fare increase
                                    </p>
                                </div>

                                <div className="bg-darkRed/10 text-darkRed text-sm font-semibold px-3 py-1 rounded-full">
                                    +25%
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Logs Section */}
                <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">

                    {/* Section Header */}
                    <div className="px-8 py-6 border-b border-gray-100 flex items-center justify-between">
                        <div>
                            <h2 className="text-xl font-semibold text-navy">
                                Price Adjustment History
                            </h2>
                            <p className="text-sm text-gray-500 mt-1">
                                Complete log of all automated price updates.
                            </p>
                        </div>

                        <div className="text-sm text-gray-400 font-medium">
                            {logs.length} total changes
                        </div>
                    </div>

                    {/* Table Wrapper */}
                    <div className="px-8 py-6 overflow-x-auto">
                        <PriceLogTable logs={logs} />
                    </div>
                </div>

            </div>
        </main>
    );
}