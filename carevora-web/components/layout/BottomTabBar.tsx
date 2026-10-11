"use client";

import React, { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  Brain,
  Bell,
  Menu,
  X,
} from "lucide-react";
import { DesktopSidebar } from "./DesktopSidebar";

export const BottomTabBar: React.FC = () => {
  const pathname = usePathname();
  const [drawerOpen, setDrawerOpen] = useState(false);

  const tabs = [
    { label: "Overview", href: "/dashboard", icon: LayoutDashboard },
    { label: "Residents", href: "/dashboard/residents", icon: Users },
    { label: "Assess", href: "/dashboard/cognitive/session", icon: Brain },
    { label: "Alerts", href: "/dashboard/alerts", icon: Bell, badge: "3" },
  ];

  return (
    <>
      {/* Fixed Bottom Tab Bar */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-[#ECE8F7] flex items-center justify-around py-2 px-2 shadow-[0_-4px_16px_rgba(26,20,69,0.05)] md:hidden">
        {tabs.map((tab) => {
          const isActive =
            tab.href === "/dashboard"
              ? pathname === "/dashboard"
              : pathname.startsWith(tab.href);
          const Icon = tab.icon;

          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={`flex flex-col items-center justify-center flex-1 py-1 relative min-h-[48px] ${
                isActive ? "text-[#6C3FC5]" : "text-[#8E8CA3]"
              }`}
            >
              <div className="relative">
                <Icon className="w-5 h-5" strokeWidth={isActive ? 2.2 : 1.75} />
                {tab.badge && (
                  <span className="absolute -top-1 -right-2 px-1 py-0.2 bg-[#EF4444] text-white text-[9px] font-extrabold rounded-full">
                    {tab.badge}
                  </span>
                )}
              </div>
              <span className="text-[10px] font-bold mt-1 tracking-tight">
                {tab.label}
              </span>
            </Link>
          );
        })}

        {/* More Drawer Trigger */}
        <button
          onClick={() => setDrawerOpen(true)}
          className="flex flex-col items-center justify-center flex-1 py-1 text-[#8E8CA3] min-h-[48px]"
        >
          <Menu className="w-5 h-5" strokeWidth={1.75} />
          <span className="text-[10px] font-bold mt-1 tracking-tight">More</span>
        </button>
      </nav>

      {/* Slide-in Drawer for Secondary Navigation */}
      {drawerOpen && (
        <div className="fixed inset-0 z-50 flex md:hidden">
          <div
            className="fixed inset-0 bg-black/40 backdrop-blur-xs transition-opacity"
            onClick={() => setDrawerOpen(false)}
          />
          <div className="relative w-4/5 max-w-xs bg-white h-full shadow-2xl flex flex-col z-10 animate-in slide-in-from-left duration-200">
            <div className="p-4 flex items-center justify-between border-b border-[#ECE8F7]">
              <span className="text-xs font-bold uppercase tracking-wider text-[#8E8CA3]">
                Navigation Menu
              </span>
              <button
                onClick={() => setDrawerOpen(false)}
                className="p-1 rounded-lg text-[#8E8CA3] hover:text-[#1A1445]"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto">
              <DesktopSidebar
                className="w-full border-none h-auto"
                onNavigate={() => setDrawerOpen(false)}
              />
            </div>
          </div>
        </div>
      )}
    </>
  );
};
