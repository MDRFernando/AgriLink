'use client';

import React, { useState } from 'react';
import {
  Sprout,
  Store,
  Truck,
  Building2,
  Bell,
  Search,
  Menu,
  X,
  ShieldCheck,
  LogOut,
} from 'lucide-react';
import { UserRole } from '@/lib/types';
import { logoutAction } from '@/app/actions/authActions';
import { useQuery } from '@tanstack/react-query';
import { getNotificationsAction } from '@/app/actions/notificationActions';

interface NavbarProps {
  currentRole: UserRole;
  searchQuery: string;
  onSearchChange: (q: string) => void;
  mobileMenuOpen: boolean;
  setMobileMenuOpen: (open: boolean) => void;
  currentUser?: {
    id: string;
    email: string;
    name?: string | null;
    role: string;
    organizationName?: string | null;
    district?: string | null;
    isVerified?: boolean;
  } | null;
}

const ROLE_CONFIG: Record<
  UserRole,
  { label: string; icon: React.ComponentType<{ className?: string }> }
> = {
  farmer: {
    label: 'Farmer',
    icon: Sprout,
  },
  buyer: {
    label: 'Wholesale Buyer',
    icon: Store,
  },
  transporter: {
    label: 'Logistics Operator',
    icon: Truck,
  },
  government: {
    label: 'Government / Admin',
    icon: Building2,
  },
};

