'use client';

import React, { useState } from 'react';
import { Navbar } from '@/components/Navbar';
import { Sidebar } from '@/components/Sidebar';
import { FarmerView } from '@/components/roles/FarmerView';
import { BuyerView } from '@/components/roles/BuyerView';
import { TransporterView } from '@/components/roles/TransporterView';
import { GovernmentView } from '@/components/roles/GovernmentView';
import { UserRole } from '@/lib/types';

interface DashboardClientProps {
  initialUser: {
    id: string;
    email: string;
    name?: string | null;
    role: string;
    organizationName?: string | null;
    district?: string | null;
    isVerified?: boolean;
  };
  initialRole: UserRole;
}

export function DashboardClient({ initialUser, initialRole }: DashboardClientProps) {
  const [currentRole, setCurrentRole] = useState<UserRole>(initialRole);
  const [activeTab, setActiveTab] = useState<string>('overview');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [mobileMenuOpen, setMobileMenuOpen] = useState<boolean>(false);

  return (
    <div className="min-h-screen bg-zinc-50/70 font-sans text-zinc-900 antialiased dark:bg-zinc-950 dark:text-zinc-100">
      <Navbar
        currentRole={currentRole}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        mobileMenuOpen={mobileMenuOpen}
        setMobileMenuOpen={setMobileMenuOpen}
        currentUser={initialUser}
      />

      <div className="flex">
        <Sidebar
          currentRole={currentRole}
          activeTab={activeTab}
          onTabChange={setActiveTab}
          mobileMenuOpen={mobileMenuOpen}
          setMobileMenuOpen={setMobileMenuOpen}
        />

        <main className="min-w-0 flex-1 p-4 sm:p-6 lg:p-8">
          <div className="mx-auto max-w-7xl">
            {currentRole === 'farmer' && (
              <FarmerView activeTab={activeTab} searchQuery={searchQuery} />
            )}
            {currentRole === 'buyer' && (
              <BuyerView activeTab={activeTab} searchQuery={searchQuery} />
            )}
            {currentRole === 'transporter' && (
              <TransporterView activeTab={activeTab} searchQuery={searchQuery} />
            )}
            {currentRole === 'government' && (
              <GovernmentView activeTab={activeTab} searchQuery={searchQuery} />
            )}
          </div>
        </main>
      </div>
    </div>
  );
}
