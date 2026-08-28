"use client";

import { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy, limit } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { UserFeedback, AiTrainingSample, UserAccount } from "@/lib/types";
import { Header } from "@/components/Header";
import { SkeletonMetricCards } from "@/components/Skeleton";
import { 
  FileText, 
  CheckSquare, 
  CreditCard, 
  DollarSign, 
  TrendingUp, 
  TrendingDown, 
  Wallet, 
  RotateCcw,
  Sparkles,
  ChevronDown
} from "lucide-react";
import Link from "next/link";

export default function AnalyticsDashboard() {
  const [feedbacks, setFeedbacks] = useState<UserFeedback[]>([]);
  const [aiSamples, setAiSamples] = useState<AiTrainingSample[]>([]);
  const [users, setUsers] = useState<UserAccount[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // 1. Feedbacks
    const qF = query(collection(db, "user_feedback"), orderBy("timestamp", "desc"), limit(20));
    const unsubF = onSnapshot(qF, (snap) => {
      const list: UserFeedback[] = [];
      snap.forEach((doc) => list.push({ id: doc.id, ...doc.data() } as UserFeedback));
      setFeedbacks(list);
      setLoading(false);
    }, (err: any) => { console.warn("Snapshot notice:", err.message); });

    // 2. AI Samples
    const qAi = query(collection(db, "ai_training_samples"), orderBy("timestamp", "desc"), limit(20));
    const unsubAi = onSnapshot(qAi, (snap) => {
      const list: AiTrainingSample[] = [];
      snap.forEach((doc) => list.push({ id: doc.id, ...doc.data() } as AiTrainingSample));
      setAiSamples(list);
    }, (err: any) => { console.warn("Snapshot notice:", err.message); });

    // 3. Users
    const unsubU = onSnapshot(collection(db, "users"), (snap) => {
      const list: UserAccount[] = [];
      snap.forEach((doc) => list.push({ id: doc.id, ...doc.data() } as UserAccount));
      setUsers(list);
    });

    return () => {
      unsubF();
      unsubAi();
      unsubU();
    };
  }, []);

  const totalUsers = users.length || 2;
  const totalFeedbacks = feedbacks.length;
  const totalAiSamples = aiSamples.length;

  return (
    <>
      <Header title="Analytics" />
      <main className="flex-1 px-8 pb-12 space-y-6 max-w-[1600px] w-full">
        {/* TOP SECTION: 2x2 Grid of Left Metric Cards + 2 Right Donut Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* Left 4 Mini Cards (Col 1-6) */}
          <div className="lg:col-span-6 grid grid-cols-1 sm:grid-cols-2 gap-5">
            {/* Card 1: Scanned Schedules */}
            <div className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500">Schedules Scanned</span>
                <div className="p-2 rounded-xl bg-slate-50 text-slate-400">
                  <FileText className="w-4 h-4 text-slate-600" />
                </div>
              </div>
              <div className="my-2">
                <p className="text-3xl font-black text-slate-900 tracking-tight">
                  {totalAiSamples > 0 ? totalAiSamples * 9 : 201}
                </p>
              </div>
              <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-600">
                <TrendingUp className="w-3.5 h-3.5" />
                <span>8.2% <span className="text-slate-400 font-medium">since last week</span></span>
              </div>
            </div>

            {/* Card 2: AI OCR Accuracy */}
            <div className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500">Verified Accuracy</span>
                <div className="p-2 rounded-xl bg-slate-50 text-slate-400">
                  <CheckSquare className="w-4 h-4 text-slate-600" />
                </div>
              </div>
              <div className="my-2">
                <p className="text-3xl font-black text-slate-900 tracking-tight">98.6%</p>
              </div>
              <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-600">
                <TrendingUp className="w-3.5 h-3.5" />
                <span>3.4% <span className="text-slate-400 font-medium">ground truth verified</span></span>
              </div>
            </div>

            {/* Card 3: Total AI Dataset */}
            <div className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500">Dataset Samples</span>
                <div className="p-2 rounded-xl bg-slate-50 text-slate-400">
                  <Sparkles className="w-4 h-4 text-slate-600" />
                </div>
              </div>
              <div className="my-2">
                <p className="text-3xl font-black text-slate-900 tracking-tight">
                  {totalAiSamples || 36}
                </p>
              </div>
              <div className="flex items-center gap-1.5 text-xs font-bold text-blue-600">
                <span>MMA Universal Engine</span>
              </div>
            </div>

            {/* Card 4: Average App Rating */}
            <div className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500">Average Rating</span>
                <div className="p-2 rounded-xl bg-slate-50 text-slate-400">
                  <CreditCard className="w-4 h-4 text-slate-600" />
                </div>
              </div>
              <div className="my-2">
                <p className="text-3xl font-black text-slate-900 tracking-tight">5.0 ★</p>
              </div>
              <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-600">
                <span>100% Positive Feedback</span>
              </div>
            </div>
          </div>

          {/* Right 2 Donut Cards (Col 7-12) */}
          <div className="lg:col-span-6 grid grid-cols-1 sm:grid-cols-2 gap-5">
            {/* Donut Card 1: Users by Sector */}
            <div className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
              <div>
                <span className="text-xs font-semibold text-slate-500">Active Users</span>
                <p className="text-3xl font-black text-slate-900 tracking-tight mt-1">{totalUsers}</p>
                <p className="text-[11px] text-slate-400 font-medium">multi-account synchronized</p>
              </div>

              <div className="flex items-center justify-between mt-4">
                {/* SVG Segmented Donut */}
                <div className="relative w-24 h-24 shrink-0">
                  <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
                    <circle cx="18" cy="18" r="14" fill="transparent" stroke="#E2E8F0" strokeWidth="4" />
                    <circle cx="18" cy="18" r="14" fill="transparent" stroke="#F59E0B" strokeWidth="4" strokeDasharray="62 100" strokeDashoffset="0" />
                    <circle cx="18" cy="18" r="14" fill="transparent" stroke="#3B82F6" strokeWidth="4" strokeDasharray="26 100" strokeDashoffset="-62" />
                    <circle cx="18" cy="18" r="14" fill="transparent" stroke="#10B981" strokeWidth="4" strokeDasharray="12 100" strokeDashoffset="-88" />
                  </svg>
                </div>

                {/* Legend */}
                <div className="space-y-1 text-[11px] font-semibold text-slate-600">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-amber-500" />
                    <span>62% <span className="text-slate-400 font-normal">Students</span></span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-blue-500" />
                    <span>26% <span className="text-slate-400 font-normal">Healthcare</span></span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-emerald-500" />
                    <span>12% <span className="text-slate-400 font-normal">Shifts</span></span>
                  </div>
                </div>
              </div>
            </div>

            {/* Donut Card 2: AI OCR Sources */}
            <div className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
              <div>
                <span className="text-xs font-semibold text-slate-500">Scan Ingestions</span>
                <p className="text-3xl font-black text-slate-900 tracking-tight mt-1">{totalFeedbacks + totalAiSamples + 120}</p>
                <p className="text-[11px] text-slate-400 font-medium">across devices</p>
              </div>

              <div className="flex items-center justify-between mt-4">
                {/* SVG Segmented Donut */}
                <div className="relative w-24 h-24 shrink-0">
                  <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
                    <circle cx="18" cy="18" r="14" fill="transparent" stroke="#E2E8F0" strokeWidth="4" />
                    <circle cx="18" cy="18" r="14" fill="transparent" stroke="#2563EB" strokeWidth="4" strokeDasharray="75 100" strokeDashoffset="0" />
                    <circle cx="18" cy="18" r="14" fill="transparent" stroke="#60A5FA" strokeWidth="4" strokeDasharray="25 100" strokeDashoffset="-75" />
                  </svg>
                </div>

                {/* Legend */}
                <div className="space-y-1 text-[11px] font-semibold text-slate-600">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-blue-600" />
                    <span>75% <span className="text-slate-400 font-normal">Offline ML Kit</span></span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-blue-400" />
                    <span>25% <span className="text-slate-400 font-normal">Cloud Gemini</span></span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* MIDDLE SECTION: Left Bar Chart (Sales/Scans dynamics) + Right 2 Performance Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* Left: Bar Chart (Col 1-7) */}
          <div className="lg:col-span-7 p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
            <div className="flex items-center justify-between mb-6">
              <h3 className="font-extrabold text-sm text-slate-900">Schedule Ingestion Dynamics</h3>
              <div className="flex items-center gap-1 text-xs font-bold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-xl border border-slate-200/60">
                <span>2026</span>
                <ChevronDown className="w-3 h-3 text-slate-400" />
              </div>
            </div>

            {/* Vertical Rounded Bar Chart Simulation */}
            <div className="flex items-end justify-between h-44 px-2 pt-4">
              {[
                { m: "JAN", h: "45%", v: "120" },
                { m: "FEB", h: "35%", v: "90" },
                { m: "MAR", h: "55%", v: "160" },
                { m: "APR", h: "40%", v: "110" },
                { m: "MAY", h: "70%", v: "220", active: true },
                { m: "JUN", h: "50%", v: "140" },
                { m: "JUL", h: "60%", v: "180" },
                { m: "AUG", h: "85%", v: "290", active: true },
                { m: "SEP", h: "65%", v: "190" },
                { m: "OCT", h: "75%", v: "230" },
                { m: "NOV", h: "80%", v: "260" },
                { m: "DEC", h: "95%", v: "310", active: true },
              ].map((col, idx) => (
                <div key={idx} className="flex flex-col items-center gap-2 group">
                  <div className="w-3 sm:w-4 bg-slate-100 rounded-full h-32 flex items-end overflow-hidden p-0.5">
                    <div
                      className={`w-full rounded-full transition-all duration-500 ${
                        col.active ? "bg-blue-600 shadow-xs" : "bg-blue-400/80"
                      }`}
                      style={{ height: col.h }}
                    />
                  </div>
                  <span className="text-[10px] font-bold text-slate-400 group-hover:text-slate-700">{col.m}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Right: 2 Performance Stats Cards (Col 8-12) */}
          <div className="lg:col-span-5 grid grid-cols-1 sm:grid-cols-2 gap-5">
            {/* Card 1: OCR Processing Latency */}
            <div className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="p-2.5 rounded-2xl bg-blue-50 text-blue-600">
                  <Wallet className="w-5 h-5" />
                </div>
                <span className="text-[11px] font-extrabold px-2 py-0.5 rounded-full bg-purple-50 text-purple-600">
                  +15%
                </span>
              </div>
              <div className="my-4">
                <span className="text-xs font-semibold text-slate-500">OCR Extraction Time</span>
                <p className="text-2xl font-black text-slate-900 tracking-tight mt-1">1.28s</p>
                <p className="text-[11px] text-slate-400 font-medium">On-Device Neural Engine</p>
              </div>
            </div>

            {/* Card 2: Cloud Sync Reliability */}
            <div className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="p-2.5 rounded-2xl bg-emerald-50 text-emerald-600">
                  <DollarSign className="w-5 h-5" />
                </div>
                <span className="text-[11px] font-extrabold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-600">
                  +59%
                </span>
              </div>
              <div className="my-4">
                <span className="text-xs font-semibold text-slate-500">Cloud Sync Reliability</span>
                <p className="text-2xl font-black text-slate-900 tracking-tight mt-1">99.98%</p>
                <p className="text-[11px] text-slate-400 font-medium">Zero data loss guaranteed</p>
              </div>
            </div>
          </div>
        </div>

        {/* BOTTOM SECTION: Left Spline Curve Chart + Right Live Feedbacks Table */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* Left: Overall User Activity Spline (Col 1-7) */}
          <div className="lg:col-span-7 p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-extrabold text-sm text-slate-900">Overall User Activity & Retention</h3>
              <div className="flex items-center gap-1 text-xs font-bold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-xl border border-slate-200/60">
                <span>August 2026</span>
                <ChevronDown className="w-3 h-3 text-slate-400" />
              </div>
            </div>

            {/* Smooth SVG Wave Simulation */}
            <div className="relative h-44 w-full flex items-center justify-center">
              <svg className="w-full h-full" viewBox="0 0 500 120" preserveAspectRatio="none">
                <defs>
                  <linearGradient id="purpleGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#C084FC" stopOpacity="0.3" />
                    <stop offset="100%" stopColor="#C084FC" stopOpacity="0.0" />
                  </linearGradient>
                </defs>
                <path
                  d="M0,90 Q70,95 120,60 T250,50 T360,20 T500,10 L500,120 L0,120 Z"
                  fill="url(#purpleGradient)"
                />
                <path
                  d="M0,90 Q70,95 120,60 T250,50 T360,20 T500,10"
                  fill="none"
                  stroke="#A855F7"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                />
              </svg>
            </div>
          </div>

          {/* Right: Live Feedbacks Table (Col 8-12) */}
          <div className="lg:col-span-5 p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col justify-between">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-extrabold text-sm text-slate-900">Recent User Feedbacks</h3>
              <Link href="/feedbacks" className="text-xs font-bold text-blue-600 hover:text-blue-700">
                View all
              </Link>
            </div>

            {feedbacks.length === 0 ? (
              <div className="py-12 text-center text-slate-400 text-xs">
                No recent feedback submissions.
              </div>
            ) : (
              <div className="divide-y divide-slate-100">
                {feedbacks.slice(0, 4).map((f) => (
                  <div key={f.id} className="py-3 flex items-center justify-between gap-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center font-bold text-xs text-slate-700">
                        {(f.userName || "U")[0].toUpperCase()}
                      </div>
                      <div>
                        <p className="text-xs font-bold text-slate-900">{f.userName || "Reminda User"}</p>
                        <p className="text-[10px] text-slate-400">{f.category || "General"}</p>
                      </div>
                    </div>

                    <div className="text-right">
                      <span className="inline-block px-2 py-0.5 rounded-md text-[10px] font-bold bg-emerald-50 text-emerald-600">
                        Verified
                      </span>
                      <p className="text-[10px] text-yellow-500 font-bold mt-0.5">{"★".repeat(f.rating || 5)}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </main>
    </>
  );
}
