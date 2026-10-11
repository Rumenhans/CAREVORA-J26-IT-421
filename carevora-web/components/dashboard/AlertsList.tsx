"use client";

import React from "react";
import Link from "next/link";
import { AlertCircle, AlertTriangle, Clock, ArrowUpRight } from "lucide-react";
import { mockAlerts } from "@/lib/mock-data";

export const AlertsList: React.FC = () => {
  return (
    <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 sm:p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col justify-between h-full">
      <div className="flex items-center justify-between mb-3">
        <div>
          <h3 className="font-[var(--font-jakarta)] text-sm sm:text-base font-extrabold text-[#1A1445]">
            Alerts & Notifications
          </h3>
          <p className="text-[11px] text-[#8E8CA3] mt-0.5">
            Automated AI risk detections
          </p>
        </div>

        <Link
          href="/dashboard/alerts"
          className="text-xs font-semibold text-[#6C3FC5] hover:underline inline-flex items-center gap-1"
        >
          <span>View All</span>
          <ArrowUpRight className="w-3.5 h-3.5" />
        </Link>
      </div>

      {/* List items */}
      <div className="space-y-2.5 overflow-y-auto max-h-56">
        {mockAlerts.map((alert) => {
          const isHigh = alert.type === "High Risk";
          const isModerate = alert.type === "Moderate Risk";

          return (
            <div
              key={alert.id}
              className={`p-3 rounded-xl border transition-all ${
                isHigh
                  ? "bg-[#FDE8E8]/40 border-[#EF4444]/20"
                  : isModerate
                  ? "bg-[#FEF3DC]/40 border-[#F59E0B]/20"
                  : "bg-[#FAF8FF] border-[#E9E1FF]/60"
              }`}
            >
              <div className="flex items-start gap-2.5">
                <div className="mt-0.5 shrink-0">
                  {isHigh ? (
                    <AlertCircle className="w-4 h-4 text-[#EF4444]" />
                  ) : isModerate ? (
                    <AlertTriangle className="w-4 h-4 text-[#F59E0B]" />
                  ) : (
                    <Clock className="w-4 h-4 text-[#6C3FC5]" />
                  )}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-1">
                    <span className="text-xs font-bold text-[#1A1445] truncate">
                      {alert.title}
                    </span>
                    <span className="text-[10px] text-[#8E8CA3] shrink-0 font-medium">
                      {alert.timestamp}
                    </span>
                  </div>
                  <p className="text-[11px] text-[#5B5A6E] mt-0.5 line-clamp-2">
                    {alert.description}
                  </p>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="pt-3 border-t border-[#ECE8F7]/60 text-center">
        <span className="text-[11px] text-[#8E8CA3]">
          3 active notifications requiring clinical attention
        </span>
      </div>
    </div>
  );
};
