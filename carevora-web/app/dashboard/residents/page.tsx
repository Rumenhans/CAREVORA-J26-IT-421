"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, Users, ArrowUpRight } from "lucide-react";
import { mockResident } from "@/lib/mock-data";
import { RiskBadge } from "@/components/ui/RiskBadge";

export default function ResidentsPage() {
  const residentsList = [
    mockResident,
    {
      id: "9002",
      name: "Mrs. Margaret Silva",
      age: 82,
      gender: "Female",
      roomNumber: "108",
      lastAssessmentDate: "11 May 2025, 04:15 PM",
      overallWellnessIndex: 0.74,
      cognitiveHealthScore: 0.70,
      emotionalWellnessScore: 0.65,
      metabolicHealthScore: 0.81,
      cognitiveTrendDelta: 0.05,
      emotionalTrendDelta: -0.02,
      metabolicTrendDelta: 0.08,
      overallTrendDelta: 0.04,
    },
    {
      id: "9003",
      name: "Mr. Arthur Fernando",
      age: 75,
      gender: "Male",
      roomNumber: "204",
      lastAssessmentDate: "09 May 2025, 11:00 AM",
      overallWellnessIndex: 0.38,
      cognitiveHealthScore: 0.35,
      emotionalWellnessScore: 0.42,
      metabolicHealthScore: 0.39,
      cognitiveTrendDelta: -0.04,
      emotionalTrendDelta: -0.06,
      metabolicTrendDelta: -0.02,
      overallTrendDelta: -0.05,
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
            Residents Directory
          </h2>
          <p className="text-xs text-[#5B5A6E] mt-0.5">
            Active resident profiles and multimodal wellness monitoring
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

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {residentsList.map((res) => (
          <div
            key={res.id}
            className="bg-white rounded-2xl border border-[#ECE8F7] p-5 shadow-[0_8px_24px_rgba(108,63,197,0.06)] space-y-4"
          >
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#6C3FC5] to-[#5B2FB0] text-white flex items-center justify-center font-bold text-sm">
                  {res.name.split(" ").map((n) => n[0]).slice(0, 2).join("")}
                </div>
                <div>
                  <h3 className="font-bold text-sm text-[#1A1445]">{res.name}</h3>
                  <p className="text-xs text-[#8E8CA3]">
                    ID: {res.id} • Room {res.roomNumber}
                  </p>
                </div>
              </div>
              <RiskBadge score={res.overallWellnessIndex} />
            </div>

            <div className="grid grid-cols-3 gap-2 p-3 rounded-xl bg-[#FAF8FF] border border-[#ECE8F7] text-center text-xs">
              <div>
                <span className="text-[#8E8CA3] text-[10px] block">Cognitive</span>
                <span className="font-bold text-[#1A1445]">
                  {res.cognitiveHealthScore.toFixed(2)}
                </span>
              </div>
              <div>
                <span className="text-[#8E8CA3] text-[10px] block">Emotional</span>
                <span className="font-bold text-[#1A1445]">
                  {res.emotionalWellnessScore.toFixed(2)}
                </span>
              </div>
              <div>
                <span className="text-[#8E8CA3] text-[10px] block">Metabolic</span>
                <span className="font-bold text-[#1A1445]">
                  {res.metabolicHealthScore.toFixed(2)}
                </span>
              </div>
            </div>

            <div className="flex items-center justify-between text-xs pt-1">
              <span className="text-[#8E8CA3]">
                {res.gender}, {res.age} yrs
              </span>
              <Link
                href="/dashboard/cognitive/session"
                className="font-bold text-[#6C3FC5] hover:underline flex items-center gap-1"
              >
                <span>Assess</span>
                <ArrowUpRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
