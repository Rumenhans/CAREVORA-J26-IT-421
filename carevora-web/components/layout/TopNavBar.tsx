"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { Bell, Calendar, ChevronRight } from "lucide-react";

export const TopNavBar: React.FC = () => {
  const [currentDateStr, setCurrentDateStr] = useState("12 May 2025, 10:45 AM");

  useEffect(() => {
    // Format live date nicely
    const updateTime = () => {
      const now = new Date();
      const options: Intl.DateTimeFormatOptions = {
        day: "2-digit",
        month: "short",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      };
      setCurrentDateStr(now.toLocaleDateString("en-US", options));
    };
    updateTime();
    const interval = setInterval(updateTime, 60000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="w-full bg-white border-b border-[#ECE8F7] px-4 sm:px-8 py-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sticky top-0 z-30 shadow-[0_2px_12px_rgba(26,20,69,0.02)]">
      {/* Left Title & Subtitle */}
      <div>
        <h1 className="font-[var(--font-jakarta)] text-lg sm:text-xl font-extrabold text-[#1A1445] flex items-center gap-1.5">
          <span>Welcome back, Seetha!</span>
          <span className="text-xl">👋</span>
        </h1>
        <p className="text-xs text-[#5B5A6E] mt-0.5 font-normal">
          Here&apos;s the overall wellness overview of your residents.
        </p>
      </div>

      {/* Right Controls: Notification bell + live date chip */}
      <div className="flex items-center gap-3 self-end sm:self-center">
        {/* Date chip */}
        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#FAF8FF] border border-[#E9E1FF] text-xs font-semibold text-[#5B2FB0]">
          <Calendar className="w-3.5 h-3.5 text-[#6C3FC5]" strokeWidth={1.75} />
          <span>{currentDateStr}</span>
        </div>

        {/* Bell with badge 3 */}
        <Link
          href="/dashboard/alerts"
          className="relative p-2 rounded-xl border border-[#ECE8F7] bg-white hover:bg-[#FAF8FF] text-[#1A1445] transition-colors"
        >
          <Bell className="w-4 h-4 text-[#5B5A6E]" strokeWidth={1.75} />
          <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-[#EF4444] text-white text-[10px] font-extrabold flex items-center justify-center">
            3
          </span>
        </Link>
      </div>
    </header>
  );
};
