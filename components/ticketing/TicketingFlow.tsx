"use client";

import { useEffect, useMemo, useState } from "react";

type TripUI = {
  id: number;
  departureTime: string;
  driver: string;
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

function todayYYYYMMDD() {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

export default function TicketingFlow() {
  // ✅ Date picker (used to filter trips)
  const [tripDate, setTripDate] = useState<string>(todayYYYYMMDD());

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

  const [passengerName, setPassengerName] = useState("");
  const [passengerContact, setPassengerContact] = useState("");

  // 1) Load trips whenever date changes (Option B)
  useEffect(() => {
    (async () => {
      try {
        setLoadingTrips(true);
        setError(null);

        const res = await fetch(
          `/api/trips?date=${encodeURIComponent(tripDate)}`,
          {
            cache: "no-store",
          },
        );
        if (!res.ok) throw new Error(await res.text());

        const data: TripUI[] = await res.json();
        setTrips(data);

        // Select first trip for that date (or clear if none)
        const firstId = data[0]?.id ?? null;
        setSelectedTripId(firstId);
        setSelectedSeats([]);
        setSeats([]);
      } catch (e: any) {
        setError(e?.message ?? "Failed to load trips");
        setTrips([]);
        setSelectedTripId(null);
        setSeats([]);
      } finally {
        setLoadingTrips(false);
      }
    })();
  }, [tripDate]);

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

    if (!passengerName.trim()) {
      setError("Passenger name is required.");
      return;
    }
    if (!passengerContact.trim()) {
      setError("Passenger phone/email is required.");
      return;
    }

    try {
      setBooking(true);
      setError(null);

      // Optional optimistic UI
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
          passenger: {
            name: passengerName.trim(),
            contactInfo: passengerContact.trim(),
          },
        }),
      });

      if (!res.ok) {
        await refreshSeats();
        throw new Error(await res.text());
      }

      setPassengerName("");
      setPassengerContact("");
      setSelectedSeats([]);
      await refreshSeats();
      console.log("DB Seat Booking Done!");
    } catch (e: any) {
      setError(e?.message ?? "Booking failed");
    } finally {
      setBooking(false);
    }
  }

  return (
  <main className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50 py-12 px-6">
    <div className="max-w-7xl mx-auto">

      {/* Header */}
      <header className="mb-10">
        <h1 className="text-4xl font-bold bg-gradient-to-r from-indigo-600 to-blue-600 bg-clip-text text-transparent">
          Passenger Ticketing
        </h1>
        <p className="text-slate-600 mt-2 text-lg">
          Pick date → select trip → choose seats → enter passenger info → confirm booking.
        </p>
      </header>

      {error && (
        <div className="mb-8 rounded-2xl border border-rose-200 bg-rose-50 px-6 py-4 text-rose-700 shadow-sm">
          {error}
        </div>
      )}

      <div className="grid gap-8 lg:grid-cols-[420px_1fr]">

        {/* LEFT PANEL */}
        <section className="bg-white/80 backdrop-blur-md rounded-3xl border border-white shadow-xl p-8">
          <h2 className="text-xl font-semibold text-slate-900">Trip</h2>

          <div className="mt-6">
            <label className="block text-sm font-medium text-slate-700">
              Trip Date
            </label>
            <input
              type="date"
              value={tripDate}
              onChange={(e) => setTripDate(e.target.value)}
              disabled={loadingTrips || booking}
              className="mt-2 w-full rounded-2xl border border-slate-300 bg-white px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
            />
          </div>

          <select
            className="mt-5 w-full rounded-2xl border border-slate-300 bg-white px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
            value={selectedTripId ?? ""}
            disabled={loadingTrips || trips.length === 0 || booking}
            onChange={(e) => {
              setSelectedTripId(Number(e.target.value));
              setSelectedSeats([]);
            }}
          >
            {trips.map((t) => (
              <option key={t.id} value={t.id}>
                {t.route.start} → {t.route.end} ({formatDT(t.departureTime)})
              </option>
            ))}
          </select>

          {trips.length === 0 && !loadingTrips && (
            <div className="mt-4 text-sm text-slate-600">
              No trips found for {tripDate}.
            </div>
          )}

          {selectedTrip && (
            <div className="mt-6 bg-gradient-to-br from-indigo-50 to-blue-50 rounded-2xl p-6 border border-indigo-100 text-sm">
              <div className="font-semibold text-slate-900 text-base">
                {selectedTrip.route.start} → {selectedTrip.route.end}
              </div>

              <div className="text-slate-600 mt-1">
                Departure: {formatDT(selectedTrip.departureTime)}
              </div>

              <div className="text-slate-600 mt-1">
                Driver: {selectedTrip.driver}
              </div>

              <div className="text-slate-600">
                Seats Available:{" "}
                {loadingSeats
                  ? "Loading..."
                  : `${availableCount} / ${selectedTrip.vehicle.capacity}`}
              </div>

              <div className="mt-3 text-xl font-bold text-indigo-600">
                ৳ {selectedTrip.price} per seat
              </div>
            </div>
          )}
        </section>

        {/* RIGHT PANEL */}
        <section className="bg-white/80 backdrop-blur-md rounded-3xl border border-white shadow-xl p-8">
          <h2 className="text-xl font-semibold text-slate-900 mb-6">
            Seat Selection
          </h2>

          {loadingSeats ? (
            <div className="text-slate-600">Loading seats...</div>
          ) : (
            <div className="grid grid-cols-6 sm:grid-cols-8 md:grid-cols-10 gap-3">
              {seats.map((s) => {
                const isSelected = selectedSeats.includes(s.seatNo);
                const disabled = s.status !== "available" || booking;

                return (
                  <button
                    key={s.seatNo}
                    disabled={disabled}
                    onClick={() => toggleSeat(s.seatNo)}
                    className={`
                      h-11 rounded-2xl text-sm font-semibold border transition-all duration-200
                      ${
                        disabled
                          ? "bg-slate-200 text-slate-400 border-slate-200 cursor-not-allowed"
                          : isSelected
                          ? "bg-indigo-600 text-white border-indigo-600 shadow-lg scale-105"
                          : "bg-white border-slate-300 hover:bg-indigo-500 hover:text-white hover:border-indigo-500"
                      }
                    `}
                  >
                    {String(s.seatNo).padStart(2, "0")}
                  </button>
                );
              })}
            </div>
          )}

          <div className="mt-8 flex justify-between items-center text-sm border-t border-slate-200 pt-6">
            <div className="text-slate-700">
              Selected Seats:{" "}
              <span className="font-semibold text-slate-900">
                {selectedSeats.length ? selectedSeats.join(", ") : "None"}
              </span>
            </div>

            <div className="text-xl font-bold text-indigo-600">
              Total: ৳{" "}
              {selectedTrip ? selectedSeats.length * selectedTrip.price : 0}
            </div>
          </div>

          <div className="mt-8 grid gap-5">
            <div>
              <label className="block text-sm font-medium text-slate-700">
                Passenger Name
              </label>
              <input
                value={passengerName}
                onChange={(e) => setPassengerName(e.target.value)}
                placeholder="e.g. Kazi Badrul Hasan"
                className="mt-2 w-full rounded-2xl border border-slate-300 bg-white px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                disabled={booking}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700">
                Phone / Email
              </label>
              <input
                value={passengerContact}
                onChange={(e) => setPassengerContact(e.target.value)}
                placeholder="e.g. 017xx… or name@email.com"
                className="mt-2 w-full rounded-2xl border border-slate-300 bg-white px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition"
                disabled={booking}
              />
            </div>
          </div>

          <button
            disabled={
              booking ||
              selectedSeats.length === 0 ||
              !selectedTripId ||
              !passengerName.trim() ||
              !passengerContact.trim()
            }
            onClick={confirmBooking}
            className="mt-8 w-full rounded-2xl bg-gradient-to-r from-indigo-600 to-blue-600 text-white py-3.5 font-semibold text-base shadow-lg hover:opacity-90 transition disabled:opacity-40"
          >
            {booking ? "Booking..." : "Confirm Ticket"}
          </button>
        </section>
      </div>
    </div>
  </main>
);
}
