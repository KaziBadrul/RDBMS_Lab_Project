"use client";

import { useEffect, useState } from "react";

type HistoryRow = {
  historyId: number;
  assignDate: string;
  shift: "morning" | "day" | "evening" | "night";
  action: string;
  driverId: number | null;
  vehicleId: number | null;
  prevDriverId: number | null;
  prevVehicleId: number | null;
  changedAt: string;
  note: string | null;
};

function todayYYYYMMDD() {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

export default function DriverHistoryPage() {
  const [date, setDate] = useState<string>("");
  const [shift, setShift] = useState<string>("");

  const [rows, setRows] = useState<HistoryRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const qs = new URLSearchParams();
      if (date) qs.set("date", date);
      if (shift) qs.set("shift", shift);

      const res = await fetch(`/api/driver/history?${qs}`, {
        cache: "no-store",
      });

      if (!res.ok) throw new Error(await res.text());
      const data: HistoryRow[] = await res.json();
      setRows(data);
    } catch (e: any) {
      setError(e?.message ?? "Failed to load history");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <main className="max-w-6xl mx-auto p-6">
      <header className="mb-6">
        <h1 className="text-3xl font-bold text-slate-900">
          Driver Assignment History
        </h1>
        <p className="text-slate-600 mt-1">
          Audit trail of driver ↔ vehicle assignments (per day & shift).
        </p>
      </header>

      <section className="bg-white rounded-2xl shadow-lg border border-slate-200 p-5 mb-6">
        <div className="flex flex-wrap gap-4 items-end">
          <div>
            <label className="block text-sm font-medium text-slate-700">
              Date
            </label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="mt-1 rounded-xl border border-slate-300 bg-slate-50 px-3 py-2"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700">
              Shift
            </label>
            <select
              value={shift}
              onChange={(e) => setShift(e.target.value)}
              className="mt-1 rounded-xl border border-slate-300 bg-slate-50 px-3 py-2"
            >
              <option value="">All</option>
              <option value="morning">Morning</option>
              <option value="day">Day</option>
              <option value="evening">Evening</option>
              <option value="night">Night</option>
            </select>
          </div>

          <button
            onClick={load}
            disabled={loading}
            className="rounded-xl bg-slate-900 text-white px-4 py-2 text-sm disabled:opacity-40"
          >
            {loading ? "Loading..." : "Apply Filter"}
          </button>

          <button
            onClick={() => {
              setDate("");
              setShift("");
              setTimeout(load, 0);
            }}
            className="rounded-xl border border-slate-300 px-4 py-2 text-sm hover:bg-slate-50"
          >
            Clear
          </button>
        </div>
      </section>

      {error && (
        <div className="mb-6 rounded-xl border border-rose-200 bg-rose-50 p-4 text-rose-700">
          {error}
        </div>
      )}

      <section className="bg-white rounded-2xl shadow-lg border border-slate-200 p-5">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-slate-600">
                <th className="py-2">Date</th>
                <th className="py-2">Shift</th>
                <th className="py-2">Action</th>
                <th className="py-2">Driver</th>
                <th className="py-2">Vehicle</th>
                <th className="py-2">Previous</th>
                <th className="py-2">Time</th>
                <th className="py-2">Note</th>
              </tr>
            </thead>

            <tbody>
              {rows.map((r) => (
                <tr key={r.historyId} className="border-t">
                  <td className="py-3">{r.assignDate}</td>
                  <td className="py-3 capitalize">{r.shift}</td>
                  <td className="py-3 font-semibold">{r.action}</td>
                  <td className="py-3">
                    {r.driverId ? `Driver #${r.driverId}` : "—"}
                  </td>
                  <td className="py-3">
                    {r.vehicleId ? `Vehicle #${r.vehicleId}` : "—"}
                  </td>
                  <td className="py-3 text-xs text-slate-600">
                    {r.prevDriverId || r.prevVehicleId
                      ? `D:${r.prevDriverId ?? "-"} / V:${r.prevVehicleId ?? "-"}`
                      : "—"}
                  </td>
                  <td className="py-3">
                    {new Date(r.changedAt).toLocaleTimeString()}
                  </td>
                  <td className="py-3 text-slate-600">{r.note ?? ""}</td>
                </tr>
              ))}

              {!loading && rows.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-6 text-slate-500">
                    No history found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>
    </main>
  );
}
