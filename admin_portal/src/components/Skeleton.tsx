"use client";

import React from "react";

// 1. Single Shimmer Bar
export function Skeleton({ className = "" }: { className?: string }) {
  return (
    <div
      className={`animate-pulse rounded-xl bg-slate-200/80 ${className}`}
    />
  );
}

// 2. Full Page / Section Loading Spinner
export function LoadingSpinner({
  label = "Syncing live cloud data...",
  className = "",
}: {
  label?: string;
  className?: string;
}) {
  return (
    <div className={`flex flex-col items-center justify-center p-12 space-y-3 text-slate-400 ${className}`}>
      <div className="relative">
        <div className="w-10 h-10 rounded-full border-2 border-blue-100 border-t-blue-600 animate-spin" />
      </div>
      <p className="text-xs font-bold text-slate-500 animate-pulse">{label}</p>
    </div>
  );
}

// 3. Skeleton Table for Users & List views
export function SkeletonTable({ rows = 5 }: { rows?: number }) {
  return (
    <div className="rounded-3xl bg-white border border-slate-200/70 shadow-xs overflow-hidden">
      <div className="p-4 bg-slate-50/80 border-b border-slate-200/70 flex items-center justify-between">
        <Skeleton className="h-4 w-32" />
        <Skeleton className="h-4 w-20" />
      </div>
      <div className="divide-y divide-slate-100 p-2 space-y-2">
        {Array.from({ length: rows }).map((_, i) => (
          <div key={i} className="flex items-center justify-between p-3.5 space-x-4 animate-pulse">
            <div className="flex items-center gap-3 flex-1">
              <Skeleton className="w-9 h-9 rounded-full shrink-0" />
              <div className="space-y-1.5 flex-1">
                <Skeleton className="h-3.5 w-1/3" />
                <Skeleton className="h-2.5 w-1/4" />
              </div>
            </div>
            <Skeleton className="h-3.5 w-1/4 hidden md:block" />
            <Skeleton className="h-6 w-20 rounded-lg hidden sm:block" />
            <Skeleton className="h-7 w-24 rounded-xl" />
          </div>
        ))}
      </div>
    </div>
  );
}

// 4. Skeleton Card Grid for Institutions, Announcements, Dataset
export function SkeletonCardGrid({ count = 8 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="p-5 rounded-3xl bg-white border border-slate-200/70 shadow-xs space-y-3.5 animate-pulse"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Skeleton className="w-11 h-11 rounded-2xl shrink-0" />
              <div className="space-y-1.5">
                <Skeleton className="h-3.5 w-24" />
                <Skeleton className="h-2.5 w-16" />
              </div>
            </div>
            <Skeleton className="w-6 h-6 rounded-lg" />
          </div>

          <div className="space-y-2 pt-2 border-t border-slate-100">
            <Skeleton className="h-3 w-full" />
            <Skeleton className="h-3 w-3/4" />
          </div>

          <div className="flex items-center justify-between pt-2">
            <Skeleton className="h-5 w-16 rounded-md" />
            <Skeleton className="h-7 w-20 rounded-xl" />
          </div>
        </div>
      ))}
    </div>
  );
}

// 5. Skeleton Stats Grid
export function SkeletonMetricCards({ count = 4 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="p-5 rounded-3xl bg-white border border-slate-200/70 shadow-xs space-y-2.5 animate-pulse"
        >
          <div className="flex items-center justify-between">
            <Skeleton className="h-3 w-20" />
            <Skeleton className="w-8 h-8 rounded-xl" />
          </div>
          <Skeleton className="h-7 w-24" />
          <Skeleton className="h-2.5 w-32" />
        </div>
      ))}
    </div>
  );
}