export function Navbar({
  currentRole,
  searchQuery,
  onSearchChange,
  mobileMenuOpen,
  setMobileMenuOpen,
  currentUser,
}: NavbarProps) {
  const [notifOpen, setNotifOpen] = useState(false);
  const [mobileSearchVisible, setMobileSearchVisible] = useState(false);

  const activeRoleConfig = ROLE_CONFIG[currentRole] || ROLE_CONFIG.farmer;
  const ActiveIcon = activeRoleConfig.icon;

  const { data: notifications = [] } = useQuery({
    queryKey: ['notifications', currentRole],
    queryFn: () => getNotificationsAction(currentRole),
  });

  return (
    <header className="sticky top-0 z-40 w-full border-b border-zinc-200 bg-white/95 backdrop-blur-sm dark:border-zinc-800 dark:bg-zinc-900/95">
      <div className="flex h-16 items-center justify-between px-4 sm:px-6">
        {/* Brand & Mobile Toggle */}
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-zinc-200 text-zinc-600 hover:bg-zinc-100 lg:hidden dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
            aria-label="Toggle navigation"
          >
            {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>

          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-700 text-white shadow-xs">
              <Sprout className="h-5 w-5" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="text-base font-bold tracking-tight text-zinc-900 dark:text-zinc-50">
                  AgriLink
                </span>
                <span className="rounded bg-emerald-100 px-1.5 py-0.5 text-[10px] font-semibold text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
                  BitApp
                </span>
              </div>
              <p className="hidden text-[11px] text-zinc-500 sm:block dark:text-zinc-400">
                National Agricultural Exchange & Intelligence
              </p>
            </div>
          </div>
        </div>

        {/* Global Search - Desktop */}
        <div className="hidden max-w-xs flex-1 px-4 md:block lg:max-w-md">
          <div className="relative">
            <Search className="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-zinc-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              placeholder={`Filter ${activeRoleConfig.label.toLowerCase()} listings, orders, records...`}
              className="w-full rounded-lg border border-zinc-200 bg-zinc-50 py-1.5 pr-4 pl-9 text-xs text-zinc-900 placeholder-zinc-400 transition-colors focus:border-emerald-600 focus:bg-white focus:outline-hidden dark:border-zinc-700 dark:bg-zinc-800/80 dark:text-zinc-100 dark:placeholder-zinc-500 dark:focus:border-emerald-500 dark:focus:bg-zinc-900"
            />
          </div>
        </div>

        {/* Actions: Role Badge, Notifications, User Profile */}
        <div className="flex items-center gap-2 sm:gap-3">
          {/* Mobile Search Toggle */}
          <button
            type="button"
            onClick={() => setMobileSearchVisible(!mobileSearchVisible)}
            className="flex h-9 w-9 items-center justify-center rounded-lg border border-zinc-200 text-zinc-600 hover:bg-zinc-100 md:hidden dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
            aria-label="Toggle search"
          >
            <Search className="h-4 w-4" />
          </button>

          {/* Active Role Indicator (Clean Badge - Role Changer Removed) */}
          <div className="flex items-center gap-2 rounded-lg border border-zinc-200 bg-zinc-50 px-2.5 py-1.5 text-xs font-semibold text-zinc-800 sm:px-3 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-200">
            <ActiveIcon className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
            <span className="hidden sm:inline">{activeRoleConfig.label}</span>
          </div>

          {/* Notifications Popover */}
          <div className="relative">
            <button
              type="button"
              onClick={() => setNotifOpen(!notifOpen)}
              className="relative flex h-9 w-9 items-center justify-center rounded-lg border border-zinc-200 text-zinc-600 transition hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
              aria-label="View notifications"
            >
              <Bell className="h-4 w-4" />
              {notifications.length > 0 && (
                <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-emerald-600 ring-2 ring-white dark:ring-zinc-900" />
              )}
            </button>

            {notifOpen && (
              <>
                <div className="fixed inset-0 z-20" onClick={() => setNotifOpen(false)} />
                <div className="absolute right-0 z-30 mt-2 w-80 origin-top-right rounded-xl border border-zinc-200 bg-white p-3 shadow-xl sm:w-96 dark:border-zinc-800 dark:bg-zinc-900">
                  <div className="flex items-center justify-between border-b border-zinc-100 pb-2 dark:border-zinc-800">
                    <h4 className="text-xs font-semibold text-zinc-900 dark:text-zinc-100">
                      Live Activity & Alerts
                    </h4>
                    <span className="text-[10px] text-emerald-600 font-medium">
                      {notifications.length} active
                    </span>
                  </div>
                  <div className="mt-2 divide-y divide-zinc-100 space-y-1 dark:divide-zinc-800">
                    {notifications.map((n, i) => (
                      <div key={i} className="py-2">
                        <div className="flex items-center justify-between">
                          <p className="text-xs font-medium text-zinc-900 dark:text-zinc-100">
                            {n.title}
                          </p>
                          <span className="text-[10px] text-zinc-400">{n.time}</span>
                        </div>
                        <p className="mt-0.5 text-xs text-zinc-500 dark:text-zinc-400">
                          {n.desc}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              </>
            )}
          </div>

          {/* User Identity & Logout */}
          <div className="flex items-center gap-3 border-l border-zinc-200 pl-3 dark:border-zinc-800">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-emerald-100 text-xs font-bold text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
              {(currentUser?.name || currentUser?.email || activeRoleConfig.label).charAt(0).toUpperCase()}
            </div>
            <div className="hidden lg:block text-left text-xs">
              <div className="flex items-center gap-1 font-semibold text-zinc-900 dark:text-zinc-100">
                <span className="truncate max-w-[130px]">
                  {currentUser?.name || currentUser?.email?.split('@')[0]}
                </span>
                {currentUser?.isVerified && (
                  <ShieldCheck className="h-3.5 w-3.5 text-emerald-600" />
                )}
              </div>
              <span className="text-[10px] text-zinc-400 capitalize">
                {currentUser?.organizationName || currentUser?.role || 'Verified Partner'}
              </span>
            </div>

            <button
              type="button"
              onClick={() => logoutAction()}
              title="Sign Out"
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-200 text-zinc-500 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600 dark:border-zinc-700 dark:text-zinc-400 dark:hover:border-red-900 dark:hover:bg-red-950/40 dark:hover:text-red-400"
            >
              <LogOut className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Expandable Search Bar */}
      {mobileSearchVisible && (
        <div className="border-t border-zinc-200 bg-zinc-50 p-3 md:hidden dark:border-zinc-800 dark:bg-zinc-900">
          <div className="relative">
            <Search className="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-zinc-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              placeholder={`Search ${activeRoleConfig.label.toLowerCase()} listings, orders...`}
              className="w-full rounded-lg border border-zinc-200 bg-white py-2 pr-4 pl-9 text-xs text-zinc-900 placeholder-zinc-400 focus:border-emerald-600 focus:outline-hidden dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-100"
            />
          </div>
        </div>
      )}
    </header>
  );
}
