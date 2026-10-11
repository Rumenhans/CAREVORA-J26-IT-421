import React from "react";
import { DesktopSidebar } from "@/components/layout/DesktopSidebar";
import { TopNavBar } from "@/components/layout/TopNavBar";
import { BottomTabBar } from "@/components/layout/BottomTabBar";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-[#F5F6FB] flex flex-col md:flex-row">
      {/* Desktop Sidebar (Fixed 260px) */}
      <DesktopSidebar className="hidden md:flex sticky top-0" />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 pb-16 md:pb-6">
        <TopNavBar />
        <main className="p-4 sm:p-6 lg:p-8 flex-1 max-w-[1600px] w-full mx-auto">
          {children}
        </main>
      </div>

      {/* Mobile Bottom Tab Bar (< 768px) */}
      <BottomTabBar />
    </div>
  );
}
