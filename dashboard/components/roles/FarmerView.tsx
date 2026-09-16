'use client';

import React, { useState } from 'react';
import {
  Sprout,
  TrendingUp,
  Gavel,
  Scale,
  Calendar,
  MapPin,
  Clock,
  Plus,
  CheckCircle2,
  DollarSign,
  Calculator,
  History,
  AlertCircle
} from 'lucide-react';
import { StatCard } from '../common/StatCard';
import { GradeBadge, StatusBadge, Badge } from '../common/Badge';
import { ActionModal } from '../common/ActionModal';
import { EmptyState } from '../common/EmptyState';
import {
  MOCK_PRODUCTIONS,
  MOCK_CROP_PLANS
} from '@/lib/mockData';
import { ProductionListing, QualityGrade } from '@/lib/types';

interface FarmerViewProps {
  activeTab: string;
  searchQuery: string;
}

export function FarmerView({ activeTab, searchQuery }: FarmerViewProps) {
  const [productions, setProductions] = useState<ProductionListing[]>(MOCK_PRODUCTIONS);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [acceptedBids, setAcceptedBids] = useState<Record<string, boolean>>({});

  // Modals state
  const [isNewListingModalOpen, setIsNewListingModalOpen] = useState(false);
  const [auditBidsListing, setAuditBidsListing] = useState<ProductionListing | null>(null);

  // New Listing Form State
  const [newCropType, setNewCropType] = useState('Keeri Samba Paddy');
  const [newVariety, setNewVariety] = useState('BG-360 Certified');
  const [newCategory, setNewCategory] = useState<'Vegetables' | 'Paddy & Rice' | 'Fruits' | 'Spices'>('Paddy & Rice');
  const [newQuantity, setNewQuantity] = useState(3000);
  const [newGrade, setNewGrade] = useState<QualityGrade>('A');
  const [newPrice, setNewPrice] = useState(210);
  const [newHarvestDate, setNewHarvestDate] = useState('2026-09-30');

  // Calculator State
  const [calcQuantity, setCalcQuantity] = useState<number>(3500);
  const [calcCropPrice, setCalcCropPrice] = useState<number>(215);
  const [calcTraditionalPrice, setCalcTraditionalPrice] = useState<number>(165);
  const [calcTransportRate, setCalcTransportRate] = useState<number>(12);

  const filteredProductions = productions.filter((p) => {
    const matchesSearch =
      p.cropType.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.variety.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.listingCode.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.district.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesCategory =
      selectedCategory === 'all' || p.category.toLowerCase() === selectedCategory.toLowerCase();

    return matchesSearch && matchesCategory;
  });

  const handleAcceptBid = (prodId: string) => {
    setAcceptedBids((prev) => ({ ...prev, [prodId]: true }));
  };

  const handleCreateListing = (e: React.FormEvent) => {
    e.preventDefault();
    const newEntry: ProductionListing = {
      id: `prod-${Date.now()}`,
      listingCode: `LST-2026-${Math.floor(1000 + Math.random() * 9000)}`,
      farmerName: 'Sunil Bandara',
      farmerPhone: '+94 77 123 4567',
      cropType: newCropType,
      variety: newVariety,
      category: newCategory,
      quantityKg: Number(newQuantity),
      qualityGrade: newGrade,
      harvestDate: newHarvestDate,
      region: 'North Central',
      district: 'Anuradhapura',
      status: 'available',
      minAcceptablePriceKg: Number(newPrice),
      traditionalFarmgatePriceKg: Math.round(newPrice * 0.78),
      projectedRevenue: Number(newQuantity) * Number(newPrice),
      description: `Direct farmgate listing submitted by Sunil Bandara. Moisture controlled, graded ${newGrade}.`,
      activeAuction: {
        id: `auc-${Date.now()}`,
        openingBid: Number(newPrice),
        currentHighestBid: Number(newPrice),
        bidCount: 1,
        endsInMinutes: 180,
        status: 'open',
        highestBidderName: 'Initial Reserve Open'
      }
    };

    setProductions([newEntry, ...productions]);
    setIsNewListingModalOpen(false);
  };

  // Calculator computations
  const totalTraditionalRevenue = calcQuantity * calcTraditionalPrice;
  const totalDirectRevenue = calcQuantity * calcCropPrice;
  const totalTransportCost = calcQuantity * calcTransportRate;
  const netDirectRevenue = totalDirectRevenue - totalTransportCost;
  const netGainLkr = netDirectRevenue - totalTraditionalRevenue;
  const netGainPercent = ((netGainLkr / totalTraditionalRevenue) * 100).toFixed(1);

  return (
    <div className="space-y-6">
      {/* Clean, Non-Slop Page Header */}
      <div className="flex flex-col justify-between gap-4 border-b border-zinc-200 pb-5 sm:flex-row sm:items-center dark:border-zinc-800">
        <div>
          <div className="flex items-center gap-2 text-xs text-zinc-500 dark:text-zinc-400">
            <span>AgriLink</span>
            <span>/</span>
            <span className="font-semibold text-emerald-700 dark:text-emerald-400">Farmer Operations</span>
            <span>•</span>
            <span>Eppawala, Anuradhapura</span>
          </div>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50 sm:text-3xl">
            Farmer Harvest & Auction Desk
          </h1>
          <p className="mt-0.5 text-xs text-zinc-500 dark:text-zinc-400 sm:text-sm">
            Monitor real-time wholesale bids, manage graded produce batches, and simulate farmgate income.
          </p>
        </div>

        <div className="flex shrink-0 items-center gap-2.5">
          <button
            type="button"
            onClick={() => setIsNewListingModalOpen(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-emerald-700 px-4 py-2 text-xs font-semibold text-white shadow-xs transition hover:bg-emerald-800"
          >
            <Plus className="h-4 w-4" />
            <span>List New Produce</span>
          </button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Active Harvest Listings"
          value={productions.length.toString()}
          subtitle="Across 3 agricultural categories"
          icon={Sprout}
        />
        <StatCard
          title="Live Produce On Offer"
          value={`${productions.reduce((acc, p) => acc + p.quantityKg, 0).toLocaleString()} kg`}
          subtitle="Ready for harvest & available"
          icon={Scale}
        />
        <StatCard
          title="Projected Farmgate Revenue"
          value={`Rs. ${(productions.reduce((acc, p) => acc + p.projectedRevenue, 0) / 1000000).toFixed(2)}M`}
          change={{
            value: '+28.4%',
            isPositive: true,
            label: 'vs middleman benchmark'
          }}
          icon={DollarSign}
        />
        <StatCard
          title="Avg Bidding Premium"
          value="+14.2%"
          change={{
            value: '+Rs. 38/kg',
            isPositive: true,
            label: 'above reserve price'
          }}
          icon={TrendingUp}
        />
      </div>

      {/* Live Auctions Section */}
      {(activeTab === 'overview' || activeTab === 'auctions') && (
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                <Gavel className="h-4 w-4 text-emerald-600" />
                Live Auctions & Real-Time Buyer Bids
              </h2>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                Transparent wholesale buyer bids with soft-close protection
              </p>
            </div>
            <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300">
              <span className="h-2 w-2 animate-pulse rounded-full bg-emerald-500" />
              Live Auction Engine Active
            </span>
          </div>

          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            {productions
              .filter((p) => p.activeAuction)
              .map((p) => {
                const auc = p.activeAuction!;
                const isAccepted = acceptedBids[p.id];
                const gainPerKg = auc.currentHighestBid - p.traditionalFarmgatePriceKg;

                return (
                  <div
                    key={p.id}
                    className="rounded-xl border border-zinc-200 bg-white p-5 shadow-2xs transition hover:border-zinc-300 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-zinc-700"
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-xs font-semibold text-zinc-500">
                            {p.listingCode}
                          </span>
                          <GradeBadge grade={p.qualityGrade} />
                        </div>
                        <h3 className="mt-1 text-base font-bold text-zinc-900 dark:text-zinc-100">
                          {p.cropType}{' '}
                          <span className="text-xs font-normal text-zinc-500">({p.variety})</span>
                        </h3>
                      </div>
                      <div className="text-right">
                        <span className="flex items-center justify-end gap-1 text-xs font-medium text-amber-600 dark:text-amber-400">
                          <Clock className="h-3.5 w-3.5" />
                          {auc.endsInMinutes}m left
                        </span>
                        <span className="text-[11px] text-zinc-400">{auc.bidCount} bids placed</span>
                      </div>
                    </div>

                    <div className="mt-4 grid grid-cols-3 rounded-lg border border-zinc-100 bg-zinc-50 p-3 text-center dark:border-zinc-800 dark:bg-zinc-800/40">
                      <div>
                        <p className="text-[10px] text-zinc-500 uppercase">Quantity</p>
                        <p className="text-sm font-semibold text-zinc-800 dark:text-zinc-200">
                          {p.quantityKg.toLocaleString()} kg
                        </p>
                      </div>
                      <div>
                        <p className="text-[10px] text-zinc-500 uppercase">Opening Bid</p>
                        <p className="text-sm font-semibold text-zinc-800 dark:text-zinc-200">
                          Rs. {auc.openingBid}
                        </p>
                      </div>
                      <div>
                        <p className="text-[10px] font-semibold text-emerald-600 uppercase">
                          Highest Bid
                        </p>
                        <p className="text-base font-bold text-emerald-700 dark:text-emerald-400">
                          Rs. {auc.currentHighestBid}/kg
                        </p>
                      </div>
                    </div>

                    <div className="mt-3 flex items-center justify-between text-xs text-zinc-600 dark:text-zinc-400">
                      <div>
                        <span className="text-zinc-400">Current Lead: </span>
                        <span className="font-medium text-zinc-900 dark:text-zinc-200">
                          {auc.highestBidderName}
                        </span>
                      </div>
                      <div className="text-emerald-600 dark:text-emerald-400 font-medium">
                        +Rs. {gainPerKg}/kg vs middleman
                      </div>
                    </div>

                    <div className="mt-4 flex items-center gap-3 border-t border-zinc-100 pt-3 dark:border-zinc-800">
                      {isAccepted ? (
                        <div className="flex w-full items-center justify-center gap-2 rounded-lg bg-emerald-50 py-2 text-xs font-semibold text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
                          <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                          Bid Accepted & Order Generated!
                        </div>
                      ) : (
                        <>
                          <button
                            type="button"
                            onClick={() => handleAcceptBid(p.id)}
                            className="flex-1 rounded-lg bg-emerald-700 py-2 text-xs font-semibold text-white transition hover:bg-emerald-800"
                          >
                            Accept Winning Bid
                          </button>
                          <button
                            type="button"
                            onClick={() => setAuditBidsListing(p)}
                            className="inline-flex items-center gap-1 rounded-lg border border-zinc-200 px-3 py-2 text-xs font-medium text-zinc-700 hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
                          >
                            <History className="h-3.5 w-3.5" />
                            Audit Bids
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                );
              })}
          </div>
        </section>
      )}

      {/* Listings Tab */}
      {(activeTab === 'overview' || activeTab === 'listings') && (
        <section className="space-y-4">
          <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
            <div>
              <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                <Sprout className="h-4 w-4 text-emerald-600" />
                My Produce Batches & Harvest Stages
              </h2>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                Track status from field cultivation to wholesale dispatch
              </p>
            </div>

            {/* Category Filter */}
            <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
              {['all', 'Vegetables', 'Paddy & Rice', 'Spices'].map((cat) => (
                <button
                  key={cat}
                  type="button"
                  onClick={() => setSelectedCategory(cat)}
                  className={`rounded-lg px-3 py-1 text-xs font-medium transition ${
                    selectedCategory === cat
                      ? 'bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900'
                      : 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-400'
                  }`}
                >
                  {cat === 'all' ? 'All Crops' : cat}
                </button>
              ))}
            </div>
          </div>

          {/* Table Container */}
          {filteredProductions.length === 0 ? (
            <EmptyState
              title="No produce batches match your search"
              description="Try changing the crop category or clearing the search bar."
              onReset={() => setSelectedCategory('all')}
            />
          ) : (
            <div className="overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-2xs dark:border-zinc-800 dark:bg-zinc-900">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="border-b border-zinc-200 bg-zinc-50 text-[11px] font-semibold uppercase tracking-wider text-zinc-500 dark:border-zinc-800 dark:bg-zinc-800/50 dark:text-zinc-400">
                    <tr>
                      <th className="px-4 py-3">Code / Crop</th>
                      <th className="px-4 py-3">Grade</th>
                      <th className="px-4 py-3">Quantity</th>
                      <th className="px-4 py-3">Harvest Date</th>
                      <th className="px-4 py-3">Reserve Price</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3 text-right">Projected Value</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-zinc-100 dark:divide-zinc-800/60">
                    {filteredProductions.map((p) => (
                      <tr
                        key={p.id}
                        className="transition-colors hover:bg-zinc-50/70 dark:hover:bg-zinc-800/40"
                      >
                        <td className="px-4 py-3 font-medium">
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-[11px] text-zinc-400">{p.listingCode}</span>
                            <div>
                              <p className="font-semibold text-zinc-900 dark:text-zinc-100">
                                {p.cropType}
                              </p>
                              <p className="text-[11px] text-zinc-500 dark:text-zinc-400">{p.variety}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <GradeBadge grade={p.qualityGrade} />
                        </td>
                        <td className="px-4 py-3 font-mono font-medium text-zinc-800 dark:text-zinc-200">
                          {p.quantityKg.toLocaleString()} kg
                        </td>
                        <td className="px-4 py-3 text-zinc-600 dark:text-zinc-400">
                          {p.harvestDate}
                        </td>
                        <td className="px-4 py-3 font-mono text-zinc-900 dark:text-zinc-100">
                          Rs. {p.minAcceptablePriceKg}/kg
                        </td>
                        <td className="px-4 py-3">
                          <StatusBadge status={p.status} />
                        </td>
                        <td className="px-4 py-3 text-right font-mono font-semibold text-emerald-700 dark:text-emerald-400">
                          Rs. {p.projectedRevenue.toLocaleString()}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </section>
      )}

      {/* Crop Plans Tab */}
      {activeTab === 'crop_plans' && (
        <section className="space-y-4">
          <div>
            <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <Calendar className="h-4 w-4 text-emerald-600" />
              Seasonal Cultivation Plans (Maha / Yala)
            </h2>
            <p className="text-xs text-zinc-500 dark:text-zinc-400">
              Government-registered cultivation schedules to prevent regional gluts and deficits
            </p>
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            {MOCK_CROP_PLANS.map((plan) => (
              <div
                key={plan.id}
                className="rounded-xl border border-zinc-200 bg-white p-5 shadow-2xs dark:border-zinc-800 dark:bg-zinc-900"
              >
                <div className="flex items-center justify-between">
                  <span className="rounded-md bg-emerald-50 px-2 py-0.5 text-xs font-semibold text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
                    {plan.season}
                  </span>
                  <StatusBadge status={plan.status} />
                </div>
                <h3 className="mt-3 text-base font-bold text-zinc-900 dark:text-zinc-100">
                  {plan.cropType}
                </h3>
                <div className="mt-3 space-y-1.5 text-xs text-zinc-600 dark:text-zinc-400">
                  <div className="flex justify-between">
                    <span className="text-zinc-400">Acreage:</span>
                    <span className="font-semibold text-zinc-800 dark:text-zinc-200">
                      {plan.areaAcres} Acres
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-zinc-400">Expected Yield:</span>
                    <span className="font-mono font-semibold text-zinc-800 dark:text-zinc-200">
                      {plan.expectedYieldKg.toLocaleString()} kg
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-zinc-400">Location:</span>
                    <span>
                      {plan.dsDivision}, {plan.district}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-zinc-400">Target Harvest:</span>
                    <span className="font-medium text-emerald-600 dark:text-emerald-400">
                      {plan.harvestTargetDate}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Income Impact Calculator */}
      {(activeTab === 'overview' || activeTab === 'calculator') && (
        <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-2xs dark:border-zinc-800 dark:bg-zinc-900">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
              <Calculator className="h-4 w-4" />
            </div>
            <div>
              <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100">
                Farmer Net Income Impact Calculator
              </h2>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                Demonstrating direct economic advantage of AgriLink vs middleman supply chain
              </p>
            </div>
          </div>

          <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-12">
            {/* Input Controls */}
            <div className="space-y-4 lg:col-span-6">
              <div>
                <div className="flex justify-between text-xs font-medium text-zinc-700 dark:text-zinc-300">
                  <span>Harvest Volume (kg):</span>
                  <span className="font-mono font-bold text-emerald-700 dark:text-emerald-400">
                    {calcQuantity.toLocaleString()} kg
                  </span>
                </div>
                <input
                  type="range"
                  min="500"
                  max="10000"
                  step="250"
                  value={calcQuantity}
                  onChange={(e) => setCalcQuantity(Number(e.target.value))}
                  className="mt-2 w-full accent-emerald-600"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-medium text-zinc-600 dark:text-zinc-400">
                    BitApp Direct Price (Rs./kg)
                  </label>
                  <input
                    type="number"
                    value={calcCropPrice}
                    onChange={(e) => setCalcCropPrice(Number(e.target.value))}
                    className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-2 text-xs font-semibold dark:border-zinc-700 dark:bg-zinc-800"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-zinc-600 dark:text-zinc-400">
                    Middleman Price (Rs./kg)
                  </label>
                  <input
                    type="number"
                    value={calcTraditionalPrice}
                    onChange={(e) => setCalcTraditionalPrice(Number(e.target.value))}
                    className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-2 text-xs font-semibold dark:border-zinc-700 dark:bg-zinc-800"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-medium text-zinc-600 dark:text-zinc-400">
                  Estimated Transport Share (Rs./kg)
                </label>
                <input
                  type="number"
                  value={calcTransportRate}
                  onChange={(e) => setCalcTransportRate(Number(e.target.value))}
                  className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-2 text-xs font-semibold dark:border-zinc-700 dark:bg-zinc-800"
                />
              </div>
            </div>

            {/* Results Comparison Card */}
            <div className="rounded-xl border border-emerald-200 bg-emerald-50/50 p-5 lg:col-span-6 dark:border-emerald-800/60 dark:bg-emerald-950/20">
              <h3 className="text-xs font-semibold tracking-wider text-emerald-900 uppercase dark:text-emerald-300">
                Direct Net Payout Comparison
              </h3>

              <div className="mt-4 space-y-3 text-xs">
                <div className="flex justify-between border-b border-emerald-100 pb-2 dark:border-emerald-800/40">
                  <span className="text-zinc-600 dark:text-zinc-400">Traditional Middleman Net:</span>
                  <span className="font-mono font-semibold text-zinc-800 dark:text-zinc-200">
                    Rs. {totalTraditionalRevenue.toLocaleString()}
                  </span>
                </div>
                <div className="flex justify-between border-b border-emerald-100 pb-2 dark:border-emerald-800/40">
                  <span className="text-zinc-600 dark:text-zinc-400">BitApp Gross Sale:</span>
                  <span className="font-mono font-semibold text-zinc-800 dark:text-zinc-200">
                    Rs. {totalDirectRevenue.toLocaleString()}
                  </span>
                </div>
                <div className="flex justify-between border-b border-emerald-100 pb-2 dark:border-emerald-800/40">
                  <span className="text-zinc-600 dark:text-zinc-400">Deducted Logistics Fee:</span>
                  <span className="font-mono text-rose-600 dark:text-rose-400 font-medium">
                    - Rs. {totalTransportCost.toLocaleString()}
                  </span>
                </div>
                <div className="flex items-baseline justify-between pt-1">
                  <span className="font-semibold text-emerald-950 dark:text-emerald-200">
                    Direct Farmer Net Income:
                  </span>
                  <span className="font-mono text-lg font-bold text-emerald-800 dark:text-emerald-300">
                    Rs. {netDirectRevenue.toLocaleString()}
                  </span>
                </div>
              </div>

              <div className="mt-4 flex items-center justify-between rounded-lg bg-emerald-700 px-3.5 py-2.5 text-white">
                <span className="text-xs font-medium">Additional Net Farmer Profit:</span>
                <span className="font-mono text-sm font-bold">
                  +Rs. {netGainLkr.toLocaleString()} ({netGainPercent}%)
                </span>
              </div>
            </div>
          </div>
        </section>
      )}

      {/* New Produce Listing Modal */}
      <ActionModal
        isOpen={isNewListingModalOpen}
        onClose={() => setIsNewListingModalOpen(false)}
        title="List New Produce Batch"
        subtitle="Register your upcoming harvest for direct wholesale auction"
        maxWidth="lg"
      >
        <form onSubmit={handleCreateListing} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Crop Type
              </label>
              <input
                type="text"
                required
                value={newCropType}
                onChange={(e) => setNewCropType(e.target.value)}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Variety
              </label>
              <input
                type="text"
                required
                value={newVariety}
                onChange={(e) => setNewVariety(e.target.value)}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Category
              </label>
              <select
                value={newCategory}
                onChange={(e) => setNewCategory(e.target.value as any)}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-2.5 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              >
                <option value="Paddy & Rice">Paddy & Rice</option>
                <option value="Vegetables">Vegetables</option>
                <option value="Spices">Spices</option>
                <option value="Fruits">Fruits</option>
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Grade
              </label>
              <select
                value={newGrade}
                onChange={(e) => setNewGrade(e.target.value as QualityGrade)}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-2.5 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              >
                <option value="A">Grade A (Premium)</option>
                <option value="B">Grade B (Standard)</option>
                <option value="C">Grade C</option>
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Quantity (kg)
              </label>
              <input
                type="number"
                required
                value={newQuantity}
                onChange={(e) => setNewQuantity(Number(e.target.value))}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Opening Reserve Price (Rs./kg)
              </label>
              <input
                type="number"
                required
                value={newPrice}
                onChange={(e) => setNewPrice(Number(e.target.value))}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Expected Harvest Date
              </label>
              <input
                type="date"
                required
                value={newHarvestDate}
                onChange={(e) => setNewHarvestDate(e.target.value)}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
            </div>
          </div>

          <div className="mt-5 flex justify-end gap-2 border-t border-zinc-100 pt-3 dark:border-zinc-800">
            <button
              type="button"
              onClick={() => setIsNewListingModalOpen(false)}
              className="rounded-lg border border-zinc-200 px-4 py-2 text-xs font-medium text-zinc-600 hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-emerald-700 px-4 py-2 text-xs font-semibold text-white hover:bg-emerald-800"
            >
              Publish to Marketplace
            </button>
          </div>
        </form>
      </ActionModal>

      {/* Audit Bids History Modal */}
      {auditBidsListing && (
        <ActionModal
          isOpen={!!auditBidsListing}
          onClose={() => setAuditBidsListing(null)}
          title={`Auction Bidding History: ${auditBidsListing.cropType}`}
          subtitle={`Listing ${auditBidsListing.listingCode} • ${auditBidsListing.quantityKg.toLocaleString()} kg`}
        >
          <div className="space-y-3">
            <div className="rounded-lg bg-zinc-50 p-3 text-xs dark:bg-zinc-800/50">
              <div className="flex justify-between font-medium">
                <span className="text-zinc-500">Opening Bid:</span>
                <span className="font-mono">Rs. {auditBidsListing.activeAuction?.openingBid}/kg</span>
              </div>
              <div className="mt-1 flex justify-between font-bold text-emerald-700 dark:text-emerald-400">
                <span>Current Highest Bid:</span>
                <span className="font-mono">Rs. {auditBidsListing.activeAuction?.currentHighestBid}/kg</span>
              </div>
            </div>

            <div className="divide-y divide-zinc-100 text-xs dark:divide-zinc-800">
              <div className="flex items-center justify-between py-2">
                <div>
                  <p className="font-semibold text-zinc-900 dark:text-zinc-100">
                    {auditBidsListing.activeAuction?.highestBidderName}
                  </p>
                  <span className="text-[10px] text-zinc-400">Lead Bidder • 12 mins ago</span>
                </div>
                <span className="font-mono font-bold text-emerald-700 dark:text-emerald-400">
                  Rs. {auditBidsListing.activeAuction?.currentHighestBid}/kg
                </span>
              </div>
              <div className="flex items-center justify-between py-2">
                <div>
                  <p className="font-medium text-zinc-700 dark:text-zinc-300">
                    Cargills Quality Foods PLC
                  </p>
                  <span className="text-[10px] text-zinc-400">Prior Bidder • 28 mins ago</span>
                </div>
                <span className="font-mono font-medium text-zinc-600 dark:text-zinc-400">
                  Rs. {(auditBidsListing.activeAuction?.currentHighestBid || 200) - 10}/kg
                </span>
              </div>
              <div className="flex items-center justify-between py-2">
                <div>
                  <p className="font-medium text-zinc-700 dark:text-zinc-300">
                    Nawaloka Fresh Mart
                  </p>
                  <span className="text-[10px] text-zinc-400">Prior Bidder • 45 mins ago</span>
                </div>
                <span className="font-mono font-medium text-zinc-600 dark:text-zinc-400">
                  Rs. {(auditBidsListing.activeAuction?.currentHighestBid || 200) - 20}/kg
                </span>
              </div>
            </div>

            <div className="mt-4 border-t border-zinc-100 pt-3 text-right dark:border-zinc-800">
              <button
                type="button"
                onClick={() => setAuditBidsListing(null)}
                className="rounded-lg bg-zinc-900 px-4 py-1.5 text-xs font-medium text-white hover:bg-zinc-800 dark:bg-zinc-100 dark:text-zinc-900"
              >
                Close Audit
              </button>
            </div>
          </div>
        </ActionModal>
      )}
    </div>
  );
}
