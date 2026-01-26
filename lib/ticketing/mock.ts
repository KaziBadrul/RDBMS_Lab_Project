// lib/ticketing/mock.ts
export type Trip = {
  id: string;
  route: { start: string; end: string; distanceKm: number };
  departureTime: string; // ISO
  arrivalTime: string; // ISO
  vehicle: { id: string; plate: string; capacity: number };
  price: number;
};

export type SeatStatus = "available" | "reserved" | "sold";

export type Seat = {
  seatNo: number;
  status: SeatStatus;
};

export const mockTrips: Trip[] = [
  {
    id: "T-1001",
    route: { start: "Gulistan", end: "Uttara", distanceKm: 18.5 },
    departureTime: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    arrivalTime: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
    vehicle: { id: "V-12", plate: "DHA-1234", capacity: 36 },
    price: 80,
  },
  {
    id: "T-1002",
    route: { start: "Dhanmondi", end: "Mirpur", distanceKm: 10.2 },
    departureTime: new Date(Date.now() + 2.5 * 60 * 60 * 1000).toISOString(),
    arrivalTime: new Date(Date.now() + 3.2 * 60 * 60 * 1000).toISOString(),
    vehicle: { id: "V-09", plate: "DHA-7788", capacity: 28 },
    price: 60,
  },
];

export function generateSeats(capacity: number, seed = 1): Seat[] {
  // deterministic-ish mock availability
  const seats: Seat[] = [];
  let x = seed * 9973;
  for (let i = 1; i <= capacity; i++) {
    x = (x * 1103515245 + 12345) % 2147483647;
    const r = x % 100;
    let status: SeatStatus = "available";
    if (r < 10) status = "sold";
    else if (r < 25) status = "reserved";
    seats.push({ seatNo: i, status });
  }
  return seats;
}
