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
  Store,
  Building2,
  Circle,
} from 'lucide-react';
import { UserRole } from '@/lib/types';

interface SidebarProps {
  currentRole: UserRole;
  onRoleChange: (role: UserRole) => void;
  activeTab: string;
  onTabChange: (tab: string) => void;
  mobileMenuOpen: boolean;
  setMobileMenuOpen: (open: boolean) => void;
}

const PERSONAS: Record<
  UserRole,
  {
    name: string;
    title: string;
    location: string;
    roleLabel: string;
    icon: React.ComponentType<{ className?: string }>;
  }
> = {
  farmer: {
    name: 'Sunil Bandara',
    title: 'Smallholder Farmer',
    location: 'Eppawala, Anuradhapura',
    roleLabel: 'Producer',
    icon: Sprout,
  },
  buyer: {
    name: 'Keells Food Products PLC',
    title: 'Institutional Wholesale',
    location: 'Colombo Central Hub',
    roleLabel: 'Verified Buyer',
    icon: Store,
  },
  transporter: {
    name: 'Rajarata Express Logistics',
    title: 'Fleet Carrier (4 Units)',
    location: 'Anuradhapura Hub',
    roleLabel: 'Transporter',
    icon: Truck,
  },
  government: {
    name: 'Dept of Agriculture',
    title: 'Agrarian Development',
    location: 'National Intelligence Desk',
    roleLabel: 'Govt Admin',
    icon: Building2,
  },
};

const NAV_ITEMS: Record<
  UserRole,
  {
    id: string;
    label: string;
    icon: React.ComponentType<{ className?: string }>;
    badge?: string;
  }[]
> = {
  farmer: [
    { id: 'overview', label: 'Farm Overview', icon: LayoutDashboard },
    { id: 'listings', label: 'Produce Listings', icon: Sprout, badge: '6' },
    { id: 'auctions', label: 'Live Auctions', icon: Gavel, badge: '5' },
    { id: 'crop_plans', label: 'Crop Plans', icon: CalendarDays },
    { id: 'calculator', label: 'Income Calculator', icon: Calculator },
  ],
  buyer: [
    { id: 'overview', label: 'Procurement Hub', icon: LayoutDashboard },
    { id: 'marketplace', label: 'Marketplace', icon: ShoppingBag, badge: '6' },
    { id: 'demands', label: 'Sourcing Demands', icon: FileSpreadsheet, badge: '4' },
    { id: 'orders', label: 'Orders & Tracking', icon: Boxes, badge: '2' },
  ],
  transporter: [
    { id: 'overview', label: 'Dispatch Centre', icon: LayoutDashboard },
    { id: 'available_jobs', label: 'Freight Jobs', icon: Compass, badge: '2' },
    { id: 'active_trips', label: 'Active Trips', icon: Truck, badge: '2' },
    { id: 'fleet', label: 'Fleet & Drivers', icon: Users, badge: '4' },
  ],
  government: [
    { id: 'overview', label: 'National Overview', icon: LayoutDashboard },
    { id: 'supply_map', label: 'Supply & Demand', icon: MapPin },
    { id: 'market_prices', label: 'Price Intelligence', icon: TrendingUp },
    { id: 'verifications', label: 'KYC Desk', icon: ShieldCheck, badge: '2' },
  ],
};

export function Sidebar({
  currentRole,
  activeTab,
  onTabChange,
  mobileMenuOpen,
  setMobileMenuOpen,
}: SidebarProps) {
  const persona = PERSONAS[currentRole];
  const PersonaIcon = persona.icon;
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

      {/* Persona card */}
      <div className="rounded-lg bg-zinc-900 p-3 dark:bg-zinc-800">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-emerald-600 text-white">
            <PersonaIcon className="h-4.5 w-4.5" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-[13px] font-semibold leading-tight text-white">
              {persona.name}
            </p>
            <p className="truncate text-[11px] leading-tight text-zinc-400">
              {persona.title}
            </p>
          </div>
        </div>
        <div className="mt-2.5 flex items-center gap-1.5 text-[10px] text-zinc-500">
          <MapPin className="h-3 w-3 shrink-0 text-zinc-500" />
          <span className="truncate">{persona.location}</span>
        </div>
      </div>

      {/* Navigation */}
      <div className="mt-6 flex-1">
        <p className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
          Navigation
        </p>
        <nav className="space-y-0.5">
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

                {item.badge && (
                  <span
                    className={`min-w-[18px] rounded-full px-1.5 py-px text-center text-[10px] font-semibold tabular-nums ${
                      isActive
                        ? 'bg-emerald-600 text-white dark:bg-emerald-500'
                        : 'bg-zinc-200 text-zinc-600 dark:bg-zinc-700 dark:text-zinc-300'
                    }`}
                  >
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Footer status */}
      <div className="mt-auto border-t border-zinc-100 pt-4 dark:border-zinc-800">
        <div className="rounded-lg border border-zinc-200 p-3 dark:border-zinc-800">
          <div className="flex items-center gap-2">
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-500" />
            </span>
            <span className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
              Maha 2026 Season
            </span>
            <span className="ml-auto rounded bg-emerald-50 px-1.5 py-px text-[10px] font-semibold text-emerald-700 dark:bg-emerald-950 dark:text-emerald-400">
              Live
            </span>
          </div>
          <p className="mt-1.5 text-[11px] leading-relaxed text-zinc-500 dark:text-zinc-400">
            Direct price discovery active. In-memory demo sandbox.
          </p>
        </div>
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
