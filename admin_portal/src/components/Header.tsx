"use client";

import { Calendar, Sun, Moon, RefreshCw } from "lucide-react";
import { format } from "date-fns";
import { useAuth } from "@/context/AuthContext";
import { useTheme } from "@/context/ThemeContext";

export function Header({ title = "Analytics", onRefresh }: { title?: string; onRefresh?: () => void }) {
  const currentDateStr = `${format(new Date(), "dd.MM.yyyy")} - Today`;
  const { user } = useAuth();
  const { theme, toggleTheme } = useTheme();

  return (
    <header className="px-8 pt-8 pb-4 flex items-center justify-between">
      <div className="flex items-center gap-6">
        <h1 className="text-3xl font-black text-slate-900 dark:text-white tracking-tight">{title}</h1>

        <div className="hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-2xl bg-white dark:bg-[#1C1D2B] border border-slate-200/80 dark:border-[#282A3D] text-slate-700 dark:text-[#9499B0] text-xs font-bold shadow-xs">
          <span>{currentDateStr}</span>
          <Calendar className="w-3.5 h-3.5 text-slate-400 dark:text-[#6E738A]" />
        </div>
      </div>

      <div className="flex items-center gap-4">
        {/* Interactive Theme Switcher Toggle */}
        <button
          type="button"
          onClick={toggleTheme}
          className="flex items-center p-1 rounded-full bg-white dark:bg-[#1C1D2B] border border-slate-200/80 dark:border-[#282A3D] shadow-xs cursor-pointer transition-all hover:scale-105"
          title={`Switch to ${theme === "light" ? "Dark" : "Light"} mode`}
        >
          <div
            className={`p-1.5 rounded-full transition-all duration-300 ${
              theme === "light"
                ? "bg-blue-600 text-white shadow-xs"
                : "text-slate-400 dark:text-[#6E738A] hover:text-slate-600"
            }`}
          >
            <Sun className="w-3.5 h-3.5" />
          </div>
          <div
            className={`p-1.5 rounded-full transition-all duration-300 ${
              theme === "dark"
                ? "bg-blue-600 text-white shadow-xs"
                : "text-slate-400 hover:text-slate-600"
            }`}
          >
            <Moon className="w-3.5 h-3.5" />
          </div>
        </button>

        {onRefresh && (
          <button
            onClick={onRefresh}
            className="p-2 rounded-2xl bg-white dark:bg-[#1C1D2B] hover:bg-slate-50 dark:hover:bg-[#25273A] border border-slate-200/80 dark:border-[#282A3D] text-slate-600 dark:text-[#9499B0] transition-colors shadow-xs"
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
              referrerPolicy="no-referrer"
              className="w-9 h-9 rounded-full object-cover border border-slate-200 dark:border-[#282A3D] shadow-sm"
            />
          ) : (
            <div className="w-9 h-9 rounded-full bg-linear-to-tr from-blue-600 to-indigo-600 text-white flex items-center justify-center font-bold text-xs shadow-sm">
              {(user?.displayName || "A")[0].toUpperCase()}
            </div>
          )}
          <div className="hidden md:block text-left">
            <p className="text-xs font-bold text-slate-900 dark:text-white leading-tight">{user?.displayName || "Alfie Lynard"}</p>
            <p className="text-[10px] text-slate-500 dark:text-[#9499B0] font-mono leading-tight">{user?.email || "Admin"}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
