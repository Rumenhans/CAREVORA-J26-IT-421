"use client";

import React, { useEffect, useState } from "react";
import { ResidentHeaderCard } from "@/components/dashboard/ResidentHeaderCard";
import { ScoreCard } from "@/components/dashboard/ScoreCard";
import { RiskTrendChart } from "@/components/charts/RiskTrendChart";
import { ComponentDonutChart } from "@/components/charts/ComponentDonutChart";
import { AlertsList } from "@/components/dashboard/AlertsList";
import { RecentAssessmentsTable } from "@/components/dashboard/RecentAssessmentsTable";
import {
  mockResident,
  mockRecentAssessments,
  AssessmentRecord,
} from "@/lib/mock-data";

export default function DashboardOverviewPage() {
  const [assessments, setAssessments] = useState<AssessmentRecord[]>(
    mockRecentAssessments
  );

  useEffect(() => {
    // Check if new completed session was recorded in localStorage
    if (typeof window !== "undefined") {
      const stored = localStorage.getItem("carevora_latest_assessment");
      if (stored) {
        try {
          const parsed = JSON.parse(stored);
          setAssessments([parsed, ...mockRecentAssessments]);
        } catch {
          // fallback
        }
      }
    }
  }, []);

  return (
    <div className="space-y-6">
      {/* 1. Resident Identity Top Card */}
      <ResidentHeaderCard resident={mockResident} />

      {/* 2. 4 Multimodal Score Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 overflow-x-auto pb-1">
        <ScoreCard
          title="Cognitive Health"
          score={mockResident.cognitiveHealthScore}
          delta={mockResident.cognitiveTrendDelta}
        />
        <ScoreCard
          title="Emotional Wellness"
          score={mockResident.emotionalWellnessScore}
          delta={mockResident.emotionalTrendDelta}
        />
        <ScoreCard
          title="Metabolic Health"
          score={mockResident.metabolicHealthScore}
          delta={mockResident.metabolicTrendDelta}
        />
        <ScoreCard
          title="Overall Wellness Index"
          score={mockResident.overallWellnessIndex}
          delta={mockResident.overallTrendDelta}
          isGauge={true}
        />
      </div>

      {/* 3. Middle Analytics Row: Trend Line, Contribution Donut, Alerts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-1 min-h-[340px]">
          <RiskTrendChart />
        </div>
        <div className="lg:col-span-1 min-h-[340px]">
          <ComponentDonutChart />
        </div>
        <div className="lg:col-span-1 min-h-[340px]">
          <AlertsList />
        </div>
      </div>

      {/* 4. Recent Assessments Table */}
      <div>
        <RecentAssessmentsTable assessments={assessments} />
      </div>
    </div>
  );
}
