"use client";

import React from "react";
import { Check, Circle } from "lucide-react";
import { CognitiveQuestion } from "@/lib/mock-data";

interface QuestionsOverviewListProps {
  questions: CognitiveQuestion[];
  currentIndex: number;
  completedIds: number[];
  onSelectQuestion: (index: number) => void;
}

export const QuestionsOverviewList: React.FC<QuestionsOverviewListProps> = ({
  questions,
  currentIndex,
  completedIds,
  onSelectQuestion,
}) => {
  const [showAll, setShowAll] = React.useState(false);
  const visibleQuestions = showAll ? questions : questions.slice(0, 6);

  return (
    <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 shadow-[0_8px_24px_rgba(108,63,197,0.06)] space-y-3">
      <div className="flex items-center justify-between">
        <h4 className="font-[var(--font-jakarta)] text-sm font-extrabold text-[#1A1445]">
          Questions Overview
        </h4>
        <span className="text-[11px] font-bold text-[#6C3FC5]">
          {completedIds.length} / {questions.length}
        </span>
      </div>

      <div className="space-y-1.5 max-h-72 overflow-y-auto pr-1">
        {visibleQuestions.map((q, idx) => {
          const isCurrent = idx === currentIndex;
          const isDone = completedIds.includes(q.id);

          return (
            <button
              key={q.id}
              onClick={() => onSelectQuestion(idx)}
              className={`w-full flex items-center justify-between p-2.5 rounded-xl text-xs text-left transition-all ${
                isCurrent
                  ? "bg-[#EDE9FE] border border-[#6C3FC5]/30 text-[#6C3FC5] font-bold shadow-2xs"
                  : isDone
                  ? "bg-[#FAF8FF] text-[#1A1445] font-semibold border border-[#ECE8F7]"
                  : "bg-transparent text-[#8E8CA3] hover:bg-[#FAF8FF]"
              }`}
            >
              <div className="flex items-center gap-2 truncate">
                <span className="w-5 text-[11px] font-bold shrink-0">
                  {q.id}.
                </span>
                <span className="truncate">{q.category}</span>
              </div>

              <div className="shrink-0 ml-2">
                {isDone ? (
                  <div className="w-4 h-4 rounded-full bg-[#22C55E] text-white flex items-center justify-center">
                    <Check className="w-3 h-3 stroke-[3]" />
                  </div>
                ) : isCurrent ? (
                  <div className="w-2.5 h-2.5 rounded-full bg-[#6C3FC5] animate-pulse" />
                ) : (
                  <Circle className="w-3.5 h-3.5 text-[#D8CEF6]" />
                )}
              </div>
            </button>
          );
        })}
      </div>

      {questions.length > 6 && (
        <button
          onClick={() => setShowAll(!showAll)}
          className="w-full py-2 text-center text-xs font-bold text-[#6C3FC5] hover:underline"
        >
          {showAll ? "Show Less" : `+ ${questions.length - 6} More Questions`}
        </button>
      )}
    </div>
  );
};
