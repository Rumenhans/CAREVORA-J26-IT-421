export type RiskLevel = "Low" | "Moderate" | "High";

export interface RiskConfig {
  label: RiskLevel;
  textColor: string;
  bgColor: string;
  borderColor: string;
  badgeClass: string;
}

/**
 * Carevora Risk Level Logic:
 * Score < 0.40       => Low (Green #22C55E, Soft BG #E7F8EE)
 * Score 0.40 - 0.69  => Moderate (Amber #F59E0B, Soft BG #FEF3DC)
 * Score >= 0.70      => High (Red #EF4444, Soft BG #FDE8E8)
 */
export function getRiskLevel(score: number): RiskLevel {
  if (score < 0.40) return "Low";
  if (score <= 0.69) return "Moderate";
  return "High";
}

export function getRiskConfig(scoreOrLevel: number | RiskLevel): RiskConfig {
  const level: RiskLevel =
    typeof scoreOrLevel === "number" ? getRiskLevel(scoreOrLevel) : scoreOrLevel;

  switch (level) {
    case "Low":
      return {
        label: "Low",
        textColor: "#22C55E",
        bgColor: "#E7F8EE",
        borderColor: "rgba(34, 197, 94, 0.25)",
        badgeClass: "bg-[#E7F8EE] text-[#22C55E] border-[#22C55E]/30",
      };
    case "Moderate":
      return {
        label: "Moderate",
        textColor: "#F59E0B",
        bgColor: "#FEF3DC",
        borderColor: "rgba(245, 158, 11, 0.25)",
        badgeClass: "bg-[#FEF3DC] text-[#F59E0B] border-[#F59E0B]/30",
      };
    case "High":
      return {
        label: "High",
        textColor: "#EF4444",
        bgColor: "#FDE8E8",
        borderColor: "rgba(239, 68, 68, 0.25)",
        badgeClass: "bg-[#FDE8E8] text-[#EF4444] border-[#EF4444]/30",
      };
  }
}
