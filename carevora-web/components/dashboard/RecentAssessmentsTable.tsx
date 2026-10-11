"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowUpRight } from "lucide-react";
import { AssessmentRecord } from "@/lib/mock-data";
import { RiskBadge } from "@/components/ui/RiskBadge";
import { AssessmentDetailDrawer } from "./AssessmentDetailDrawer";

interface RecentAssessmentsTableProps {
  assessments: AssessmentRecord[];
}

export const RecentAssessmentsTable: React.FC<RecentAssessmentsTableProps> = ({
  assessments,
}) => {
  const [selectedAssessment, setSelectedAssessment] =
    useState<AssessmentRecord | null>(null);

  return (
    <div className="w-full bg-white rounded-2xl border border-[#ECE8F7] p-5 sm:p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)]">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 mb-5">
        <div>
          <h3 className="font-[var(--font-jakarta)] text-sm sm:text-base font-extrabold text-[#1A1445]">
            Recent Assessments
          </h3>
          <p className="text-[11px] text-[#8E8CA3] mt-0.5">
            Historical multimodal risk scores for Mr. James Perera
          </p>
        </div>

        <Link
          href="/dashboard/cognitive/history"
          className="text-xs font-semibold text-[#6C3FC5] hover:underline inline-flex items-center gap-1"
        >
          <span>View All Assessments</span>
          <ArrowUpRight className="w-3.5 h-3.5" />
        </Link>
      </div>

      {/* Desktop Table View */}
      <div className="overflow-x-auto hidden md:block">
        <table className="w-full text-left border-collapse text-xs">
          <thead>
            <tr className="border-b border-[#ECE8F7] text-[#8E8CA3] font-semibold text-[11px]">
              <th className="pb-3 font-semibold">Date & Time</th>
              <th className="pb-3 font-semibold">Cognitive</th>
              <th className="pb-3 font-semibold">Emotional</th>
              <th className="pb-3 font-semibold">Metabolic</th>
              <th className="pb-3 font-semibold">Overall Risk</th>
              <th className="pb-3 font-semibold">Assessed By</th>
              <th className="pb-3 font-semibold text-right">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#ECE8F7]/60">
            {assessments.slice(0, 3).map((item) => (
              <tr key={item.id} className="hover:bg-[#FAF8FF]/60 transition-colors">
                <td className="py-3.5 font-bold text-[#1A1445]">
                  {item.dateTime}
                </td>
                <td className="py-3.5">
                  <div className="flex items-center gap-2">
                    <span className="font-extrabold text-[#1A1445]">
                      {item.cognitiveScore.toFixed(2)}
                    </span>
                    <RiskBadge score={item.cognitiveScore} />
                  </div>
                </td>
                <td className="py-3.5">
                  <div className="flex items-center gap-2">
                    <span className="font-extrabold text-[#1A1445]">
                      {item.emotionalScore.toFixed(2)}
                    </span>
                    <RiskBadge score={item.emotionalScore} />
                  </div>
                </td>
                <td className="py-3.5">
                  <div className="flex items-center gap-2">
                    <span className="font-extrabold text-[#1A1445]">
                      {item.metabolicScore.toFixed(2)}
                    </span>
                    <RiskBadge score={item.metabolicScore} />
                  </div>
                </td>
                <td className="py-3.5">
                  <div className="flex items-center gap-2">
                    <span className="font-extrabold text-[#1A1445]">
                      {item.overallRiskScore.toFixed(2)}
                    </span>
                    <RiskBadge score={item.overallRiskScore} />
                  </div>
                </td>
                <td className="py-3.5 text-[#5B5A6E] font-medium">
                  {item.assessedBy}
                </td>
                <td className="py-3.5 text-right">
                  <button
                    onClick={() => setSelectedAssessment(item)}
                    className="px-3 py-1.5 rounded-lg border border-[#E4DEF5] bg-[#FAF8FF] text-[11px] font-bold text-[#6C3FC5] hover:bg-[#EDE9FE] transition-colors"
                  >
                    Details
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile Card List View (< 768px) */}
      <div className="space-y-3 md:hidden">
        {assessments.slice(0, 3).map((item) => (
          <div
            key={item.id}
            className="p-4 rounded-xl border border-[#ECE8F7] bg-[#FAF8FF]/40 space-y-2.5"
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-[#1A1445]">
                {item.dateTime}
              </span>
              <RiskBadge score={item.overallRiskScore} />
            </div>

            <div className="grid grid-cols-3 gap-2 text-[11px] pt-1">
              <div>
                <span className="text-[#8E8CA3] block">Cognitive</span>
                <span className="font-bold text-[#1A1445]">
                  {item.cognitiveScore.toFixed(2)}
                </span>
              </div>
              <div>
                <span className="text-[#8E8CA3] block">Emotional</span>
                <span className="font-bold text-[#1A1445]">
                  {item.emotionalScore.toFixed(2)}
                </span>
              </div>
              <div>
                <span className="text-[#8E8CA3] block">Metabolic</span>
                <span className="font-bold text-[#1A1445]">
                  {item.metabolicScore.toFixed(2)}
                </span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-2 border-t border-[#ECE8F7] text-xs">
              <span className="text-[11px] text-[#8E8CA3]">
                By {item.assessedBy}
              </span>
              <button
                onClick={() => setSelectedAssessment(item)}
                className="px-3 py-1 rounded-lg bg-[#6C3FC5] text-white text-[11px] font-bold"
              >
                Details
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Table Footer */}
      <div className="flex items-center justify-between mt-4 pt-3 border-t border-[#ECE8F7]/60 text-xs text-[#8E8CA3]">
        <span>Showing last 3 assessments</span>
        <Link
          href="/dashboard/cognitive/history"
          className="text-[#6C3FC5] font-semibold hover:underline"
        >
          View All Assessments &rarr;
        </Link>
      </div>

      {/* Detail Slide Drawer */}
      <AssessmentDetailDrawer
        assessment={selectedAssessment}
        onClose={() => setSelectedAssessment(null)}
      />
    </div>
  );
};
