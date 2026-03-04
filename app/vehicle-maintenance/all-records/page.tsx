"use client";

import { useState, useEffect } from "react";
import Link from "next/link";

interface MaintenanceRecord {
  recordId: number;
  vehicleId: number;
  date: string;
  description: string;
  cost: number | string | null;
  odometer: number | null;
  interval: number | null;
  vehicle: {
    licensePlate: string;
  };
}

export default function AllMaintenanceRecordsPage() {
  const [records, setRecords] = useState<MaintenanceRecord[]>([]);
  const [loading, setLoading] = useState(true);

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

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100/60 py-16 px-6 flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin mx-auto"></div>
          <p className="text-slate-500 font-medium">Crunching records...</p>
        </div>
      </div>
    );
  }

  return (
    <main className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100/60 py-16 px-6">
      <div className="max-w-6xl mx-auto space-y-12">

        {/* Header */}
        <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
          <div className="space-y-4">
            <h1 className="text-4xl md:text-5xl font-extrabold text-slate-900 tracking-tight">
              Maintenance Records
            </h1>
            <p className="text-lg text-slate-600 max-w-2xl leading-relaxed">
              Complete overview of all vehicle maintenance activities and service history.
            </p>
          </div>
          <Link
            href="/vehicle-maintenance"
            className="px-6 py-3 bg-white border border-slate-200 text-slate-700 font-semibold rounded-2xl shadow-sm hover:shadow-md hover:bg-slate-50 transition-all text-center"
          >
            ← Add New Record
          </Link>
        </header>

        {/* Records List */}
        <section className="space-y-6">
          {records.length === 0 ? (
            <div className="bg-white rounded-3xl border border-dashed border-slate-300 p-20 text-center">
              <p className="text-slate-500 text-lg">No maintenance records found yet.</p>
              <Link href="/vehicle-maintenance" className="text-indigo-600 font-semibold mt-2 inline-block hover:underline">
                Create the first record
              </Link>
            </div>
          ) : (
            records.map((record, index) => (
              <div
                key={record.recordId}
                className="bg-white rounded-3xl border border-slate-200 shadow-sm hover:shadow-xl transition-all duration-300 p-8"
              >
                <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">

                  {/* Left Section */}
                  <div className="space-y-4">
                    <div className="flex items-center gap-4">
                      <h2 className="text-2xl font-bold text-slate-900">
                        {record.vehicle.licensePlate}
                      </h2>
                      {record.cost && (
                        <span className="px-4 py-1 text-sm rounded-full bg-emerald-100 text-emerald-700 font-semibold">
                          ${Number(record.cost).toLocaleString()}
                        </span>
                      )}
                    </div>

                    <p className="text-slate-600 text-lg">
                      {record.description}
                    </p>

                    <div className="flex flex-wrap gap-8 text-slate-500 text-base">
                      <div>
                        <span className="block text-sm text-slate-400">
                          Service Date
                        </span>
                        {new Date(record.date).toLocaleDateString("en-US", {
                          year: "numeric",
                          month: "short",
                          day: "numeric",
                        })}
                      </div>
                      <div>
                        <span className="block text-sm text-slate-400">
                          Odometer
                        </span>
                        {record.odometer
                          ? `${record.odometer.toLocaleString()} km`
                          : <span className="text-slate-400 italic text-sm">Not recorded</span>}
                      </div>
                      <div>
                        <span className="block text-sm text-slate-400">
                          Interval
                        </span>
                        {record.interval
                          ? `${record.interval.toLocaleString()} km`
                          : <span className="text-slate-400 italic text-sm">Not recorded</span>}
                      </div>
                    </div>
                  </div>

                  {/* Right Accent */}
                  <div className="text-right">
                    <div className="text-sm text-slate-400">Record ID</div>
                    <div className="text-lg font-semibold text-slate-700">
                      #{String(record.recordId).padStart(4, '0')}
                    </div>
                  </div>

                </div>
              </div>
            ))
          )}
        </section>

      </div>
    </main>
  );
}
