"use client";

import React, { useState, useRef, useEffect } from "react";
import { ChevronDown, Check } from "lucide-react";

export interface DropdownOption {
  value: string;
  label: string;
  icon?: React.ComponentType<{ className?: string }>;
  colorClass?: string;
}

interface CustomDropdownProps {
  value: string;
  onChange: (val: string) => void;
  options: (string | DropdownOption)[];
  placeholder?: string;
  className?: string;
  buttonClassName?: string;
  compact?: boolean;
}

export function CustomDropdown({
  value,
  onChange,
  options,
  placeholder = "Select option...",
  className = "",
  buttonClassName = "",
  compact = false,
}: CustomDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Normalize options
  const normalizedOptions: DropdownOption[] = options.map((opt) => {
    if (typeof opt === "string") {
      return { value: opt, label: opt };
    }
    return opt;
  });

  const selectedOption = normalizedOptions.find((opt) => opt.value === value) || {
    value,
    label: value || placeholder,
  };

  // Close when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div ref={dropdownRef} className={`relative select-none text-xs ${className}`}>
      {/* Trigger Button */}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className={`w-full text-left flex items-center justify-between transition-all font-bold focus:outline-none ${
          compact
            ? "px-3 py-1.5 rounded-xl text-[11px]"
            : "p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 hover:border-blue-400 focus:border-blue-500"
        } ${
          isOpen ? "border-blue-500 ring-2 ring-blue-500/10 bg-white shadow-xs" : ""
        } ${buttonClassName}`}
      >
        <span className="truncate flex items-center gap-1.5">
          {selectedOption.icon && <selectedOption.icon className="w-3.5 h-3.5 shrink-0 text-slate-400" />}
          {selectedOption.label}
        </span>
        <ChevronDown
          className={`w-3.5 h-3.5 text-slate-400 transition-transform duration-200 shrink-0 ml-2 ${
            isOpen ? "rotate-180 text-blue-600" : ""
          }`}
        />
      </button>

      {/* Popover Menu */}
      {isOpen && (
        <div className="absolute z-[999] left-0 right-0 mt-1.5 p-1.5 rounded-2xl bg-white border border-slate-200/90 shadow-xl max-h-60 overflow-y-auto space-y-1 animate-in fade-in zoom-in-95 min-w-[140px]">
          {normalizedOptions.map((opt) => {
            const isSelected = opt.value === value;
            return (
              <button
                key={opt.value}
                type="button"
                onClick={() => {
                  onChange(opt.value);
                  setIsOpen(false);
                }}
                className={`w-full px-3 py-2 rounded-xl text-left flex items-center justify-between font-semibold text-xs transition-colors ${
                  isSelected
                    ? "bg-blue-50 text-blue-700 font-bold"
                    : "text-slate-700 hover:bg-slate-50 hover:text-slate-900"
                }`}
              >
                <div className="flex items-center gap-2 truncate">
                  {opt.icon && <opt.icon className="w-3.5 h-3.5 shrink-0 text-slate-400" />}
                  <span className="truncate">{opt.label}</span>
                </div>

                {isSelected && <Check className="w-3.5 h-3.5 text-blue-600 shrink-0 ml-2" />}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
