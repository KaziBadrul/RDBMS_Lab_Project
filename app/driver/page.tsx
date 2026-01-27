"use client";

import { useEffect, useMemo, useState } from "react";

type ShiftType = "morning" | "day" | "evening" | "night";

type DriverRow = {
  driverId: number;
  name: string;
  licenseNumber: string;
  contactInfo: string | null;
  assignedVehicle: { vehicleId: number; licensePlate: string } | null;
};

type VehicleRow = {
  vehicleId: number;
  licensePlate: string;
  capacity: number;
  status: "active" | "inactive" | "maintenance";
  assignedDriver: { driverId: number; name: string } | null;
};

function todayYYYYMMDD() {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

export default function DriverPage() {
  const [date, setDate] = useState(todayYYYYMMDD());
  const [shift, setShift] = useState<ShiftType>("morning");

  const [drivers, setDrivers] = useState<DriverRow[]>([]);
  const [vehicles, setVehicles] = useState<VehicleRow[]>([]);
  const [selectedVehicleByDriver, setSelectedVehicleByDriver] = useState<
    Record<number, number | "">
  >({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const vehiclesById = useMemo(
    () => new Map(vehicles.map((v) => [v.vehicleId, v])),
    [vehicles],
  );

  async function loadAll() {
    setLoading(true);
    setError(null);
    try {
      const qs = `?date=${encodeURIComponent(date)}&shift=${encodeURIComponent(shift)}`;
      const [dRes, vRes] = await Promise.all([
        fetch(`/api/drivers${qs}`, { cache: "no-store" }),
        fetch(`/api/vehicles${qs}`, { cache: "no-store" }),
      ]);

      if (!dRes.ok) throw new Error(await dRes.text());
      if (!vRes.ok) throw new Error(await vRes.text());

      const d: DriverRow[] = await dRes.json();
      const v: VehicleRow[] = await vRes.json();

      setDrivers(d);
      setVehicles(v);

      const initial: Record<number, number | ""> = {};
      for (const dr of d)
        initial[dr.driverId] = dr.assignedVehicle?.vehicleId ?? "";
      setSelectedVehicleByDriver(initial);
    } catch (e: any) {
      setError(e?.message ?? "Failed to load");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadAll();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [date, shift]);

  async function assign(driverId: number) {
    const vehicleId = selectedVehicleByDriver[driverId];
    if (vehicleId === "" || vehicleId == null) return;

    const chosen = vehiclesById.get(Number(vehicleId));
    if (chosen?.status === "maintenance") {
      setError("Cannot assign to a vehicle in maintenance.");
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/assign-driver", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ driverId, vehicleId, date, shift }),
      });
      if (!res.ok) throw new Error(await res.text());
      await loadAll();
    } catch (e: any) {
      setError(e?.message ?? "Assign failed");
    } finally {
      setLoading(false);
    }
  }

  async function unassign(driverId: number) {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/unassign-driver", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ driverId, date, shift }),
      });
      if (!res.ok) throw new Error(await res.text());
      await loadAll();
    } catch (e: any) {
      setError(e?.message ?? "Unassign failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="max-w-6xl mx-auto p-6">
      <header className="mb-6">
        <h1 className="text-3xl font-bold text-slate-900">Driver Assignment</h1>
        <p className="text-slate-600 mt-1">
          Assign drivers to buses per <b>day</b> and <b>shift</b>. Vehicles in{" "}
          <b>maintenance</b> cannot be assigned.
        </p>
      </header>

      {error && (
        <div className="mb-6 rounded-xl border border-rose-200 bg-rose-50 p-4 text-rose-700">
          {error}
        </div>
      )}

      <section className="bg-white rounded-2xl shadow-lg border border-slate-200 p-5">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between mb-4">
          <div className="flex gap-3">
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
                onChange={(e) => setShift(e.target.value as ShiftType)}
                className="mt-1 rounded-xl border border-slate-300 bg-slate-50 px-3 py-2"
              >
                <option value="morning">Morning</option>
                <option value="day">Day</option>
                <option value="evening">Evening</option>
                <option value="night">Night</option>
              </select>
            </div>
          </div>

          <button
            onClick={loadAll}
            disabled={loading}
            className="rounded-xl border border-slate-300 px-3 py-2 text-sm hover:bg-slate-50 disabled:opacity-50"
          >
            {loading ? "Loading..." : "Refresh"}
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-slate-600">
                <th className="py-2">Driver</th>
                <th className="py-2">License</th>
                <th className="py-2">Contact</th>
                <th className="py-2">Current Vehicle</th>
                <th className="py-2">Assign Vehicle</th>
                <th className="py-2">Actions</th>
              </tr>
            </thead>

            <tbody>
              {drivers.map((d) => {
                const selectedVehicleId =
                  selectedVehicleByDriver[d.driverId] ?? "";
                const selectedVehicle =
                  selectedVehicleId === ""
                    ? null
                    : (vehiclesById.get(Number(selectedVehicleId)) ?? null);

                return (
                  <tr key={d.driverId} className="border-t">
                    <td className="py-3 font-semibold text-slate-900">
                      {d.name}
                    </td>
                    <td className="py-3 text-slate-700">{d.licenseNumber}</td>
                    <td className="py-3 text-slate-700">
                      {d.contactInfo ?? "-"}
                    </td>
                    <td className="py-3 text-slate-700">
                      {d.assignedVehicle ? d.assignedVehicle.licensePlate : "—"}
                    </td>

                    <td className="py-3">
                      <select
                        className="w-full rounded-xl border border-slate-300 bg-slate-50 px-3 py-2"
                        value={selectedVehicleId}
                        onChange={(e) =>
                          setSelectedVehicleByDriver((prev) => ({
                            ...prev,
                            [d.driverId]:
                              e.target.value === ""
                                ? ""
                                : Number(e.target.value),
                          }))
                        }
                        disabled={loading}
                      >
                        <option value="">Select a vehicle...</option>

                        {vehicles.map((v) => {
                          const maintenance = v.status === "maintenance";
                          const label = `${v.licensePlate} (cap ${v.capacity}) — ${v.status}`;
                          const assigned = v.assignedDriver
                            ? ` — assigned to ${v.assignedDriver.name}`
                            : "";
                          return (
                            <option
                              key={v.vehicleId}
                              value={v.vehicleId}
                              disabled={maintenance}
                            >
                              {label}
                              {maintenance ? " (blocked)" : ""}
                              {assigned}
                            </option>
                          );
                        })}
                      </select>

                      {selectedVehicle?.status === "maintenance" && (
                        <div className="mt-1 text-xs text-rose-700">
                          This vehicle is in maintenance. Assignment is blocked.
                        </div>
                      )}
                    </td>

                    <td className="py-3 flex gap-2">
                      <button
                        onClick={() => assign(d.driverId)}
                        disabled={
                          loading ||
                          selectedVehicleId === "" ||
                          selectedVehicle?.status === "maintenance"
                        }
                        className="rounded-xl bg-slate-900 text-white px-3 py-2 text-sm disabled:opacity-40"
                      >
                        Assign
                      </button>

                      <button
                        onClick={() => unassign(d.driverId)}
                        disabled={loading || !d.assignedVehicle}
                        className="rounded-xl border border-slate-300 px-3 py-2 text-sm hover:bg-slate-50 disabled:opacity-40"
                      >
                        Unassign
                      </button>
                    </td>
                  </tr>
                );
              })}

              {drivers.length === 0 && (
                <tr>
                  <td className="py-6 text-slate-500" colSpan={6}>
                    No drivers found.
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
