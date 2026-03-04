import TicketingCard from "./TicketingCard";
import DriverCard from "./DriverCard";
import MaintenanceCard from "./MaintenanceCard";
import TripCard from "./TripCard";
import AdminCard from "./AdminCard";
import MyTicketsCard from "./MyTicketsCard";

import Link from "next/link";
import { SessionUser } from "@/lib/auth";

export default function Dashboard({ user }: { user: SessionUser | null }) {
  const isAdmin = user?.role === "admin";

  return (
    <div className="min-h-screen bg-[#F6F8FB] flex font-sans antialiased text-slate-900">

      {/* Sidebar: Inspiration-styled navigation */}
      <aside className="hidden md:flex w-64 bg-white border-r border-slate-100 p-8 flex-col sticky top-0 h-screen">
        <div className="flex items-center gap-3 mb-12">
          <div className="h-9 w-9 bg-blue-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-200">
             <span className="text-white font-bold text-lg italic">T</span>
          </div>
          <h1 className="text-xl font-black tracking-tight text-slate-800">
            TripWise
          </h1>
        </div>

        <nav className="space-y-3">
          <div className="flex items-center gap-3 px-5 py-3 rounded-xl bg-blue-50 text-blue-600 font-bold shadow-sm">
            <div className="h-1.5 w-1.5 rounded-full bg-blue-600" />
            Dashboard
          </div>
        </nav>
      </aside>

      {/* Main Area */}
      <main className="flex-1 px-8 md:px-12 py-10">

        {/* Header: Clean & Modern */}
        <div className="flex items-center justify-between mb-12">
          <div>
            <h2 className="text-3xl font-bold tracking-tight text-slate-800">
              Dashboard
            </h2>
            {user && (
              <p className="text-slate-400 mt-1 text-sm font-medium capitalize">
                {user.role} Management
              </p>
            )}
          </div>

          {/* Profile Badge: Inspiration-styled */}
          {user && (
            <div className="flex items-center gap-3 bg-white pl-1.5 pr-5 py-1.5 rounded-full border border-slate-100 shadow-sm">
              <div className="h-9 w-9 rounded-full bg-slate-800 flex items-center justify-center text-white text-xs font-bold uppercase">
                {user.role.charAt(0)}
              </div>
              <p className="text-sm font-bold capitalize text-slate-700">
                {user.role}
              </p>
            </div>
          )}
        </div>

        {/* Cards Grid: Restored to your original functional layout */}
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">

          <Link href="/ticketing" className="group transition-all duration-300 hover:-translate-y-2">
            <div className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] group-hover:shadow-[0_20px_50px_rgba(0,0,0,0.08)] transition-shadow duration-300">
              <TicketingCard />
            </div>
          </Link>

          <Link href="/driver" className="group transition-all duration-300 hover:-translate-y-2">
            <div className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] group-hover:shadow-[0_20px_50px_rgba(0,0,0,0.08)] transition-shadow duration-300">
              <DriverCard />
            </div>
          </Link>

          <div className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_20px_50px_rgba(0,0,0,0.08)] hover:-translate-y-2 transition-all duration-300">
            <MaintenanceCard />
          </div>

          <div className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_20px_50px_rgba(0,0,0,0.08)] hover:-translate-y-2 transition-all duration-300">
            <TripCard />
          </div>

          <Link href="/my-tickets" className="group transition-all duration-300 hover:-translate-y-2">
            <div className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] group-hover:shadow-[0_20px_50_rgba(0,0,0,0.08)] transition-shadow duration-300">
              <MyTicketsCard />
            </div>
          </Link>

          {isAdmin && (
            <Link href="/admin/pricing" className="group transition-all duration-300 hover:-translate-y-2">
              <div className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] group-hover:shadow-[0_20px_50_rgba(0,0,0,0.08)] transition-shadow duration-300">
                <AdminCard />
              </div>
            </Link>
          )}

        </div>

      </main>
    </div>
  );
}