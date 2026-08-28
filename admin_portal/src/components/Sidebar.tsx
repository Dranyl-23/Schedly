"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  LayoutGrid, 
  MessageSquare, 
  Database, 
  Users, 
  School,
  Megaphone,
  Sliders,
  LogOut
} from "lucide-react";
import { useAuth } from "@/context/AuthContext";

export function Sidebar() {
  const pathname = usePathname();
  const { logout } = useAuth();

  const mainNav = [
    { href: "/", label: "Analytics", icon: LayoutGrid },
    { href: "/institutions", label: "Institutions & Schools", icon: School },
    { href: "/announcements", label: "Broadcast Notices", icon: Megaphone },
    { href: "/config", label: "App Config & Flags", icon: Sliders },
    { href: "/dataset", label: "AI Dataset Lab", icon: Database },
    { href: "/feedbacks", label: "Messages & Reviews", icon: MessageSquare },
    { href: "/users", label: "Customers & Users", icon: Users },
  ];

  return (
    <aside className="w-64 bg-white border-r border-slate-200/80 flex flex-col justify-between shrink-0 select-none min-h-screen p-5 z-20 sticky top-0 h-screen">
      <div>
        {/* Brand Header */}
        <div className="flex items-center gap-3 px-2 py-3 mb-6">
          <div className="w-10 h-10 flex items-center justify-center">
            <img
              src="/images/Reminda - NoBG.png"
              alt="Reminda Logo"
              className="w-full h-full object-contain drop-shadow-sm"
            />
          </div>
          <div>
            <h1 className="font-extrabold text-lg text-slate-900 tracking-tight flex items-center gap-1.5">
              Reminda
            </h1>
            <p className="text-[11px] text-slate-500 font-semibold">Executive Portal</p>
          </div>
        </div>

        {/* Navigation Items */}
        <nav className="space-y-1.5">
          {mainNav.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3.5 px-4 py-3 rounded-2xl text-sm font-bold transition-all duration-200 ${
                  isActive
                    ? "bg-blue-50 text-blue-600 shadow-sm"
                    : "text-slate-700 hover:text-slate-900 hover:bg-slate-50"
                }`}
              >
                <Icon className={`w-5 h-5 ${isActive ? "text-blue-600" : "text-slate-600"}`} />
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* Divider */}
        <div className="my-6 border-t border-slate-100" />

        {/* Secondary Links */}
        <div className="space-y-1">
          <button
            onClick={() => logout()}
            className="w-full flex items-center gap-3.5 px-4 py-2.5 rounded-2xl text-sm font-semibold text-slate-700 hover:text-red-600 hover:bg-red-50/50 transition-colors text-left"
          >
            <LogOut className="w-5 h-5 text-slate-600" />
            Sign Out
          </button>
        </div>
      </div>

      {/* 3D Mascot Contact Support Card */}
      <div className="relative mt-8 p-4 rounded-3xl bg-gradient-to-b from-blue-50/80 to-indigo-50/50 border border-blue-100/60 overflow-hidden shadow-sm">
        <div className="relative z-10 flex flex-col items-start pr-12">
          <p className="text-[12px] font-bold text-slate-800 leading-snug">Need help?</p>
          <p className="text-[10px] text-slate-500 mb-3">Feel free to contact</p>
          <a
            href="mailto:alfielynard23@gmail.com"
            className="px-3.5 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-extrabold text-[11px] shadow-sm shadow-blue-600/20 transition-colors"
          >
            Get support
          </a>
        </div>
        <div className="absolute -right-2 -bottom-2 w-20 h-28 pointer-events-none opacity-95">
          <img
            src="/images/Friendly 3D Hoodie Mascot with Smartphone.png"
            alt="Mascot"
            className="w-full h-full object-contain"
          />
        </div>
      </div>
    </aside>
  );
}
