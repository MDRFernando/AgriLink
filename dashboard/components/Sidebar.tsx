'use client';

import React from 'react';
import {
  LayoutDashboard,
  Sprout,
  Gavel,
  CalendarDays,
  Calculator,
  ShoppingBag,
  FileSpreadsheet,
  Truck,
  Boxes,
  MapPin,
  TrendingUp,
  ShieldCheck,
  Users,
  Compass,
  X,
  LogOut,
} from 'lucide-react';
import { UserRole } from '@/lib/types';
import { logoutAction } from '@/app/actions/authActions';

interface SidebarProps {
  currentRole: UserRole;
  activeTab: string;
  onTabChange: (tab: string) => void;
  mobileMenuOpen: boolean;
  setMobileMenuOpen: (open: boolean) => void;
}

const NAV_ITEMS: Record<
  UserRole,
  {
    id: string;
    label: string;
    icon: React.ComponentType<{ className?: string }>;
  }[]
> = {
  farmer: [
    { id: 'overview', label: 'Farm Overview', icon: LayoutDashboard },
    { id: 'listings', label: 'Produce Listings', icon: Sprout },
    { id: 'auctions', label: 'Live Auctions', icon: Gavel },
    { id: 'crop_plans', label: 'Crop Plans', icon: CalendarDays },
    { id: 'calculator', label: 'Income Calculator', icon: Calculator },
  ],
  buyer: [
    { id: 'overview', label: 'Procurement Hub', icon: LayoutDashboard },
    { id: 'marketplace', label: 'Marketplace', icon: ShoppingBag },
    { id: 'demands', label: 'Sourcing Demands', icon: FileSpreadsheet },
    { id: 'orders', label: 'Orders & Tracking', icon: Boxes },
  ],
  transporter: [
    { id: 'overview', label: 'Dispatch Centre', icon: LayoutDashboard },
    { id: 'available_jobs', label: 'Freight Jobs', icon: Compass },
    { id: 'active_trips', label: 'Active Trips', icon: Truck },
    { id: 'fleet', label: 'Fleet & Drivers', icon: Users },
  ],
  government: [
    { id: 'overview', label: 'National Overview', icon: LayoutDashboard },
    { id: 'supply_map', label: 'Supply & Demand', icon: MapPin },
    { id: 'market_prices', label: 'Price Intelligence', icon: TrendingUp },
    { id: 'verifications', label: 'KYC Desk', icon: ShieldCheck },
  ],
};

export function Sidebar({
  currentRole,
  activeTab,
  onTabChange,
  mobileMenuOpen,
  setMobileMenuOpen,
}: SidebarProps) {
  const navItems = NAV_ITEMS[currentRole] || [];

  const handleSelectTab = (id: string) => {
    onTabChange(id);
    setMobileMenuOpen(false);
  };

  const sidebarContent = (
    <div className="flex h-full flex-col">
      {/* Mobile close bar */}
      <div className="flex items-center justify-between px-1 pb-4 lg:hidden">
        <div className="flex items-center gap-2">
          <div className="flex h-7 w-7 items-center justify-center rounded-md bg-emerald-700 text-white">
            <Sprout className="h-3.5 w-3.5" />
          </div>
          <span className="text-sm font-semibold text-zinc-900 dark:text-zinc-100">
            AgriLink
          </span>
        </div>
        <button
          type="button"
          onClick={() => setMobileMenuOpen(false)}
          className="flex h-7 w-7 items-center justify-center rounded-md text-zinc-400 transition-colors hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-800 dark:hover:text-zinc-300"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      {/* Navigation */}
      <div className="flex-1">
        <p className="mb-2 px-3 text-[10px] font-semibold uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
          Navigation
        </p>
        <nav className="space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => handleSelectTab(item.id)}
                className={`group relative flex w-full items-center gap-2.5 rounded-md px-3 py-2 text-[13px] transition-colors ${
                  isActive
                    ? 'bg-emerald-50 font-semibold text-emerald-900 dark:bg-emerald-950/40 dark:text-emerald-200'
                    : 'text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 dark:text-zinc-400 dark:hover:bg-zinc-800/60 dark:hover:text-zinc-200'
                }`}
              >
                {/* Active indicator pill */}
                {isActive && (
                  <span className="absolute left-0 top-1/2 h-4 w-[3px] -translate-y-1/2 rounded-r-full bg-emerald-600 dark:bg-emerald-400" />
                )}

                <Icon
                  className={`h-4 w-4 shrink-0 ${
                    isActive
                      ? 'text-emerald-600 dark:text-emerald-400'
                      : 'text-zinc-400 group-hover:text-zinc-500 dark:text-zinc-500 dark:group-hover:text-zinc-400'
                  }`}
                />
                <span className="flex-1 truncate text-left">{item.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Footer / Logout */}
      <div className="mt-auto border-t border-zinc-100 pt-4 dark:border-zinc-800">
        <button
          type="button"
          onClick={() => logoutAction()}
          className="flex w-full items-center justify-center gap-2 rounded-lg border border-zinc-200 py-2.5 text-xs font-medium text-zinc-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600 dark:border-zinc-800 dark:text-zinc-400 dark:hover:border-red-900 dark:hover:bg-red-950/40 dark:hover:text-red-400"
        >
          <LogOut className="h-4 w-4" />
          <span>Sign Out</span>
        </button>
      </div>
    </div>
  );

  return (
    <>
      {/* Mobile backdrop */}
      {mobileMenuOpen && (
        <div
          className="fixed inset-0 z-40 bg-zinc-950/50 backdrop-blur-sm transition-opacity lg:hidden"
          onClick={() => setMobileMenuOpen(false)}
        />
      )}

      {/* Mobile drawer */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-[280px] flex-col border-r border-zinc-200 bg-white p-4 shadow-2xl transition-transform duration-200 ease-out lg:hidden dark:border-zinc-800 dark:bg-zinc-900 ${
          mobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {sidebarContent}
      </aside>

      {/* Desktop sidebar */}
      <aside className="hidden w-[260px] shrink-0 lg:block">
        <div className="sticky top-16 flex h-[calc(100vh-4rem)] flex-col overflow-y-auto border-r border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950/40">
          {sidebarContent}
        </div>
      </aside>
    </>
  );
}
