"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, Heart, Smile, Frown, Sparkles, TrendingUp } from "lucide-react";
import { mockResident } from "@/lib/mock-data";
import { RiskBadge } from "@/components/ui/RiskBadge";

export default function EmotionalWellnessPage() {
  const emotionalLog = [
    {
      date: "Today, 10:30 AM",
      valence: "Positive (0.78)",
      dominantAffect: "Relaxed / Happy",
      cues: "Smiling composure, relaxed resting brow, steady eye engagement",
      risk: "Low",
    },
    {
      date: "Yesterday, 02:45 PM",
      valence: "Neutral (0.61)",
      dominantAffect: "Calm / Pensive",
      cues: "Mild conversational hesitation, slight flat affect during memory task",
      risk: "Moderate",
    },
    {
      date: "07 May 2025, 09:15 AM",
      valence: "Elevated Distress (0.42)",
      dominantAffect: "Withdrawn",
      cues: "Furrowed brow, minimal verbal response, fidgeting posture",
      risk: "High",
    },
  ];

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
            Emotional Wellness & Affect Analysis
          </h2>
          <p className="text-xs text-[#5B5A6E] mt-0.5">
            AI-driven facial affect detection, vocal prosody emotion, and psychological well-being
          </p>
        </div>

        <Link
          href="/dashboard"
          className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6C3FC5] hover:underline"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back to Dashboard</span>
        </Link>
      </div>

      {/* Overview Card */}
      <div className="bg-white rounded-2xl border border-[#ECE8F7] p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-[#FDE8E8] text-[#EF4444] flex items-center justify-center shrink-0">
            <Heart className="w-7 h-7 fill-current" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-extrabold text-lg text-[#1A1445]">
                Emotional Index: {mockResident.emotionalWellnessScore.toFixed(2)}
              </h3>
              <RiskBadge score={mockResident.emotionalWellnessScore} />
            </div>
            <p className="text-xs text-[#5B5A6E] mt-1">
              Grounded on FER-2013 Affect Dimensions & Acoustic Tone Analysis
            </p>
          </div>
        </div>

        <div className="flex items-center gap-4 text-xs">
          <div className="p-3 rounded-xl bg-[#FAF8FF] border border-[#ECE8F7] text-center">
            <span className="text-[#8E8CA3] text-[10px] block font-bold uppercase">
              Dominant State
            </span>
            <span className="font-extrabold text-[#1A1445] text-sm mt-0.5 block">
              Serene / Cheerful
            </span>
          </div>
          <div className="p-3 rounded-xl bg-[#FAF8FF] border border-[#ECE8F7] text-center">
            <span className="text-[#8E8CA3] text-[10px] block font-bold uppercase">
              30-Day Trend
            </span>
            <span className="font-extrabold text-[#22C55E] text-sm mt-0.5 block flex items-center justify-center gap-0.5">
              <TrendingUp className="w-3.5 h-3.5" /> +12%
            </span>
          </div>
        </div>
      </div>

      {/* Affect Logs */}
      <div className="bg-white rounded-2xl border border-[#ECE8F7] p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] space-y-4">
        <h3 className="font-bold text-sm text-[#1A1445]">
          Recent Affect & Mood Detection Sessions
        </h3>

        <div className="divide-y divide-[#ECE8F7]">
          {emotionalLog.map((log, index) => (
            <div key={index} className="py-4 flex flex-col md:flex-row items-start md:items-center justify-between gap-3">
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold text-[#1A1445]">{log.date}</span>
                  <span className="text-xs font-semibold text-[#6C3FC5]">({log.valence})</span>
                  <RiskBadge level={log.risk as any} />
                </div>
                <p className="text-xs text-[#5B5A6E] font-medium">{log.cues}</p>
              </div>

              <span className="px-3 py-1 rounded-full bg-[#FAF8FF] border border-[#E9E1FF] text-xs font-bold text-[#5B2FB0]">
                {log.dominantAffect}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
