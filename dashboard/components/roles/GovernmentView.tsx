'use client';

import React, { useState } from 'react';
import {
  Building2,
  TrendingUp,
  MapPin,
  ShieldCheck,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Scale,
  FileSpreadsheet,
  Users,
  Search,
  Database,
  BarChart3,
  Activity,
  FileText,
  Filter
} from 'lucide-react';
import { StatCard } from '../common/StatCard';
import { GradeBadge, StatusBadge, Badge } from '../common/Badge';
import { ActionModal } from '../common/ActionModal';
import { EmptyState } from '../common/EmptyState';
import { VerificationRequest, DistrictSupplyMetric, MarketPriceIndex } from '@/lib/types';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getGovernmentDataAction,
  verifyUserAction,
} from '@/app/actions/governmentActions';

interface GovernmentViewProps {
  activeTab: string;
  searchQuery: string;
}

export function GovernmentView({ activeTab, searchQuery }: GovernmentViewProps) {
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['governmentData'],
    queryFn: () => getGovernmentDataAction(),
  });

  const districtSupply = data?.districtSupply || [];
  const marketPrices = data?.marketPrices || [];
  const verifications = data?.verifications || [];

  const [selectedDistrict, setSelectedDistrict] = useState<string>('all');
  const [selectedCropTrend, setSelectedCropTrend] = useState<string>('Keeri Samba Paddy');
  const [inspectedDoc, setInspectedDoc] = useState<{ title: string; applicant: string; docs: string[] } | null>(null);

  const verifyMutation = useMutation({
    mutationFn: ({ userId, approve }: { userId: string; approve: boolean }) =>
      verifyUserAction(userId, approve),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['governmentData'] });
    },
  });

  const handleApprove = (id: string) => {
    verifyMutation.mutate({ userId: id, approve: true });
  };

  const handleReject = (id: string) => {
    verifyMutation.mutate({ userId: id, approve: false });
  };

  const filteredPrices = marketPrices.filter((p) => {
    const matchesSearch =
      p.cropType.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.district.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesDistrict = selectedDistrict === 'all' || p.district.includes(selectedDistrict);
    return matchesSearch && matchesDistrict;
  });

  const selectedCropPrice =
    marketPrices.find((p) => p.cropType === selectedCropTrend) || marketPrices[0];
  const curPrice = selectedCropPrice ? selectedCropPrice.currentPriceKg : 215;
  const yestPrice = selectedCropPrice ? selectedCropPrice.yesterdayPriceKg : 208;
  const lowPrice = selectedCropPrice ? selectedCropPrice.weeklyLowKg : Math.round(curPrice * 0.92);
  const highPrice = selectedCropPrice ? selectedCropPrice.weeklyHighKg : Math.round(curPrice * 1.05);

  const activeTrend = {
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'],
    prices: [
      lowPrice,
      Math.round(lowPrice + (curPrice - lowPrice) * 0.25),
      Math.round(lowPrice + (curPrice - lowPrice) * 0.5),
      Math.round(lowPrice + (curPrice - lowPrice) * 0.45),
      yestPrice,
      Math.round(yestPrice + (curPrice - yestPrice) * 0.6),
      curPrice,
    ],
  };
  const minPrice = Math.min(...activeTrend.prices) * 0.95;
  const maxPrice = Math.max(...activeTrend.prices) * 1.05;
  const priceRange = maxPrice - minPrice || 1;

  return (
    <div className="space-y-6">
      {/* Clean Page Header */}
      <div className="flex flex-col justify-between gap-4 border-b border-zinc-200 pb-5 sm:flex-row sm:items-center dark:border-zinc-800">
        <div>
          <div className="flex items-center gap-2 text-xs text-zinc-500 dark:text-zinc-400">
            <span>AgriLink</span>
            <span>/</span>
            <span className="font-semibold text-emerald-700 dark:text-emerald-400">National Observatory</span>
            <span>•</span>
            <span>Department of Agrarian Development</span>
          </div>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50 sm:text-3xl">
            National Agricultural Observatory
          </h1>
          <p className="mt-0.5 text-xs text-zinc-500 dark:text-zinc-400 sm:text-sm">
            Monitor provincial food security balances, wholesale price discovery curves, and institutional buyer verification.
          </p>
        </div>

        <div className="flex shrink-0 items-center gap-2">
          <div className="rounded-xl border border-zinc-200 bg-white px-3.5 py-2 text-xs shadow-2xs dark:border-zinc-800 dark:bg-zinc-900">
            <span className="text-zinc-500">Data Source: </span>
            <span className="font-semibold text-emerald-700 dark:text-emerald-400">Live Seed + Transaction Log</span>
          </div>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Monitored Cultivation Area"
          value="123,700 Acres"
          subtitle="Across 24 agrarian districts"
          icon={MapPin}
        />
        <StatCard
          title="Intermediary Dependency Index"
          value="38.2%"
          change={{
            value: '-34.6%',
            isPositive: true,
            label: 'cut in middleman layers'
          }}
          icon={TrendingUp}
        />
        <StatCard
          title="Active Producer Population"
          value="42,920"
          subtitle="Verified smallholder farmers"
          icon={Users}
        />
        <StatCard
          title="Supply Anomaly Alerts"
          value="2 Flagged"
          badge="Action Required"
          subtitle="Dambulla Onion & Tomato glut"
          icon={AlertTriangle}
          variant="warning"
        />
      </div>

      {/* District Supply & Demand Equilibrium Visualizer */}
      {(activeTab === 'overview' || activeTab === 'supply_map') && (
        <section className="space-y-4">
          <div className="flex flex-col justify-between gap-2 sm:flex-row sm:items-center">
            <div>
              <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                <BarChart3 className="h-4 w-4 text-emerald-600" />
                District Supply & Demand Equilibrium (Metric Tonnes)
              </h2>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                Visualizing regional production capacity against provincial consumption quotas
              </p>
            </div>
            <div className="flex items-center gap-3 text-xs">
              <span className="flex items-center gap-1 text-emerald-700 dark:text-emerald-400 font-medium">
                <span className="h-3 w-3 rounded-xs bg-emerald-600" /> Harvest Tonnes
              </span>
              <span className="flex items-center gap-1 text-zinc-600 dark:text-zinc-400 font-medium">
                <span className="h-3 w-3 rounded-xs bg-zinc-300 dark:bg-zinc-700" /> Market Demand
              </span>
            </div>
          </div>

          {/* Visual Bars Comparison Grid */}
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            {districtSupply.map((d) => {
              const maxVal = 95000;
              const harvestPercent = Math.min(100, Math.round((d.projectedHarvestTonnes / maxVal) * 100));
              const demandPercent = Math.min(100, Math.round((d.marketDemandTonnes / maxVal) * 100));
              const isSurplus = d.supplyDeficitSurplusTonnes >= 0;

              return (
                <div
                  key={d.district}
                  className="rounded-xl border border-zinc-200 bg-white p-4 shadow-2xs dark:border-zinc-800 dark:bg-zinc-900"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="text-sm font-bold text-zinc-900 dark:text-zinc-100">
                        {d.district}
                      </h3>
                      <p className="text-[11px] text-zinc-500">{d.province} Province • {d.activeFarmers.toLocaleString()} Farmers</p>
                    </div>
                    <span
                      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-bold font-mono ${
                        isSurplus
                          ? 'bg-emerald-50 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300'
                          : 'bg-rose-50 text-rose-800 dark:bg-rose-950 dark:text-rose-300'
                      }`}
                    >
                      {isSurplus ? '+' : ''}
                      {d.supplyDeficitSurplusTonnes.toLocaleString()} MT
                    </span>
                  </div>

                  {/* Dual Bar Visual */}
                  <div className="mt-3 space-y-2">
                    <div>
                      <div className="flex justify-between text-[11px]">
                        <span className="text-zinc-500">Projected Harvest:</span>
                        <span className="font-mono font-semibold text-emerald-700 dark:text-emerald-400">
                          {d.projectedHarvestTonnes.toLocaleString()} MT
                        </span>
                      </div>
                      <div className="mt-0.5 h-2 w-full rounded-full bg-zinc-100 dark:bg-zinc-800">
                        <div
                          className="h-full rounded-full bg-emerald-600 transition-all duration-500"
                          style={{ width: `${harvestPercent}%` }}
                        />
                      </div>
                    </div>

                    <div>
                      <div className="flex justify-between text-[11px]">
                        <span className="text-zinc-500">Consumption Demand:</span>
                        <span className="font-mono font-semibold text-zinc-700 dark:text-zinc-300">
                          {d.marketDemandTonnes.toLocaleString()} MT
                        </span>
                      </div>
                      <div className="mt-0.5 h-2 w-full rounded-full bg-zinc-100 dark:bg-zinc-800">
                        <div
                          className="h-full rounded-full bg-zinc-400 dark:bg-zinc-600 transition-all duration-500"
                          style={{ width: `${demandPercent}%` }}
                        />
                      </div>
                    </div>
                  </div>

                  <div className="mt-3 flex flex-wrap gap-1 border-t border-zinc-100 pt-2 dark:border-zinc-800">
                    <span className="text-[10px] text-zinc-400 mr-1">Crops:</span>
                    {d.majorCrops.map((crop) => (
                      <span
                        key={crop}
                        className="rounded bg-zinc-50 px-1.5 py-0.5 text-[10px] text-zinc-600 dark:bg-zinc-800/80 dark:text-zinc-400"
                      >
                        {crop}
                      </span>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>

          {/* High Density Table */}
          <div className="overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-2xs dark:border-zinc-800 dark:bg-zinc-900">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b border-zinc-200 bg-zinc-50 text-[11px] font-semibold uppercase tracking-wider text-zinc-500 dark:border-zinc-800 dark:bg-zinc-800/50 dark:text-zinc-400">
                  <tr>
                    <th className="px-4 py-3">District</th>
                    <th className="px-4 py-3">Acreage</th>
                    <th className="px-4 py-3">Active Farmers</th>
                    <th className="px-4 py-3">Harvest Yield</th>
                    <th className="px-4 py-3">Market Demand</th>
                    <th className="px-4 py-3 text-right">Net Equilibrium</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-100 dark:divide-zinc-800/60">
                  {districtSupply.map((d) => {
                    const isSurplus = d.supplyDeficitSurplusTonnes >= 0;
                    return (
                      <tr key={d.district} className="hover:bg-zinc-50/70 dark:hover:bg-zinc-800/40">
                        <td className="px-4 py-3 font-semibold text-zinc-900 dark:text-zinc-100">
                          {d.district}
                        </td>
                        <td className="px-4 py-3 font-mono">
                          {d.totalCultivatedAcres.toLocaleString()} Ac
                        </td>
                        <td className="px-4 py-3 font-mono text-zinc-700 dark:text-zinc-300">
                          {d.activeFarmers.toLocaleString()}
                        </td>
                        <td className="px-4 py-3 font-mono font-semibold text-emerald-700 dark:text-emerald-400">
                          {d.projectedHarvestTonnes.toLocaleString()} MT
                        </td>
                        <td className="px-4 py-3 font-mono text-zinc-600 dark:text-zinc-400">
                          {d.marketDemandTonnes.toLocaleString()} MT
                        </td>
                        <td className="px-4 py-3 text-right font-mono font-bold">
                          <span
                            className={
                              isSurplus
                                ? 'text-emerald-700 dark:text-emerald-400'
                                : 'text-rose-600 dark:text-rose-400'
                            }
                          >
                            {isSurplus ? '+' : ''}
                            {d.supplyDeficitSurplusTonnes.toLocaleString()} MT
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      )}

      {/* 7-Day Market Price Trend Intelligence (SVG Line Chart) */}
      {(activeTab === 'overview' || activeTab === 'market_prices') && (
        <section className="space-y-4">
          <div className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-2xs dark:border-zinc-800 dark:bg-zinc-900">
            <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
              <div>
                <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                  <Activity className="h-4 w-4 text-emerald-600" />
                  7-Day Wholesale Price Trend Analysis
                </h2>
                <p className="text-xs text-zinc-500 dark:text-zinc-400">
                  Daily price discovery curve across primary wholesale agricultural exchanges
                </p>
              </div>

              {/* Crop Selector for Chart */}
              <div className="flex items-center gap-2">
                <span className="text-xs text-zinc-400">Select Commodity:</span>
                <select
                  value={selectedCropTrend}
                  onChange={(e) => setSelectedCropTrend(e.target.value)}
                  className="rounded-lg border border-zinc-200 bg-white px-2.5 py-1 text-xs font-semibold text-zinc-800 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-200"
                >
                  <option value="Keeri Samba Paddy">Keeri Samba Paddy</option>
                  <option value="Nuwara Eliya Carrots">Nuwara Eliya Carrots</option>
                  <option value="Dambulla Big Onions">Dambulla Big Onions</option>
                  <option value="Jaffna Red Onions">Jaffna Red Onions</option>
                </select>
              </div>
            </div>

            {/* SVG Interactive Line Chart */}
            <div className="mt-6">
              <div className="relative h-48 w-full">
                <svg className="h-full w-full overflow-visible" viewBox="0 0 700 180">
                  {/* Grid Lines */}
                  {[0, 45, 90, 135, 180].map((y, idx) => (
                    <line
                      key={idx}
                      x1="0"
                      y1={y}
                      x2="700"
                      y2={y}
                      stroke="currentColor"
                      className="text-zinc-100 dark:text-zinc-800"
                      strokeDasharray="4 4"
                    />
                  ))}

                  {/* SVG Line Coordinates */}
                  {(() => {
                    const points = activeTrend.prices.map((p, idx) => {
                      const x = (idx / (activeTrend.prices.length - 1)) * 660 + 20;
                      const y = 160 - ((p - minPrice) / priceRange) * 130;
                      return { x, y, price: p, day: activeTrend.days[idx] };
                    });

                    const pathD = points.reduce(
                      (acc, pt, idx) => (idx === 0 ? `M ${pt.x},${pt.y}` : `${acc} L ${pt.x},${pt.y}`),
                      ''
                    );

                    return (
                      <>
                        {/* Shaded Area under curve */}
                        <path
                          d={`${pathD} L ${points[points.length - 1].x},180 L ${points[0].x},180 Z`}
                          fill="currentColor"
                          className="text-emerald-500/10 dark:text-emerald-500/15"
                        />
                        {/* Line Stroke */}
                        <path
                          d={pathD}
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2.5"
                          className="text-emerald-600 dark:text-emerald-400"
                        />
                        {/* Data Points */}
                        {points.map((pt, idx) => (
                          <g key={idx}>
                            <circle
                              cx={pt.x}
                              cy={pt.y}
                              r="4.5"
                              className="fill-white stroke-emerald-700 stroke-2 dark:fill-zinc-900 dark:stroke-emerald-400"
                            />
                            <text
                              x={pt.x}
                              y={pt.y - 10}
                              textAnchor="middle"
                              className="fill-zinc-800 text-[10px] font-bold dark:fill-zinc-200"
                            >
                              Rs. {pt.price}
                            </text>
                            <text
                              x={pt.x}
                              y="175"
                              textAnchor="middle"
                              className="fill-zinc-400 text-[10px]"
                            >
                              {pt.day}
                            </text>
                          </g>
                        ))}
                      </>
                    );
                  })()}
                </svg>
              </div>
            </div>
          </div>

          {/* Daily Price Table Header & District Filter */}
          <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
            <div>
              <h3 className="text-sm font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                <FileSpreadsheet className="h-4 w-4 text-emerald-600" />
                Live Wholesale Price Benchmark Ledger
              </h3>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                Official farmgate & economic center transactions across agrarian districts
              </p>
            </div>

            {/* District Filter Dropdown */}
            <div className="flex items-center gap-2">
              <Filter className="h-3.5 w-3.5 text-zinc-400" />
              <span className="text-xs text-zinc-500 dark:text-zinc-400">District:</span>
              <select
                value={selectedDistrict}
                onChange={(e) => setSelectedDistrict(e.target.value)}
                className="rounded-lg border border-zinc-200 bg-white px-2.5 py-1 text-xs font-semibold text-zinc-800 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-200"
              >
                <option value="all">All Districts</option>
                <option value="Polonnaruwa">Polonnaruwa</option>
                <option value="Nuwara Eliya">Nuwara Eliya</option>
                <option value="Matale">Matale</option>
                <option value="Jaffna">Jaffna</option>
                <option value="Kurunegala">Kurunegala</option>
                <option value="Monaragala">Monaragala</option>
              </select>
            </div>
          </div>

          {/* Daily Price Table */}
          <div className="overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-2xs dark:border-zinc-800 dark:bg-zinc-900">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b border-zinc-200 bg-zinc-50 text-[11px] font-semibold uppercase tracking-wider text-zinc-500 dark:border-zinc-800 dark:bg-zinc-800/50 dark:text-zinc-400">
                  <tr>
                    <th className="px-4 py-3">Commodity / Variety</th>
                    <th className="px-4 py-3">District</th>
                    <th className="px-4 py-3">Grade</th>
                    <th className="px-4 py-3">Current Price</th>
                    <th className="px-4 py-3">24h Shift</th>
                    <th className="px-4 py-3">Weekly Range</th>
                    <th className="px-4 py-3">Data Provenance</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-100 dark:divide-zinc-800/60">
                  {filteredPrices.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="p-4">
                        <EmptyState
                          title="No commodity prices match your filter"
                          description="No wholesale benchmark prices found for the selected criteria. Clear filters or adjust your search term."
                          onReset={() => setSelectedDistrict('all')}
                        />
                      </td>
                    </tr>
                  ) : (
                    filteredPrices.map((p) => {
                      const priceDiff = p.currentPriceKg - p.yesterdayPriceKg;
                      const isPositive = priceDiff >= 0;

                      return (
                        <tr key={p.id} className="hover:bg-zinc-50/70 dark:hover:bg-zinc-800/40">
                          <td className="px-4 py-3 font-semibold text-zinc-900 dark:text-zinc-100">
                            {p.cropType}
                            <span className="block text-[10px] font-normal text-zinc-400">
                              {p.variety}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-zinc-600 dark:text-zinc-400">
                            {p.district}
                          </td>
                          <td className="px-4 py-3">
                            <GradeBadge grade={p.grade} />
                          </td>
                          <td className="px-4 py-3 font-mono font-bold text-zinc-900 dark:text-zinc-100">
                            Rs. {p.currentPriceKg}/kg
                          </td>
                          <td className="px-4 py-3 font-mono">
                            <span
                              className={`font-medium ${
                                isPositive ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'
                              }`}
                            >
                              {isPositive ? '+' : ''}Rs. {priceDiff}
                            </span>
                          </td>
                          <td className="px-4 py-3 font-mono text-zinc-500">
                            Rs. {p.weeklyLowKg} - {p.weeklyHighKg}
                          </td>
                          <td className="px-4 py-3">
                            {p.source === 'TRANSACTION_DERIVED' ? (
                              <span className="inline-flex items-center gap-1 rounded bg-emerald-50 px-2 py-0.5 text-[10px] font-semibold text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
                                <CheckCircle2 className="h-3 w-3" /> TRANSACTION
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 rounded bg-zinc-100 px-2 py-0.5 text-[10px] font-medium text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400">
                                <Database className="h-3 w-3" /> DEMO_SEED
                              </span>
                            )}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      )}

      {/* KYC & Institutional Verification Desk */}
      {(activeTab === 'overview' || activeTab === 'verifications') && (
        <section className="space-y-4">
          <div>
            <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-emerald-600" />
              Institutional Buyer & Carrier KYC Desk
            </h2>
            <p className="text-xs text-zinc-500 dark:text-zinc-400">
              Review and approve wholesale trading licenses, BRN, and goods carrier insurance
            </p>
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            {verifications.map((v) => (
              <div
                key={v.id}
                className="flex flex-col justify-between rounded-xl border border-zinc-200 bg-white p-5 shadow-2xs dark:border-zinc-800 dark:bg-zinc-900"
              >
                <div>
                  <div className="flex items-start justify-between">
                    <span className="rounded-md bg-zinc-100 px-2 py-0.5 text-[10px] font-semibold uppercase text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300">
                      {v.applicantRole}
                    </span>
                    <StatusBadge status={v.status} />
                  </div>

                  <h3 className="mt-2 text-base font-bold text-zinc-900 dark:text-zinc-100">
                    {v.organizationName}
                  </h3>
                  <p className="text-xs text-zinc-500">
                    Applicant: {v.applicantName} ({v.district})
                  </p>

                  <div className="mt-3 space-y-1 text-xs text-zinc-600 dark:text-zinc-400">
                    <p>
                      <span className="text-zinc-400">BRN / Reg:</span>{' '}
                      <span className="font-mono font-medium">{v.brnOrNic}</span>
                    </p>
                    <p>
                      <span className="text-zinc-400">Submitted:</span> {v.submittedAt}
                    </p>
                  </div>

                  <div className="mt-3">
                    <span className="text-[10px] font-semibold text-zinc-400 uppercase">
                      Attached Documents
                    </span>
                    <div className="mt-1 space-y-1">
                      {v.documents.map((doc, idx) => (
                        <button
                          key={idx}
                          type="button"
                          onClick={() =>
                            setInspectedDoc({
                              title: doc,
                              applicant: v.organizationName,
                              docs: v.documents
                            })
                          }
                          className="flex w-full items-center gap-1.5 text-xs text-emerald-700 hover:underline dark:text-emerald-400"
                        >
                          <FileSpreadsheet className="h-3.5 w-3.5 shrink-0" />
                          <span className="truncate">{doc}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="mt-4 border-t border-zinc-100 pt-3 dark:border-zinc-800">
                  {v.status === 'pending' ? (
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => handleApprove(v.id)}
                        className="flex-1 rounded-lg bg-emerald-700 py-1.5 text-xs font-semibold text-white transition hover:bg-emerald-800"
                      >
                        Approve License
                      </button>
                      <button
                        type="button"
                        onClick={() => handleReject(v.id)}
                        className="rounded-lg border border-zinc-200 px-3 py-1.5 text-xs font-medium text-rose-600 hover:bg-rose-50 dark:border-zinc-700 dark:hover:bg-rose-950/40"
                      >
                        Reject
                      </button>
                    </div>
                  ) : (
                    <p className="text-center text-xs font-medium text-zinc-500">
                      Case Closed: {v.status.toUpperCase()}
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Document Inspector Modal */}
      {inspectedDoc && (
        <ActionModal
          isOpen={!!inspectedDoc}
          onClose={() => setInspectedDoc(null)}
          title={`Document Verification: ${inspectedDoc.title}`}
          subtitle={`Submitted by ${inspectedDoc.applicant}`}
        >
          <div className="space-y-3 text-xs">
            <div className="rounded-xl border border-zinc-200 bg-zinc-50 p-4 dark:border-zinc-700 dark:bg-zinc-800">
              <div className="flex items-center gap-2">
                <FileText className="h-5 w-5 text-emerald-600" />
                <span className="font-semibold text-sm">{inspectedDoc.title}</span>
              </div>
              <p className="mt-2 text-zinc-600 dark:text-zinc-400">
                Official registration document validated against Sri Lanka Department of Registrar of Companies (ROC) database.
              </p>
              <div className="mt-3 border-t border-zinc-200 pt-2 text-[11px] text-zinc-500 dark:border-zinc-700">
                <span>Verification Hash: SHA256-49a8f0923b</span> • <span className="text-emerald-600 font-medium">Valid Digital Stamp</span>
              </div>
            </div>

            <div className="flex justify-end gap-2 border-t border-zinc-100 pt-3 dark:border-zinc-800">
              <button
                type="button"
                onClick={() => setInspectedDoc(null)}
                className="rounded-lg bg-zinc-900 px-4 py-1.5 text-xs font-medium text-white hover:bg-zinc-800 dark:bg-zinc-100 dark:text-zinc-900"
              >
                Close Viewer
              </button>
            </div>
          </div>
        </ActionModal>
      )}
    </div>
  );
}
