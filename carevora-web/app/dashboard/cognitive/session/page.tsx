"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  Volume2,
  Mic,
  MicOff,
  RotateCcw,
  Sparkles,
  HelpCircle,
  AlertOctagon,
  CheckCircle2,
} from "lucide-react";
import { CitySkyline } from "@/components/brand/CitySkyline";
import { VoiceWaveform } from "@/components/assessment/VoiceWaveform";
import { QuestionsOverviewList } from "@/components/assessment/QuestionsOverviewList";
import {
  cognitiveQuestionsList,
  mockResident,
  AssessmentRecord,
} from "@/lib/mock-data";
import { speakText, stopSpeaking } from "@/lib/speech";

export default function CognitiveSessionPage() {
  const router = useRouter();
  const [currentIdx, setCurrentIdx] = useState(0);
  const [completedIds, setCompletedIds] = useState<number[]>([]);
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState("");
  const [answers, setAnswers] = useState<Record<number, string>>({});
  const [showTips, setShowTips] = useState(false);
  const [showEndModal, setShowEndModal] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [elapsedSeconds, setElapsedSeconds] = useState(145);

  const totalQuestions = cognitiveQuestionsList.length;
  const currentQuestion = cognitiveQuestionsList[currentIdx];
  const progressPercent = Math.round(((completedIds.length) / totalQuestions) * 100);

  // Timer
  useEffect(() => {
    const timer = setInterval(() => {
      setElapsedSeconds((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatElapsed = (sec: number) => {
    const mins = Math.floor(sec / 60);
    const remaining = sec % 60;
    return `${mins}m ${remaining < 10 ? "0" : ""}${remaining}s`;
  };

  // Play question text via TTS
  const handleReadQuestion = () => {
    if (isSpeaking) {
      stopSpeaking();
      setIsSpeaking(false);
      return;
    }
    setIsSpeaking(true);
    speakText(currentQuestion.questionText, () => {
      setIsSpeaking(false);
    });
  };

  // Start/Stop voice answer input
  const toggleListening = () => {
    if (isListening) {
      setIsListening(false);
    } else {
      setIsListening(true);
      // Simulate real-time speech response if recognition takes time
      setTimeout(() => {
        if (!transcript) {
          setTranscript("Today is Monday, October 9th, 2026.");
        }
      }, 2500);
    }
  };

  const handleNextQuestion = () => {
    // Record current answer
    const updatedCompleted = Array.from(
      new Set([...completedIds, currentQuestion.id])
    );
    setCompletedIds(updatedCompleted);
    setAnswers((prev) => ({
      ...prev,
      [currentQuestion.id]: transcript || "Answer recorded verbally.",
    }));
    setTranscript("");
    setIsListening(false);

    if (currentIdx < totalQuestions - 1) {
      setCurrentIdx(currentIdx + 1);
    } else {
      setShowEndModal(true);
    }
  };

  const handleFinishAssessment = () => {
    // Compute cognitive score and append to Recent Assessments
    const mockNewScore: AssessmentRecord = {
      id: `asm-${Date.now()}`,
      dateTime: "Just now",
      cognitiveScore: 0.68,
      emotionalScore: 0.72,
      metabolicScore: 0.55,
      overallRiskScore: 0.65,
      assessedBy: "Seetha N.",
      status: "Completed",
      notes: "Cognitive assessment session successfully completed. Orientation and immediate memory scores intact.",
    };

    if (typeof window !== "undefined") {
      localStorage.setItem(
        "carevora_latest_assessment",
        JSON.stringify(mockNewScore)
      );
    }

    router.push("/dashboard");
  };

  return (
    <div className="space-y-6">
      {/* Top Header Row: Back link & Title */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <Link
          href="/dashboard"
          className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6C3FC5] hover:underline"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back to overview</span>
        </Link>

        <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-white border border-[#ECE8F7] text-xs font-semibold text-[#5B2FB0]">
          <span>Session Started:</span>
          <span className="font-bold text-[#1A1445]">{formatElapsed(elapsedSeconds)}</span>
        </div>
      </div>

      {/* Resident Context Banner */}
      <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-xl bg-gradient-to-tr from-[#6C3FC5] to-[#5B2FB0] text-white flex items-center justify-center font-bold text-base shadow-xs">
            JP
          </div>
          <div>
            <h2 className="font-[var(--font-jakarta)] text-base font-extrabold text-[#1A1445]">
              {mockResident.name} (ID: R001)
            </h2>
            <p className="text-xs text-[#5B5A6E]">
              Age: {mockResident.age} • Male • Room {mockResident.roomNumber}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <span className="px-3 py-1 rounded-full bg-[#FAF8FF] border border-[#E9E1FF] text-xs font-bold text-[#6C3FC5]">
            Standard Cognitive Assessment
          </span>
        </div>
      </div>

      {/* Main 2-Column Assessment Workspace */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* ================= LEFT MAIN COLUMN (2 Cols) ================= */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-2xl border border-[#ECE8F7] p-6 sm:p-8 shadow-[0_8px_24px_rgba(108,63,197,0.06)] space-y-6">
            
            {/* Header: Progress title and bar */}
            <div>
              <div className="flex items-center justify-between text-xs mb-2">
                <span className="font-bold text-[#1A1445]">
                  Cognitive Assessment in Progress
                </span>
                <span className="font-extrabold text-[#6C3FC5]">
                  Question {currentIdx + 1} of {totalQuestions} ({progressPercent}%)
                </span>
              </div>
              <div className="w-full h-2.5 bg-[#FAF8FF] border border-[#E9E1FF] rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-[#6C3FC5] to-[#5B2FB0] rounded-full transition-all duration-300"
                  style={{ width: `${Math.max(progressPercent, 5)}%` }}
                />
              </div>
            </div>

            {/* Large Lavender Question Panel */}
            <div className="bg-[#FAF8FF] border-2 border-[#E9E1FF] rounded-2xl p-6 relative overflow-hidden space-y-4">
              <div className="flex items-start justify-between gap-4">
                <span className="px-2.5 py-1 rounded-full bg-white border border-[#E4DEF5] text-[11px] font-bold text-[#6C3FC5]">
                  {currentQuestion.category}
                </span>

                {/* Speaker Button for TTS Read-aloud */}
                <button
                  onClick={handleReadQuestion}
                  className={`p-2.5 rounded-xl border transition-all ${
                    isSpeaking
                      ? "bg-[#6C3FC5] text-white border-[#6C3FC5] animate-pulse"
                      : "bg-white border-[#E4DEF5] text-[#6C3FC5] hover:bg-[#EDE9FE]"
                  }`}
                  title="Read question aloud"
                >
                  <Volume2 className="w-5 h-5" strokeWidth={1.75} />
                </button>
              </div>

              {/* Bold Question Text */}
              <h3 className="font-[var(--font-jakarta)] text-lg sm:text-xl font-extrabold text-[#1A1445] leading-relaxed">
                {currentQuestion.questionText}
              </h3>

              {/* Pastel City Skyline Illustration SVG */}
              <div className="pt-2">
                <CitySkyline height={75} />
              </div>

              {/* AI Assistant Speech Bubble */}
              <div className="flex items-start gap-2.5 p-3 rounded-xl bg-white/90 border border-[#ECE8F7] shadow-2xs">
                <Sparkles className="w-4 h-4 text-[#6C3FC5] shrink-0 mt-0.5" />
                <p className="text-xs text-[#5B5A6E] font-medium italic">
                  AI Guidance: &ldquo;Please take your time and answer clearly.&rdquo;
                </p>
              </div>
            </div>

            {/* Voice & Transcript Response Panel */}
            <div className="p-6 rounded-2xl border border-[#ECE8F7] bg-white space-y-4 text-center">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-[#1A1445]">
                  {isListening ? "Listening to response..." : "Response Panel"}
                </span>
                <span className="text-[11px] text-[#8E8CA3]">
                  Web Speech Recognition
                </span>
              </div>

              {/* Animated Green Waveform */}
              <VoiceWaveform isListening={isListening} />

              {/* Transcript display */}
              <div className="min-h-16 p-3 rounded-xl bg-[#FAF8FF] border border-[#E9E1FF] text-left">
                {transcript ? (
                  <p className="text-sm font-semibold text-[#1A1445]">
                    &ldquo;{transcript}&rdquo;
                  </p>
                ) : (
                  <p className="text-xs text-[#8E8CA3] italic">
                    Tap the microphone button to start recording or speak clearly into the microphone.
                  </p>
                )}
              </div>

              {/* Microphone & Actions Row */}
              <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-2">
                <div className="flex items-center gap-2">
                  <button
                    onClick={handleReadQuestion}
                    className="px-3.5 py-2 rounded-xl border border-[#E4DEF5] bg-[#FAF8FF] text-xs font-bold text-[#6C3FC5] hover:bg-[#EDE9FE] transition-colors flex items-center gap-1.5"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                    <span>Repeat Question</span>
                  </button>
                  <span className="text-[11px] text-[#8E8CA3] hidden sm:inline">
                    You can request the question to be repeated if needed.
                  </span>
                </div>

                {/* Big Round Purple Mic Button */}
                <div className="flex items-center gap-3">
                  <button
                    onClick={toggleListening}
                    className={`w-14 h-14 rounded-full flex items-center justify-center text-white transition-all shadow-lg ${
                      isListening
                        ? "bg-[#EF4444] hover:bg-[#DC2626] animate-pulse"
                        : "bg-[#6C3FC5] hover:bg-[#5B2FB0]"
                    }`}
                    title={isListening ? "Stop listening" : "Start speaking"}
                  >
                    {isListening ? (
                      <MicOff className="w-6 h-6" />
                    ) : (
                      <Mic className="w-6 h-6" />
                    )}
                  </button>

                  <button
                    onClick={handleNextQuestion}
                    className="px-5 py-2.5 rounded-xl bg-[#6C3FC5] text-white font-bold text-xs hover:bg-[#5B2FB0] transition-colors shadow-2xs"
                  >
                    {currentIdx === totalQuestions - 1 ? "Finish" : "Next Question →"}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ================= RIGHT COLUMN (1 Col) ================= */}
        <div className="space-y-5">
          {/* 1. Assessment Progress Ring */}
          <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 shadow-[0_8px_24px_rgba(108,63,197,0.06)] flex flex-col items-center text-center">
            <h4 className="font-[var(--font-jakarta)] text-sm font-extrabold text-[#1A1445] mb-3">
              Assessment Progress
            </h4>
            
            {/* SVG Progress Ring */}
            <div className="relative w-28 h-28 flex items-center justify-center my-2">
              <svg className="w-full h-full -rotate-90" viewBox="0 0 100 100">
                <circle
                  cx="50"
                  cy="50"
                  r="40"
                  fill="none"
                  stroke="#F4F0FF"
                  strokeWidth="8"
                />
                <circle
                  cx="50"
                  cy="50"
                  r="40"
                  fill="none"
                  stroke="#6C3FC5"
                  strokeWidth="8"
                  strokeLinecap="round"
                  strokeDasharray="251.2"
                  strokeDashoffset={251.2 - (251.2 * progressPercent) / 100}
                  className="transition-all duration-500 ease-out"
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
                  {progressPercent}%
                </span>
                <span className="text-[10px] text-[#8E8CA3]">Completed</span>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-2 w-full pt-3 border-t border-[#ECE8F7]/60 text-center">
              <div>
                <span className="text-[10px] text-[#8E8CA3] block">Done</span>
                <span className="text-xs font-bold text-[#22C55E]">
                  {completedIds.length}
                </span>
              </div>
              <div>
                <span className="text-[10px] text-[#8E8CA3] block">Current</span>
                <span className="text-xs font-bold text-[#6C3FC5]">
                  {currentIdx + 1}
                </span>
              </div>
              <div>
                <span className="text-[10px] text-[#8E8CA3] block">Remaining</span>
                <span className="text-xs font-bold text-[#8E8CA3]">
                  {totalQuestions - completedIds.length}
                </span>
              </div>
            </div>
          </div>

          {/* 2. Questions Overview Checklist */}
          <QuestionsOverviewList
            questions={cognitiveQuestionsList}
            currentIndex={currentIdx}
            completedIds={completedIds}
            onSelectQuestion={(idx) => setCurrentIdx(idx)}
          />

          {/* 3. AI Assistant Tips Card */}
          <div className="bg-white rounded-2xl border border-[#ECE8F7] p-5 shadow-[0_8px_24px_rgba(108,63,197,0.06)] space-y-3">
            <div className="flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-[#6C3FC5]" />
              <h4 className="font-[var(--font-jakarta)] text-sm font-extrabold text-[#1A1445]">
                AI Assistant
              </h4>
            </div>
            <p className="text-xs text-[#5B5A6E] leading-relaxed">
              Real-time speech cadence and semantic answer evaluation is actively running.
            </p>
            <button
              onClick={() => setShowTips(true)}
              className="w-full py-2 rounded-xl border border-[#E4DEF5] bg-[#FAF8FF] text-xs font-bold text-[#6C3FC5] hover:bg-[#EDE9FE] transition-colors"
            >
              Show Tips & Evaluation Criteria
            </button>
          </div>

          {/* 4. End Assessment Button */}
          <button
            onClick={() => setShowEndModal(true)}
            className="w-full py-3 rounded-2xl border border-[#EF4444]/30 bg-[#FDE8E8]/40 hover:bg-[#FDE8E8] text-[#EF4444] font-bold text-xs transition-colors flex items-center justify-center gap-2 shadow-2xs"
          >
            <AlertOctagon className="w-4 h-4" />
            <span>End Assessment</span>
          </button>
        </div>
      </div>

      {/* Confirmation & Finish Modal */}
      {showEndModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-black/50 backdrop-blur-xs"
            onClick={() => setShowEndModal(false)}
          />
          <div className="relative w-full max-w-md bg-white rounded-3xl p-6 sm:p-8 shadow-2xl z-10 space-y-4 text-center animate-in zoom-in-95">
            <div className="w-14 h-14 rounded-full bg-[#E7F8EE] text-[#22C55E] flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-8 h-8" />
            </div>

            <h3 className="font-[var(--font-jakarta)] text-xl font-extrabold text-[#1A1445]">
              Complete Cognitive Assessment?
            </h3>

            <p className="text-xs text-[#5B5A6E]">
              You have answered {completedIds.length} of {totalQuestions} questions for Mr. James Perera. Do you want to finalize and compute the clinical cognitive risk score?
            </p>

            <div className="flex gap-3 pt-2">
              <button
                onClick={() => setShowEndModal(false)}
                className="flex-1 py-2.5 rounded-xl border border-[#ECE8F7] text-xs font-bold text-[#5B5A6E] hover:bg-[#F8F7FC]"
              >
                Continue Assessment
              </button>
              <button
                onClick={handleFinishAssessment}
                className="flex-1 py-2.5 rounded-xl bg-[#6C3FC5] hover:bg-[#5B2FB0] text-white text-xs font-bold shadow-md"
              >
                Finalize & Save
              </button>
            </div>
          </div>
        </div>
      )}

      {/* AI Tips Modal */}
      {showTips && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-black/50 backdrop-blur-xs"
            onClick={() => setShowTips(false)}
          />
          <div className="relative w-full max-w-lg bg-white rounded-3xl p-6 sm:p-8 shadow-2xl z-10 space-y-4 animate-in zoom-in-95">
            <div className="flex items-center justify-between border-b border-[#ECE8F7] pb-3">
              <div className="flex items-center gap-2">
                <HelpCircle className="w-5 h-5 text-[#6C3FC5]" />
                <h3 className="font-[var(--font-jakarta)] text-base font-extrabold text-[#1A1445]">
                  Clinical Evaluation Tips
                </h3>
              </div>
              <button
                onClick={() => setShowTips(false)}
                className="text-xs font-bold text-[#8E8CA3] hover:text-[#1A1445]"
              >
                Close
              </button>
            </div>

            <div className="space-y-3 text-xs text-[#5B5A6E]">
              <div className="p-3 rounded-xl bg-[#FAF8FF] border border-[#E9E1FF]">
                <strong className="text-[#1A1445] block mb-1">Current Question Guidance:</strong>
                {currentQuestion.aiTip}
              </div>
              <div className="p-3 rounded-xl bg-[#FAF8FF] border border-[#E9E1FF]">
                <strong className="text-[#1A1445] block mb-1">Standardized Answer Rubric:</strong>
                {currentQuestion.recommendedAnswerGuide}
              </div>
            </div>

            <button
              onClick={() => setShowTips(false)}
              className="w-full py-2.5 rounded-xl bg-[#6C3FC5] text-white font-bold text-xs"
            >
              Understood
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
