"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { Mail, Lock, Eye, EyeOff, Shield, LogIn, Sparkles } from "lucide-react";
import { Logo } from "@/components/brand/Logo";
import { CaregiverHands } from "@/components/brand/CaregiverHands";

interface LoginFormValues {
  email: string;
  password: string;
  rememberMe: boolean;
}

export default function LoginPage() {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormValues>({
    defaultValues: {
      email: "seetha@carevora.com",
      password: "demo1234",
      rememberMe: true,
    },
  });

  const onSubmit = async (data: LoginFormValues) => {
    setIsLoading(true);
    setAuthError(null);

    // Simulated Authentication Delay
    await new Promise((resolve) => setTimeout(resolve, 800));

    if (data.email === "seetha@carevora.com" && data.password === "demo1234") {
      // Set simple mock cookie / localStorage
      if (typeof window !== "undefined") {
        localStorage.setItem("carevora_auth", "true");
        localStorage.setItem("carevora_user", "Seetha N.");
      }
      router.push("/dashboard");
    } else {
      setIsLoading(false);
      setAuthError("Invalid credentials. Try: seetha@carevora.com / demo1234");
    }
  };

  return (
    <div className="relative min-h-screen w-full flex items-center justify-center overflow-x-hidden bg-[#F8F7FC] p-4 lg:p-8">
      {/* Background: Soft lavender-to-pink watercolor gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#F4F0FF] via-[#FFFFFF] to-[#FDF2F8] pointer-events-none" />

      {/* Ambient circular watercolor glow shapes */}
      <div className="absolute -top-24 -left-24 w-96 h-96 rounded-full bg-[#E9E1FF]/40 blur-3xl pointer-events-none" />
      <div className="absolute -bottom-28 -right-20 w-[480px] h-[480px] rounded-full bg-[#E88BC4]/15 blur-3xl pointer-events-none" />

      {/* Subtle sparkles */}
      <div className="absolute top-16 left-28 text-[#6C3FC5]/30 pointer-events-none hidden sm:block">
        <Sparkles className="w-6 h-6 animate-pulse" />
      </div>
      <div className="absolute bottom-28 left-48 text-[#E88BC4]/40 pointer-events-none hidden sm:block">
        <Sparkles className="w-5 h-5 animate-pulse" />
      </div>
      <div className="absolute top-24 right-40 text-[#6C3FC5]/25 pointer-events-none hidden sm:block">
        <Sparkles className="w-5 h-5" />
      </div>

      {/* Botanical leaf silhouettes at bottom corners */}
      <div className="absolute bottom-4 left-6 opacity-20 pointer-events-none hidden lg:block">
        <svg width="120" height="120" viewBox="0 0 120 120" fill="none">
          <path
            d="M 10 110 C 20 40, 80 50, 110 10 C 70 50, 40 100, 10 110 Z"
            fill="#6CC24A"
          />
          <path
            d="M 12 110 C 50 80, 100 80, 115 50 C 75 75, 45 105, 12 110 Z"
            fill="#7DD65A"
          />
        </svg>
      </div>
      <div className="absolute bottom-4 right-6 opacity-20 pointer-events-none hidden lg:block scale-x-[-1]">
        <svg width="120" height="120" viewBox="0 0 120 120" fill="none">
          <path
            d="M 10 110 C 20 40, 80 50, 110 10 C 70 50, 40 100, 10 110 Z"
            fill="#6CC24A"
          />
        </svg>
      </div>

      {/* Main Container: 50/50 Desktop Layout or Centered Mobile Card */}
      <div className="relative z-10 w-full max-w-[1440px] mx-auto min-h-[820px] flex flex-col lg:flex-row items-center justify-between gap-10 lg:gap-16 py-6">
        
        {/* ================= LEFT SIDE (50%) ================= */}
        <div className="w-full lg:w-1/2 flex flex-col items-center text-center px-4 sm:px-8 py-4">
          {/* Large centered Carevora Logo */}
          <div className="mb-4 transform hover:scale-105 transition-transform duration-300">
            <Logo size={140} variant="icon" />
          </div>

          {/* CAREVORA in elegant serif small caps, deep purple */}
          <h1 className="font-[var(--font-cormorant)] text-4xl sm:text-5xl font-bold tracking-[0.24em] uppercase text-[#5B2FB0] mt-2">
            CAREVORA
          </h1>

          {/* Thin divider with small pink heart in the middle */}
          <div className="flex items-center justify-center gap-3 w-64 my-4">
            <div className="flex-1 h-[1.5px] bg-[#E9E1FF]" />
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="#E88BC4"
              className="text-[#E88BC4] shrink-0"
            >
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
            <div className="flex-1 h-[1.5px] bg-[#E9E1FF]" />
          </div>

          {/* Tagline */}
          <p className="font-[var(--font-jakarta)] text-lg sm:text-xl font-bold text-[#1A1445] tracking-tight">
            Compassionate Care, Smarter Tomorrow
          </p>

          {/* 3-line description in gray */}
          <div className="mt-3 text-[#5B5A6E] text-sm sm:text-base leading-relaxed max-w-md font-normal">
            <p>AI-Powered Wellness Monitoring</p>
            <p>and Early Risk Detection System</p>
            <p>for Elderly Care Homes</p>
          </div>

          {/* Bottom Caregiver Hands Illustration (Translucent purple silhouette) */}
          <div className="mt-8 sm:mt-12 w-full flex justify-center">
            <CaregiverHands width={340} height={130} />
          </div>
        </div>

        {/* ================= RIGHT SIDE (50%) ================= */}
        <div className="w-full lg:w-1/2 flex justify-center px-2 sm:px-6">
          <div className="w-full max-w-[500px] bg-white rounded-[36px] border-2 border-[#E9E1FF] p-8 sm:p-12 shadow-[0_12px_36px_rgba(108,63,197,0.12)] relative">
            
            {/* Header */}
            <div className="text-center mb-8">
              <h2 className="font-[var(--font-jakarta)] text-2xl sm:text-3xl font-extrabold text-[#1A1445]">
                Welcome Back!
              </h2>
              <p className="text-sm text-[#5B5A6E] mt-2">
                Sign in to continue to{" "}
                <span className="font-bold text-[#6C3FC5]">Carevora</span>
              </p>
            </div>

            {authError && (
              <div className="mb-5 p-3 rounded-xl bg-red-50 border border-red-200 text-red-600 text-xs font-medium text-center">
                {authError}
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
              {/* Email field */}
              <div>
                <label className="block text-xs font-semibold text-[#1A1445] mb-2">
                  Email Address
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#8E8CA3]">
                    <Mail className="w-4 h-4" strokeWidth={1.75} />
                  </div>
                  <input
                    type="email"
                    {...register("email", {
                      required: "Please enter your email",
                      pattern: {
                        value: /^\S+@\S+$/i,
                        message: "Please enter a valid email address",
                      },
                    })}
                    placeholder="Enter your email"
                    className="w-full h-12 pl-10 pr-4 text-sm bg-[#FAF8FF] border border-[#E4DEF5] rounded-xl text-[#1A1445] placeholder-[#8E8CA3] focus:outline-none focus:ring-2 focus:ring-[#6C3FC5] focus:border-transparent transition-all"
                  />
                </div>
                {errors.email && (
                  <p className="text-xs text-red-500 mt-1.5">{errors.email.message}</p>
                )}
              </div>

              {/* Password field */}
              <div>
                <label className="block text-xs font-semibold text-[#1A1445] mb-2">
                  Password
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#8E8CA3]">
                    <Lock className="w-4 h-4" strokeWidth={1.75} />
                  </div>
                  <input
                    type={showPassword ? "text" : "password"}
                    {...register("password", {
                      required: "Please enter your password",
                      minLength: {
                        value: 6,
                        message: "Password must be at least 6 characters",
                      },
                    })}
                    placeholder="Enter your password"
                    className="w-full h-12 pl-10 pr-11 text-sm bg-[#FAF8FF] border border-[#E4DEF5] rounded-xl text-[#1A1445] placeholder-[#8E8CA3] focus:outline-none focus:ring-2 focus:ring-[#6C3FC5] focus:border-transparent transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-[#8E8CA3] hover:text-[#6C3FC5] transition-colors"
                  >
                    {showPassword ? (
                      <EyeOff className="w-4 h-4" strokeWidth={1.75} />
                    ) : (
                      <Eye className="w-4 h-4" strokeWidth={1.75} />
                    )}
                  </button>
                </div>
                {errors.password && (
                  <p className="text-xs text-red-500 mt-1.5">
                    {errors.password.message}
                  </p>
                )}
              </div>

              {/* Row: Remember me + Forgot password */}
              <div className="flex items-center justify-between text-xs pt-1">
                <label className="flex items-center gap-2 cursor-pointer text-[#5B5A6E] font-medium select-none">
                  <input
                    type="checkbox"
                    {...register("rememberMe")}
                    className="w-4 h-4 rounded text-[#6C3FC5] focus:ring-[#6C3FC5] border-[#E4DEF5] accent-[#6C3FC5]"
                  />
                  <span>Remember me</span>
                </label>
                <a
                  href="#forgot"
                  onClick={(e) => {
                    e.preventDefault();
                    alert("Demo: Reset link dispatched to seetha@carevora.com");
                  }}
                  className="text-[#6C3FC5] font-semibold hover:underline"
                >
                  Forgot password?
                </a>
              </div>

              {/* LOGIN Primary Button */}
              <button
                type="submit"
                disabled={isLoading}
                className="w-full h-12 rounded-xl bg-gradient-to-r from-[#6C3FC5] to-[#5B2FB0] text-white font-bold text-sm tracking-wider uppercase flex items-center justify-center gap-2 shadow-[0_6px_20px_rgba(108,63,197,0.30)] hover:opacity-95 active:scale-[0.99] transition-all disabled:opacity-70 mt-6"
              >
                {isLoading ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    <LogIn className="w-4 h-4" strokeWidth={2} />
                    <span>LOGIN</span>
                  </>
                )}
              </button>
            </form>

            {/* Divider with "or" */}
            <div className="flex items-center gap-3 my-6">
              <div className="flex-1 h-[1px] bg-[#ECE8F7]" />
              <span className="text-xs font-semibold text-[#8E8CA3]">or</span>
              <div className="flex-1 h-[1px] bg-[#ECE8F7]" />
            </div>

            {/* SSO Outlined Button */}
            <button
              type="button"
              onClick={() => alert("SSO integration configured for Enterprise Health ID.")}
              className="w-full h-12 rounded-xl border border-[#E4DEF5] bg-transparent text-[#1A1445] font-semibold text-sm flex items-center justify-center gap-2 hover:bg-[#FAF8FF] transition-colors"
            >
              <Shield className="w-4 h-4 text-[#6C3FC5]" strokeWidth={1.75} />
              <span>Sign in with SSO</span>
            </button>

            {/* Register link */}
            <div className="text-center mt-7 text-xs text-[#5B5A6E]">
              Don&apos;t have an account?{" "}
              <a
                href="#register"
                onClick={(e) => {
                  e.preventDefault();
                  alert("Please contact your care home administrator to register.");
                }}
                className="font-bold text-[#6C3FC5] hover:underline"
              >
                Register here
              </a>
            </div>

            {/* Demo credentials hint pill */}
            <div className="mt-6 pt-4 border-t border-[#ECE8F7]/60 text-center">
              <span className="inline-block px-3 py-1 bg-[#FAF8FF] border border-[#E9E1FF] text-[#5B2FB0] rounded-full text-[11px] font-medium">
                Demo Caregiver: seetha@carevora.com / demo1234
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
