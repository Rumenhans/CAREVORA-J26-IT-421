"use client";

import React from "react";
import { X, CheckCircle2, AlertTriangle, FileText, User, Calendar } from "lucide-react";
import { AssessmentRecord } from "@/lib/mock-data";
import { RiskBadge } from "@/components/ui/RiskBadge";

interface AssessmentDetailDrawerProps {
  assessment: AssessmentRecord | null;
  onClose: () => void;
}

export const AssessmentDetailDrawer: React.FC<AssessmentDetailDrawerProps> = ({
  assessment,
  onClose,
}) => {
  if (!assessment) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/40 backdrop-blur-xs transition-opacity"
        onClick={onClose}
      />

      {/* Drawer */}
      <div className="relative w-full max-w-md bg-white h-full shadow-2xl flex flex-col z-10 animate-in slide-in-from-right duration-300">
        {/* Header */}
        <div className="p-5 border-b border-[#ECE8F7] flex items-center justify-between bg-[#FAF8FF]">
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-[#6C3FC5]">
              Assessment Report
            </span>
            <h3 className="font-[var(--font-jakarta)] text-lg font-extrabold text-[#1A1445]">
              Session Details
            </h3>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-xl border border-[#ECE8F7] bg-white text-[#5B5A6E] hover:text-[#1A1445]"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body Content */}
        <div className="p-6 overflow-y-auto space-y-6 flex-1 text-sm">
          {/* Metadata Grid */}
          <div className="grid grid-cols-2 gap-3 p-4 rounded-xl bg-[#F8F7FC] border border-[#ECE8F7]">
            <div>
              <span className="text-[11px] text-[#8E8CA3] block">Date & Time</span>
              <span className="text-xs font-bold text-[#1A1445] flex items-center gap-1 mt-0.5">
                <Calendar className="w-3 h-3 text-[#6C3FC5]" />
                {assessment.dateTime}
              </span>
            </div>
            <div>
              <span className="text-[11px] text-[#8E8CA3] block">Assessed By</span>
              <span className="text-xs font-bold text-[#1A1445] flex items-center gap-1 mt-0.5">
                <User className="w-3 h-3 text-[#6C3FC5]" />
                {assessment.assessedBy}
              </span>
            </div>
          </div>

          {/* Scores Breakdown */}
          <div>
            <h4 className="font-bold text-xs text-[#1A1445] uppercase tracking-wider mb-3">
              Multimodal Clinical Scores
            </h4>
            <div className="space-y-2.5">
              <div className="flex items-center justify-between p-3 rounded-xl border border-[#ECE8F7]">
                <span className="text-xs font-semibold text-[#5B5A6E]">
                  Cognitive Health
                </span>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-extrabold text-[#1A1445]">
                    {assessment.cognitiveScore.toFixed(2)}
                  </span>
                  <RiskBadge score={assessment.cognitiveScore} />
                </div>
              </div>

              <div className="flex items-center justify-between p-3 rounded-xl border border-[#ECE8F7]">
                <span className="text-xs font-semibold text-[#5B5A6E]">
                  Emotional Wellness
                </span>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-extrabold text-[#1A1445]">
                    {assessment.emotionalScore.toFixed(2)}
                  </span>
                  <RiskBadge score={assessment.emotionalScore} />
                </div>
              </div>

              <div className="flex items-center justify-between p-3 rounded-xl border border-[#ECE8F7]">
                <span className="text-xs font-semibold text-[#5B5A6E]">
                  Metabolic Health
                </span>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-extrabold text-[#1A1445]">
                    {assessment.metabolicScore.toFixed(2)}
                  </span>
                  <RiskBadge score={assessment.metabolicScore} />
                </div>
              </div>

              <div className="flex items-center justify-between p-3 rounded-xl border-2 border-[#E9E1FF] bg-[#FAF8FF]">
                <span className="text-xs font-bold text-[#5B2FB0]">
                  Overall Composite Risk
                </span>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-extrabold text-[#1A1445]">
                    {assessment.overallRiskScore.toFixed(2)}
                  </span>
                  <RiskBadge score={assessment.overallRiskScore} />
                </div>
              </div>
            </div>
          </div>

          {/* Clinical Caregiver Notes */}
          <div>
            <h4 className="font-bold text-xs text-[#1A1445] uppercase tracking-wider mb-2">
              Caregiver Clinical Observations
            </h4>
            <div className="p-3.5 rounded-xl bg-[#FAF8FF] border border-[#ECE8F7] text-xs text-[#5B5A6E] leading-relaxed">
              {assessment.notes || "No additional clinical notes recorded."}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-[#ECE8F7] bg-white">
          <button
            onClick={onClose}
            className="w-full py-2.5 rounded-xl bg-[#6C3FC5] text-white font-bold text-xs hover:bg-[#5B2FB0] transition-colors"
          >
            Close Report
          </button>
        </div>
      </div>
    </div>
  );
};
