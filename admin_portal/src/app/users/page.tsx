"use client";

import { useEffect, useState } from "react";
import { 
  collection, 
  onSnapshot, 
  query, 
  getDocs,
  doc,
  deleteDoc 
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { UserAccount, UserProfileDoc, UserScheduleDoc } from "@/lib/types";
import { Header } from "@/components/Header";
import { ConfirmModal } from "@/components/ConfirmModal";
import { SkeletonTable, LoadingSpinner } from "@/components/Skeleton";
import { 
  Users,
  Clock,
  MapPin, 
  Search, 
  Layers, 
  X, 
  Mail, 
  ChevronRight, 
  CheckCircle2, 
  CalendarCheck,
  Trash2
} from "lucide-react";

export default function UsersPage() {
  const [users, setUsers] = useState<UserAccount[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [inspectingUser, setInspectingUser] = useState<UserAccount | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  
  // Custom Confirmation Modal State
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; name: string } | null>(null);

  // Inspector Data State
  const [userProfiles, setUserProfiles] = useState<UserProfileDoc[]>([]);
  const [userSchedules, setUserSchedules] = useState<UserScheduleDoc[]>([]);
  const [isLoadingInspector, setIsLoadingInspector] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "users"));
    const unsub = onSnapshot(q, (snap) => {
      const list: UserAccount[] = [];
      snap.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() } as UserAccount);
      });
      setUsers(list);
      setIsLoading(false);
    }, (err: any) => {
      console.warn("Users snapshot notice:", err.message);
    });

    return () => unsub();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await deleteDoc(doc(db, "users", deleteTarget.id));
      if (inspectingUser && inspectingUser.id === deleteTarget.id) {
        setInspectingUser(null);
      }
      showToast(`User record "${deleteTarget.name}" permanently deleted.`);
    } catch (err: any) {
      showToast("Delete failed: " + err.message);
    } finally {
      setDeleteTarget(null);
    }
  };

  // Fetch Schedules & Custom Profiles for selected user
  const openInspector = async (user: UserAccount) => {
    setInspectingUser(user);
    setIsLoadingInspector(true);
    setUserProfiles([]);
    setUserSchedules([]);

    try {
      // 1. Fetch Profiles
      const profilesSnap = await getDocs(collection(db, "users", user.id, "profiles"));
      const pList: UserProfileDoc[] = [];
      profilesSnap.forEach(d => pList.push({ id: d.id, ...d.data() } as UserProfileDoc));
      setUserProfiles(pList);

      // 2. Fetch Schedules
      const schedulesSnap = await getDocs(collection(db, "users", user.id, "schedules"));
      const sList: UserScheduleDoc[] = [];
      schedulesSnap.forEach(d => sList.push({ id: d.id, ...d.data() } as UserScheduleDoc));
      setUserSchedules(sList);
    } catch (err: any) {
      console.error("Inspector error:", err);
    } finally {
      setIsLoadingInspector(false);
    }
  };

  const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  const filtered = users.filter((u) => {
    return (
      (u.displayName || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (u.email || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (u.id || "").toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  return (
    <>
      <Header title="Customers & User Accounts" />
      <main className="flex-1 px-8 pb-12 space-y-6 max-w-[1600px] w-full">
        {/* Toast */}
        {toastMessage && (
          <div className="fixed bottom-6 right-6 z-50 px-4 py-3 rounded-2xl bg-slate-900 text-white text-xs font-bold shadow-xl flex items-center gap-2.5 animate-bounce">
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            <span>{toastMessage}</span>
          </div>
        )}

        {/* Custom Confirmation Modal */}
        <ConfirmModal
          isOpen={!!deleteTarget}
          title="Delete User Account?"
          message={`Are you sure you want to permanently delete the account for "${deleteTarget?.name}"? This action will remove all their cloud-synced schedule records.`}
          confirmText="Yes, Delete Record"
          cancelText="Keep Account"
          onConfirm={handleConfirmDelete}
          onCancel={() => setDeleteTarget(null)}
        />

        {/* Top Information Bar */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <p className="text-xs text-slate-500 font-semibold">
              Live Registered Mobile Users ({users.length} Active). Click any user to inspect their live schedule profiles & classes for customer support troubleshooting.
            </p>
          </div>

          <div className="px-3.5 py-2 rounded-2xl bg-white border border-slate-200/80 text-xs font-bold text-slate-700 shadow-xs">
            Total Users: {users.length}
          </div>
        </div>

        {/* Search Bar */}
        <div className="p-4 rounded-3xl bg-white border border-slate-200/70 shadow-xs">
          <div className="relative w-full">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by customer name, email address, or Firebase UID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 rounded-2xl bg-slate-50 border border-slate-200/70 text-slate-900 text-xs placeholder-slate-400 focus:outline-none focus:border-blue-500"
            />
          </div>
        </div>

        {/* Users Table */}
        {isLoading ? (
          <SkeletonTable rows={5} />
        ) : filtered.length === 0 ? (
          <div className="py-20 text-center rounded-3xl bg-white border border-slate-200/70 text-slate-400 text-xs space-y-2">
            <Users className="w-10 h-10 mx-auto text-slate-300" />
            <p className="font-bold text-sm text-slate-800">No registered users yet</p>
            <p className="text-slate-400">Users who open Reminda or log in on Android/iOS will automatically appear here in real time.</p>
          </div>
        ) : (
          <div className="rounded-3xl bg-white border border-slate-200/70 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50/80 border-b border-slate-200/70 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                    <th className="py-3.5 px-6">Customer / User</th>
                    <th className="py-3.5 px-6">Email Address</th>
                    <th className="py-3.5 px-6">Platform & App</th>
                    <th className="py-3.5 px-6">Firebase User ID</th>
                    <th className="py-3.5 px-6 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
                  {filtered.map((u) => (
                    <tr
                      key={u.id}
                      onClick={() => openInspector(u)}
                      className="hover:bg-blue-50/40 cursor-pointer transition-colors"
                    >
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          {u.photoUrl ? (
                            <img
                              src={u.photoUrl}
                              alt={u.displayName || "User"}
                              className="w-9 h-9 rounded-full object-cover border border-slate-200 shadow-xs shrink-0"
                              referrerPolicy="no-referrer"
                            />
                          ) : (
                            <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 text-white flex items-center justify-center font-black text-xs shadow-xs shrink-0">
                              {(u.displayName || u.email || "U")[0].toUpperCase()}
                            </div>
                          )}
                          <div>
                            <p className="font-extrabold text-slate-900 text-xs">{u.displayName || "Reminda User"}</p>
                            <p className="text-[10px] text-slate-400 font-mono">UID: {u.id.slice(0, 10)}...</p>
                          </div>
                        </div>
                      </td>

                      <td className="py-4 px-6 text-slate-600 font-mono text-xs">
                        {u.email || "Anonymous Account"}
                      </td>

                      <td className="py-4 px-6 text-slate-500 text-xs">
                        <span className="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 font-bold text-[10px]">
                          {u.platform || "Android"} • {u.appVersion || "v1.0.0"}
                        </span>
                      </td>

                      <td className="py-4 px-6 font-mono text-slate-400 text-[11px]">
                        {u.id}
                      </td>

                      <td className="py-4 px-6 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <span className="px-3 py-1.5 rounded-xl bg-blue-50 hover:bg-blue-100 text-blue-700 font-bold text-[11px] inline-flex items-center gap-1 transition-colors">
                            <span>Inspect</span>
                            <ChevronRight className="w-3.5 h-3.5" />
                          </span>

                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setDeleteTarget({ id: u.id, name: u.displayName || u.email || "User" });
                            }}
                            className="p-1.5 rounded-xl text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                            title="Delete User Record"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* User Schedule Inspector Drawer / Modal */}
        {inspectingUser && (
          <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="w-full max-w-3xl bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-5 animate-in fade-in zoom-in-95 max-h-[90vh] overflow-y-auto">
              {/* Header */}
              <div className="flex items-start justify-between pb-4 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  {inspectingUser.photoUrl ? (
                    <img
                      src={inspectingUser.photoUrl}
                      alt={inspectingUser.displayName || "User"}
                      className="w-12 h-12 rounded-2xl object-cover border border-slate-200 shadow-md shadow-blue-500/20 shrink-0"
                      referrerPolicy="no-referrer"
                    />
                  ) : (
                    <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 text-white flex items-center justify-center font-black text-sm shadow-md shadow-blue-500/20 shrink-0">
                      {(inspectingUser.displayName || inspectingUser.email || "U")[0].toUpperCase()}
                    </div>
                  )}
                  <div>
                    <h3 className="font-extrabold text-base text-slate-900">{inspectingUser.displayName || "User"}</h3>
                    <p className="text-xs text-slate-400 font-mono flex items-center gap-1.5">
                      <Mail className="w-3.5 h-3.5" />
                      {inspectingUser.email}
                    </p>
                  </div>
                </div>

                <button
                  onClick={() => setInspectingUser(null)}
                  className="p-2 rounded-xl hover:bg-slate-100 text-slate-400 transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Statistics summary */}
              <div className="grid grid-cols-3 gap-3 text-xs">
                <div className="p-3.5 rounded-2xl bg-blue-50/60 border border-blue-100/80">
                  <p className="font-bold text-blue-700 text-[10px] uppercase tracking-wider">Schedule Profiles</p>
                  <p className="text-lg font-black text-slate-900 mt-0.5">{userProfiles.length}</p>
                </div>
                <div className="p-3.5 rounded-2xl bg-emerald-50/60 border border-emerald-100/80">
                  <p className="font-bold text-emerald-700 text-[10px] uppercase tracking-wider">Total Active Classes</p>
                  <p className="text-lg font-black text-slate-900 mt-0.5">{userSchedules.length}</p>
                </div>
                <div className="p-3.5 rounded-2xl bg-purple-50/60 border border-purple-100/80">
                  <p className="font-bold text-purple-700 text-[10px] uppercase tracking-wider">App Version</p>
                  <p className="text-lg font-black text-slate-900 mt-0.5">{inspectingUser.appVersion || "v1.0.0+8"}</p>
                </div>
              </div>

              {isLoadingInspector ? (
                <LoadingSpinner label="Fetching user schedules & profiles from cloud..." className="py-8" />
              ) : (
                <>
              {/* Profiles Section */}
              <div className="space-y-2">
                <h4 className="font-extrabold text-xs text-slate-900 flex items-center gap-1.5">
                  <Layers className="w-4 h-4 text-blue-600" />
                  <span>Custom Schedule Profiles ({userProfiles.length})</span>
                </h4>

                {userProfiles.length === 0 ? (
                  <p className="text-xs text-slate-400 p-4 rounded-2xl bg-slate-50 border border-slate-100">
                    No custom profiles synced in cloud for this user.
                  </p>
                ) : (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                    {userProfiles.map((p) => (
                      <div key={p.id} className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200/70 space-y-1">
                        <div className="flex items-center justify-between">
                          <p className="font-extrabold text-slate-900">{p.name || "Default Profile"}</p>
                          {p.isCurrent && (
                            <span className="px-2 py-0.5 rounded-md bg-emerald-100 text-emerald-800 font-bold text-[9px]">
                              Active Profile
                            </span>
                          )}
                        </div>
                        <p className="text-[11px] text-slate-500">
                          {p.institutionName} • <span className="font-semibold text-slate-700">{p.role}</span>
                        </p>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Timetables / Classes Section */}
              <div className="space-y-2">
                <h4 className="font-extrabold text-xs text-slate-900 flex items-center gap-1.5">
                  <CalendarCheck className="w-4 h-4 text-indigo-600" />
                  <span>Timetable Classes & Duty Shifts ({userSchedules.length})</span>
                </h4>

                {userSchedules.length === 0 ? (
                  <p className="text-xs text-slate-400 p-4 rounded-2xl bg-slate-50 border border-slate-100">
                    No schedules or classes currently in Firestore.
                  </p>
                ) : (
                  <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
                    {userSchedules.map((s) => (
                      <div
                        key={s.id}
                        className="p-3 rounded-2xl bg-white border border-slate-200 text-xs flex items-center justify-between hover:border-blue-300 transition-colors"
                      >
                        <div>
                          <p className="font-extrabold text-slate-900">{s.title}</p>
                          <p className="text-[11px] text-slate-500 flex items-center gap-2 mt-0.5">
                            <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5 text-slate-400" /> {s.startTime} - {s.endTime}</span>
                            <span>•</span>
                            <span className="flex items-center gap-1"><MapPin className="w-3.5 h-3.5 text-slate-400" /> {s.location || "Online / TBA"}</span>
                          </p>
                        </div>

                        <div className="flex items-center gap-1">
                          {s.daysOfWeek?.map((d) => (
                            <span
                              key={d}
                              className="w-5 h-5 rounded-md bg-blue-50 text-blue-700 font-black text-[9px] flex items-center justify-center"
                            >
                              {dayNames[d] ? dayNames[d][0] : d}
                            </span>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              </>
              )}

              {/* Footer */}
              <div className="flex items-center justify-between pt-3 border-t border-slate-100 text-xs">
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setDeleteTarget({ id: inspectingUser.id, name: inspectingUser.displayName || inspectingUser.email })}
                    className="px-3 py-1.5 rounded-xl bg-red-50 hover:bg-red-100 text-red-600 font-bold text-xs flex items-center gap-1.5 transition-colors"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Delete User Record</span>
                  </button>
                  <span className="text-[10px] text-slate-400 font-mono">User ID: {inspectingUser.id}</span>
                </div>
                <a
                  href={`mailto:${inspectingUser.email}?subject=Reminda Support Assistance`}
                  className="px-4 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center gap-1.5"
                >
                  <Mail className="w-3.5 h-3.5" />
                  <span>Email User</span>
                </a>
              </div>
            </div>
          </div>
        )}
      </main>
    </>
  );
}
