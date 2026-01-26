import TicketingCard from "./TicketingCard";
import DriverCard from "./DriverCard";
import MaintenanceCard from "./MaintenanceCard";
import TripCard from "./TripCard";

export default function Dashboard() {
  return (
    <main className="p-8 max-w-7xl mx-auto">
      <h1 className="text-4xl font-bold text-darkRed mb-8">
        City Transportation System
      </h1>

      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <TicketingCard />
        <DriverCard />
        <MaintenanceCard />
        <TripCard />
      </div>
    </main>
  );
}
