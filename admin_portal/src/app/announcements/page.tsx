"use client";

import { createPortal } from "react-dom";

import { useEffect, useState } from "react";
import { 
  collection, 
  onSnapshot, 
  query, 
  orderBy, 
  doc, 
  setDoc, 
  deleteDoc, 
  updateDoc,
  serverTimestamp 
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Announcement } from "@/lib/types";
import { Header } from "@/components/Header";
import { ConfirmModal } from "@/components/ConfirmModal";
import { CustomDropdown } from "@/components/CustomDropdown";
import { SkeletonCardGrid } from "@/components/Skeleton";
import { 
  Megaphone, 
  Plus, 
  Trash2, 
  Edit3, 
  CheckCircle2, 
  AlertTriangle, 
  Info, 
  Sparkles, 
  Flame, 
  X, 
  ExternalLink,
  Smartphone,
  Eye,
  Radio
} from "lucide-react";

export default function AnnouncementsPage() {
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  useEffect(() => {
    if (isModalOpen) document.body.style.overflow = "hidden";
    else document.body.style.overflow = "";
    return () => { document.body.style.overflow = ""; };
  }, [isModalOpen]);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [deleteTargetId, setDeleteTargetId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Form State
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [type, setType] = useState<"info" | "warning" | "urgent" | "promo">("info");
  const [isActive, setIsActive] = useState(true);
  const [actionLabel, setActionLabel] = useState("");
  const [actionUrl, setActionUrl] = useState("");

  useEffect(() => {
    const q = query(collection(db, "announcements"), orderBy("createdAt", "desc"));
    const unsub = onSnapshot(q, (snap) => {
      const list: Announcement[] = [];
      snap.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() } as Announcement);
      }, (err: any) => { console.warn("Snapshot notice:", err.message); });
      setAnnouncements(list);
      setIsLoading(false);
    });
    return () => unsub();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const openAddModal = () => {
    setEditingId(null);
    setTitle("");
    setMessage("");
    setType("info");
    setIsActive(true);
    setActionLabel("");
    setActionUrl("");
    setIsModalOpen(true);
  };

  const openEditModal = (item: Announcement) => {
    setEditingId(item.id);
    setTitle(item.title);
    setMessage(item.message);
    setType(item.type || "info");
    setIsActive(item.isActive ?? true);
    setActionLabel(item.actionLabel || "");
    setActionUrl(item.actionUrl || "");
    setIsModalOpen(true);
  };

  const handleToggleActive = async (id: string, currentStatus: boolean) => {
    try {
      await updateDoc(doc(db, "announcements", id), {
        isActive: !currentStatus,
        updatedAt: serverTimestamp()
      });
      showToast(!currentStatus ? "Broadcast turned ON (Live on mobile apps)" : "Broadcast turned OFF (Archived)");
    } catch (err: any) {
      showToast("Error updating status: " + err.message);
    }
  };

  const handleSaveAnnouncement = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !message.trim()) {
      showToast("Please provide both an announcement title and message.");
      return;
    }

    try {
      const docId = editingId || `notice-${Date.now().toString().slice(-6)}`;
      const docRef = doc(db, "announcements", docId);

      await setDoc(docRef, {
        title: title.trim(),
        message: message.trim(),
        type,
        isActive,
        actionLabel: actionLabel.trim(),
        actionUrl: actionUrl.trim(),
        updatedAt: serverTimestamp(),
        createdAt: serverTimestamp()
      }, { merge: true });

      setIsModalOpen(false);
      showToast(editingId ? "Announcement updated successfully!" : "Announcement is now LIVE on all users' Home screens!");
    } catch (err: any) {
      console.error("Save error:", err);
      showToast("Failed to save: " + err.message);
    }
  };

  const handleDeleteAnnouncement = async () => {
    if (!deleteTargetId) return;
    try {
      await deleteDoc(doc(db, "announcements", deleteTargetId));
      showToast("Announcement permanently deleted.");
    } catch (err: any) {
      showToast("Delete failed: " + err.message);
    } finally {
      setDeleteTargetId(null);
    }
  };

  const getTypeStyle = (t: string) => {
    switch (t) {
      case "warning":
        return { bg: "bg-amber-50 border-amber-200 text-amber-800", icon: AlertTriangle, badge: "bg-amber-100 text-amber-800" };
      case "urgent":
        return { bg: "bg-rose-50 border-rose-200 text-rose-800", icon: Flame, badge: "bg-rose-100 text-rose-800" };
      case "promo":
        return { bg: "bg-indigo-50 border-indigo-200 text-indigo-800", icon: Sparkles, badge: "bg-indigo-100 text-indigo-800" };
      default:
        return { bg: "bg-blue-50 border-blue-200 text-blue-800", icon: Info, badge: "bg-blue-100 text-blue-800" };
    }
  };

  return (
    <>
      <Header title="Broadcast Notices & Announcements" />
      <main className="flex-1 px-8 pb-12 space-y-6 max-w-[1600px] w-full">
        {/* Custom Delete Confirmation Modal */}
        <ConfirmModal
          isOpen={!!deleteTargetId}
          title="Delete Announcement?"
          message="Are you sure you want to delete this broadcast notice? It will disappear immediately from all mobile home screens."
          confirmText="Yes, Delete Announcement"
          cancelText="Cancel"
          onConfirm={handleDeleteAnnouncement}
          onCancel={() => setDeleteTargetId(null)}
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
            <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold flex items-center gap-2">
              <Radio className="w-4 h-4 text-emerald-500 animate-pulse" />
              <span>Realtime In-App Banner Broadcaster. Any active notices appear immediately at the top of users&apos; Home screens.</span>
            </p>
          </div>

          <button
            onClick={openAddModal}
            className="px-4 py-2.5 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs shadow-xs transition-colors flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            Create Announcement
          </button>
        </div>

        {/* Announcements List */}
        {isLoading ? (
          <SkeletonCardGrid count={4} />
        ) : announcements.length === 0 ? (
          <div className="py-20 text-center rounded-3xl bg-white dark:bg-[#1C1D2B] border border-slate-200 dark:border-[#282A3D]/70 dark:border-[#282A3D] text-slate-400 text-xs space-y-3">
            <Megaphone className="w-10 h-10 mx-auto text-slate-300" />
            <p className="font-semibold text-slate-800 dark:text-slate-200 text-sm">No announcements broadcasted yet</p>
            <p className="text-slate-400">Post advisories, maintenance news, or feature updates to all mobile users.</p>
            <button
              onClick={openAddModal}
              className="px-4 py-2 rounded-xl bg-blue-600 text-white font-bold text-xs inline-flex items-center gap-1.5 mt-2"
            >
              <Plus className="w-3.5 h-3.5" />
              Create First Announcement
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
            {announcements.map((item) => {
              const style = getTypeStyle(item.type);
              const Icon = style.icon;

              return (
                <div
                  key={item.id}
                  className={`p-6 rounded-3xl border transition-all ${
                    item.isActive 
                      ? "bg-white border-slate-200 dark:border-[#282A3D]/90 shadow-sm" 
                      : "bg-slate-50 dark:bg-[#25273A]/60/60 border-slate-200 dark:border-[#282A3D]/50 opacity-75"
                  }`}
                >
                  <div className="flex items-start justify-between gap-3 mb-3">
                    <div className="flex items-center gap-2.5">
                      <span className={`px-2.5 py-1 rounded-xl text-[11px] font-bold flex items-center gap-1.5 ${style.badge}`}>
                        <Icon className="w-3.5 h-3.5" />
                        {item.type.toUpperCase()}
                      </span>

                      {item.isActive ? (
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping" />
                          Live on Mobile
                        </span>
                      ) : (
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-slate-100 dark:bg-[#25273A] text-slate-500 dark:text-slate-400">
                          Inactive / Draft
                        </span>
                      )}
                    </div>

                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => openEditModal(item)}
                        className="p-1.5 rounded-xl hover:bg-slate-100 dark:bg-[#25273A] text-slate-500 dark:text-slate-400 transition-colors"
                        title="Edit Announcement"
                      >
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => setDeleteTargetId(item.id)}
                        className="p-1.5 rounded-xl hover:bg-red-50 text-slate-400 hover:text-red-600 transition-colors"
                        title="Delete Announcement"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  <h3 className="font-extrabold text-slate-900 dark:text-white text-sm mb-1.5">{item.title}</h3>
                  <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed whitespace-pre-wrap mb-4">{item.message}</p>

                  {/* Actions & Preview Footer */}
                  <div className="flex items-center justify-between pt-3 border-t border-slate-100 dark:border-[#282A3D] text-xs">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleToggleActive(item.id, item.isActive)}
                        className={`px-3 py-1.5 rounded-xl text-[11px] font-bold transition-colors ${
                          item.isActive
                            ? "bg-slate-100 dark:bg-[#25273A] hover:bg-slate-200 text-slate-700 dark:text-slate-300"
                            : "bg-emerald-600 hover:bg-emerald-700 text-white shadow-xs"
                        }`}
                      >
                        {item.isActive ? "Pause Broadcast" : "Broadcast Now"}
                      </button>

                      {item.actionLabel && (
                        <span className="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-[#25273A] text-slate-600 dark:text-slate-400 font-bold text-[10px] flex items-center gap-1">
                          Button: {item.actionLabel}
                        </span>
                      )}
                    </div>

                    <span className="text-[10px] text-slate-400 font-mono">
                      ID: {item.id}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Create / Edit Modal */}
        {isModalOpen && typeof document !== "undefined" && createPortal(
          <div className="fixed inset-0 z-[9999] bg-black/70 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto animate-in fade-in duration-150">
            <div className="w-full max-w-lg bg-white dark:bg-[#1C1D2B] rounded-3xl p-6 shadow-2xl border border-slate-200 dark:border-[#282A3D] space-y-4 animate-in fade-in zoom-in-95 max-h-[90vh] overflow-y-auto">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-[#282A3D]">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
                    <Megaphone className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="font-extrabold text-sm text-slate-900 dark:text-white">
                      {editingId ? "Edit Announcement" : "Create In-App Announcement"}
                    </h3>
                    <p className="text-[11px] text-slate-400">Broadcasts directly to Reminda home screens</p>
                  </div>
                </div>
                <button
                  onClick={() => setIsModalOpen(false)}
                  className="p-1.5 rounded-xl hover:bg-slate-100 dark:bg-[#25273A] text-slate-400"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <form onSubmit={handleSaveAnnouncement} className="space-y-4 text-xs">
                {/* Title */}
                <div className="space-y-1">
                  <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                    Banner Headline / Title *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Reminda v1.0.1 Update Released!"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white font-bold focus:outline-none focus:border-blue-500"
                  />
                </div>

                {/* Message */}
                <div className="space-y-1">
                  <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                    Message / Advisory Content *
                  </label>
                  <textarea
                    rows={4}
                    required
                    placeholder="e.g. We have upgraded the Offline Neural Vision scanner for 3x faster timetable parsing."
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white leading-relaxed focus:outline-none focus:border-blue-500"
                  />
                </div>

                {/* Type & Broadcast Status */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                      Notice Priority / Type
                    </label>
                    <CustomDropdown
                      value={type}
                      onChange={(val) => setType(val as any)}
                      options={[
                        { value: "info", label: "Information (Blue)" },
                        { value: "warning", label: "Advisory / Maintenance (Amber)" },
                        { value: "urgent", label: "Urgent / Critical (Red)" },
                        { value: "promo", label: "Feature Release (Indigo)" },
                      ]}
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                      Broadcast Status
                    </label>
                    <CustomDropdown
                      value={isActive ? "active" : "draft"}
                      onChange={(val) => setIsActive(val === "active")}
                      options={[
                        { value: "active", label: "Live Broadcast (Visible in App)" },
                        { value: "draft", label: "Save as Draft (Hidden)" },
                      ]}
                    />
                  </div>
                </div>

                {/* Action Button (Optional) */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                      Action Button Text (Optional)
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Learn More or Update App"
                      value={actionLabel}
                      onChange={(e) => setActionLabel(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white focus:outline-none"
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                      Action Web / Store URL (Optional)
                    </label>
                    <input
                      type="url"
                      placeholder="https://..."
                      value={actionUrl}
                      onChange={(e) => setActionUrl(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white focus:outline-none"
                    />
                  </div>
                </div>

                {/* Live Mobile In-App Preview */}
                <div className="p-3.5 rounded-2xl bg-slate-100 dark:bg-[#25273A] border border-slate-200 dark:border-[#282A3D] space-y-1.5">
                  <p className="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider flex items-center gap-1">
                    <Smartphone className="w-3.5 h-3.5 text-slate-400" />
                    Live Mobile Banner Preview
                  </p>
                  <div className={`p-3 rounded-xl border text-xs ${getTypeStyle(type).bg}`}>
                    <p className="font-extrabold text-slate-900 dark:text-white">{title || "Your Announcement Title Here"}</p>
                    <p className="text-[11px] text-slate-700 dark:text-slate-300 mt-0.5">{message || "Your message will appear here for all users in the mobile app."}</p>
                    {actionLabel && (
                      <span className="inline-block mt-2 px-2.5 py-1 rounded-lg bg-slate-900 text-white font-bold text-[10px]">
                        {actionLabel}
                      </span>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100 dark:border-[#282A3D]">
                  <button
                    type="button"
                    onClick={() => setIsModalOpen(false)}
                    className="px-4 py-2 rounded-xl text-slate-500 dark:text-slate-400 hover:bg-slate-100 dark:bg-[#25273A] font-bold"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold shadow-xs transition-colors"
                  >
                    {editingId ? "Save Changes" : "Broadcast Announcement"}
                  </button>
                </div>
              </form>
            </div>
          </div>,
          document.body
        )}
      </main>
    </>
  );
}
