"use client";

import React from "react";
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts";
import { Brain } from "lucide-react";
import { mockRiskContribution } from "@/lib/mock-data";

export const ComponentDonutChart: React.FC = () => {
  return (
    <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 sm:p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col justify-between h-full">
      <div className="mb-2">
        <h3 className="font-[var(--font-jakarta)] text-sm sm:text-base font-extrabold text-[#1A1445]">
          Component Contribution to Overall Risk
        </h3>
        <p className="text-[11px] text-[#8E8CA3] mt-0.5">
          Proportional weight breakdown
        </p>
      </div>

      {/* Donut with Center Brain Icon */}
      <div className="relative w-full h-44 flex items-center justify-center">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Tooltip
              formatter={(val: any, name: any) => [`${val}%`, `${name}`]}
              contentStyle={{
                backgroundColor: "#FFFFFF",
                borderRadius: "10px",
                border: "1px solid #ECE8F7",
                fontSize: "12px",
              }}
            />
            <Pie
              data={mockRiskContribution}
              cx="50%"
              cy="50%"
              innerRadius={52}
              outerRadius={72}
              paddingAngle={3}
              dataKey="value"
            >
              {mockRiskContribution.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} />
              ))}
            </Pie>
          </PieChart>
        </ResponsiveContainer>

        {/* Center Brain Icon */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="w-11 h-11 rounded-full bg-[#FAF8FF] border border-[#E9E1FF] flex items-center justify-center shadow-xs">
            <Brain className="w-5 h-5 text-[#6C3FC5]" strokeWidth={1.75} />
          </div>
        </div>
      </div>

      {/* Legend with percentages */}
      <div className="grid grid-cols-3 gap-2 pt-3 border-t border-[#ECE8F7]/60 text-center">
        {mockRiskContribution.map((item) => (
          <div key={item.name} className="flex flex-col items-center">
            <div className="flex items-center gap-1.5">
              <span
                className="w-2.5 h-2.5 rounded-full"
                style={{ backgroundColor: item.color }}
              />
              <span className="text-[11px] font-semibold text-[#5B5A6E]">
                {item.name}
              </span>
            </div>
            <span className="text-xs font-bold text-[#1A1445] mt-0.5">
              {item.value}%
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};
