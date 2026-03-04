import TicketingCard from "./TicketingCard";
import DriverCard from "./DriverCard";
import MaintenanceCard from "./MaintenanceCard";
import TripCard from "./TripCard";
import AdminCard from "./AdminCard";

import Link from "next/link";
import { SessionUser } from "@/lib/auth";

export default function Dashboard({ user }: { user: SessionUser | null }) {
  const isAdmin = user?.role === "admin";

  return (
    <main className="p-8 max-w-7xl mx-auto">
      <h1 className="text-4xl font-bold text-darkRed mb-8">TripWise</h1>

      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <Link href="/ticketing">
          <TicketingCard />
        </Link>
        <Link href="/driver">
          <DriverCard />
        </Link>
        <MaintenanceCard />
        <TripCard />
        {isAdmin && (
          <Link href="/admin/pricing">
            <AdminCard />
          </Link>
        )}
      </div>
    </main>
  );
}
