"use client";

import { useState, useEffect } from "react";

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

export default function VehicleMaintenancePage() {
  const [lastServiceKm, setLastServiceKm] = useState("");
  const [currentKm, setCurrentKm] = useState("");
  const [intervalKm, setIntervalKm] = useState("");

  // Form states
  const [licensePlate, setLicensePlate] = useState("");
  const [maintenanceType, setMaintenanceType] = useState("Oil Change");
  const [serviceDate, setServiceDate] = useState("");
  const [notes, setNotes] = useState("");
  const [cost, setCost] = useState("");
  const [odometer, setOdometer] = useState("");
  const [interval, setInterval] = useState("");

  // UI states
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [messageType, setMessageType] = useState<"success" | "error" | "">(
    ""
  );
  const [maintenanceRecords, setMaintenanceRecords] = useState<
    MaintenanceRecord[]
  >([]);
  const [fetchingRecords, setFetchingRecords] = useState(true);

  const remaining =
    lastServiceKm && currentKm && intervalKm
      ? Number(lastServiceKm) + Number(intervalKm) - Number(currentKm)
      : null;

  const isOverdue = remaining !== null && remaining < 0;

  // Fetch maintenance records on mount
  useEffect(() => {
    const fetchRecords = async () => {
      try {
        const response = await fetch("/api/maintenance");
        if (response.ok) {
          const data = await response.json();
          setMaintenanceRecords(data);
        }
      } catch (error) {
        console.error("Error fetching maintenance records:", error);
      } finally {
        setFetchingRecords(false);
      }
    };

    fetchRecords();
  }, []);

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!licensePlate || !maintenanceType || !serviceDate) {
      setMessage("Please fill in all required fields");
      setMessageType("error");
      return;
    }

    setLoading(true);
    setMessage("");
    setMessageType("");

    try {
      const response = await fetch("/api/maintenance", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          licensePlate,
          maintenanceType,
          serviceDate,
          notes,
          cost: cost || null,
          odometer: odometer || null,
          interval: interval || null,
        }),
      });

      if (response.ok) {
        const newRecord = await response.json();
        setMaintenanceRecords([newRecord, ...maintenanceRecords]);
        setMessage("Maintenance record saved successfully!");
        setMessageType("success");

        // Reset form
        setLicensePlate("");
        setMaintenanceType("Oil Change");
        setServiceDate("");
        setNotes("");
        setCost("");
        setOdometer("");
        setInterval("");
      } else {
        const errorData = await response.json();
        setMessage(errorData.error || "Failed to save maintenance record");
        setMessageType("error");
      }
    } catch (error) {
      console.error("Error saving maintenance record:", error);
      setMessage("An error occurred while saving");
      setMessageType("error");
    } finally {
      setLoading(false);
    }
  };

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

              {message && (
                <div
                  className={`p-4 rounded-2xl text-sm font-medium ${messageType === "success"
                    ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                    : "bg-rose-50 text-rose-700 border border-rose-200"
                    }`}
                >
                  {message}
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-slate-700">
                    Vehicle License Plate *
                  </label>
                  <input
                    type="text"
                    placeholder="Enter license plate"
                    value={licensePlate}
                    onChange={(e) => setLicensePlate(e.target.value)}
                    className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700">
                    Maintenance Type *
                  </label>
                  <select
                    value={maintenanceType}
                    onChange={(e) => setMaintenanceType(e.target.value)}
                    className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                    required
                  >
                    <option>Oil Change</option>
                    <option>Engine Check</option>
                    <option>Brake Inspection</option>
                    <option>Tire Replacement</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700">
                    Service Date *
                  </label>
                  <input
                    type="date"
                    value={serviceDate}
                    onChange={(e) => setServiceDate(e.target.value)}
                    className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                    required
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700">
                      Odometer (km)
                    </label>
                    <input
                      type="number"
                      placeholder="e.g. 18500"
                      value={odometer}
                      onChange={(e) => setOdometer(e.target.value)}
                      className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700">
                      Interval (km)
                    </label>
                    <input
                      type="number"
                      placeholder="e.g. 5000"
                      value={interval}
                      onChange={(e) => setInterval(e.target.value)}
                      className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700">
                    Cost (Optional)
                  </label>
                  <input
                    type="number"
                    placeholder="Enter cost"
                    value={cost}
                    onChange={(e) => setCost(e.target.value)}
                    step="0.01"
                    className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700">
                    Notes (Optional)
                  </label>
                  <textarea
                    rows={3}
                    placeholder="Additional service details..."
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition resize-none"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full rounded-2xl bg-indigo-600 text-white py-3 font-semibold shadow-lg hover:bg-indigo-700 active:scale-[0.98] transition disabled:bg-indigo-400 disabled:cursor-not-allowed"
                >
                  {loading ? "Saving..." : "Save Maintenance Record"}
                </button>
              </form>
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
                    className={`rounded-xl p-4 text-sm font-medium ${isOverdue
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

                {fetchingRecords ? (
                  <div className="text-sm text-slate-500 text-center py-4">
                    Loading records...
                  </div>
                ) : maintenanceRecords.length === 0 ? (
                  <div className="text-sm text-slate-500 text-center py-4">
                    No maintenance records yet
                  </div>
                ) : (
                  <div className="space-y-3 text-sm">
                    {maintenanceRecords.map((record) => (
                      <div
                        key={record.recordId}
                        className="bg-slate-50 p-3 rounded-xl space-y-1"
                      >
                        <div className="flex justify-between">
                          <span className="font-medium text-slate-700">
                            {record.vehicle.licensePlate} • {record.description}
                          </span>
                          <span className="text-slate-400 text-xs font-mono">
                            #{String(record.recordId).padStart(4, "0")}
                          </span>
                        </div>
                        <div className="flex gap-4 text-xs text-slate-500">
                          <span>
                            {new Date(record.date).toLocaleDateString("en-US", {
                              year: "numeric",
                              month: "short",
                              day: "numeric",
                            })}
                          </span>
                          {record.cost && <span>${Number(record.cost).toLocaleString()}</span>}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}