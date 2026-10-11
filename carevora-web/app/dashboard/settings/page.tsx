"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, Sliders, Type, Volume2, Shield } from "lucide-react";

export default function SettingsPage() {
  return (
    <div className="space-y-6 max-w-3xl">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
            Caregiver Settings
          </h2>
          <p className="text-xs text-[#5B5A6E] mt-0.5">
            Accessibility options, voice synthesis parameters, and system preferences
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

      <div className="bg-white rounded-2xl border border-[#ECE8F7] p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] space-y-6">
        <div>
          <h3 className="font-bold text-sm text-[#1A1445] flex items-center gap-2 mb-3">
            <Type className="w-4 h-4 text-[#6C3FC5]" />
            <span>Accessibility & Visual Display</span>
          </h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3.5 rounded-xl bg-[#FAF8FF] border border-[#ECE8F7]">
              <div>
                <span className="text-xs font-bold text-[#1A1445] block">
                  Enhanced Font Sizing
                </span>
                <span className="text-[11px] text-[#8E8CA3]">
                  Increases interface font scaling for elderly care convenience
                </span>
              </div>
              <input
                type="checkbox"
                defaultChecked
                className="w-4 h-4 rounded text-[#6C3FC5] accent-[#6C3FC5]"
              />
            </div>
          </div>
        </div>

        <div>
          <h3 className="font-bold text-sm text-[#1A1445] flex items-center gap-2 mb-3">
            <Volume2 className="w-4 h-4 text-[#6C3FC5]" />
            <span>Voice & Audio Speech</span>
          </h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3.5 rounded-xl bg-[#FAF8FF] border border-[#ECE8F7]">
              <div>
                <span className="text-xs font-bold text-[#1A1445] block">
                  Automatic Question Read-Aloud
                </span>
                <span className="text-[11px] text-[#8E8CA3]">
                  Reads cognitive assessment questions via Web Speech Synthesis automatically
                </span>
              </div>
              <input
                type="checkbox"
                defaultChecked
                className="w-4 h-4 rounded text-[#6C3FC5] accent-[#6C3FC5]"
              />
            </div>
          </div>
        </div>

        <div>
          <h3 className="font-bold text-sm text-[#1A1445] flex items-center gap-2 mb-3">
            <Shield className="w-4 h-4 text-[#6C3FC5]" />
            <span>Data Privacy & Auditing</span>
          </h3>
          <p className="text-xs text-[#5B5A6E] leading-relaxed">
            All clinical observations, voice transcripts, and cognitive risk markers are encrypted with zero persistent voice audio transmission outside your verified care network.
          </p>
        </div>
      </div>
    </div>
  );
}
