"use client";

import { useState } from "react";

export default function VehicleMaintenancePage() {
  const [lastServiceKm, setLastServiceKm] = useState("");
  const [currentKm, setCurrentKm] = useState("");
  const [intervalKm, setIntervalKm] = useState("");

  const remaining =
    lastServiceKm && currentKm && intervalKm
      ? Number(lastServiceKm) + Number(intervalKm) - Number(currentKm)
      : null;

  const isOverdue = remaining !== null && remaining < 0;

  return (
    <main className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100 p-8">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <header className="mb-10">
          <h1 className="text-4xl font-bold text-slate-900 tracking-tight">
            Vehicle Maintenance
          </h1>
          <p className="text-slate-600 mt-2">
            Add maintenance records and visually validate service intervals.
          </p>
        </header>

        {/* Card */}
        <section className="bg-white/80 backdrop-blur-xl border border-slate-200 shadow-xl rounded-3xl p-8">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* LEFT - Form */}
            <div className="space-y-6">
              <h2 className="text-xl font-semibold text-slate-800">
                Add Maintenance Record
              </h2>

              <div>
                <label className="block text-sm font-medium text-slate-700">
                  Vehicle License Plate
                </label>
                <input
                  type="text"
                  placeholder="Enter license plate"
                  className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700">
                  Maintenance Type
                </label>
                <select className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition">
                  <option>Oil Change</option>
                  <option>Engine Check</option>
                  <option>Brake Inspection</option>
                  <option>Tire Replacement</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700">
                  Service Date
                </label>
                <input
                  type="date"
                  className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700">
                  Notes
                </label>
                <textarea
                  rows={3}
                  placeholder="Additional service details..."
                  className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition resize-none"
                />
              </div>

              <button className="w-full rounded-2xl bg-indigo-600 text-white py-3 font-semibold shadow-lg hover:bg-indigo-700 active:scale-[0.98] transition">
                Save Maintenance Record
              </button>
            </div>

            {/* RIGHT - Service Interval Validation UI */}
            <div className="space-y-6">
              <h2 className="text-xl font-semibold text-slate-800">
                Service Interval Validation
              </h2>

              <div className="bg-slate-50 border border-slate-200 rounded-2xl p-6 space-y-5">
                <div>
                  <label className="block text-sm font-medium text-slate-700">
                    Last Service Odometer (km)
                  </label>
                  <input
                    type="number"
                    value={lastServiceKm}
                    onChange={(e) => setLastServiceKm(e.target.value)}
                    placeholder="e.g. 15000"
                    className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700">
                    Current Odometer (km)
                  </label>
                  <input
                    type="number"
                    value={currentKm}
                    onChange={(e) => setCurrentKm(e.target.value)}
                    placeholder="e.g. 18500"
                    className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700">
                    Service Interval (km)
                  </label>
                  <input
                    type="number"
                    value={intervalKm}
                    onChange={(e) => setIntervalKm(e.target.value)}
                    placeholder="e.g. 5000"
                    className="mt-2 w-full rounded-xl border border-slate-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition"
                  />
                </div>

                {remaining !== null && (
                  <div
                    className={`rounded-xl p-4 text-sm font-medium ${
                      isOverdue
                        ? "bg-rose-50 text-rose-700 border border-rose-200"
                        : remaining < 1000
                        ? "bg-amber-50 text-amber-700 border border-amber-200"
                        : "bg-emerald-50 text-emerald-700 border border-emerald-200"
                    }`}
                  >
                    {isOverdue
                      ? `Service overdue by ${Math.abs(remaining)} km`
                      : `${remaining} km remaining until next service`}
                  </div>
                )}
              </div>

              {/* Recent Records UI Mock */}
              <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
                <h3 className="text-sm font-semibold text-slate-700 mb-4">
                  Recent Maintenance Records
                </h3>

                <div className="space-y-3 text-sm">
                  <div className="flex justify-between bg-slate-50 p-3 rounded-xl">
                    <span>ABC-123 • Oil Change</span>
                    <span className="text-slate-500">Jan 15, 2026</span>
                  </div>
                  <div className="flex justify-between bg-slate-50 p-3 rounded-xl">
                    <span>XYZ-789 • Brake Inspection</span>
                    <span className="text-slate-500">Dec 28, 2025</span>
                  </div>
                  <div className="flex justify-between bg-slate-50 p-3 rounded-xl">
                    <span>LMN-456 • Engine Check</span>
                    <span className="text-slate-500">Dec 10, 2025</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}