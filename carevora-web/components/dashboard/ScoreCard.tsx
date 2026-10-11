"use client";

import React from "react";
import { ArrowUp, ArrowDown } from "lucide-react";
import { RiskBadge } from "@/components/ui/RiskBadge";

interface ScoreCardProps {
  title: string;
  score: number; // 0.00 to 1.00
  delta: number; // e.g. +0.08
  customColor?: string;
  isGauge?: boolean;
}

export const ScoreCard: React.FC<ScoreCardProps> = ({
  title,
  score,
  delta,
  isGauge = false,
}) => {
  // Semi-circle gauge rendering for Overall Wellness Index
  if (isGauge) {
    const percentage = Math.min(Math.max(score * 100, 0), 100);
    // Gauge stroke rotation: 180 degrees sweep
    const radius = 38;
    const circumference = Math.PI * radius;
    const strokeDashoffset = circumference - (circumference * percentage) / 100;

    return (
      <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col justify-between h-full min-w-[220px]">
        <div className="flex items-center justify-between">
          <span className="text-xs font-bold text-[#5B5A6E] tracking-tight">
            {title}
          </span>
          <RiskBadge score={score} />
        </div>

        {/* Semicircle Gauge Visual */}
        <div className="relative flex flex-col items-center justify-center my-2">
          <svg width="120" height="70" viewBox="0 0 120 70" className="overflow-visible">
            {/* Background Arch */}
            <path
              d="M 15 65 A 45 45 0 0 1 105 65"
              fill="none"
              stroke="#F4F0FF"
              strokeWidth="9"
              strokeLinecap="round"
            />
            {/* Value Arch */}
            <path
              d="M 15 65 A 45 45 0 0 1 105 65"
              fill="none"
              stroke="#6C3FC5"
              strokeWidth="9"
              strokeLinecap="round"
              strokeDasharray={141}
              strokeDashoffset={141 - (141 * percentage) / 100}
              className="transition-all duration-700 ease-out"
            />
          </svg>
          <div className="absolute bottom-0 text-center">
            <span className="font-[var(--font-jakarta)] text-2xl font-extrabold text-[#1A1445]">
              {score.toFixed(2)}
            </span>
          </div>
        </div>

        <div className="flex items-center justify-between text-xs pt-1 border-t border-[#ECE8F7]/60">
          <span className="text-[#8E8CA3]">Out of 1.00</span>
          <div className="flex items-center text-xs font-bold text-[#22C55E]">
            <ArrowUp className="w-3.5 h-3.5" />
            <span>{delta.toFixed(2)}</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col justify-between h-full min-w-[220px]">
      <div className="flex items-center justify-between">
        <span className="text-xs font-bold text-[#5B5A6E] tracking-tight">
          {title}
        </span>
        <RiskBadge score={score} />
      </div>

      <div className="my-3">
        <div className="flex items-baseline gap-1">
          <span className="font-[var(--font-jakarta)] text-3xl font-extrabold text-[#1A1445]">
            {score.toFixed(2)}
          </span>
          <span className="text-xs text-[#8E8CA3] font-semibold">/ 1.00</span>
        </div>
      </div>

      <div className="flex items-center justify-between text-xs pt-2 border-t border-[#ECE8F7]/60">
        <span className="text-[#8E8CA3]">vs. last month</span>
        <div
          className={`flex items-center text-xs font-bold ${
            delta >= 0 ? "text-[#EF4444]" : "text-[#22C55E]"
          }`}
        >
          {delta >= 0 ? (
            <ArrowUp className="w-3.5 h-3.5" />
          ) : (
            <ArrowDown className="w-3.5 h-3.5" />
          )}
          <span>{Math.abs(delta).toFixed(2)}</span>
        </div>
      </div>
    </div>
  );
};
