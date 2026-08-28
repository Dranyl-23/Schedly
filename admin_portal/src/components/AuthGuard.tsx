"use client";

import { useAuth } from "@/context/AuthContext";
import { ShieldAlert, Sparkles, Lock, ArrowRight, LogOut, CalendarCheck } from "lucide-react";

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { user, isAdmin, loading, error, loginWithGoogle, logout } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen w-full bg-[#F8FAFC] flex flex-col items-center justify-center space-y-4">
        <div className="w-16 h-16 flex items-center justify-center animate-bounce">
          <img
            src="/images/Reminda - NoBG.png"
            alt="Reminda Logo"
            className="w-full h-full object-contain drop-shadow-md"
          />
        </div>
        <p className="text-xs font-bold text-slate-500 tracking-wider uppercase">Loading Reminda Command Center...</p>
      </div>
    );
  }

  // Not logged in -> Show Google Sign In Screen
  if (!user) {
    return (
      <div className="min-h-screen w-full bg-[#F8FAFC] flex items-center justify-center p-6 selection:bg-blue-100">
        <div className="w-full max-w-md bg-white rounded-3xl border border-slate-200/80 p-8 shadow-xl shadow-slate-200/50 text-center space-y-6">
          {/* Official 3D Logo */}
          <div className="flex flex-col items-center">
            <div className="w-20 h-20 flex items-center justify-center mb-3">
              <img
                src="/images/Reminda - NoBG.png"
                alt="Reminda Official Logo"
                className="w-full h-full object-contain drop-shadow-lg"
              />
            </div>
            <h2 className="text-2xl font-black text-slate-900 tracking-tight">Reminda Admin Portal</h2>
            <p className="text-xs text-slate-500 mt-1 max-w-xs leading-relaxed">
              Sign in with your authorized Google Account to manage feedbacks, users, and AI telemetry.
            </p>
          </div>

          {/* Error notice if any (Custom Friendly Alert) */}
          {error && (
            <div className="p-3.5 rounded-2xl bg-rose-50/80 dark:bg-rose-950/40 border border-rose-200/80 dark:border-rose-800/60 text-rose-700 dark:text-rose-300 text-xs font-semibold flex items-start gap-2.5 text-left animate-in fade-in zoom-in-95 duration-200 shadow-xs">
              <ShieldAlert className="w-4 h-4 shrink-0 mt-0.5 text-rose-600 dark:text-rose-400" />
              <span className="leading-snug">{error}</span>
            </div>
          )}

          {/* Google Sign In Button */}
          <button
            onClick={loginWithGoogle}
            className="w-full py-3.5 px-6 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-sm shadow-md shadow-slate-900/20 transition-all flex items-center justify-center gap-3 group"
          >
            {/* Google Colorful G SVG */}
            <svg className="w-4 h-4" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
              />
            </svg>
            <span>Sign in with Google</span>
            <ArrowRight className="w-4 h-4 text-slate-400 group-hover:translate-x-0.5 transition-transform" />
          </button>

          {/* Admin Email Whitelist Notice */}
          <div className="pt-4 border-t border-slate-100 flex items-center justify-center gap-1.5 text-[11px] text-slate-400 font-medium">
            <Lock className="w-3.5 h-3.5 text-blue-600" />
            <span>Authorized: <strong className="text-slate-700 font-semibold">Admin only</strong></span>
          </div>
        </div>
      </div>
    );
  }

  // Logged in but not authorized
  if (!isAdmin) {
    return (
      <div className="min-h-screen w-full bg-[#F8FAFC] flex items-center justify-center p-6">
        <div className="w-full max-w-md bg-white rounded-3xl border border-slate-200 p-8 shadow-xl text-center space-y-5">
          <div className="w-14 h-14 rounded-2xl bg-red-50 text-red-600 flex items-center justify-center mx-auto">
            <ShieldAlert className="w-7 h-7" />
          </div>
          <div>
            <h3 className="text-lg font-black text-slate-900">Access Restricted</h3>
            <p className="text-xs text-slate-500 mt-1">
              You are signed in as <span className="font-bold text-slate-800">{user.email}</span>, which does not have administrator privileges.
            </p>
          </div>
          <button
            onClick={logout}
            className="w-full py-3 rounded-2xl bg-slate-900 text-white text-xs font-bold flex items-center justify-center gap-2"
          >
            <LogOut className="w-4 h-4" />
            Switch or Sign Out
          </button>
        </div>
      </div>
    );
  }

  // Authenticated as Admin
  return <>{children}</>;
}
