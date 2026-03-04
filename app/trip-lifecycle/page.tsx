"use client";

export default function TripLifecyclePage() {
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
              {/* Top Action Cards */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="group bg-white rounded-2xl border border-slate-200 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 p-7 flex flex-col">
            <h2 className="text-lg font-semibold text-slate-800">
              Schedule Trip
            </h2>
            <p className="text-sm text-slate-500 mt-3 leading-relaxed flex-1">
              Create and manage upcoming trips with route and timing details.
            </p>
            <button className="mt-7 w-full bg-indigo-600 text-white rounded-xl py-2.5 font-medium hover:bg-indigo-700 transition">
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
            <button className="mt-7 w-full bg-emerald-600 text-white rounded-xl py-2.5 font-medium hover:bg-emerald-700 transition">
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
            <button className="mt-7 w-full bg-slate-900 text-white rounded-xl py-2.5 font-medium hover:bg-black transition">
              View Summary
            </button>
          </div>
        </section>
        {/* Schedule Trip Form */}
        <section className="bg-white rounded-2xl border border-slate-200 shadow-sm p-10">
          <div className="mb-8">
            <h2 className="text-2xl font-semibold text-slate-900">
              Schedule a New Trip
            </h2>
            <p className="text-sm text-slate-500 mt-2">
              Fill in the details below to create a new scheduled trip.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <input
              type="text"
              placeholder="Route (e.g., City A → City B)"
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            />
            <input
              type="date"
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            />
            <input
              type="time"
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            />
            <input
              type="number"
              placeholder="Ticket Price"
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            />
            <input
              type="number"
              placeholder="Total Seats"
              className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
            />
            <select className="rounded-xl border border-slate-300 bg-slate-50 px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition">
              <option>Select Vehicle</option>
              <option>BUS-101</option>
              <option>BUS-202</option>
            </select>
          </div>

          <button className="mt-10 bg-indigo-600 text-white px-8 py-3 rounded-xl font-medium hover:bg-indigo-700 transition shadow-sm hover:shadow-md">
            Save Trip
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
                  <th className="py-4 font-semibold">Seats Sold</th>
                  <th className="py-4 font-semibold">Revenue</th>
                  <th className="py-4 font-semibold">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                <tr className="hover:bg-slate-50 transition">
                  <td className="py-4 font-medium text-slate-900">
                    City A → City B
                  </td>
                  <td className="py-4 text-slate-600">10:00 AM</td>
                  <td className="py-4 text-slate-600">32 / 40</td>
                  <td className="py-4 text-slate-600">$640</td>
                  <td className="py-4">
                    <span className="px-3 py-1 text-xs rounded-full bg-emerald-100 text-emerald-700 font-medium">
                      Ongoing
                    </span>
                  </td>
                </tr>
                <tr className="hover:bg-slate-50 transition">
                  <td className="py-4 font-medium text-slate-900">
                    City C → City D
                  </td>
                  <td className="py-4 text-slate-600">2:00 PM</td>
                  <td className="py-4 text-slate-600">18 / 40</td>
                  <td className="py-4 text-slate-600">$360</td>
                  <td className="py-4">
                    <span className="px-3 py-1 text-xs rounded-full bg-amber-100 text-amber-700 font-medium">
                      Boarding
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        {/* Daily Summary */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-7 hover:shadow-lg transition">
            <h3 className="text-sm text-slate-500 font-medium">
              Total Trips Today
            </h3>
            <p className="text-3xl font-bold text-slate-900 mt-3">
              12
            </p>
          </div>

          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-7 hover:shadow-lg transition">
            <h3 className="text-sm text-slate-500 font-medium">
              Tickets Sold
            </h3>
            <p className="text-3xl font-bold text-slate-900 mt-3">
              348
            </p>
          </div>

          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-7 hover:shadow-lg transition">
            <h3 className="text-sm text-slate-500 font-medium">
              Total Revenue
            </h3>
            <p className="text-3xl font-bold text-emerald-600 mt-3">
              $6,920
            </p>
          </div>
        </section>

      </div>
    </main>
  );
}