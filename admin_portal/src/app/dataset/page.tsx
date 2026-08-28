"use client";

import { useEffect, useState } from "react";
import { 
  collection, 
  onSnapshot, 
  query, 
  orderBy, 
  doc, 
  updateDoc, 
  deleteDoc,
  serverTimestamp 
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { AiTrainingSample, VerifiedScheduleEntry } from "@/lib/types";
import { Header } from "@/components/Header";
import { ConfirmModal } from "@/components/ConfirmModal";
import { SkeletonCardGrid } from "@/components/Skeleton";
import { 
  Database, 
  Download, 
  Search, 
  Sparkles, 
  Edit3, 
  Trash2, 
  CheckCircle2, 
  AlertCircle, 
  FileSpreadsheet, 
  Code,
  X,
  Plus,
  Filter,
  Check
} from "lucide-react";

export default function DatasetPage() {
  const [samples, setSamples] = useState<AiTrainingSample[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedQuality, setSelectedQuality] = useState("all");
  const [editingSample, setEditingSample] = useState<AiTrainingSample | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; name: string } | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Edit State
  const [editOcrText, setEditOcrText] = useState("");
  const [editQuality, setEditQuality] = useState<"clean" | "unreviewed" | "flagged">("unreviewed");
  const [editEntries, setEditEntries] = useState<VerifiedScheduleEntry[]>([]);

  useEffect(() => {
    const q = query(collection(db, "ai_training_samples"), orderBy("timestamp", "desc"));
    const unsub = onSnapshot(q, (snap) => {
      const list: AiTrainingSample[] = [];
      snap.forEach((doc) => {
        const data = doc.data();
        list.push({ 
          id: doc.id, 
          qualityStatus: data.qualityStatus || "unreviewed",
          ...data 
        } as AiTrainingSample);
      }, (err: any) => { console.warn("Snapshot notice:", err.message); });
      setSamples(list);
      setIsLoading(false);
    });
    return () => unsub();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const openEditModal = (s: AiTrainingSample) => {
    setEditingSample(s);
    setEditOcrText(s.rawOcrText || "");
    setEditQuality(s.qualityStatus || "unreviewed");
    setEditEntries(s.verifiedEntries ? JSON.parse(JSON.stringify(s.verifiedEntries)) : []);
  };

  const handleSaveAnnotatedSample = async () => {
    if (!editingSample) return;
    try {
      await updateDoc(doc(db, "ai_training_samples", editingSample.id), {
        rawOcrText: editOcrText,
        qualityStatus: editQuality,
        verifiedEntries: editEntries,
        entriesCount: editEntries.length,
        updatedAt: serverTimestamp()
      });
      setEditingSample(null);
      showToast("Training sample annotated and updated in cloud!");
    } catch (err: any) {
      showToast("Failed to save annotation: " + err.message);
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await deleteDoc(doc(db, "ai_training_samples", deleteTarget.id));
      showToast("Blurred / corrupted sample purged from dataset.");
    } catch (err: any) {
      showToast("Delete failed: " + err.message);
    } finally {
      setDeleteTarget(null);
    }
  };

  // 1-Click JSON Exporter
  const exportJSON = (cleanOnly: boolean = false) => {
    const dataToExport = cleanOnly 
      ? samples.filter(s => s.qualityStatus !== "flagged") 
      : samples;

    const blob = new Blob([JSON.stringify(dataToExport, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `reminda_ai_dataset_${cleanOnly ? "clean_" : ""}${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    showToast(`Exported ${dataToExport.length} samples to JSON!`);
  };

  // 1-Click CSV Exporter
  const exportCSV = () => {
    const cleanSamples = samples.filter(s => s.qualityStatus !== "flagged");
    let csv = "Sample ID,Institution,Role,Platform,Entries Count,Quality Status,Raw OCR Text\n";
    cleanSamples.forEach((s) => {
      const escapedOcr = `"${(s.rawOcrText || "").replace(/"/g, '""')}"`;
      csv += `"${s.id}","${s.institutionName}","${s.role}","${s.platform}",${s.entriesCount || 0},"${s.qualityStatus || 'unreviewed'}",${escapedOcr}\n`;
    });

    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `reminda_ai_dataset_clean_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    showToast(`Exported ${cleanSamples.length} clean samples to CSV!`);
  };

  const filtered = samples.filter((s) => {
    const matchesSearch = 
      (s.institutionName || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (s.role || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (s.rawOcrText || "").toLowerCase().includes(searchQuery.toLowerCase());
    const matchesQuality = selectedQuality === "all" || (s.qualityStatus || "unreviewed") === selectedQuality;
    return matchesSearch && matchesQuality;
  });

  return (
    <>
      <Header title="AI Training Dataset & Annotation Lab" />
      <main className="flex-1 px-8 pb-12 space-y-6 max-w-[1600px] w-full">
        {/* Custom Delete Confirmation Modal */}
        <ConfirmModal
          isOpen={!!deleteTarget}
          title="Purge Training Sample?"
          message={`Are you sure you want to purge this blurred / corrupted scan telemetry from "${deleteTarget?.name}"?`}
          confirmText="Yes, Purge Sample"
          cancelText="Cancel"
          onConfirm={handleConfirmDelete}
          onCancel={() => setDeleteTarget(null)}
        />

        {/* Toast */}
        {toastMessage && (
          <div className="fixed bottom-6 right-6 z-50 px-4 py-3 rounded-2xl bg-slate-900 text-white text-xs font-bold shadow-xl flex items-center gap-2.5 animate-bounce">
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            <span>{toastMessage}</span>
          </div>
        )}

        {/* Top Header Actions */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <p className="text-xs text-slate-500 font-semibold">
              Ground-Truth Dataset Manager. Review OCR telemetry, purge blurred photos, and annotate schedule boundaries before model fine-tuning.
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              onClick={() => exportJSON(true)}
              className="px-4 py-2.5 rounded-2xl bg-white border border-slate-200/80 text-slate-800 hover:bg-slate-50 font-bold text-xs shadow-xs transition-colors flex items-center gap-2"
            >
              <Code className="w-4 h-4 text-blue-600" />
              Export Clean JSON
            </button>
            <button
              onClick={exportCSV}
              className="px-4 py-2.5 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs shadow-xs transition-colors flex items-center gap-2"
            >
              <FileSpreadsheet className="w-4 h-4" />
              Export Clean CSV
            </button>
          </div>
        </div>

        {/* Search & Quality Filter */}
        <div className="p-4 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col md:flex-row items-center gap-4">
          <div className="relative flex-1 w-full">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search dataset by school name, role, or OCR text keywords..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 rounded-2xl bg-slate-50 border border-slate-200/70 text-slate-900 text-xs placeholder-slate-400 focus:outline-none focus:border-blue-500"
            />
          </div>

          <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto">
            <button
              onClick={() => setSelectedQuality("all")}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-colors ${
                selectedQuality === "all" ? "bg-slate-900 text-white shadow-xs" : "bg-slate-100 text-slate-600 hover:bg-slate-200"
              }`}
            >
              All Samples ({samples.length})
            </button>
            <button
              onClick={() => setSelectedQuality("clean")}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-colors flex items-center gap-1.5 ${
                selectedQuality === "clean" ? "bg-emerald-600 text-white shadow-xs" : "bg-emerald-50 text-emerald-700 hover:bg-emerald-100"
              }`}
            >
              <Check className="w-3.5 h-3.5" />
              Clean & Verified
            </button>
            <button
              onClick={() => setSelectedQuality("flagged")}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-colors flex items-center gap-1.5 ${
                selectedQuality === "flagged" ? "bg-rose-600 text-white shadow-xs" : "bg-rose-50 text-rose-700 hover:bg-rose-100"
              }`}
            >
              <AlertCircle className="w-3.5 h-3.5" />
              Flagged / Blurred
            </button>
          </div>
        </div>

        {/* Dataset Samples Grid */}
        {isLoading ? (
          <SkeletonCardGrid count={6} />
        ) : filtered.length === 0 ? (
          <div className="py-20 text-center rounded-3xl bg-white border border-slate-200/70 text-slate-400 text-xs space-y-2">
            <Database className="w-10 h-10 mx-auto text-slate-300" />
            <p className="font-bold text-sm text-slate-800">No training samples found</p>
            <p className="text-slate-400">Telemetry will automatically appear here when mobile users scan schedules with MMA Spatial Parser.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filtered.map((s) => (
              <div
                key={s.id}
                className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs hover:shadow-md transition-all space-y-4"
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center font-black text-xs">
                      {s.role ? s.role.slice(0, 3).toUpperCase() : "AI"}
                    </div>
                    <div>
                      <h4 className="font-extrabold text-sm text-slate-900">{s.institutionName || "Unknown Institution"}</h4>
                      <p className="text-[11px] text-slate-500 font-medium">
                        Role: {s.role} • Platform: {s.platform || "Android"} • App: {s.appVersion || "v1.0.0"}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <span className={`px-2.5 py-1 rounded-xl text-[11px] font-bold ${
                      s.qualityStatus === "clean" 
                        ? "bg-emerald-50 text-emerald-700 border border-emerald-200" 
                        : s.qualityStatus === "flagged"
                        ? "bg-rose-50 text-rose-700 border border-rose-200"
                        : "bg-slate-100 text-slate-600"
                    }`}>
                      {s.qualityStatus === "clean" ? "Clean & Verified" : s.qualityStatus === "flagged" ? "Flagged" : "Unreviewed"}
                    </span>

                    <button
                      onClick={() => openEditModal(s)}
                      className="px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs flex items-center gap-1.5 transition-colors"
                    >
                      <Edit3 className="w-3.5 h-3.5" />
                      Annotate
                    </button>

                    <button
                      onClick={() => setDeleteTarget({ id: s.id, name: s.institutionName })}
                      className="p-2 rounded-xl text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                      title="Purge blurred sample"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Raw OCR vs Verified Schedule Entries Grid */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 text-xs">
                  {/* Raw OCR Stream */}
                  <div className="p-4 rounded-2xl bg-slate-50/80 border border-slate-200/60 space-y-2">
                    <p className="font-bold text-slate-500 uppercase tracking-wider text-[10px]">
                      Raw Spatial OCR Extracted Text
                    </p>
                    <pre className="text-[11px] text-slate-800 font-mono whitespace-pre-wrap leading-relaxed max-h-40 overflow-y-auto">
                      {s.rawOcrText || "No raw text available."}
                    </pre>
                  </div>

                  {/* Verified Schedule Ground Truth */}
                  <div className="p-4 rounded-2xl bg-blue-50/40 border border-blue-100/60 space-y-2">
                    <p className="font-bold text-blue-700 uppercase tracking-wider text-[10px]">
                      Parsed Ground-Truth Schedule ({s.verifiedEntries?.length || 0} classes)
                    </p>
                    <div className="space-y-1.5 max-h-40 overflow-y-auto">
                      {s.verifiedEntries?.map((entry, idx) => (
                        <div key={idx} className="p-2 rounded-xl bg-white border border-blue-100/80 text-[11px] flex items-center justify-between">
                          <span className="font-bold text-slate-900">{entry.title}</span>
                          <span className="text-slate-500 font-mono">{entry.startTime} - {entry.endTime} ({entry.location})</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Annotator Modal */}
        {editingSample && (
          <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="w-full max-w-2xl bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95 max-h-[90vh] overflow-y-auto">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
                    <Edit3 className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="font-extrabold text-sm text-slate-900">Annotate AI Training Sample</h3>
                    <p className="text-[11px] text-slate-400">{editingSample.institutionName} • {editingSample.role}</p>
                  </div>
                </div>
                <button onClick={() => setEditingSample(null)} className="p-1.5 rounded-xl hover:bg-slate-100 text-slate-400">
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="space-y-4 text-xs">
                {/* Quality Status Selector */}
                <div className="space-y-1">
                  <label className="font-bold text-slate-600 uppercase tracking-wider text-[10px]">Dataset Quality Tag</label>
                  <div className="grid grid-cols-3 gap-2">
                    <button
                      type="button"
                      onClick={() => setEditQuality("clean")}
                      className={`p-2.5 rounded-xl font-bold border transition-colors ${
                        editQuality === "clean" ? "bg-emerald-500 text-white border-emerald-500 shadow-xs" : "bg-slate-50 text-slate-700 border-slate-200"
                      }`}
                    >
                      Clean & High Quality
                    </button>
                    <button
                      type="button"
                      onClick={() => setEditQuality("unreviewed")}
                      className={`p-2.5 rounded-xl font-bold border transition-colors ${
                        editQuality === "unreviewed" ? "bg-slate-900 text-white border-slate-900 shadow-xs" : "bg-slate-50 text-slate-700 border-slate-200"
                      }`}
                    >
                      Unreviewed
                    </button>
                    <button
                      type="button"
                      onClick={() => setEditQuality("flagged")}
                      className={`p-2.5 rounded-xl font-bold border transition-colors ${
                        editQuality === "flagged" ? "bg-rose-500 text-white border-rose-500 shadow-xs" : "bg-slate-50 text-slate-700 border-slate-200"
                      }`}
                    >
                      Flagged / Blurred
                    </button>
                  </div>
                </div>

                {/* Edit Raw OCR Text */}
                <div className="space-y-1">
                  <label className="font-bold text-slate-600 uppercase tracking-wider text-[10px]">Corrected OCR Text Stream</label>
                  <textarea
                    rows={6}
                    value={editOcrText}
                    onChange={(e) => setEditOcrText(e.target.value)}
                    className="w-full p-3 rounded-xl bg-slate-50 border border-slate-200 font-mono text-[11px] leading-relaxed focus:outline-none focus:border-blue-500"
                  />
                </div>

                {/* Footer Buttons */}
                <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                  <button onClick={() => setEditingSample(null)} className="px-4 py-2 rounded-xl text-slate-500 hover:bg-slate-100 font-bold">
                    Cancel
                  </button>
                  <button
                    onClick={handleSaveAnnotatedSample}
                    className="px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold shadow-xs transition-colors"
                  >
                    Save Cleaned Annotation
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>
    </>
  );
}
