"use client";

import { useEffect, useMemo, useState } from "react";

type TripUI = {
  id: number;
  departureTime: string;
  price: number;
  route: { start: string; end: string };
  vehicle: { capacity: number };
};

type SeatUI = {
  seatNo: number;
  status: "available" | "held" | "sold";
};

function formatDT(iso: string) {
  const d = new Date(iso);
  return d.toLocaleString([], { dateStyle: "medium", timeStyle: "short" });
}

export default function TicketingFlow() {
  // DB-backed trips
  const [trips, setTrips] = useState<TripUI[]>([]);
  const [selectedTripId, setSelectedTripId] = useState<number | null>(null);

  // DB-backed seats for selected trip
  const [seats, setSeats] = useState<SeatUI[]>([]);
  const [selectedSeats, setSelectedSeats] = useState<number[]>([]);

  // UI states
  const [loadingTrips, setLoadingTrips] = useState(false);
  const [loadingSeats, setLoadingSeats] = useState(false);
  const [booking, setBooking] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 1) Load trips once
  useEffect(() => {
    (async () => {
      try {
        setLoadingTrips(true);
        setError(null);

        const res = await fetch("/api/trips", { cache: "no-store" });
        if (!res.ok) throw new Error(await res.text());

        const data: TripUI[] = await res.json();
        setTrips(data);

        // Default select first trip
        setSelectedTripId(data[0]?.id ?? null);
      } catch (e: any) {
        setError(e?.message ?? "Failed to load trips");
      } finally {
        setLoadingTrips(false);
      }
    })();
  }, []);

  // 2) Load seats whenever selectedTripId changes
  useEffect(() => {
    if (!selectedTripId) {
      setSeats([]);
      return;
    }

    (async () => {
      try {
        setLoadingSeats(true);
        setError(null);
        setSelectedSeats([]);

        const res = await fetch(`/api/trips/${selectedTripId}/seats`, {
          cache: "no-store",
        });
        if (!res.ok) throw new Error(await res.text());

        const data: SeatUI[] = await res.json();
        setSeats(data);
      } catch (e: any) {
        setError(e?.message ?? "Failed to load seats");
      } finally {
        setLoadingSeats(false);
      }
    })();
  }, [selectedTripId]);

  const selectedTrip = useMemo(
    () => trips.find((t) => t.id === selectedTripId) ?? null,
    [trips, selectedTripId],
  );

  const availableCount = useMemo(
    () => seats.filter((s) => s.status === "available").length,
    [seats],
  );

  function toggleSeat(seatNo: number) {
    setSelectedSeats((prev) =>
      prev.includes(seatNo)
        ? prev.filter((n) => n !== seatNo)
        : [...prev, seatNo],
    );
  }

  async function refreshSeats() {
    if (!selectedTripId) return;
    const res = await fetch(`/api/trips/${selectedTripId}/seats`, {
      cache: "no-store",
    });
    if (res.ok) {
      const data: SeatUI[] = await res.json();
      setSeats(data);
    }
  }

  // 3) Book via API (Prisma transaction on server)
  async function confirmBooking() {
    if (!selectedTripId || !selectedTrip || selectedSeats.length === 0) return;

    try {
      setBooking(true);
      setError(null);

      // Optional optimistic UI: mark selected seats as sold immediately
      const optimistic = seats.map((s) =>
        selectedSeats.includes(s.seatNo)
          ? { ...s, status: "sold" as const }
          : s,
      );
      setSeats(optimistic);

      const res = await fetch("/api/book", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          tripId: selectedTripId,
          seatNumbers: selectedSeats,
          // TODO: replace with real passenger form input
          passenger: { name: "Demo Passenger", contactInfo: "0123456789" },
        }),
      });

      if (!res.ok) {
        // rollback: reload seats from DB
        await refreshSeats();
        throw new Error(await res.text());
      }

      setSelectedSeats([]);
      // Always refresh after booking so client matches DB exactly
      await refreshSeats();
      console.log("DB Seat Booking Done!");
    } catch (e: any) {
      setError(e?.message ?? "Booking failed");
    } finally {
      setBooking(false);
    }
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

      {error && (
        <div className="mb-6 rounded-xl border border-rose-200 bg-rose-50 p-4 text-rose-700">
          {error}
        </div>
      )}

      <div className="grid gap-6 lg:grid-cols-[420px_1fr]">
        {/* LEFT PANEL */}
        <section className="bg-white rounded-2xl shadow-lg border border-slate-200 p-5">
          <h2 className="text-lg font-semibold text-slate-900">Trip</h2>

          <select
            className="mt-4 w-full rounded-xl border border-slate-300 bg-slate-50 px-3 py-2"
            value={selectedTripId ?? ""}
            disabled={loadingTrips || trips.length === 0}
            onChange={(e) => {
              setSelectedTripId(Number(e.target.value));
              setSelectedSeats([]);
            }}
          >
            {trips.map((t) => (
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
                Seats Available:{" "}
                {loadingSeats
                  ? "Loading..."
                  : `${availableCount} / ${selectedTrip.vehicle.capacity}`}
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

          {loadingSeats ? (
            <div className="text-slate-600">Loading seats...</div>
          ) : (
            <div className="grid grid-cols-6 sm:grid-cols-8 md:grid-cols-10 gap-2">
              {seats.map((s) => {
                const isSelected = selectedSeats.includes(s.seatNo);
                const disabled = s.status !== "available" || booking;

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
          )}

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
            disabled={booking || selectedSeats.length === 0 || !selectedTripId}
            onClick={confirmBooking}
            className="mt-5 w-full rounded-full bg-rose-600 text-white py-2.5 font-semibold hover:bg-rose-700 disabled:opacity-40"
          >
            {booking ? "Booking..." : "Confirm Ticket"}
          </button>
        </section>
      </div>
    </main>
  );
}
