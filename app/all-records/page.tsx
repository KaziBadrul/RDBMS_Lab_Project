"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { format } from "date-fns";

interface MaintenanceRecord {
    recordId: number;
    vehicleId: number;
    date: string;
    description: string;
    cost: number | null;
    odometer: number | null;
    interval: number | null;
    vehicle: {
        licensePlate: string;
    };
}

export default function AllRecordsPage() {
    const [records, setRecords] = useState<MaintenanceRecord[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");

    useEffect(() => {
        const fetchRecords = async () => {
            try {
                const response = await fetch("/api/maintenance");
                if (response.ok) {
                    const data = await response.json();
                    setRecords(data);
                }
            } catch (error) {
                console.error("Error fetching records:", error);
            } finally {
                setLoading(false);
            }
        };

        fetchRecords();
    }, []);

    const filteredRecords = records.filter(r =>
        r.vehicle.licensePlate.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.description.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <main className="min-h-screen bg-slate-50 p-8">
            <div className="max-w-6xl mx-auto">
                <header className="mb-8 flex justify-between items-center">
                    <div>
                        <h1 className="text-3xl font-bold text-slate-900">All Maintenance Records</h1>
                        <p className="text-slate-500 mt-1">A complete history of all vehicle services.</p>
                    </div>
                    <Link
                        href="/vehicle-maintenance"
                        className="bg-white border border-slate-200 px-4 py-2 rounded-xl text-sm font-medium hover:bg-slate-50 transition shadow-sm"
                    >
                        ← Back to Dashboard
                    </Link>
                </header>

                <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                    <div className="p-6 border-b border-slate-100 bg-slate-50/50">
                        <input
                            type="text"
                            placeholder="Search by license plate or description..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full max-w-md rounded-xl border border-slate-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 transition"
                        />
                    </div>

                    <div className="overflow-x-auto">
                        <table className="w-full text-sm text-left">
                            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
                                <tr>
                                    <th className="px-6 py-4">Date</th>
                                    <th className="px-6 py-4">Vehicle</th>
                                    <th className="px-6 py-4">Description</th>
                                    <th className="px-6 py-4">Odometer (km)</th>
                                    <th className="px-6 py-4">Cost (৳)</th>
                                    <th className="px-6 py-4">Record ID</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {loading ? (
                                    <tr>
                                        <td colSpan={6} className="px-6 py-8 text-center text-slate-400">Loading records...</td>
                                    </tr>
                                ) : filteredRecords.length === 0 ? (
                                    <tr>
                                        <td colSpan={6} className="px-6 py-8 text-center text-slate-400">No records found.</td>
                                    </tr>
                                ) : (
                                    filteredRecords.map((r) => (
                                        <tr key={r.recordId} className="hover:bg-slate-50 transition-colors">
                                            <td className="px-6 py-4 font-medium text-slate-700">
                                                {format(new Date(r.date), "MMM d, yyyy")}
                                            </td>
                                            <td className="px-6 py-4 text-slate-600 font-mono text-xs">
                                                {r.vehicle.licensePlate}
                                            </td>
                                            <td className="px-6 py-4 text-slate-600 max-w-xs truncate">
                                                {r.description}
                                            </td>
                                            <td className="px-6 py-4 text-slate-600">
                                                {r.odometer ? `${r.odometer.toLocaleString()} km` : "-"}
                                            </td>
                                            <td className="px-6 py-4 font-semibold text-slate-900">
                                                {r.cost ? `৳${Number(r.cost).toLocaleString()}` : "-"}
                                            </td>
                                            <td className="px-6 py-4 text-slate-400 text-xs">
                                                #{String(r.recordId).padStart(4, "0")}
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </main>
    );
}
