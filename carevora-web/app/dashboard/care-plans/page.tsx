"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, ClipboardList, CheckCircle2, Clock, Plus, User } from "lucide-react";
import { mockResident } from "@/lib/mock-data";

export default function CarePlansPage() {
  const carePlans = [
    {
      id: "cp-1",
      title: "Daily Cognitive Stimulation & Reminiscence Therapy",
      category: "Cognitive Wellness",
      schedule: "Twice daily (10:00 AM & 03:00 PM)",
      status: "In Progress",
      assignedCaregiver: "Seetha N.",
      tasks: [
        "Structured 15-minute photo album orientation",
        "Category animal naming verbal fluency drill",
        "Guided memory recall journal check",
      ],
    },
    {
      id: "cp-2",
      title: "Gentle Mobility & Hydration Schedule",
      category: "Metabolic & Physical",
      schedule: "Every 2 hours during daytime",
      status: "Active",
      assignedCaregiver: "Kamal P.",
      tasks: [
        "Assisted hallway stroll with walking frame (15 mins)",
        "200ml electrolyte hydration encouragement",
        "Seated ankle rotations and joint flexibility",
      ],
    },
    {
      id: "cp-3",
      title: "Evening Affect & Relaxation Protocol",
      category: "Emotional Well-being",
      schedule: "Daily at 07:30 PM",
      status: "Scheduled",
      assignedCaregiver: "Seetha N.",
      tasks: [
        "Calm instrumental music listening session",
        "Warm chamomile tea and verbal wind-down reassurance",
        "Facial affect check before bedtime",
      ],
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <div>
          <h2 className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
            Individualized Care Plans
          </h2>
          <p className="text-xs text-[#5B5A6E] mt-0.5">
            Active care interventions and scheduled caregiver protocols for {mockResident.name}
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => alert("New Care Plan builder opened.")}
            className="px-4 py-2 rounded-xl bg-[#6C3FC5] text-white text-xs font-bold hover:bg-[#5B2FB0] transition-colors flex items-center gap-1.5 shadow-2xs"
          >
            <Plus className="w-4 h-4" />
            <span>Create New Plan</span>
          </button>

          <Link
            href="/dashboard"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6C3FC5] hover:underline"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Dashboard</span>
          </Link>
        </div>
      </div>

      {/* Care Plans List */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {carePlans.map((plan) => (
          <div
            key={plan.id}
            className="bg-white rounded-2xl border border-[#ECE8F7] p-6 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col justify-between space-y-4"
          >
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="px-2.5 py-1 rounded-full bg-[#FAF8FF] border border-[#E9E1FF] text-[10px] font-bold text-[#6C3FC5]">
                  {plan.category}
                </span>
                <span className="text-[11px] font-bold text-[#22C55E] flex items-center gap-1">
                  ● {plan.status}
                </span>
              </div>

              <h3 className="font-bold text-sm text-[#1A1445] leading-snug">
                {plan.title}
              </h3>

              <div className="flex items-center gap-1.5 text-xs text-[#8E8CA3]">
                <Clock className="w-3.5 h-3.5 text-[#6C3FC5]" />
                <span>{plan.schedule}</span>
              </div>

              {/* Tasks Checklist */}
              <div className="pt-2 space-y-2">
                <span className="text-[11px] font-bold uppercase tracking-wider text-[#8E8CA3] block">
                  Action Checklist
                </span>
                {plan.tasks.map((task, i) => (
                  <div key={i} className="flex items-start gap-2 text-xs text-[#5B5A6E]">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#22C55E] shrink-0 mt-0.5" />
                    <span>{task}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="pt-4 border-t border-[#ECE8F7] flex items-center justify-between text-xs">
              <span className="text-[#8E8CA3] flex items-center gap-1">
                <User className="w-3 h-3 text-[#6C3FC5]" />
                Assigned: <strong className="text-[#1A1445]">{plan.assignedCaregiver}</strong>
              </span>

              <button
                onClick={() => alert(`Marking actions complete for ${plan.title}`)}
                className="font-bold text-[#6C3FC5] hover:underline"
              >
                Log Completion &rarr;
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
