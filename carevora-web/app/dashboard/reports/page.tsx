"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, FileBarChart, Download, Share2, Calendar } from "lucide-react";
import { mockResident, mockRecentAssessments } from "@/lib/mock-data";
import { RiskTrendChart } from "@/components/charts/RiskTrendChart";
import { ComponentDonutChart } from "@/components/charts/ComponentDonutChart";
import { RiskBadge } from "@/components/ui/RiskBadge";

export default function ReportsPage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <div>
          <h2 className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
            Reports & Clinical Analytics
          </h2>
          <p className="text-xs text-[#5B5A6E] mt-0.5">
            Comprehensive wellness analytics, longitudinal summaries, and downloadable PDF reports
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => alert("Exporting comprehensive clinical report PDF...")}
            className="px-4 py-2 rounded-xl bg-[#6C3FC5] text-white text-xs font-bold hover:bg-[#5B2FB0] transition-colors flex items-center gap-1.5 shadow-2xs"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Export PDF</span>
          </button>

          <Link
            href="/dashboard"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6C3FC5] hover:underline"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Dashboard</span>
          </Link>
        </div>
      </div>

      {/* Analytics Visuals Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="h-80">
          <RiskTrendChart />
        </div>
        <div className="h-80">
          <ComponentDonutChart />
        </div>
      </div>

      {/* Historical Summary Table */}
      <div className="bg-white rounded-2xl border border-[#ECE8F7] p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] space-y-4">
        <h3 className="font-bold text-sm text-[#1A1445]">
          Generated Clinical Session Reports
        </h3>

        <div className="divide-y divide-[#ECE8F7] text-xs">
          {mockRecentAssessments.map((item) => (
            <div key={item.id} className="py-3.5 flex items-center justify-between gap-4">
              <div className="space-y-1">
                <span className="font-bold text-[#1A1445] block">{item.dateTime}</span>
                <span className="text-[#8E8CA3]">Assessor: {item.assessedBy} • Status: {item.status}</span>
              </div>

              <div className="flex items-center gap-3">
                <RiskBadge score={item.overallRiskScore} />
                <button
                  onClick={() => alert(`Downloading detailed audit report for session ${item.id}`)}
                  className="p-2 rounded-lg border border-[#ECE8F7] text-[#6C3FC5] hover:bg-[#FAF8FF]"
                  title="Download report"
                >
                  <Download className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
