"use client";

import { useEffect, useState } from "react";
import { 
  collection, 
  onSnapshot, 
  query, 
  orderBy, 
  doc, 
  updateDoc, 
  deleteDoc 
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { UserFeedback } from "@/lib/types";
import { Header } from "@/components/Header";
import { ConfirmModal } from "@/components/ConfirmModal";
import { CustomDropdown } from "@/components/CustomDropdown";
import { SkeletonCardGrid } from "@/components/Skeleton";
import { 
  MessageSquare, 
  Search, 
  Star, 
  Mail, 
  CheckCircle2, 
  Clock, 
  Trash2, 
  Send, 
  Sparkles, 
  AlertCircle, 
  Copy, 
  Check, 
  X,
  RefreshCw,
  ExternalLink
} from "lucide-react";

export default function FeedbacksPage() {
  const [feedbacks, setFeedbacks] = useState<UserFeedback[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [selectedStatus, setSelectedStatus] = useState<"all" | "pending" | "in-progress" | "resolved">("all");
  const [replyModalFeedback, setReplyModalFeedback] = useState<UserFeedback | null>(null);
  const [replyMessage, setReplyMessage] = useState("");
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [deleteTargetId, setDeleteTargetId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const q = query(collection(db, "user_feedback"), orderBy("timestamp", "desc"));
    const unsub = onSnapshot(q, (snap) => {
      const list: UserFeedback[] = [];
      snap.forEach((doc) => {
        const data = doc.data();
        list.push({ 
          id: doc.id, 
          status: data.status || "pending",
          ...data 
        } as UserFeedback);
      }, (err: any) => { console.warn("Snapshot notice:", err.message); });
      setFeedbacks(list);
      setIsLoading(false);
    });

    return () => unsub();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  // 1. Update Status Action
  const handleUpdateStatus = async (id: string, newStatus: "pending" | "in-progress" | "resolved") => {
    try {
      await updateDoc(doc(db, "user_feedback", id), {
        status: newStatus,
        updatedAt: new Date().toISOString()
      });
      showToast(`Status updated to "${newStatus.toUpperCase()}"!`);
    } catch (err: any) {
      console.error("Failed to update status:", err);
      showToast("Error updating status.");
    }
  };

  // 2. Delete Feedback Action
  const handleConfirmDelete = async () => {
    if (!deleteTargetId) return;
    try {
      await deleteDoc(doc(db, "user_feedback", deleteTargetId));
      showToast("Feedback deleted successfully.");
    } catch (err: any) {
      console.error("Failed to delete feedback:", err);
      showToast("Error deleting feedback.");
    } finally {
      setDeleteTargetId(null);
    }
  };

  // 3. Open Reply Modal
  const openReplyModal = (f: UserFeedback) => {
    setReplyModalFeedback(f);
    setReplyMessage(
      `Hi ${f.userName || "there"},

Thank you for reaching out to the Reminda support team! Regarding your feedback:
"${f.message}"

[Your reply message here]

Best regards,
Alfie Lynard
Reminda Team`
    );
    setCopied(false);
  };

  // 4. Send via Native Mail App
  const handleSendEmail = () => {
    if (!replyModalFeedback || !replyModalFeedback.contactEmail) return;
    const subject = encodeURIComponent(`Re: Your Reminda App Feedback (${replyModalFeedback.category})`);
    const body = encodeURIComponent(replyMessage);
    window.open(`mailto:${replyModalFeedback.contactEmail}?subject=${subject}&body=${body}`, "_blank");
  };

  // 5. Copy Response
  const handleCopyResponse = () => {
    navigator.clipboard.writeText(replyMessage);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const categories = ["All", "General Feedback", "Feature Request", "Bug Report", "Scanner / OCR Issue"];

  const filtered = feedbacks.filter((f) => {
    const matchesSearch = 
      (f.message || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (f.userName || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (f.contactEmail || "").toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCat = selectedCategory === "All" || f.category === selectedCategory;
    const matchesStatus = selectedStatus === "all" || (f.status || "pending") === selectedStatus;
    return matchesSearch && matchesCat && matchesStatus;
  });

  const pendingCount = feedbacks.filter(f => (f.status || "pending") === "pending").length;
  const inProgressCount = feedbacks.filter(f => f.status === "in-progress").length;
  const resolvedCount = feedbacks.filter(f => f.status === "resolved").length;

  return (
    <>
      <Header title="Messages & Reviews" />
      <main className="flex-1 px-8 pb-12 space-y-6 max-w-[1600px] w-full">
        {/* Custom Delete Confirmation Modal */}
        <ConfirmModal
          isOpen={!!deleteTargetId}
          title="Delete Feedback Message?"
          message="Are you sure you want to delete this customer feedback message?"
          confirmText="Yes, Delete Message"
          cancelText="Cancel"
          onConfirm={handleConfirmDelete}
          onCancel={() => setDeleteTargetId(null)}
        />

        {/* Toast Notification */}
        {toastMessage && (
          <div className="fixed bottom-6 right-6 z-50 px-4 py-3 rounded-2xl bg-slate-900 text-white text-xs font-bold shadow-xl flex items-center gap-2.5 animate-bounce">
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            <span>{toastMessage}</span>
          </div>
        )}

        {/* Top Status Tabs Bar */}
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-2 p-1.5 rounded-2xl bg-white border border-slate-200/70 shadow-xs">
            <button
              onClick={() => setSelectedStatus("all")}
              className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                selectedStatus === "all"
                  ? "bg-slate-900 text-white shadow-xs"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              All ({feedbacks.length})
            </button>
            <button
              onClick={() => setSelectedStatus("pending")}
              className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                selectedStatus === "pending"
                  ? "bg-amber-500 text-white shadow-xs"
                  : "text-amber-700 hover:bg-amber-50"
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-amber-400" />
              Pending ({pendingCount})
            </button>
            <button
              onClick={() => setSelectedStatus("in-progress")}
              className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                selectedStatus === "in-progress"
                  ? "bg-blue-600 text-white shadow-xs"
                  : "text-blue-700 hover:bg-blue-50"
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-blue-400" />
              In-Progress ({inProgressCount})
            </button>
            <button
              onClick={() => setSelectedStatus("resolved")}
              className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                selectedStatus === "resolved"
                  ? "bg-emerald-600 text-white shadow-xs"
                  : "text-emerald-700 hover:bg-emerald-50"
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-emerald-400" />
              Resolved ({resolvedCount})
            </button>
          </div>
        </div>

        {/* Search & Category Filter Bar */}
        <div className="p-4 rounded-3xl bg-white border border-slate-200/70 shadow-xs flex flex-col md:flex-row items-center gap-4">
          <div className="relative flex-1 w-full">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by user name, contact email, or review keywords..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 rounded-2xl bg-slate-50 border border-slate-200/70 text-slate-900 text-xs placeholder-slate-400 focus:outline-none focus:border-blue-500"
            />
          </div>

          <div className="flex items-center gap-1.5 overflow-x-auto w-full md:w-auto pb-1 md:pb-0">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-colors ${
                  selectedCategory === cat
                    ? "bg-blue-600 text-white shadow-xs"
                    : "bg-slate-100 text-slate-600 hover:bg-slate-200/80"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>

        {/* Feedback Cards Stream */}
        {isLoading ? (
          <SkeletonCardGrid count={6} />
        ) : filtered.length === 0 ? (
          <div className="py-20 text-center rounded-3xl bg-white border border-slate-200/70 text-slate-400 text-xs space-y-2">
            <MessageSquare className="w-8 h-8 mx-auto text-slate-300" />
            <p>No feedback submissions found matching your filter.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {filtered.map((f) => {
              const currentStatus = f.status || "pending";

              return (
                <div
                  key={f.id}
                  className="p-6 rounded-3xl bg-white border border-slate-200/70 shadow-xs hover:shadow-md transition-all flex flex-col justify-between"
                >
                  <div>
                    {/* User Header & Star Rating */}
                    <div className="flex items-start justify-between gap-3 mb-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 text-white flex items-center justify-center font-black text-sm shadow-xs">
                          {(f.userName || "U")[0].toUpperCase()}
                        </div>
                        <div>
                          <h4 className="font-extrabold text-sm text-slate-900">{f.userName || "User"}</h4>
                          <p className="text-[11px] text-slate-400 font-mono flex items-center gap-1">
                            <Mail className="w-3 h-3 text-slate-400" />
                            {f.contactEmail || "Anonymous / Guest"}
                          </p>
                        </div>
                      </div>

                      <div className="text-right">
                        <div className="text-yellow-400 text-xs font-black">
                          {"★".repeat(f.rating || 5)}
                        </div>
                      </div>
                    </div>

                    {/* Category & Status Pill Bar */}
                    <div className="flex items-center justify-between gap-2 mb-3">
                      <span className="px-2.5 py-0.5 rounded-lg text-[10px] font-bold bg-slate-100 text-slate-700">
                        {f.category}
                      </span>

                      {/* Interactive Status Switcher */}
                      <CustomDropdown
                        value={currentStatus}
                        onChange={(val) => handleUpdateStatus(f.id, val as any)}
                        compact
                        buttonClassName={`border font-bold text-[11px] ${
                          currentStatus === "resolved"
                            ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                            : currentStatus === "in-progress"
                            ? "bg-blue-50 text-blue-700 border-blue-200"
                            : "bg-amber-50 text-amber-700 border-amber-200"
                        }`}
                        options={[
                          { value: "pending", label: "Pending" },
                          { value: "in-progress", label: "In-Progress" },
                          { value: "resolved", label: "Resolved" },
                        ]}
                      />
                    </div>

                    {/* User Feedback Message Content */}
                    <p className="text-xs text-slate-800 leading-relaxed bg-slate-50/70 p-4 rounded-2xl border border-slate-100 mb-4 whitespace-pre-wrap">
                      {f.message}
                    </p>
                  </div>

                  {/* Actions Footer: Reply + Delete Buttons */}
                  <div>
                    <div className="flex items-center justify-between pt-3 border-t border-slate-100">
                      <div className="flex items-center gap-2">
                        {f.contactEmail ? (
                          <button
                            onClick={() => openReplyModal(f)}
                            className="px-3 py-1.5 rounded-xl bg-blue-50 hover:bg-blue-100 text-blue-700 font-bold text-[11px] transition-colors flex items-center gap-1.5"
                          >
                            <Send className="w-3 h-3" />
                            Reply to User
                          </button>
                        ) : (
                          <span className="text-[10px] text-slate-400 italic">No contact email</span>
                        )}
                      </div>

                      <button
                        onClick={() => setDeleteTargetId(f.id)}
                        className="p-2 rounded-xl text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                        title="Delete spam feedback"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Interactive Reply Modal */}
        {replyModalFeedback && (
          <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="w-full max-w-lg bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
                    <Send className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="font-extrabold text-sm text-slate-900">Reply to {replyModalFeedback.userName || "User"}</h3>
                    <p className="text-[11px] text-slate-400 font-mono">{replyModalFeedback.contactEmail}</p>
                  </div>
                </div>
                <button
                  onClick={() => setReplyModalFeedback(null)}
                  className="p-1.5 rounded-xl hover:bg-slate-100 text-slate-400"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              {/* Message composer */}
              <div className="space-y-1.5">
                <label className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">Your Response Message</label>
                <textarea
                  rows={7}
                  value={replyMessage}
                  onChange={(e) => setReplyMessage(e.target.value)}
                  className="w-full p-3.5 rounded-2xl bg-slate-50 border border-slate-200 text-xs text-slate-900 focus:outline-none focus:border-blue-500 leading-relaxed font-sans"
                />
              </div>

              {/* Action Buttons */}
              <div className="flex items-center justify-between pt-2">
                <button
                  onClick={handleCopyResponse}
                  className="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs flex items-center gap-1.5 transition-colors"
                >
                  {copied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                  <span>{copied ? "Copied!" : "Copy Text"}</span>
                </button>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setReplyModalFeedback(null)}
                    className="px-4 py-2 rounded-xl text-slate-500 hover:bg-slate-100 font-bold text-xs"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleSendEmail}
                    className="px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs shadow-xs flex items-center gap-1.5 transition-colors"
                  >
                    <ExternalLink className="w-3.5 h-3.5" />
                    <span>Send via Email Client</span>
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
