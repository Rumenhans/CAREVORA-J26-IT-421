import React from "react";

interface CitySkylineProps {
  className?: string;
  width?: number | string;
  height?: number | string;
}

export const CitySkyline: React.FC<CitySkylineProps> = ({
  className = "",
  width = "100%",
  height = 96,
}) => {
  return (
    <svg
      width={width}
      height={height}
      viewBox="0 0 600 120"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      preserveAspectRatio="none"
    >
      <defs>
        <linearGradient id="skyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#FAF8FF" stopOpacity="0.2" />
          <stop offset="100%" stopColor="#E9E1FF" stopOpacity="0.6" />
        </linearGradient>
      </defs>

      {/* Background Soft Sky Tint */}
      <rect width="600" height="120" fill="url(#skyGrad)" />

      {/* Subtle Pastel Horizon Sun / Moon */}
      <circle cx="480" cy="40" r="26" fill="#FDE2EE" fillOpacity="0.8" />

      {/* Distant skyline layer (very soft lavender) */}
      <path
        d="M 0 120 
           L 0 78 L 30 78 L 30 65 L 60 65 L 60 85 L 95 85 L 95 50 L 120 50 L 120 75 
           L 160 75 L 160 45 L 190 45 L 190 80 L 230 80 L 230 60 L 270 60 L 270 90 
           L 320 90 L 320 40 L 350 40 L 350 75 L 390 75 L 390 55 L 430 55 L 430 85 
           L 480 85 L 480 65 L 520 65 L 520 80 L 560 80 L 560 60 L 600 60 L 600 120 Z"
        fill="#EDE7FC"
        fillOpacity="0.6"
      />

      {/* Foreground pastel architectural silhouettes (soft violet/lavender with fine white windows) */}
      <path
        d="M 0 120 
           L 0 92 L 40 92 L 40 76 L 75 76 L 75 100 L 110 100 L 110 68 L 145 68 L 145 94 
           L 180 94 L 180 62 L 210 62 L 210 102 L 255 102 L 255 74 L 290 74 L 290 90 
           L 340 90 L 340 58 L 375 58 L 375 88 L 415 88 L 415 72 L 450 72 L 450 96 
           L 500 96 L 500 78 L 540 78 L 540 92 L 600 92 L 600 120 Z"
        fill="#DCD1F7"
        fillOpacity="0.85"
      />

      {/* Tiny architectural windows */}
      <rect x="120" y="78" width="6" height="8" rx="1" fill="#FFFFFF" fillOpacity="0.7" />
      <rect x="130" y="78" width="6" height="8" rx="1" fill="#FFFFFF" fillOpacity="0.7" />
      <rect x="190" y="72" width="6" height="8" rx="1" fill="#FFFFFF" fillOpacity="0.7" />
      <rect x="190" y="84" width="6" height="8" rx="1" fill="#FFFFFF" fillOpacity="0.7" />
      <rect x="350" y="68" width="6" height="8" rx="1" fill="#FFFFFF" fillOpacity="0.7" />
      <rect x="360" y="68" width="6" height="8" rx="1" fill="#FFFFFF" fillOpacity="0.7" />
      <rect x="350" y="80" width="6" height="8" rx="1" fill="#FFFFFF" fillOpacity="0.7" />
      <rect x="425" y="80" width="6" height="8" rx="1" fill="#FFFFFF" fillOpacity="0.7" />

      {/* Tree & greenery soft silhouettes at base */}
      <circle cx="28" cy="112" r="14" fill="#6CC24A" fillOpacity="0.4" />
      <circle cx="230" cy="114" r="12" fill="#6CC24A" fillOpacity="0.35" />
      <circle cx="475" cy="112" r="15" fill="#6CC24A" fillOpacity="0.4" />
    </svg>
  );
};
