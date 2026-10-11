"use client";

import React, { useState } from "react";
import Link from "next/link";
import {
  ArrowRight,
  Play,
  CheckCircle2,
  Brain,
  Heart,
  Activity,
  Shield,
  Sparkles,
  Users,
  Menu,
  X,
  User,
} from "lucide-react";
import { Logo } from "@/components/brand/Logo";

export default function LandingPage() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <div className="min-h-screen bg-[#F8F7FC] text-[#5B5A6E] overflow-x-hidden selection:bg-[#EDE9FE] selection:text-[#6C3FC5]">
      
      {/* ================= 1. STICKY NAVBAR ================= */}
      <header className="sticky top-0 z-50 bg-white/90 backdrop-blur-md border-b border-[#ECE8F7] px-4 sm:px-8 py-3.5 shadow-2xs">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <Link href="/">
            <Logo size={42} variant="full" />
          </Link>

          {/* Desktop Navigation Links */}
          <nav className="hidden lg:flex items-center gap-7 text-xs font-semibold text-[#5B5A6E]">
            <Link
              href="/"
              className="text-[#6C3FC5] font-bold border-b-2 border-[#6C3FC5] pb-1"
            >
              Home
            </Link>
            <Link href="#about" className="hover:text-[#6C3FC5] transition-colors">
              About
            </Link>
            <Link href="#solution" className="hover:text-[#6C3FC5] transition-colors">
              Our Solution
            </Link>
            <Link href="#how-it-works" className="hover:text-[#6C3FC5] transition-colors">
              How It Works
            </Link>
            <Link href="#for-caregivers" className="hover:text-[#6C3FC5] transition-colors">
              For Caregivers
            </Link>
            <Link href="#contact" className="hover:text-[#6C3FC5] transition-colors">
              Contact
            </Link>
          </nav>

          {/* Desktop Action Buttons */}
          <div className="hidden sm:flex items-center gap-3">
            <Link
              href="/login"
              className="px-4 py-2 rounded-xl border border-[#E4DEF5] text-xs font-bold text-[#1A1445] hover:bg-[#FAF8FF] transition-colors flex items-center gap-1.5"
            >
              <User className="w-3.5 h-3.5 text-[#6C3FC5]" />
              <span>Log In</span>
            </Link>

            <Link
              href="/dashboard"
              className="px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#6C3FC5] to-[#5B2FB0] text-white text-xs font-bold shadow-[0_4px_16px_rgba(108,63,197,0.25)] hover:opacity-95 transition-all flex items-center gap-1.5"
            >
              <span>Get Started</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          {/* Mobile Hamburger Trigger */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="lg:hidden p-2 rounded-xl border border-[#ECE8F7] text-[#1A1445]"
          >
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>

        {/* Mobile Navigation Drawer */}
        {mobileMenuOpen && (
          <div className="lg:hidden pt-4 pb-3 border-t border-[#ECE8F7] mt-3 space-y-2 text-sm font-semibold">
            <Link
              href="/"
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2 text-[#6C3FC5] bg-[#FAF8FF] rounded-lg"
            >
              Home
            </Link>
            <Link
              href="#about"
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2 hover:bg-[#FAF8FF] rounded-lg"
            >
              About
            </Link>
            <Link
              href="#solution"
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2 hover:bg-[#FAF8FF] rounded-lg"
            >
              Our Solution
            </Link>
            <Link
              href="#how-it-works"
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2 hover:bg-[#FAF8FF] rounded-lg"
            >
              How It Works
            </Link>
            <Link
              href="#for-caregivers"
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2 hover:bg-[#FAF8FF] rounded-lg"
            >
              For Caregivers
            </Link>
            <Link
              href="#contact"
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2 hover:bg-[#FAF8FF] rounded-lg"
            >
              Contact
            </Link>
            <div className="pt-2 flex flex-col gap-2">
              <Link
                href="/login"
                className="w-full py-2.5 text-center rounded-xl border border-[#E4DEF5] text-xs font-bold text-[#1A1445]"
              >
                Log In
              </Link>
              <Link
                href="/dashboard"
                className="w-full py-2.5 text-center rounded-xl bg-[#6C3FC5] text-white text-xs font-bold"
              >
                Get Started
              </Link>
            </div>
          </div>
        )}
      </header>

      {/* ================= 2. HERO SECTION ================= */}
      <section className="relative px-4 sm:px-8 pt-12 sm:pt-20 pb-16 max-w-7xl mx-auto overflow-hidden">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          
          {/* Left Hero Text */}
          <div className="space-y-6">
            {/* Pill */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#FAF8FF] border border-[#E9E1FF] text-xs font-bold text-[#6C3FC5]">
              <Sparkles className="w-3.5 h-3.5" />
              <span>AI-Powered Wellness Monitoring</span>
            </div>

            {/* H1 Heading */}
            <h1 className="font-[var(--font-jakarta)] text-4xl sm:text-5xl lg:text-6xl font-extrabold text-[#1A1445] leading-[1.15] tracking-tight">
              Caring Today, <br />
              <span className="text-[#6C3FC5]">Protecting Tomorrow</span>
            </h1>

            {/* Paragraph */}
            <p className="text-sm sm:text-base text-[#5B5A6E] leading-relaxed max-w-xl">
              Carevora helps caregivers in elderly care homes monitor emotional wellness, cognitive wellness, metabolic wellness and detect early signs of decline using AI-assisted assessments and intelligent insights.
            </p>

            {/* Buttons */}
            <div className="flex flex-wrap items-center gap-4 pt-2">
              <Link
                href="/dashboard"
                className="px-6 py-3.5 rounded-xl bg-gradient-to-r from-[#6C3FC5] to-[#5B2FB0] text-white font-bold text-sm shadow-[0_6px_24px_rgba(108,63,197,0.30)] hover:opacity-95 transition-all flex items-center gap-2"
              >
                <span>Get Started</span>
                <ArrowRight className="w-4 h-4" />
              </Link>

              <button
                onClick={() => alert("Carevora Product Overview Video is queued.")}
                className="px-6 py-3.5 rounded-xl border border-[#E4DEF5] bg-white text-[#1A1445] font-bold text-sm hover:bg-[#FAF8FF] transition-colors flex items-center gap-2"
              >
                <div className="w-6 h-6 rounded-full bg-[#FAF8FF] border border-[#E9E1FF] text-[#6C3FC5] flex items-center justify-center">
                  <Play className="w-3 h-3 fill-current ml-0.5" />
                </div>
                <span>Learn More</span>
              </button>
            </div>
          </div>

          {/* Right Hero Visual: Arch Masked Image Placeholder */}
          <div className="relative flex justify-center">
            {/* Ambient Lilac Halo Ring */}
            <div className="absolute inset-0 max-w-md mx-auto rounded-[60px] bg-gradient-to-tr from-[#E9E1FF] to-[#FDE2EE] blur-2xl opacity-70 -z-10" />

            {/* Arch-shaped container */}
            <div className="w-full max-w-md h-[460px] rounded-t-[220px] rounded-b-[40px] border-4 border-white shadow-[0_16px_40px_rgba(108,63,197,0.12)] overflow-hidden bg-gradient-to-br from-[#FAF8FF] via-[#F4F0FF] to-[#E9E1FF] relative flex flex-col items-center justify-center p-6 text-center">
              
              {/* Decorative graphic & placeholder notice */}
              <div className="w-24 h-24 rounded-full bg-white shadow-md flex items-center justify-center text-[#6C3FC5] mb-4">
                <Heart className="w-12 h-12 fill-[#6C3FC5]/20 stroke-[#6C3FC5]" />
              </div>

              <h3 className="font-[var(--font-jakarta)] text-lg font-extrabold text-[#1A1445]">
                Elderly Care Reimagined
              </h3>
              <p className="text-xs text-[#5B5A6E] mt-2 max-w-xs">
                Compassionate caregivers empowered with multimodal risk detection.
              </p>

              {/* TODO Note per prompt instructions */}
              <div className="mt-8 px-4 py-2 rounded-xl bg-white/80 border border-[#ECE8F7] text-[11px] text-[#8E8CA3]">
                <span>TODO: Replace with /public/images/hero-caregiver.jpg</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ================= 3. FEATURE STRIP ================= */}
      <section className="px-4 sm:px-8 py-8 max-w-7xl mx-auto">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          
          <div className="p-5 rounded-2xl bg-white border border-[#ECE8F7] shadow-2xs space-y-2">
            <div className="w-10 h-10 rounded-xl bg-[#FAF8FF] border border-[#E9E1FF] flex items-center justify-center text-[#6C3FC5]">
              <Sparkles className="w-5 h-5" />
            </div>
            <h4 className="font-[var(--font-jakarta)] text-sm font-bold text-[#1A1445]">
              AI Assistant
            </h4>
            <p className="text-xs text-[#5B5A6E]">
              Real-time conversational cues and guided evaluation prompts for caregivers.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#ECE8F7] shadow-2xs space-y-2">
            <div className="w-10 h-10 rounded-xl bg-[#FAF8FF] border border-[#E9E1FF] flex items-center justify-center text-[#6C3FC5]">
              <Brain className="w-5 h-5" />
            </div>
            <h4 className="font-[var(--font-jakarta)] text-sm font-bold text-[#1A1445]">
              Smart Analysis
            </h4>
            <p className="text-xs text-[#5B5A6E]">
              Multimodal synthesis uniting cognitive, emotional, and metabolic data.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#ECE8F7] shadow-2xs space-y-2">
            <div className="w-10 h-10 rounded-xl bg-[#FAF8FF] border border-[#E9E1FF] flex items-center justify-center text-[#6C3FC5]">
              <Activity className="w-5 h-5" />
            </div>
            <h4 className="font-[var(--font-jakarta)] text-sm font-bold text-[#1A1445]">
              Risk Insights
            </h4>
            <p className="text-xs text-[#5B5A6E]">
              Early automated detection of cognitive decline and physical vulnerability.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#ECE8F7] shadow-2xs space-y-2">
            <div className="w-10 h-10 rounded-xl bg-[#FAF8FF] border border-[#E9E1FF] flex items-center justify-center text-[#6C3FC5]">
              <Users className="w-5 h-5" />
            </div>
            <h4 className="font-[var(--font-jakarta)] text-sm font-bold text-[#1A1445]">
              Caregiver Support
            </h4>
            <p className="text-xs text-[#5B5A6E]">
              Designed hand-in-hand with clinical caregivers to streamline daily workflows.
            </p>
          </div>
        </div>
      </section>

      {/* ================= 4. PURPLE GRADIENT TRUST BAND ================= */}
      <section className="w-full bg-gradient-to-r from-[#6C3FC5] to-[#5B2FB0] text-white py-12 px-4 sm:px-8 my-8 shadow-inner">
        <div className="max-w-7xl mx-auto grid grid-cols-2 lg:grid-cols-4 gap-6 text-center">
          
          <div className="space-y-2">
            <div className="w-12 h-12 rounded-full bg-white/10 flex items-center justify-center mx-auto mb-3">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-bold text-sm sm:text-base">
              Privacy. Security. Compassion.
            </h4>
            <p className="text-xs text-[#E9E1FF]/80">HIPAA & GDPR Compliant</p>
          </div>

          <div className="space-y-2">
            <div className="w-12 h-12 rounded-full bg-white/10 flex items-center justify-center mx-auto mb-3">
              <CheckCircle2 className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-bold text-sm sm:text-base">
              Trusted by Care Homes
            </h4>
            <p className="text-xs text-[#E9E1FF]/80">Validated in senior facilities</p>
          </div>

          <div className="space-y-2">
            <div className="w-12 h-12 rounded-full bg-white/10 flex items-center justify-center mx-auto mb-3">
              <Brain className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-bold text-sm sm:text-base">
              AI-Powered Assessments
            </h4>
            <p className="text-xs text-[#E9E1FF]/80">Continuous calibration</p>
          </div>

          <div className="space-y-2">
            <div className="w-12 h-12 rounded-full bg-white/10 flex items-center justify-center mx-auto mb-3">
              <Heart className="w-6 h-6 text-white" />
            </div>
            <h4 className="font-bold text-sm sm:text-base">
              Better Care Better Lives
            </h4>
            <p className="text-xs text-[#E9E1FF]/80">Empowering healthy longevity</p>
          </div>
        </div>
      </section>

      {/* ================= 5. FOOTER ================= */}
      <footer className="border-t border-[#ECE8F7] bg-white py-10 px-4 sm:px-8 mt-16">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[#8E8CA3]">
          <Logo size={36} variant="full" />
          <p>© 2026 Carevora Inc. All rights reserved. Compassionate Care, Smarter Tomorrow.</p>
        </div>
      </footer>
    </div>
  );
}
