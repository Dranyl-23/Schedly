"use client";

import { useEffect, useState, useRef } from "react";
import { 
  collection, 
  onSnapshot, 
  query, 
  orderBy, 
  doc, 
  setDoc, 
  deleteDoc, 
  writeBatch,
  serverTimestamp 
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Institution } from "@/lib/types";
import { Header } from "@/components/Header";
import { ConfirmModal } from "@/components/ConfirmModal";
import { CustomDropdown } from "@/components/CustomDropdown";
import { SkeletonCardGrid } from "@/components/Skeleton";
import codebaseInstitutions from "@/lib/codebase_institutions.json";
import { 
  School, 
  Plus, 
  Search, 
  Trash2, 
  Edit3, 
  CheckCircle2, 
  Sparkles, 
  Building2, 
  X, 
  UploadCloud, 
  Loader2, 
  Check, 
  ChevronLeft, 
  ChevronRight,
  Filter,
  MapPin
} from "lucide-react";

export default function InstitutionsPage() {
  const [institutions, setInstitutions] = useState<Institution[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [selectedRegion, setSelectedRegion] = useState("All");
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 24;

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; name: string } | null>(null);
  const [isSyncingAll, setIsSyncingAll] = useState(false);
  const [syncProgress, setSyncProgress] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  // Form State
  const [name, setName] = useState("");
  const [shortName, setShortName] = useState("");
  const [category, setCategory] = useState("College / University");
  const [regionCode, setRegionCode] = useState("Region XI — Davao Region");
  const [city, setCity] = useState("Davao City");
  const [themeColor, setThemeColor] = useState("#2563EB");
  const [logoUrl, setLogoUrl] = useState("");
  const [emblemInitials, setEmblemInitials] = useState("");

  // Upload State
  const [isUploading, setIsUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const q = query(collection(db, "institutions"), orderBy("name", "asc"));
    const unsub = onSnapshot(q, (snap) => {
      const list: Institution[] = [];
      snap.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() } as Institution);
      });
      setInstitutions(list);
      setIsLoading(false);
    }, (err: any) => { 
      console.warn("Snapshot notice:", err.message);
      setIsLoading(false);
    });
    return () => unsub();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 4000);
  };

  const openAddModal = () => {
    setEditingId(null);
    setName("");
    setShortName("");
    setCategory("College / University");
    setRegionCode("Region XI — Davao Region");
    setCity("Davao City");
    setThemeColor("#2563EB");
    setLogoUrl("");
    setEmblemInitials("");
    setUploadSuccess(false);
    setIsModalOpen(true);
  };

  const openEditModal = (item: Institution) => {
    setEditingId(item.id);
    setName(item.name);
    setShortName(item.shortName);
    setCategory(item.category);
    setRegionCode(item.regionCode);
    setCity(item.city);
    setThemeColor(item.themeColor || "#2563EB");
    setLogoUrl(item.logoUrl || "");
    setEmblemInitials(item.emblemInitials || "");
    setUploadSuccess(!!item.logoUrl);
    setIsModalOpen(true);
  };

  // Free Cloud Image Upload Handler
  const handleFileUpload = async (file: File) => {
    if (!file.type.startsWith("image/")) {
      showToast("Please upload an image file (.png, .jpg, .webp).");
      return;
    }

    try {
      setIsUploading(true);
      setUploadSuccess(false);

      const formData = new FormData();
      formData.append("image", file);

      const imgbbKey = process.env.NEXT_PUBLIC_IMGBB_API_KEY;
      const response = await fetch(`https://api.imgbb.com/1/upload?key=${imgbbKey}`, {
        method: "POST",
        body: formData,
      });

      const data = await response.json();

      if (data.success && data.data && data.data.url) {
        const publicCdnUrl = data.data.display_url || data.data.url;
        setLogoUrl(publicCdnUrl);
        setUploadSuccess(true);
        showToast("Logo uploaded to free CDN successfully!");
      } else {
        const reader = new FileReader();
        reader.onload = () => {
          setLogoUrl(reader.result as string);
          setUploadSuccess(true);
          showToast("Logo loaded locally!");
        };
        reader.readAsDataURL(file);
      }
    } catch (err: any) {
      console.error("Upload error:", err);
      const reader = new FileReader();
      reader.onload = () => {
        setLogoUrl(reader.result as string);
        setUploadSuccess(true);
        showToast("Logo saved!");
      };
      reader.readAsDataURL(file);
    } finally {
      setIsUploading(false);
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileUpload(e.dataTransfer.files[0]);
    }
  };

  const handleSaveInstitution = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !shortName.trim()) {
      showToast("Please fill in the institution name and short name.");
      return;
    }

    try {
      const docId = editingId || name.toLowerCase().replace(/[^a-z0-9]/g, "-").slice(0, 40) + `-${Date.now().toString().slice(-4)}`;
      const docRef = doc(db, "institutions", docId);

      const savedData: Institution = {
        id: docId,
        name: name.trim(),
        shortName: shortName.trim(),
        category,
        regionCode,
        city: city.trim(),
        themeColor,
        logoUrl: logoUrl.trim(),
        emblemInitials: emblemInitials.trim() || shortName.trim().slice(0, 4).toUpperCase(),
        isOfficial: true,
      };

      // Optimistically update local state immediately so user sees changes with 0 delay
      setInstitutions((prev) => {
        const exists = prev.some((item) => item.id === docId);
        if (exists) {
          return prev.map((item) => (item.id === docId ? { ...item, ...savedData } : item));
        } else {
          return [savedData, ...prev];
        }
      });

      setIsModalOpen(false);

      await setDoc(docRef, {
        name: name.trim(),
        shortName: shortName.trim(),
        category,
        regionCode,
        city: city.trim(),
        themeColor,
        logoUrl: logoUrl.trim(),
        emblemInitials: emblemInitials.trim() || shortName.trim().slice(0, 4).toUpperCase(),
        isOfficial: true,
        updatedAt: serverTimestamp(),
        createdAt: serverTimestamp()
      }, { merge: true });

      showToast(editingId ? "Institution updated successfully!" : "New Institution added & live to all mobile apps!");
    } catch (err: any) {
      console.error("Error saving institution:", err);
      showToast("Failed to save institution: " + err.message);
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await deleteDoc(doc(db, "institutions", deleteTarget.id));
      showToast(`Deleted "${deleteTarget.name}" from directory.`);
    } catch (err: any) {
      console.error("Delete error:", err);
      showToast("Failed to delete institution.");
    } finally {
      setDeleteTarget(null);
    }
  };

  // Bulk Sync all 556 Codebase Institutions in Batches
  const handleSyncAll556 = async () => {
    try {
      setIsSyncingAll(true);
      const total = codebaseInstitutions.length;
      setSyncProgress(`0 / ${total}`);

      const chunkSize = 400;
      for (let i = 0; i < total; i += chunkSize) {
        const chunk = codebaseInstitutions.slice(i, i + chunkSize);
        const batch = writeBatch(db);

        for (const item of chunk) {
          const docRef = doc(db, "institutions", item.id);
          batch.set(docRef, {
            name: item.name,
            shortName: item.shortName,
            category: item.category,
            regionCode: item.regionCode,
            city: item.city,
            themeColor: item.themeColor,
            logoUrl: item.logoUrl || "",
            emblemInitials: item.emblemInitials || item.shortName.slice(0, 4).toUpperCase(),
            isOfficial: true,
            createdAt: serverTimestamp()
          }, { merge: true });
        }

        await batch.commit();
        setSyncProgress(`${Math.min(i + chunkSize, total)} / ${total}`);
      }

      showToast(`Successfully synced all ${total} Philippine Institutions to Cloud Firestore!`);
    } catch (err: any) {
      console.error("Sync error:", err);
      showToast("Error syncing full directory: " + err.message);
    } finally {
      setIsSyncingAll(false);
      setSyncProgress("");
    }
  };

  const categories = ["All", "College / University", "Hospital / Clinic", "Corporate / Workplace", "Government"];
  
  const regions = [
    "All",
    "NCR",
    "CAR",
    "R01",
    "R02",
    "R03",
    "R04A",
    "R04B",
    "R05",
    "R06",
    "R07",
    "R08",
    "R09",
    "R10",
    "R11",
    "R12",
    "R13",
    "BARMM"
  ];

  const filtered = institutions.filter((item) => {
    const matchesSearch = 
      (item.name || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (item.shortName || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (item.city || "").toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCat = selectedCategory === "All" || item.category === selectedCategory;
    const matchesReg = selectedRegion === "All" || (item.regionCode || "").includes(selectedRegion);
    return matchesSearch && matchesCat && matchesReg;
  });

  const totalPages = Math.ceil(filtered.length / itemsPerPage) || 1;
  const paginatedItems = filtered.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  return (
    <>
      <Header title="Institutions & Schools" />
      <main className="flex-1 px-8 pb-12 space-y-6 max-w-[1600px] w-full">
        {/* Custom Delete Confirmation Modal */}
        <ConfirmModal
          isOpen={!!deleteTarget}
          title="Delete Institution?"
          message={`Are you sure you want to delete "${deleteTarget?.name}" from the global directory? Mobile apps will no longer suggest this institution.`}
          confirmText="Yes, Delete Institution"
          cancelText="Keep"
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
            <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold flex items-center gap-1.5">
              <span>Live Cloud Directory ({institutions.length} Active Institutions across the Philippines)</span>
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={handleSyncAll556}
              disabled={isSyncingAll}
              className="px-4 py-2 rounded-2xl bg-amber-50 hover:bg-amber-100 border border-amber-200/80 text-amber-800 font-bold text-xs shadow-xs transition-colors flex items-center gap-2 disabled:opacity-50"
              title="Import all 556 Colleges, Hospitals, Fast Food & Malls from codebase"
            >
              {isSyncingAll ? (
                <Loader2 className="w-4 h-4 text-amber-600 animate-spin" />
              ) : (
                <Sparkles className="w-4 h-4 text-amber-500" />
              )}
              <span>{isSyncingAll ? `Syncing ${syncProgress}...` : `Sync All 556 Codebase Presets`}</span>
            </button>

            <button
              onClick={openAddModal}
              className="px-4 py-2.5 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs shadow-xs transition-colors flex items-center gap-2"
            >
              <Plus className="w-4 h-4" />
              Add Institution
            </button>
          </div>
        </div>

        {/* Search, Region & Category Filter Bar */}
        <div className="p-4 rounded-3xl bg-white dark:bg-[#1C1D2B] border border-slate-200 dark:border-[#282A3D]/70 dark:border-[#282A3D] shadow-xs flex flex-col lg:flex-row items-center gap-4">
          <div className="relative flex-1 w-full">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search across 500+ Philippine schools, hospitals, fast-food, or cities..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full pl-10 pr-4 py-2 rounded-2xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D]/70 text-slate-900 dark:text-white text-xs placeholder-slate-400 focus:outline-none focus:border-blue-500"
            />
          </div>

          {/* Region Dropdown Filter */}
          <div className="flex items-center gap-2 w-full lg:w-auto">
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D]/70 text-xs font-bold text-slate-700 dark:text-slate-300">
              <MapPin className="w-3.5 h-3.5 text-slate-400" />
              <CustomDropdown
                value={selectedRegion}
                onChange={(val) => {
                  setSelectedRegion(val);
                  setCurrentPage(1);
                }}
                compact
                buttonClassName="bg-transparent border-none p-0 text-slate-700 dark:text-slate-300 hover:text-blue-600"
                options={[
                  { value: "All", label: "All Regions (PH)" },
                  ...regions.filter(r => r !== "All").map(reg => ({ value: reg, label: reg }))
                ]}
              />
            </div>

            {/* Category Chips */}
            <div className="flex items-center gap-1.5 overflow-x-auto pb-1 lg:pb-0">
              {categories.map((cat) => (
                <button
                  key={cat}
                  onClick={() => {
                    setSelectedCategory(cat);
                    setCurrentPage(1);
                  }}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-colors ${
                    selectedCategory === cat
                      ? "bg-blue-600 text-white shadow-xs"
                      : "bg-slate-100 dark:bg-[#25273A] text-slate-600 dark:text-slate-400 hover:bg-slate-200/80"
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Institutions Grid / Cards */}
        {isLoading ? (
          <SkeletonCardGrid count={8} />
        ) : filtered.length === 0 ? (
          <div className="py-20 text-center rounded-3xl bg-white dark:bg-[#1C1D2B] border border-slate-200 dark:border-[#282A3D]/70 dark:border-[#282A3D] text-slate-400 text-xs space-y-4">
            <School className="w-12 h-12 mx-auto text-slate-300" />
            <div>
              <p className="font-bold text-sm text-slate-800 dark:text-slate-200">No institutions found</p>
              <p className="text-slate-400 mt-0.5">Click the button below to sync all 556 Philippine colleges, hospitals, and workplaces!</p>
            </div>
            <button
              onClick={handleSyncAll556}
              disabled={isSyncingAll}
              className="px-5 py-2.5 rounded-2xl bg-amber-500 hover:bg-amber-600 text-white font-bold text-xs shadow-xs inline-flex items-center gap-2 transition-colors"
            >
              <Sparkles className="w-4 h-4" />
              Sync All 556 Codebase Presets
            </button>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
              {paginatedItems.map((item) => (
                <div
                  key={item.id}
                  className="p-5 rounded-3xl bg-white dark:bg-[#1C1D2B] border border-slate-200 dark:border-[#282A3D]/70 dark:border-[#282A3D] shadow-xs hover:shadow-md transition-all flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-start justify-between gap-3 mb-3">
                      {/* Emblem / Logo */}
                      <div 
                        className="w-12 h-12 rounded-2xl flex items-center justify-center font-black text-sm text-white shadow-xs overflow-hidden bg-white border border-slate-100 dark:border-[#282A3D] p-1 shrink-0 relative"
                      >
                        {item.logoUrl ? (
                          <img 
                            src={item.logoUrl} 
                            alt={item.shortName} 
                            className="w-full h-full object-contain"
                            referrerPolicy="no-referrer"
                            onError={(e) => {
                              const target = e.target as HTMLElement;
                              target.style.display = 'none';
                              const fallback = target.parentElement?.querySelector('.card-fallback-emblem') as HTMLElement;
                              if (fallback) fallback.style.display = 'flex';
                            }}
                          />
                        ) : null}
                        <div 
                          className={`card-fallback-emblem w-full h-full rounded-xl items-center justify-center text-white text-[11px] font-bold ${
                            item.logoUrl ? 'hidden' : 'flex'
                          }`}
                          style={{ backgroundColor: item.themeColor || "#2563EB" }}
                        >
                          <span>{item.emblemInitials || (item.shortName || "").slice(0, 3)}</span>
                        </div>
                      </div>

                      <span className="px-2 py-0.5 rounded-lg text-[10px] font-bold bg-slate-100 dark:bg-[#25273A] text-slate-700 dark:text-slate-300 truncate max-w-[120px]">
                        {item.shortName}
                      </span>
                    </div>

                    <h4 className="font-extrabold text-sm text-slate-900 dark:text-white leading-snug line-clamp-2" title={item.name}>
                      {item.name}
                    </h4>

                    <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 flex items-center gap-1">
                      <span>{item.city}</span>
                      <span>•</span>
                      <span className="text-[11px] font-medium">{item.category}</span>
                    </p>
                  </div>

                  <div className="flex items-center justify-between pt-4 mt-4 border-t border-slate-100 dark:border-[#282A3D] text-xs">
                    <div className="flex items-center gap-1.5">
                      <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: item.themeColor || "#2563EB" }} />
                      <span className="text-[10px] font-mono text-slate-400">{item.regionCode || "PH"}</span>
                    </div>

                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => openEditModal(item)}
                        className="p-1.5 rounded-xl hover:bg-slate-100 dark:bg-[#25273A] text-slate-500 dark:text-slate-400 transition-colors"
                        title="Edit"
                      >
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => setDeleteTarget({ id: item.id, name: item.name })}
                        className="p-1.5 rounded-xl hover:bg-red-50 text-slate-400 hover:text-red-600 transition-colors"
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Pagination Controls */}
            {totalPages > 1 && (
              <div className="flex items-center justify-between p-4 rounded-3xl bg-white dark:bg-[#1C1D2B] border border-slate-200 dark:border-[#282A3D]/70 dark:border-[#282A3D] shadow-xs">
                <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold">
                  Showing {(currentPage - 1) * itemsPerPage + 1} to {Math.min(currentPage * itemsPerPage, filtered.length)} of {filtered.length} institutions
                </p>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setCurrentPage(p => Math.max(p - 1, 1))}
                    disabled={currentPage === 1}
                    className="p-2 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 hover:bg-slate-100 dark:bg-[#25273A] disabled:opacity-40 text-slate-600 dark:text-slate-400 transition-colors"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>

                  <span className="px-3 py-1 text-xs font-bold text-slate-800 dark:text-slate-200">
                    Page {currentPage} of {totalPages}
                  </span>

                  <button
                    onClick={() => setCurrentPage(p => Math.min(p + 1, totalPages))}
                    disabled={currentPage === totalPages}
                    className="p-2 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 hover:bg-slate-100 dark:bg-[#25273A] disabled:opacity-40 text-slate-600 dark:text-slate-400 transition-colors"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </>
        )}

        {/* Add / Edit Institution Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="w-full max-w-lg bg-white dark:bg-[#1C1D2B] rounded-3xl p-6 shadow-2xl border border-slate-200 dark:border-[#282A3D] space-y-4 animate-in fade-in zoom-in-95 max-h-[90vh] overflow-y-auto">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-[#282A3D]">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
                    <Building2 className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="font-extrabold text-sm text-slate-900 dark:text-white">
                      {editingId ? "Edit Institution" : "Add New Institution"}
                    </h3>
                    <p className="text-[11px] text-slate-400">Live sync to Reminda mobile apps</p>
                  </div>
                </div>
                <button
                  onClick={() => setIsModalOpen(false)}
                  className="p-1.5 rounded-xl hover:bg-slate-100 dark:bg-[#25273A] text-slate-400"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <form onSubmit={handleSaveInstitution} className="space-y-4 text-xs">
                {/* 1. Drag & Drop Logo Uploader Box */}
                <div className="space-y-1.5">
                  <label className="font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider text-[10px] flex items-center justify-between">
                    <span>Institution Logo (Free Cloud CDN)</span>
                    {uploadSuccess && (
                      <span className="text-emerald-600 font-bold flex items-center gap-1 normal-case text-[11px]">
                        <Check className="w-3.5 h-3.5" /> Logo Ready
                      </span>
                    )}
                  </label>

                  <input
                    type="file"
                    ref={fileInputRef}
                    accept="image/*"
                    className="hidden"
                    onChange={(e) => {
                      if (e.target.files && e.target.files[0]) {
                        handleFileUpload(e.target.files[0]);
                      }
                    }}
                  />

                  <div
                    onDragOver={handleDragOver}
                    onDragLeave={handleDragLeave}
                    onDrop={handleDrop}
                    onClick={() => fileInputRef.current?.click()}
                    className={`border-2 border-dashed rounded-2xl p-4 flex flex-col items-center justify-center gap-2 cursor-pointer transition-all ${
                      isDragging 
                        ? "border-blue-500 bg-blue-50/50" 
                        : logoUrl 
                        ? "border-slate-200 dark:border-[#282A3D] bg-slate-50 dark:bg-[#25273A]/60/50 hover:border-slate-300" 
                        : "border-slate-200 dark:border-[#282A3D] hover:border-blue-400 bg-slate-50 dark:bg-[#25273A]/60/30"
                    }`}
                  >
                    {isUploading ? (
                      <div className="flex flex-col items-center gap-2 py-3 text-slate-500 dark:text-slate-400">
                        <Loader2 className="w-6 h-6 animate-spin text-blue-600" />
                        <span className="font-semibold text-xs">Uploading to Free Cloud CDN...</span>
                      </div>
                    ) : logoUrl ? (
                      <div className="flex items-center gap-3 w-full">
                        <div className="w-12 h-12 rounded-xl bg-white border border-slate-200 dark:border-[#282A3D] p-1 flex items-center justify-center overflow-hidden shrink-0">
                          <img src={logoUrl} alt="Preview" className="w-full h-full object-contain" />
                        </div>
                        <div className="flex-1 min-w-0 text-left">
                          <p className="text-xs font-bold text-slate-900 dark:text-white truncate">Logo Uploaded</p>
                          <p className="text-[10px] text-slate-400 truncate font-mono">{logoUrl}</p>
                        </div>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            fileInputRef.current?.click();
                          }}
                          className="px-3 py-1 rounded-lg bg-white border border-slate-200 dark:border-[#282A3D] text-slate-700 dark:text-slate-300 font-bold text-[10px] hover:bg-slate-50 dark:bg-[#25273A]/60"
                        >
                          Change
                        </button>
                      </div>
                    ) : (
                      <div className="flex flex-col items-center gap-1 text-center py-2">
                        <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center mb-1">
                          <UploadCloud className="w-5 h-5" />
                        </div>
                        <p className="text-xs font-bold text-slate-700 dark:text-slate-300">
                          Drag & drop logo image here, or <span className="text-blue-600 underline">browse</span>
                        </p>
                        <p className="text-[10px] text-slate-400">PNG, JPG, or WEBP (Transparent background recommended)</p>
                      </div>
                    )}
                  </div>
                </div>

                {/* Name */}
                <div className="space-y-1">
                  <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                    Institution / University Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Davao del Sur State College"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white focus:outline-none focus:border-blue-500"
                  />
                </div>

                {/* Short Name & Category */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                      Acronym / Short Name *
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. DSSC"
                      value={shortName}
                      onChange={(e) => setShortName(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white focus:outline-none focus:border-blue-500 font-bold"
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                      Sector Category
                    </label>
                    <CustomDropdown
                      value={category}
                      onChange={setCategory}
                      options={[
                        "College / University",
                        "Hospital / Clinic",
                        "Corporate / Workplace",
                        "Government",
                      ]}
                    />
                  </div>
                </div>

                {/* Region & City */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                      Region
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Region XI — Davao Region"
                      value={regionCode}
                      onChange={(e) => setRegionCode(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white focus:outline-none"
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                      City / Location
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Digos City"
                      value={city}
                      onChange={(e) => setCity(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white focus:outline-none"
                    />
                  </div>
                </div>

                {/* Theme Color */}
                <div className="space-y-1">
                  <label className="font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider text-[10px]">
                    Brand Theme Color (Hex)
                  </label>
                  <div className="flex items-center gap-2">
                    <input
                      type="color"
                      value={themeColor}
                      onChange={(e) => setThemeColor(e.target.value)}
                      className="w-8 h-8 rounded-lg cursor-pointer border border-slate-200 dark:border-[#282A3D]"
                    />
                    <input
                      type="text"
                      value={themeColor}
                      onChange={(e) => setThemeColor(e.target.value)}
                      className="flex-1 p-2 rounded-xl bg-slate-50 dark:bg-[#25273A]/60 border border-slate-200 dark:border-[#282A3D] text-slate-900 dark:text-white font-mono focus:outline-none"
                    />
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
                    {editingId ? "Save Changes" : "Create Institution"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </main>
    </>
  );
}
