import React from "react";
import { getRiskConfig, RiskLevel } from "@/lib/risk-utils";

interface RiskBadgeProps {
  score?: number;
  level?: RiskLevel;
  className?: string;
  showDot?: boolean;
}

export const RiskBadge: React.FC<RiskBadgeProps> = ({
  score,
  level,
  className = "",
  showDot = true,
}) => {
  const config = getRiskConfig(score !== undefined ? score : level ?? "Low");

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold border ${config.badgeClass} ${className}`}
    >
      {showDot && (
        <span
          className="w-1.5 h-1.5 rounded-full"
          style={{ backgroundColor: config.textColor }}
        />
      )}
      {config.label}
    </span>
  );
};
