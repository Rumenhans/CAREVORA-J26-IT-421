"use client";

import React from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  Brain,
  Heart,
  Activity,
  Bell,
  FileBarChart,
  ClipboardList,
  Settings,
  LogOut,
  ChevronRight,
} from "lucide-react";
import { Logo } from "@/components/brand/Logo";

interface SidebarProps {
  className?: string;
  onNavigate?: () => void;
}

export const DesktopSidebar: React.FC<SidebarProps> = ({
  className = "",
  onNavigate,
}) => {
  const pathname = usePathname();
  const router = useRouter();

  const navItems = [
    {
      label: "Overview",
      href: "/dashboard",
      icon: LayoutDashboard,
      badge: null,
    },
    {
      label: "Residents",
      href: "/dashboard/residents",
      icon: Users,
      badge: null,
    },
    {
      label: "Cognitive Assessment",
      href: "/dashboard/cognitive/session",
      icon: Brain,
      badge: null,
    },
    {
      label: "Emotional Wellness",
      href: "/dashboard/emotional",
      icon: Heart,
      badge: null,
    },
    {
      label: "Metabolic Health",
      href: "/dashboard/metabolic",
      icon: Activity,
      badge: null,
    },
    {
      label: "Alerts & Notifications",
      href: "/dashboard/alerts",
      icon: Bell,
      badge: "3",
    },
    {
      label: "Reports & Analytics",
      href: "/dashboard/reports",
      icon: FileBarChart,
      badge: null,
    },
    {
      label: "Care Plans",
      href: "/dashboard/care-plans",
      icon: ClipboardList,
      badge: "3",
    },
    {
      label: "Settings",
      href: "/dashboard/settings",
      icon: Settings,
      badge: null,
    },
  ];

  const handleLogout = () => {
    if (typeof window !== "undefined") {
      localStorage.removeItem("carevora_auth");
      localStorage.removeItem("carevora_user");
    }
    router.push("/login");
  };

  return (
    <aside
      className={`w-[260px] h-screen bg-white border-r border-[#ECE8F7] flex flex-col justify-between shrink-0 select-none ${className}`}
    >
      {/* Top Brand Section */}
      <div className="flex flex-col">
        <div className="p-5 border-b border-[#ECE8F7]/60">
          <Link href="/dashboard" className="block">
            <Logo size={42} variant="full" />
          </Link>
        </div>

        {/* Navigation Items */}
        <nav className="p-3 space-y-1 overflow-y-auto max-h-[calc(100vh-220px)]">
          {navItems.map((item) => {
            const isActive =
              item.href === "/dashboard"
                ? pathname === "/dashboard"
                : pathname.startsWith(item.href);

            const Icon = item.icon;

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onNavigate}
                className={`flex items-center justify-between px-3 py-2.5 rounded-xl text-xs font-semibold transition-all group ${
                  isActive
                    ? "bg-[#EDE9FE] text-[#6C3FC5]"
                    : "text-[#5B5A6E] hover:bg-[#FAF8FF] hover:text-[#1A1445]"
                }`}
              >
                <div className="flex items-center gap-2.5">
                  <Icon
                    className={`w-4 h-4 transition-colors ${
                      isActive ? "text-[#6C3FC5]" : "text-[#8E8CA3] group-hover:text-[#6C3FC5]"
                    }`}
                    strokeWidth={1.75}
                  />
                  <span>{item.label}</span>
                </div>

                {item.badge && (
                  <span
                    className={`px-1.5 py-0.5 rounded-full text-[10px] font-bold ${
                      isActive
                        ? "bg-[#6C3FC5] text-white"
                        : "bg-[#FDE8E8] text-[#EF4444]"
                    }`}
                  >
                    {item.badge}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Bottom Caregiver Profile & Logout */}
      <div className="p-3 border-t border-[#ECE8F7] space-y-2 bg-[#FAF8FF]/50">
        <div className="flex items-center justify-between p-2 rounded-xl bg-white border border-[#ECE8F7] shadow-sm">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-[#6C3FC5] to-[#E88BC4] text-white flex items-center justify-center font-bold text-xs shadow-inner">
              SN
            </div>
            <div className="flex flex-col text-left">
              <span className="text-[10px] uppercase font-bold text-[#8E8CA3] tracking-wider leading-none">
                Caregiver
              </span>
              <span className="text-xs font-bold text-[#1A1445] leading-tight mt-0.5">
                Seetha N.
              </span>
            </div>
          </div>
          <ChevronRight className="w-4 h-4 text-[#8E8CA3]" strokeWidth={1.75} />
        </div>

        <button
          onClick={handleLogout}
          className="w-full flex items-center justify-center gap-2 py-2 text-xs font-bold text-[#EF4444] hover:bg-[#FDE8E8]/50 rounded-xl transition-colors"
        >
          <LogOut className="w-3.5 h-3.5" strokeWidth={1.75} />
          <span>Log Out</span>
        </button>
      </div>
    </aside>
  );
};
