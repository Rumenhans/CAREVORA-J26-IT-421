import React from "react";

interface LogoProps {
  size?: number;
  variant?: "full" | "icon" | "wordmark";
  className?: string;
  isSerif?: boolean;
}

export const Logo: React.FC<LogoProps> = ({
  size = 48,
  variant = "full",
  className = "",
  isSerif = false,
}) => {
  const iconSize = size;

  const renderIcon = () => (
    <svg
      width={iconSize}
      height={iconSize}
      viewBox="0 0 120 120"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className="shrink-0"
    >
      <defs>
        <filter id="softGlow" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="8" result="blur" />
          <feComposite in="SourceGraphic" in2="blur" operator="over" />
        </filter>
        <linearGradient id="purpleRingGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#8B5CF6" />
          <stop offset="100%" stopColor="#6C3FC5" />
        </linearGradient>
      </defs>

      {/* Ambient soft glow aura */}
      <circle cx="60" cy="60" r="46" fill="#E9E1FF" fillOpacity="0.45" />

      {/* Two green leaves at top right */}
      <g transform="translate(74, 14)">
        {/* Leaf 1 */}
        <path
          d="M 12 18 C 12 18, 26 14, 30 2 C 20 6, 12 12, 12 18 Z"
          fill="#6CC24A"
        />
        {/* Leaf 2 */}
        <path
          d="M 14 19 C 14 19, 32 24, 36 34 C 28 30, 20 25, 14 19 Z"
          fill="#7DD65A"
        />
      </g>

      {/* Heart-Shaped Ring (Primary Purple #6C3FC5) */}
      <path
        d="M 60 92 
           C 60 92, 18 64, 18 38 
           C 18 20, 36 14, 52 26 
           C 57 30, 60 34, 60 34 
           C 60 34, 63 30, 68 26 
           C 84 14, 102 20, 102 38 
           C 102 64, 60 92, 60 92 Z"
        stroke="url(#purpleRingGrad)"
        strokeWidth="7"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />

      {/* Supporting Caregiver Hand holding the heart base */}
      <path
        d="M 28 98 
           C 42 86, 54 84, 60 94 
           C 66 104, 76 102, 92 92"
        stroke="#5B2FB0"
        strokeWidth="5"
        strokeLinecap="round"
        fill="none"
      />

      {/* Inside: Purple adult figure embracing small pink figure */}
      {/* Adult Head */}
      <circle cx="50" cy="46" r="6.5" fill="#6C3FC5" />
      {/* Adult Body curve */}
      <path
        d="M 38 72 C 38 56, 52 54, 58 60 C 60 62, 60 68, 60 74 Z"
        fill="#6C3FC5"
      />

      {/* Child / Elderly protected Head (Accent Pink #E88BC4) */}
      <circle cx="68" cy="52" r="5" fill="#E88BC4" />
      {/* Child / Elderly Body */}
      <path
        d="M 62 72 C 62 60, 72 58, 76 64 C 77 66, 77 70, 76 74 Z"
        fill="#E88BC4"
      />

      {/* Gentle embrace arm */}
      <path
        d="M 50 60 C 58 58, 68 62, 70 66"
        stroke="#5B2FB0"
        strokeWidth="2.5"
        strokeLinecap="round"
      />
    </svg>
  );

  if (variant === "icon") {
    return <div className={`inline-flex items-center ${className}`}>{renderIcon()}</div>;
  }

  if (variant === "wordmark") {
    return (
      <div className={`flex flex-col ${className}`}>
        <span
          className={`font-bold tracking-[0.2em] text-[#1A1445] leading-none ${
            isSerif
              ? "font-[var(--font-cormorant)] text-2xl uppercase tracking-[0.25em]"
              : "font-[var(--font-jakarta)] text-xl"
          }`}
        >
          CAREVORA
        </span>
      </div>
    );
  }

  return (
    <div className={`inline-flex items-center gap-3 ${className}`}>
      {renderIcon()}
      <div className="flex flex-col">
        <span
          className={`font-bold text-[#1A1445] tracking-[0.18em] leading-tight ${
            isSerif
              ? "font-[var(--font-cormorant)] text-2xl uppercase tracking-[0.25em]"
              : "font-[var(--font-jakarta)] text-xl tracking-[0.14em]"
          }`}
        >
          CAREVORA
        </span>
        <span className="text-[10px] font-medium tracking-wide text-[#6C3FC5]">
          Compassionate Care, Smarter Tomorrow
        </span>
      </div>
    </div>
  );
};
