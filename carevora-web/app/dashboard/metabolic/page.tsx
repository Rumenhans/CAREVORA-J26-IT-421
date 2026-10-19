"use client";

import Link from "next/link";
import { ArrowLeft, Activity, HeartPulse, Droplet, Thermometer, TrendingUp } from "lucide-react";
import { mockResident } from "@/lib/mock-data";
import { RiskBadge } from "@/components/ui/RiskBadge";

export default function MetabolicHealthPage() {
  const vitals = [
    {
      label: "Blood Pressure",
      value: "128/82 mmHg",
      status: "Optimal",
      icon: HeartPulse,
      color: "#22C55E",
      bg: "#E7F8EE",
    },
    {
      label: "Fasting Blood Glucose",
      value: "108 mg/dL",
      status: "Normal",
      icon: Droplet,
      color: "#22C55E",
      bg: "#E7F8EE",
    },
    {
      label: "Body Temperature",
      value: "98.4 °F",
      status: "Normal",
      icon: Thermometer,
      color: "#6C3FC5",
      bg: "#EDE9FE",
    },
    {
      label: "Heart Rate (Resting)",
      value: "72 bpm",
      status: "Stable",
      icon: Activity,
      color: "#22C55E",
      bg: "#E7F8EE",
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
            Metabolic & Physiological Health
          </h2>
          <p className="text-xs text-[#5B5A6E] mt-0.5">
            Vital parameters, glycemic tracking, cardiovascular indices, and physical stability
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
          <div className="w-14 h-14 rounded-2xl bg-[#FEF3DC] text-[#F59E0B] flex items-center justify-center shrink-0">
            <Activity className="w-7 h-7" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-extrabold text-lg text-[#1A1445]">
                Metabolic Score: {mockResident.metabolicHealthScore.toFixed(2)}
              </h3>
              <RiskBadge score={mockResident.metabolicHealthScore} />
            </div>
            <p className="text-xs text-[#5B5A6E] mt-1">
              Multimodal physiological baseline integration for Mr. James Perera
            </p>
          </div>
        </div>

        <div className="p-3 rounded-xl bg-[#FAF8FF] border border-[#ECE8F7] text-center">
          <span className="text-[#8E8CA3] text-[10px] block font-bold uppercase">
            30-Day Metabolic Variance
          </span>
          <span className="font-extrabold text-[#22C55E] text-sm mt-0.5 block flex items-center justify-center gap-0.5">
            <TrendingUp className="w-3.5 h-3.5" /> +0.04 Stable
          </span>
        </div>
      </div>

      {/* Vitals Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {vitals.map((vital, index) => {
          const Icon = vital.icon;
          return (
            <div
              key={index}
              className="bg-white rounded-2xl border border-[#ECE8F7] p-5 shadow-[0_8px_24px_rgba(108,63,197,0.06)] space-y-3"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-[#8E8CA3]">{vital.label}</span>
                <div
                  className="w-8 h-8 rounded-xl flex items-center justify-center"
                  style={{ backgroundColor: vital.bg, color: vital.color }}
                >
                  <Icon className="w-4 h-4" />
                </div>
              </div>

              <div>
                <span className="font-[var(--font-jakarta)] text-2xl font-extrabold text-[#1A1445] block">
                  {vital.value}
                </span>
                <span className="text-[11px] font-bold text-[#22C55E] mt-1 inline-block">
                  ● {vital.status}
                </span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
