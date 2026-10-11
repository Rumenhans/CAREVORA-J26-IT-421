"use client";

import React from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceArea,
} from "recharts";
import { ArrowUpRight } from "lucide-react";
import { mockRiskTrendData } from "@/lib/mock-data";

export const RiskTrendChart: React.FC = () => {
  return (
    <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 sm:p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col justify-between h-full">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="font-[var(--font-jakarta)] text-sm sm:text-base font-extrabold text-[#1A1445]">
            Overall Risk Trend
          </h3>
          <p className="text-[11px] text-[#8E8CA3] mt-0.5">
            Temporal fluctuation across clinical assessments
          </p>
        </div>

        <a
          href="#full-trend"
          className="text-xs font-semibold text-[#6C3FC5] hover:underline inline-flex items-center gap-1"
        >
          <span>View Full Trend</span>
          <ArrowUpRight className="w-3.5 h-3.5" />
        </a>
      </div>

      {/* Chart container */}
      <div className="w-full h-52 sm:h-56">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart
            data={mockRiskTrendData}
            margin={{ top: 12, right: 16, left: -20, bottom: 0 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#F4F0FF" vertical={false} />
            <XAxis
              dataKey="date"
              stroke="#8E8CA3"
              fontSize={11}
              tickLine={false}
              axisLine={{ stroke: "#ECE8F7" }}
            />
            <YAxis
              domain={[0.3, 0.7]}
              stroke="#8E8CA3"
              fontSize={11}
              tickLine={false}
              axisLine={{ stroke: "#ECE8F7" }}
              ticks={[0.3, 0.4, 0.5, 0.6, 0.7]}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: "#FFFFFF",
                borderRadius: "12px",
                border: "1px solid #ECE8F7",
                boxShadow: "0 8px 24px rgba(108,63,197,0.08)",
                fontSize: "12px",
              }}
              formatter={(val: any) => [`${Number(val).toFixed(2)}`, "Risk Score"]}
            />
            {/* Risk background zones */}
            <ReferenceArea y1={0.3} y2={0.4} fill="#22C55E" fillOpacity={0.04} />
            <ReferenceArea y1={0.4} y2={0.69} fill="#F59E0B" fillOpacity={0.04} />
            <ReferenceArea y1={0.7} y2={0.8} fill="#EF4444" fillOpacity={0.04} />

            <Line
              type="monotone"
              dataKey="risk"
              stroke="#6C3FC5"
              strokeWidth={3}
              dot={{
                r: 4,
                fill: "#6C3FC5",
                stroke: "#FFFFFF",
                strokeWidth: 2,
              }}
              activeDot={{
                r: 6,
                fill: "#5B2FB0",
                stroke: "#FFFFFF",
                strokeWidth: 2,
              }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Legend */}
      <div className="flex items-center justify-center gap-6 mt-3 pt-3 border-t border-[#ECE8F7]/60 text-[11px]">
        <div className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-[#22C55E]" />
          <span className="text-[#5B5A6E] font-medium">Low (&lt; 0.40)</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-[#F59E0B]" />
          <span className="text-[#5B5A6E] font-medium">Moderate (0.40 - 0.69)</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-[#EF4444]" />
          <span className="text-[#5B5A6E] font-medium">High (&ge; 0.70)</span>
        </div>
      </div>
    </div>
  );
};
