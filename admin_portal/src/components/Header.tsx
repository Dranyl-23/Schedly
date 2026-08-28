"use client";

import { Calendar, Sun, Moon, RefreshCw } from "lucide-react";
import { format } from "date-fns";
import { useAuth } from "@/context/AuthContext";

export function Header({ title = "Analytics", onRefresh }: { title?: string; onRefresh?: () => void }) {
  const currentDateStr = `${format(new Date(), "dd.MM.yyyy")} - Today`;
  const { user } = useAuth();

  return (
    <header className="px-8 pt-8 pb-4 flex items-center justify-between">
      <div className="flex items-center gap-6">
        <h1 className="text-3xl font-black text-slate-900 tracking-tight">{title}</h1>

        <div className="hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-2xl bg-white border border-slate-200/80 text-slate-600 text-xs font-bold shadow-xs">
          <span>{currentDateStr}</span>
          <Calendar className="w-3.5 h-3.5 text-slate-400" />
        </div>
      </div>

      <div className="flex items-center gap-4">
        <div className="flex items-center p-1 rounded-full bg-white border border-slate-200/80 shadow-xs">
          <div className="p-1.5 rounded-full bg-blue-600 text-white shadow-xs">
            <Sun className="w-3.5 h-3.5" />
          </div>
          <div className="p-1.5 rounded-full text-slate-400">
            <Moon className="w-3.5 h-3.5" />
          </div>
        </div>

        {onRefresh && (
          <button
            onClick={onRefresh}
            className="p-2 rounded-2xl bg-white hover:bg-slate-50 border border-slate-200/80 text-slate-600 transition-colors shadow-xs"
            title="Refresh Data"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        )}

        {/* User Profile Pill */}
        <div className="flex items-center gap-3 pl-2">
          {user?.photoURL ? (
            <img
              src={user.photoURL}
              alt="Avatar"
              className="w-9 h-9 rounded-full object-cover border border-slate-200 shadow-sm"
            />
          ) : (
            <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 text-white flex items-center justify-center font-bold text-xs shadow-sm">
              {(user?.displayName || "A")[0].toUpperCase()}
            </div>
          )}
          <div className="hidden md:block text-left">
            <p className="text-xs font-bold text-slate-900 leading-tight">{user?.displayName || "Alfie Lynard"}</p>
            <p className="text-[10px] text-slate-400 font-mono leading-tight">{user?.email || "Admin"}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
