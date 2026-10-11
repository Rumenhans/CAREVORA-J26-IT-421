import React from "react";

interface CaregiverHandsProps {
  className?: string;
  width?: number | string;
  height?: number | string;
}

export const CaregiverHands: React.FC<CaregiverHandsProps> = ({
  className = "",
  width = 320,
  height = 140,
}) => {
  return (
    <svg
      width={width}
      height={height}
      viewBox="0 0 340 140"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      <defs>
        <filter id="handsAura" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="24" />
        </filter>
      </defs>

      {/* Translucent aura glow */}
      <ellipse
        cx="170"
        cy="75"
        rx="110"
        ry="45"
        fill="#E9E1FF"
        fillOpacity="0.45"
        filter="url(#handsAura)"
      />

      {/* Supporting Caregiver Hand (Left) */}
      <path
        d="M 35 130 
           C 75 105, 110 80, 150 72 
           C 188 66, 222 75, 245 92 
           C 205 114, 135 128, 90 135 Z"
        fill="#6C3FC5"
        fillOpacity="0.08"
        stroke="#5B2FB0"
        strokeWidth="2.2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />

      {/* Elderly gently resting hand (Right) */}
      <path
        d="M 300 48 
           C 255 58, 210 66, 178 78 
           C 152 86, 142 100, 162 105 
           C 198 106, 232 90, 265 72 Z"
        fill="#6C3FC5"
        fillOpacity="0.09"
        stroke="#6C3FC5"
        strokeWidth="2.0"
        strokeLinecap="round"
        strokeLinejoin="round"
      />

      {/* Botanical left twigs */}
      <path
        d="M 15 125 C 28 90, 55 94, 15 125 Z"
        fill="#6CC24A"
        fillOpacity="0.30"
      />
      {/* Botanical right twigs */}
      <path
        d="M 320 120 C 300 90, 275 98, 320 120 Z"
        fill="#6CC24A"
        fillOpacity="0.30"
      />
    </svg>
  );
};
