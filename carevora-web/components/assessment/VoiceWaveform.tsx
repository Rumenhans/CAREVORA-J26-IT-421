"use client";

import React, { useEffect, useState } from "react";

interface VoiceWaveformProps {
  isListening: boolean;
}

export const VoiceWaveform: React.FC<VoiceWaveformProps> = ({ isListening }) => {
  const [bars, setBars] = useState<number[]>([
    20, 45, 75, 30, 85, 60, 40, 95, 65, 30, 50, 80, 40, 70, 90, 35, 55, 60,
  ]);

  useEffect(() => {
    if (!isListening) return;

    const interval = setInterval(() => {
      setBars((prev) =>
        prev.map(() => Math.floor(Math.random() * 75) + 20)
      );
    }, 120);

    return () => clearInterval(interval);
  }, [isListening]);

  return (
    <div className="flex items-center justify-center gap-1.5 h-12 py-2">
      {bars.map((height, idx) => (
        <div
          key={idx}
          className="w-1.5 rounded-full transition-all duration-100"
          style={{
            height: isListening ? `${height}%` : "15%",
            backgroundColor: isListening ? "#22C55E" : "#8E8CA3",
            opacity: isListening ? 0.9 : 0.35,
          }}
        />
      ))}
    </div>
  );
};
