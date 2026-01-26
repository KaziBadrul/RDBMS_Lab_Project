"use client";

import { useMemo, useState } from "react";
import type { Seat, Trip } from "@/lib/ticketing/mock";
import { generateSeats, mockTrips } from "@/lib/ticketing/mock";

function formatDT(iso: string) {
  const d = new Date(iso);
  return d.toLocaleString([], { dateStyle: "medium", timeStyle: "short" });
}

export default function TicketingFlow() {
  const [selectedTripId, setSelectedTripId] = useState<string>(
    mockTrips[0]?.id ?? "",
  );

  const selectedTrip = useMemo<Trip | undefined>(
    () => mockTrips.find((t) => t.id === selectedTripId),
    [selectedTripId],
  );

  /** 🔹 Persistent seat state (per trip) */
  const [seatState, setSeatState] = useState<Record<string, Seat[]>>({});

  /** 🔹 Multi-seat selection */
  const [selectedSeats, setSelectedSeats] = useState<number[]>([]);

  /** Initialize seats once per trip */
  const seats = useMemo<Seat[]>(() => {
    if (!selectedTrip) return [];
    if (seatState[selectedTrip.id]) return seatState[selectedTrip.id];

    const seed = selectedTrip.id
      .split("")
      .reduce((a, c) => a + c.charCodeAt(0), 0);

    const generated = generateSeats(selectedTrip.vehicle.capacity, seed);

    setSeatState((prev) => ({
      ...prev,
      [selectedTrip.id]: generated,
    }));

    return generated;
  }, [selectedTrip, seatState]);

  const availableCount = seats.filter((s) => s.status === "available").length;

  function toggleSeat(seatNo: number) {
    setSelectedSeats((prev) =>
      prev.includes(seatNo)
        ? prev.filter((n) => n !== seatNo)
        : [...prev, seatNo],
    );
  }

  function confirmBooking() {
    if (!selectedTrip || selectedSeats.length === 0) return;

    setSeatState((prev) => ({
      ...prev,
      [selectedTrip.id]: prev[selectedTrip.id].map((s) =>
        selectedSeats.includes(s.seatNo) ? { ...s, status: "sold" } : s,
      ),
    }));
    //! TODO: Turn from mock to postgreSQL
    console.log("Mock Seat Booking Done!");
    setSelectedSeats([]);
  }

  return (
    <main className="max-w-6xl mx-auto p-6">
      <header className="mb-6">
        <h1 className="text-3xl font-bold text-rose-800">
          Passenger Ticketing
        </h1>
        <p className="text-slate-600 mt-1">
          Select a trip → choose seats → enter passenger info → confirm booking.
        </p>
      </header>

      <div className="grid gap-6 lg:grid-cols-[420px_1fr]">
        {/* LEFT PANEL */}
        <section className="bg-white rounded-2xl shadow-lg border border-slate-200 p-5">
          <h2 className="text-lg font-semibold text-slate-900">Trip</h2>

          <select
            className="mt-4 w-full rounded-xl border border-slate-300 bg-slate-50 px-3 py-2"
            value={selectedTripId}
            onChange={(e) => {
              setSelectedTripId(e.target.value);
              setSelectedSeats([]);
            }}
          >
            {mockTrips.map((t) => (
              <option key={t.id} value={t.id}>
                {t.route.start} → {t.route.end}
              </option>
            ))}
          </select>

          {selectedTrip && (
            <div className="mt-5 bg-slate-50 rounded-xl p-4 border border-slate-200 text-sm">
              <div className="font-semibold text-slate-900">
                {selectedTrip.route.start} → {selectedTrip.route.end}
              </div>
              <div className="text-slate-600 mt-1">
                Departure: {formatDT(selectedTrip.departureTime)}
              </div>
              <div className="text-slate-600">
                Seats Available: {availableCount} /{" "}
                {selectedTrip.vehicle.capacity}
              </div>
              <div className="mt-2 font-bold text-rose-600">
                ৳ {selectedTrip.price} per seat
              </div>
            </div>
          )}
        </section>

        {/* RIGHT PANEL */}
        <section className="bg-white rounded-2xl shadow-lg border border-slate-200 p-5">
          <h2 className="text-lg font-semibold text-slate-900 mb-4">
            Seat Selection
          </h2>

          <div className="grid grid-cols-6 sm:grid-cols-8 md:grid-cols-10 gap-2">
            {seats.map((s) => {
              const isSelected = selectedSeats.includes(s.seatNo);
              const disabled = s.status !== "available";

              return (
                <button
                  key={s.seatNo}
                  disabled={disabled}
                  onClick={() => toggleSeat(s.seatNo)}
                  className={`
                    h-10 rounded-xl text-sm font-semibold border transition
                    ${
                      disabled
                        ? "bg-slate-200 text-slate-400 cursor-not-allowed"
                        : isSelected
                          ? "bg-slate-900 text-white border-slate-900"
                          : "bg-slate-50 border-slate-300 hover:bg-sky-500 hover:text-white"
                    }
                  `}
                >
                  {String(s.seatNo).padStart(2, "0")}
                </button>
              );
            })}
          </div>

          <div className="mt-5 flex justify-between items-center text-sm">
            <div className="text-slate-700">
              Selected Seats:{" "}
              <span className="font-semibold">
                {selectedSeats.length ? selectedSeats.join(", ") : "None"}
              </span>
            </div>

            <div className="font-bold text-rose-600">
              Total: ৳{" "}
              {selectedTrip ? selectedSeats.length * selectedTrip.price : 0}
            </div>
          </div>

          <button
            disabled={selectedSeats.length === 0}
            onClick={confirmBooking}
            className="mt-5 w-full rounded-full bg-rose-600 text-white py-2.5 font-semibold hover:bg-rose-700 disabled:opacity-40"
          >
            Confirm Ticket
          </button>
        </section>
      </div>
    </main>
  );
}
