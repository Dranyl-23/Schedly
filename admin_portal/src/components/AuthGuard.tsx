"use client";

import { useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { 
  ShieldCheck, 
  HelpCircle, 
  Lock, 
  ArrowRight, 
  Users, 
  MessageSquare, 
  ShieldAlert, 
  LogOut,
  BarChart3
} from "lucide-react";

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { user, isAdmin, loading, error, loginWithGoogle, logout } = useAuth();
  const [isSigningIn, setIsSigningIn] = useState(false);
  const [showHelpModal, setShowHelpModal] = useState(false);

  const handleGoogleLogin = async () => {
    try {
      setIsSigningIn(true);
      await loginWithGoogle();
    } finally {
      setIsSigningIn(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen w-full bg-[#F4F7FB] dark:bg-[#0B0D17] flex flex-col items-center justify-center space-y-4">
        <div className="w-16 h-16 flex items-center justify-center animate-bounce">
          <img
            src="/images/Reminda - NoBG.png"
            alt="Reminda Logo"
            className="w-full h-full object-contain drop-shadow-md"
          />
        </div>
        <p className="text-xs font-black text-slate-500 tracking-wider uppercase">Loading Reminda Command Center...</p>
      </div>
    );
  }

  // Not logged in -> Show exact 1-to-1 redesigned Hero Login Portal
  if (!user) {
    return (
      <div className="min-h-screen w-full bg-[#F3F6FC] dark:bg-[#090B14] text-slate-800 dark:text-slate-100 flex flex-col justify-between selection:bg-blue-100 relative overflow-hidden font-sans">
        {/* Background Ambient Decorative Circles */}
        <div className="absolute top-[-10%] right-[-5%] w-[650px] h-[650px] rounded-full bg-blue-400/10 dark:bg-blue-600/10 blur-3xl pointer-events-none" />
        <div className="absolute bottom-[-10%] left-[-5%] w-[550px] h-[550px] rounded-full bg-indigo-400/10 dark:bg-indigo-600/10 blur-3xl pointer-events-none" />
        <div className="absolute top-[35%] left-[35%] w-[450px] h-[450px] rounded-full bg-blue-300/15 dark:bg-blue-500/5 blur-2xl pointer-events-none" />

        {/* 1. TOP NAVBAR */}
        <header className="max-w-[1520px] w-full mx-auto px-6 sm:px-12 pt-6 sm:pt-8 flex items-center justify-between z-10">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 flex items-center justify-center shrink-0">
              <img
                src="/images/Reminda - NoBG.png"
                alt="Reminda Logo"
                className="w-full h-full object-contain drop-shadow-sm"
              />
            </div>
            <div>
              <span className="font-black text-xl text-slate-900 dark:text-white tracking-tight leading-none block">
                Reminda
              </span>
              <span className="font-extrabold text-xs text-blue-600 dark:text-blue-400 tracking-tight leading-none block mt-0.5">
                Admin Portal
              </span>
            </div>
          </div>

          <div className="flex items-center gap-4 sm:gap-6">
            <div className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-blue-50 dark:bg-blue-950/60 border border-blue-200/80 dark:border-blue-800/60 text-blue-700 dark:text-blue-300 text-xs font-bold shadow-2xs">
              <ShieldCheck className="w-3.5 h-3.5 text-blue-600 dark:text-blue-400" />
              <span>Admin Access Only</span>
            </div>

            <button
              onClick={() => setShowHelpModal(true)}
              className="flex items-center gap-1.5 text-xs font-bold text-slate-600 dark:text-slate-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer"
            >
              <HelpCircle className="w-4 h-4 text-slate-400" />
              <span className="hidden sm:inline">Need Help?</span>
            </button>
          </div>
        </header>

        {/* 2. HERO MAIN CONTAINER */}
        <main className="max-w-[1520px] w-full mx-auto px-6 sm:px-12 py-6 sm:py-8 my-auto grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-center z-10">
          {/* Left Column: Headline & Action Buttons (5 Cols) */}
          <div className="lg:col-span-5 space-y-6 max-w-lg mx-auto lg:mx-0 text-left">
            {/* Welcome Admin Tag */}
            <div className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-blue-50 dark:bg-blue-950/70 border border-blue-100 dark:border-blue-900/60 text-blue-600 dark:text-blue-400 text-xs font-extrabold shadow-2xs">
              <span>Welcome Admin 👋</span>
            </div>

            {/* Main Title */}
            <div className="space-y-1">
              <h1 className="text-4xl sm:text-5xl font-black text-slate-900 dark:text-white tracking-tight leading-[1.1]">
                Reminda
              </h1>
              <h1 className="text-4xl sm:text-5xl font-black text-blue-600 dark:text-blue-500 tracking-tight leading-[1.1]">
                Admin Portal
              </h1>
            </div>

            {/* Subtitle */}
            <p className="text-sm sm:text-base text-slate-600 dark:text-slate-400 leading-relaxed font-medium">
              Manage feedbacks, users, and AI telemetry with secure and seamless access.
            </p>

            {/* Error Banner if any */}
            {error && (
              <div className="p-3.5 rounded-2xl bg-rose-50 dark:bg-rose-950/50 border border-rose-200 dark:border-rose-800 text-rose-700 dark:text-rose-300 text-xs font-semibold flex items-start gap-2.5 shadow-2xs">
                <ShieldAlert className="w-4 h-4 shrink-0 mt-0.5 text-rose-600 dark:text-rose-400" />
                <span className="leading-snug">{error}</span>
              </div>
            )}

            {/* Sign in with Google Button */}
            <div className="space-y-4 pt-1">
              <button
                onClick={handleGoogleLogin}
                disabled={isSigningIn}
                className="w-full py-4 px-6 rounded-2xl bg-[#0B132B] dark:bg-[#0F172A] hover:bg-[#1C2541] dark:hover:bg-[#1E293B] text-white font-semibold text-sm shadow-xl shadow-slate-900/15 hover:shadow-2xl hover:shadow-blue-900/20 active:scale-[0.99] transition-all flex items-center justify-between group cursor-pointer disabled:opacity-75"
              >
                <div className="flex items-center gap-3.5">
                  <div className="w-7 h-7 rounded-full bg-white flex items-center justify-center shrink-0 shadow-2xs">
                    <svg className="w-4 h-4" viewBox="0 0 24 24">
                      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" />
                      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" />
                    </svg>
                  </div>
                  <span className="text-[14.5px] font-semibold text-white tracking-normal antialiased">
                    {isSigningIn ? "Authorizing Google Session..." : "Sign in with Google"}
                  </span>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:translate-x-1 transition-transform" />
              </button>

              {/* Or Divider */}
              <div className="flex items-center gap-3 py-0.5">
                <div className="flex-1 h-px bg-slate-200/80 dark:bg-slate-800" />
                <span className="text-xs font-medium text-slate-400 dark:text-slate-500 uppercase tracking-wider">or</span>
                <div className="flex-1 h-px bg-slate-200/80 dark:bg-slate-800" />
              </div>

              {/* Authorized Admin Only Security Card */}
              <div className="p-4 rounded-2xl bg-white/90 dark:bg-[#151726]/80 backdrop-blur-md border border-slate-200/80 dark:border-[#282A3D] flex items-center gap-3.5 shadow-2xs">
                <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-950/80 border border-blue-100 dark:border-blue-900/60 flex items-center justify-center text-blue-600 dark:text-blue-400 shrink-0">
                  <Lock className="w-4 h-4 stroke-[2.2]" />
                </div>
                <div className="space-y-0.5 text-left">
                  <p className="text-xs font-bold text-slate-900 dark:text-white antialiased">
                    Authorized: <span className="text-blue-600 dark:text-blue-400 font-bold">Admin only</span>
                  </p>
                  <p className="text-[11.5px] text-slate-500 dark:text-slate-400 font-normal leading-normal antialiased">
                    This portal is restricted to authorized administrators.
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: High-Res 3D Isometric Dashboard Graphic (7 Cols) */}
          <div className="lg:col-span-7 relative flex items-center justify-center">
            {/* Dashboard High-Res 3D Graphic */}
            <div className="relative w-full max-w-[760px] transform hover:scale-[1.02] transition-transform duration-500 drop-shadow-2xl">
              <img
                src="/images/Dashboard.png"
                alt="Reminda Executive Dashboard Preview"
                className="w-full h-auto object-contain rounded-2xl"
              />
            </div>
          </div>
        </main>

        {/* 3. BOTTOM 4-COLUMN FEATURE HIGHLIGHTS STRIP */}
        <footer className="max-w-[1520px] w-full mx-auto px-6 sm:px-12 pb-8 z-10 space-y-6">
          <div className="py-5 px-6 sm:px-8 rounded-3xl bg-white/90 dark:bg-[#151726]/85 backdrop-blur-md border border-slate-200/80 dark:border-[#282A3D] shadow-sm grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 items-center">
            {/* Col 1: Secure Access */}
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-950/80 border border-blue-100 dark:border-blue-900/60 text-blue-600 dark:text-blue-400 flex items-center justify-center shrink-0 shadow-2xs">
                <ShieldCheck className="w-5 h-5 stroke-[2]" />
              </div>
              <div className="space-y-0.5 text-left">
                <h4 className="font-bold text-[13.5px] text-slate-900 dark:text-white tracking-tight antialiased">
                  Secure Access
                </h4>
                <p className="text-[12px] text-slate-500 dark:text-slate-400 font-normal leading-normal antialiased">
                  Google authentication for authorized admins.
                </p>
              </div>
            </div>

            {/* Col 2: User Management */}
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-950/80 border border-blue-100 dark:border-blue-900/60 text-blue-600 dark:text-blue-400 flex items-center justify-center shrink-0 shadow-2xs">
                <Users className="w-5 h-5 stroke-[2]" />
              </div>
              <div className="space-y-0.5 text-left">
                <h4 className="font-bold text-[13.5px] text-slate-900 dark:text-white tracking-tight antialiased">
                  User Management
                </h4>
                <p className="text-[12px] text-slate-500 dark:text-slate-400 font-normal leading-normal antialiased">
                  Manage and monitor all platform users.
                </p>
              </div>
            </div>

            {/* Col 3: Feedback Insights */}
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-950/80 border border-blue-100 dark:border-blue-900/60 text-blue-600 dark:text-blue-400 flex items-center justify-center shrink-0 shadow-2xs">
                <MessageSquare className="w-5 h-5 stroke-[2]" />
              </div>
              <div className="space-y-0.5 text-left">
                <h4 className="font-bold text-[13.5px] text-slate-900 dark:text-white tracking-tight antialiased">
                  Feedback Insights
                </h4>
                <p className="text-[12px] text-slate-500 dark:text-slate-400 font-normal leading-normal antialiased">
                  Track and analyze feedback in real-time.
                </p>
              </div>
            </div>

            {/* Col 4: AI Telemetry */}
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-950/80 border border-blue-100 dark:border-blue-900/60 text-blue-600 dark:text-blue-400 flex items-center justify-center shrink-0 shadow-2xs">
                <BarChart3 className="w-5 h-5 stroke-[2]" />
              </div>
              <div className="space-y-0.5 text-left">
                <h4 className="font-bold text-[13.5px] text-slate-900 dark:text-white tracking-tight antialiased">
                  AI Telemetry
                </h4>
                <p className="text-[12px] text-slate-500 dark:text-slate-400 font-normal leading-normal antialiased">
                  Monitor AI performance and system telemetry.
                </p>
              </div>
            </div>
          </div>

          {/* Copyright Sub-footer */}
          <div className="text-center text-xs text-slate-400 dark:text-slate-500 font-normal antialiased">
            © 2026 <strong className="text-slate-700 dark:text-slate-300 font-semibold">Reminda Admin Portal</strong>. All rights reserved.
          </div>
        </footer>

        {/* Optional Help Dialog */}
        {showHelpModal && (
          <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
            <div className="w-full max-w-sm bg-white dark:bg-[#1C1D2B] rounded-3xl p-6 shadow-2xl border border-slate-200 dark:border-[#282A3D] space-y-4">
              <div className="flex items-center gap-2.5 text-blue-600">
                <HelpCircle className="w-5 h-5" />
                <h3 className="font-black text-sm text-slate-900 dark:text-white">Need Help Signing In?</h3>
              </div>
              <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
                Access to the Reminda Command Center is strictly limited to authorized administrator email addresses.
                Please ensure you sign in with your approved Google Administrator account.
              </p>
              <button
                onClick={() => setShowHelpModal(false)}
                className="w-full py-2.5 rounded-xl bg-slate-900 dark:bg-blue-600 text-white text-xs font-bold"
              >
                Close
              </button>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Logged in but not authorized as admin
  if (!isAdmin) {
    return (
      <div className="min-h-screen w-full bg-[#F3F6FC] dark:bg-[#090B14] flex items-center justify-center p-6 font-sans">
        <div className="w-full max-w-md bg-white dark:bg-[#151726] rounded-3xl border border-slate-200 dark:border-[#282A3D] p-8 shadow-2xl text-center space-y-5">
          <div className="w-14 h-14 rounded-2xl bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center mx-auto border border-rose-200 dark:border-rose-800/60">
            <ShieldAlert className="w-7 h-7" />
          </div>
          <div>
            <h3 className="text-lg font-black text-slate-900 dark:text-white">Access Restricted</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1.5 leading-relaxed">
              You are signed in as <span className="font-bold text-slate-800 dark:text-slate-200">{user.email}</span>, which does not have administrator privileges.
            </p>
          </div>
          <button
            onClick={logout}
            className="w-full py-3.5 rounded-2xl bg-slate-900 dark:bg-blue-600 hover:bg-slate-800 text-white text-xs font-bold flex items-center justify-center gap-2 shadow-md transition-all cursor-pointer"
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
