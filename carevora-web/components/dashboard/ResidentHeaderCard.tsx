"use client";

import React from "react";
import Link from "next/link";
import { ArrowUpRight, FileText } from "lucide-react";
import { Resident } from "@/lib/mock-data";

interface ResidentHeaderCardProps {
  resident: Resident;
}

export const ResidentHeaderCard: React.FC<ResidentHeaderCardProps> = ({
  resident,
}) => {
  return (
    <div className="w-full bg-white rounded-2xl border border-[#ECE8F7] p-5 sm:p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
      {/* Resident Identity */}
      <div className="flex items-center gap-4">
        {/* Avatar badge */}
        <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#6C3FC5] to-[#5B2FB0] text-white flex items-center justify-center font-extrabold text-xl shadow-md shrink-0">
          JP
        </div>

        <div className="flex flex-col">
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="font-[var(--font-jakarta)] text-lg sm:text-xl font-extrabold text-[#1A1445]">
              {resident.name}
            </h2>
            <span className="px-2.5 py-0.5 rounded-full bg-[#FAF8FF] border border-[#E9E1FF] text-[11px] font-bold text-[#6C3FC5]">
              ID: {resident.id}
            </span>
          </div>

          <p className="text-xs text-[#5B5A6E] mt-1 font-medium">
            Age: {resident.age} • {resident.gender} • Room No: {resident.roomNumber}
          </p>

          <Link
            href="/dashboard/residents"
            className="text-xs font-semibold text-[#6C3FC5] hover:underline inline-flex items-center gap-1 mt-1.5"
          >
            <span>View Profile</span>
            <ArrowUpRight className="w-3.5 h-3.5" />
          </Link>
        </div>
      </div>

      {/* Right Column: Last Assessment Date + View Detailed Report button */}
      <div className="flex flex-col sm:flex-row md:flex-col items-start md:items-end justify-between w-full md:w-auto gap-3 pt-3 md:pt-0 border-t md:border-t-0 border-[#ECE8F7]">
        <div className="text-left md:text-right">
          <span className="text-[11px] font-semibold text-[#8E8CA3] block uppercase tracking-wider">
            Last Assessment
          </span>
          <span className="text-xs font-bold text-[#1A1445]">
            {resident.lastAssessmentDate}
          </span>
        </div>

        <Link
          href="/dashboard/cognitive/session"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#FAF8FF] border border-[#E4DEF5] text-xs font-bold text-[#6C3FC5] hover:bg-[#EDE9FE] transition-colors shadow-2xs"
        >
          <FileText className="w-3.5 h-3.5 text-[#6C3FC5]" strokeWidth={1.75} />
          <span>View Detailed Report</span>
        </Link>
      </div>
    </div>
  );
};
