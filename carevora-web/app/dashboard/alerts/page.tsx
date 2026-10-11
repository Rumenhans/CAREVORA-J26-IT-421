"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, Bell } from "lucide-react";
import { AlertsList } from "@/components/dashboard/AlertsList";

export default function AlertsPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
            Clinical Alerts & Notifications
          </h2>
          <p className="text-xs text-[#5B5A6E] mt-0.5">
            Real-time risk warnings, anomaly detections, and clinical reminders
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

      <div className="max-w-2xl">
        <AlertsList />
      </div>
    </div>
  );
}
