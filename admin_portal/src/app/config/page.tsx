"use client";

import { useEffect, useState } from "react";
import { doc, onSnapshot, setDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { SystemAppConfig } from "@/lib/types";
import { Header } from "@/components/Header";
import { 
  Sliders, 
  Sparkles, 
  Cpu, 
  Smartphone, 
  ShieldAlert, 
  CheckCircle2, 
  Save, 
  RefreshCw,
  ExternalLink,
  Power,
  Zap,
  Check
} from "lucide-react";

export default function ConfigPage() {
  const [config, setConfig] = useState<SystemAppConfig>({
    geminiOnlineFallbackEnabled: true,
    minRequiredAppVersion: "1.0.0+8",
    latestAppVersion: "1.0.0+8",
    forceUpdateEnabled: false,
    updateStoreUrl: "https://github.com/Dranyl-23/Schedly/releases",
    maintenanceMode: false,
    maintenanceMessage: "We are performing a brief scheduled system upgrade. Offline features remain fully operational.",
  });

  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  useEffect(() => {
    const docRef = doc(db, "system_config", "app_control");
    const unsub = onSnapshot(docRef, (snap) => {
      if (snap.exists()) {
        setConfig((prev) => ({ ...prev, ...snap.data() } as SystemAppConfig));
      }
      setIsLoading(false);
    }, (err: any) => {
      console.warn("Config listener notice:", err.message);
      setIsLoading(false);
    });

    return () => unsub();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleSaveConfig = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setIsSaving(true);
      const docRef = doc(db, "system_config", "app_control");
      await setDoc(docRef, {
        ...config,
        updatedAt: serverTimestamp()
      }, { merge: true });
      showToast("App System Configuration & Feature Flags saved!");
    } catch (err: any) {
      console.error("Save config error:", err);
      showToast("Failed to save configuration: " + err.message);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <>
      <Header title="Remote App Config & Feature Flags" />
      <main className="flex-1 px-8 pb-12 space-y-6 max-w-[1400px] w-full">
        {/* Toast */}
        {toastMessage && (
          <div className="fixed bottom-6 right-6 z-50 px-4 py-3 rounded-2xl bg-slate-900 text-white text-xs font-bold shadow-xl flex items-center gap-2.5 animate-bounce">
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            <span>{toastMessage}</span>
          </div>
        )}

        {/* Top Header Information */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <p className="text-xs text-slate-500 font-semibold">
              Live Cloud Feature Flags. Instantly control AI Cloud engines, enforce minimum versions, or activate maintenance mode across all mobile devices.
            </p>
          </div>

          <button
            onClick={handleSaveConfig}
            disabled={isSaving}
            className="px-5 py-2.5 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs shadow-xs transition-colors flex items-center gap-2 disabled:opacity-50"
          >
            {isSaving ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
            Save Configuration
          </button>
        </div>

        <form onSubmit={handleSaveConfig} className="grid grid-cols-1 lg:grid-cols-2 gap-6 text-xs">
          {/* Card 1: AI Cloud Fallback Switch */}
          <div className="p-6 rounded-3xl bg-white border border-slate-200/80 shadow-xs space-y-5 flex flex-col justify-between">
            <div>
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
                  <Cpu className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-extrabold text-slate-900 text-sm">Gemini Cloud AI Engine Fallback</h3>
                  <p className="text-[11px] text-slate-500">Secondary cloud engine for handwritten notes</p>
                </div>
              </div>

              <p className="text-slate-600 text-xs leading-relaxed mb-4">
                When enabled, mobile apps will query Gemini 1.5 Flash if on-device offline OCR detects difficult handwriting. You can disable this during maintenance or to save API quota.
              </p>

              <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/70 flex items-center justify-between">
                <div>
                  <p className="font-extrabold text-slate-900 text-xs">
                    {config.geminiOnlineFallbackEnabled ? "Online Cloud AI is Active" : "Online Cloud AI is Paused"}
                  </p>
                  <p className="text-[11px] text-slate-400">
                    {config.geminiOnlineFallbackEnabled 
                      ? "Apps will use Cloud AI as fallback when offline fails." 
                      : "Apps are restricted to 100% Offline On-Device Neural Vision."}
                  </p>
                </div>

                <button
                  type="button"
                  onClick={() => setConfig({ ...config, geminiOnlineFallbackEnabled: !config.geminiOnlineFallbackEnabled })}
                  className={`px-4 py-2 rounded-xl text-xs font-extrabold transition-all flex items-center gap-1.5 ${
                    config.geminiOnlineFallbackEnabled 
                      ? "bg-indigo-600 text-white shadow-xs" 
                      : "bg-slate-200 text-slate-700"
                  }`}
                >
                  <Power className="w-3.5 h-3.5" />
                  {config.geminiOnlineFallbackEnabled ? "Enabled" : "Disabled"}
                </button>
              </div>
            </div>

            <div className="text-[11px] text-slate-400 flex items-center gap-1.5">
              <Zap className="w-3.5 h-3.5 text-amber-500" />
              <span>Offline MMA Neural Vision parser is always available on all devices regardless of this switch.</span>
            </div>
          </div>

          {/* Card 2: App Version Enforcer & Force Update */}
          <div className="p-6 rounded-3xl bg-white border border-slate-200/80 shadow-xs space-y-5 flex flex-col justify-between">
            <div>
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
                  <Smartphone className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-extrabold text-slate-900 text-sm">Version Control & Force Update</h3>
                  <p className="text-[11px] text-slate-500">Require users to upgrade to the latest release</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3 mb-3">
                <div className="space-y-1">
                  <label className="font-bold text-slate-600 uppercase tracking-wider text-[10px]">
                    Min Required Version
                  </label>
                  <input
                    type="text"
                    value={config.minRequiredAppVersion}
                    onChange={(e) => setConfig({ ...config, minRequiredAppVersion: e.target.value })}
                    className="w-full p-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono text-slate-900 font-bold focus:outline-none focus:border-blue-500"
                  />
                </div>

                <div className="space-y-1">
                  <label className="font-bold text-slate-600 uppercase tracking-wider text-[10px]">
                    Latest Release Version
                  </label>
                  <input
                    type="text"
                    value={config.latestAppVersion}
                    onChange={(e) => setConfig({ ...config, latestAppVersion: e.target.value })}
                    className="w-full p-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono text-slate-900 font-bold focus:outline-none focus:border-blue-500"
                  />
                </div>
              </div>

              <div className="space-y-1 mb-3">
                <label className="font-bold text-slate-600 uppercase tracking-wider text-[10px]">
                  Store / APK Download URL
                </label>
                <input
                  type="url"
                  value={config.updateStoreUrl}
                  onChange={(e) => setConfig({ ...config, updateStoreUrl: e.target.value })}
                  className="w-full p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 focus:outline-none focus:border-blue-500"
                />
              </div>

              <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/70 flex items-center justify-between">
                <div>
                  <p className="font-extrabold text-slate-900 text-xs">
                    {config.forceUpdateEnabled ? "Force Update Active" : "Optional Updates"}
                  </p>
                  <p className="text-[11px] text-slate-400">
                    {config.forceUpdateEnabled 
                      ? "Users on older versions are blocked until they update." 
                      : "Users on older versions can continue using the app normally."}
                  </p>
                </div>

                <button
                  type="button"
                  onClick={() => setConfig({ ...config, forceUpdateEnabled: !config.forceUpdateEnabled })}
                  className={`px-4 py-2 rounded-xl text-xs font-extrabold transition-all ${
                    config.forceUpdateEnabled 
                      ? "bg-rose-600 text-white shadow-xs" 
                      : "bg-slate-200 text-slate-700"
                  }`}
                >
                  {config.forceUpdateEnabled ? "Forcing Update" : "Disabled"}
                </button>
              </div>
            </div>
          </div>

          {/* Card 3: App-Wide Maintenance Advisory Mode */}
          <div className="p-6 rounded-3xl bg-white border border-slate-200/80 shadow-xs space-y-4 lg:col-span-2">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
                  <ShieldAlert className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-extrabold text-slate-900 text-sm">System Maintenance Mode Kill-Switch</h3>
                  <p className="text-[11px] text-slate-500">Show advisory banner across all active apps during database maintenance</p>
                </div>
              </div>

              <button
                type="button"
                onClick={() => setConfig({ ...config, maintenanceMode: !config.maintenanceMode })}
                className={`px-4 py-2 rounded-xl text-xs font-extrabold transition-all flex items-center gap-1.5 ${
                  config.maintenanceMode 
                    ? "bg-amber-500 text-white shadow-xs" 
                    : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                }`}
              >
                <Power className="w-3.5 h-3.5" />
                {config.maintenanceMode ? "Maintenance ACTIVE" : "Maintenance OFF"}
              </button>
            </div>

            <div className="space-y-1">
              <label className="font-bold text-slate-600 uppercase tracking-wider text-[10px]">
                Maintenance Banner Notice
              </label>
              <textarea
                rows={2}
                value={config.maintenanceMessage}
                onChange={(e) => setConfig({ ...config, maintenanceMessage: e.target.value })}
                className="w-full p-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 focus:outline-none focus:border-blue-500 leading-relaxed"
              />
            </div>
          </div>
        </form>
      </main>
    </>
  );
}
