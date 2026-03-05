"use client";

import { useState, useEffect } from "react";
import { format } from "date-fns";

interface Route {
  routeId: number;
  startLocation: string;
  endLocation: string;
}

interface Vehicle {
  vehicleId: number;
  licensePlate: string;
  capacity: number;
}

interface Driver {
  driverId: number;
  name: string;
}

interface Trip {
  id: number;
  departureTime: string;
  price: number;
  driver: string;
  route: { start: string; end: string };
  vehicle: { capacity: number; licensePlate: string };
  ticketsSold: number;
  revenue: number;
}

export default function TripLifecyclePage() {
  const [routes, setRoutes] = useState<Route[]>([]);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [loading, setLoading] = useState(true);

  // Form state
  const [routeId, setRouteId] = useState("");
  const [vehicleId, setVehicleId] = useState("");
  const [driverId, setDriverId] = useState("");
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [price, setPrice] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [routesRes, vehiclesRes, driversRes, tripsRes] = await Promise.all([
          fetch("/api/routes"),
          fetch("/api/vehicles"),
          fetch("/api/drivers"),
          fetch("/api/trips"),
        ]);

        if (routesRes.ok) setRoutes(await routesRes.json());
        if (vehiclesRes.ok) setVehicles(await vehiclesRes.json());
        if (driversRes.ok) setDrivers(await driversRes.json());
        if (tripsRes.ok) setTrips(await tripsRes.json());
      } catch (error) {
        console.error("Error fetching data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const handleSaveTrip = async () => {
    if (!routeId || !vehicleId || !driverId || !date || !time || !price) {
      alert("Please fill in all fields");
      return;
    }

    setSaving(true);
    try {
      const departureTime = new Date(`${date}T${time}`).toISOString();
      const res = await fetch("/api/trips", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          routeId,
          vehicleId,
          driverId,
          departureTime,
          price,
        }),
      });

      if (res.ok) {
        alert("Trip created successfully!");
        // Refresh trips
        const tripsRes = await fetch("/api/trips");
        if (tripsRes.ok) setTrips(await tripsRes.json());

        // Reset form
        setRouteId("");
        setVehicleId("");
        setDriverId("");
        setDate("");
        setTime("");
        setPrice("");
      } else {
        const err = await res.text();
        alert(`Error: ${err}`);
      }
    } catch (error) {
      console.error("Error saving trip:", error);
      alert("Failed to save trip");
    } finally {
      setSaving(false);
    }
  };

  const totalRevenue = trips.reduce((sum, t) => sum + t.revenue, 0);
  const totalTicketsSold = trips.reduce((sum, t) => sum + t.ticketsSold, 0);

  return (
    <main className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100/60 py-14 px-6">
      <div className="max-w-6xl mx-auto space-y-14">

        {/* Header */}
        <header className="space-y-4">
          <h1 className="text-4xl md:text-5xl font-extrabold text-slate-900 tracking-tight">
            Trip Lifecycle
          </h1>
          <p className="text-slate-600 text-lg max-w-2xl leading-relaxed">
            Schedule trips, manage ticket sales, and track daily operational performance.
          </p>
        </header>

        {/* Top Action Cards */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="group bg-white rounded-2xl border border-slate-200 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 p-7 flex flex-col">
            <h2 className="text-lg font-semibold text-slate-800">
              Schedule Trip
            </h2>
            <p className="text-sm text-slate-500 mt-3 leading-relaxed flex-1">
              Create and manage upcoming trips with route and timing details.
            </p>
            <button
              onClick={() => document.getElementById("schedule-section")?.scrollIntoView({ behavior: "smooth" })}
              className="mt-7 w-full bg-indigo-600 text-white rounded-xl py-2.5 font-medium hover:bg-indigo-700 transition"
            >
              Create Trip
            </button>
          </div>

          <div className="group bg-white rounded-2xl border border-slate-200 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 p-7 flex flex-col">
            <h2 className="text-lg font-semibold text-slate-800">
              Sell Tickets
            </h2>
            <p className="text-sm text-slate-500 mt-3 leading-relaxed flex-1">
              Issue and manage ticket sales for scheduled trips.
            </p>
            <button
              onClick={() => window.location.href = "/ticketing"}
              className="mt-7 w-full bg-emerald-600 text-white rounded-xl py-2.5 font-medium hover:bg-emerald-700 transition"
            >
              Sell Ticket
            </button>
          </div>

          <div className="group bg-white rounded-2xl border border-slate-200 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 p-7 flex flex-col">
            <h2 className="text-lg font-semibold text-slate-800">
              Daily Summary
            </h2>
            <p className="text-sm text-slate-500 mt-3 leading-relaxed flex-1">
              View daily performance, revenue, and occupancy reports.
            </p>
            <button
              onClick={() => document.getElementById("summary-section")?.scrollIntoView({ behavior: "smooth" })}
              className="mt-7 w-full bg-slate-900 text-white rounded-xl py-2.5 font-medium hover:bg-black transition"
            >
              View Summary
            </button>
          </div>
        </section>

        {/* Schedule Trip Form */}
        <section id="schedule-section" className="bg-white rounded-2xl border border-slate-200 shadow-sm p-10">
          <div className="mb-8">
            <h2 className="text-2xl font-semibold text-slate-900">
              Schedule a New Trip
            </h2>
            <p className="text-sm text-slate-500 mt-2">
              Fill in the details below to create a new scheduled trip.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <select
              value={routeId}
              onChange={(e) => setRouteId(e.target.value)}
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            >
              <option value="">Select Route</option>
              {routes.map(r => (
                <option key={r.routeId} value={r.routeId}>
                  {r.startLocation} → {r.endLocation}
                </option>
              ))}
            </select>

            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            />
            <input
              type="time"
              value={time}
              onChange={(e) => setTime(e.target.value)}
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            />

            <input
              type="number"
              placeholder="Ticket Price (৳)"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            />

            <select
              value={vehicleId}
              onChange={(e) => setVehicleId(e.target.value)}
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            >
              <option value="">Select Vehicle</option>
              {vehicles.map(v => (
                <option key={v.vehicleId} value={v.vehicleId}>
                  {v.licensePlate} ({v.capacity} seats)
                </option>
              ))}
            </select>

            <select
              value={driverId}
              onChange={(e) => setDriverId(e.target.value)}
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            >
              <option value="">Select Driver</option>
              {drivers.map(d => (
                <option key={d.driverId} value={d.driverId}>
                  {d.name}
                </option>
              ))}
            </select>
          </div>

          <button
            onClick={handleSaveTrip}
            disabled={saving}
            className="mt-10 bg-indigo-600 text-white px-8 py-3 rounded-xl font-medium hover:bg-indigo-700 transition shadow-sm hover:shadow-md disabled:opacity-50"
          >
            {saving ? "Saving..." : "Save Trip"}
          </button>
        </section>

        {/* Ticket Sales Table */}
        <section className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="px-10 py-7 border-b border-slate-100">
            <h2 className="text-2xl font-semibold text-slate-900">
              Active Trips & Ticket Sales
            </h2>
            <p className="text-sm text-slate-500 mt-2">
              Overview of ongoing trips and ticket performance.
            </p>
          </div>

          <div className="overflow-x-auto px-10 py-6">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-slate-500 border-b border-slate-200">
                  <th className="py-4 font-semibold">Route</th>
                  <th className="py-4 font-semibold">Departure</th>
                  <th className="py-4 font-semibold">Vehicle</th>
                  <th className="py-4 font-semibold">Seats Sold</th>
                  <th className="py-4 font-semibold">Revenue</th>
                  <th className="py-4 font-semibold">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {trips.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">No active trips found for today.</td>
                  </tr>
                ) : (
                  trips.map((t) => (
                    <tr key={t.id} className="hover:bg-slate-50 transition">
                      <td className="py-4 font-medium text-slate-900">
                        {t.route.start} → {t.route.end}
                      </td>
                      <td className="py-4 text-slate-600">
                        {format(new Date(t.departureTime), "p")}
                      </td>
                      <td className="py-4 text-slate-600">
                        {t.vehicle.licensePlate}
                      </td>
                      <td className="py-4 text-slate-600">
                        {t.ticketsSold} / {t.vehicle.capacity}
                      </td>
                      <td className="py-4 text-slate-600">
                        ৳{t.revenue.toLocaleString()}
                      </td>
                      <td className="py-4">
                        <span className={`px-3 py-1 text-xs rounded-full font-medium ${new Date(t.departureTime) > new Date()
                          ? "bg-emerald-100 text-emerald-700"
                          : "bg-slate-100 text-slate-500"
                          }`}>
                          {new Date(t.departureTime) > new Date() ? "Scheduled" : "Completed"}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </section>

        {/* Daily Summary */}
        <section id="summary-section" className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-7 hover:shadow-lg transition">
            <h3 className="text-sm text-slate-500 font-medium">
              Total Trips Today
            </h3>
            <p className="text-3xl font-bold text-slate-900 mt-3">
              {trips.length}
            </p>
          </div>

          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-7 hover:shadow-lg transition">
            <h3 className="text-sm text-slate-500 font-medium">
              Tickets Sold
            </h3>
            <p className="text-3xl font-bold text-slate-900 mt-3">
              {totalTicketsSold}
            </p>
          </div>

          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-7 hover:shadow-lg transition">
            <h3 className="text-sm text-slate-500 font-medium">
              Total Revenue
            </h3>
            <p className="text-3xl font-bold text-emerald-600 mt-3">
              ৳{totalRevenue.toLocaleString()}
            </p>
          </div>
        </section>

      </div>
    </main>
  );
}