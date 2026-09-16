'use client';

import React, { useState } from 'react';
import {
  ShoppingBag,
  Gavel,
  Truck,
  CheckCircle2,
  Clock,
  MapPin,
  Filter,
  ArrowRight,
  ShieldCheck,
  Building2,
  Plus,
  Send,
  Boxes,
  FileSpreadsheet
} from 'lucide-react';
import { StatCard } from '../common/StatCard';
import { GradeBadge, StatusBadge, Badge } from '../common/Badge';
import { ActionModal } from '../common/ActionModal';
import { EmptyState } from '../common/EmptyState';
import {
  MOCK_PRODUCTIONS,
  MOCK_DEMANDS,
  MOCK_ORDERS
} from '@/lib/mockData';
import { ProductionListing, QualityGrade, DemandRequest } from '@/lib/types';

interface BuyerViewProps {
  activeTab: string;
  searchQuery: string;
}

export function BuyerView({ activeTab, searchQuery }: BuyerViewProps) {
  const [productions, setProductions] = useState<ProductionListing[]>(MOCK_PRODUCTIONS);
  const [demands, setDemands] = useState<DemandRequest[]>(MOCK_DEMANDS);
  const [selectedGrade, setSelectedGrade] = useState<string>('all');
  const [selectedDistrict, setSelectedDistrict] = useState<string>('all');
  const [bidInputs, setBidInputs] = useState<Record<string, number>>({});
  const [placedBids, setPlacedBids] = useState<Record<string, number>>({});
  const [successToast, setSuccessToast] = useState<string | null>(null);

  // Modals state
  const [isDemandModalOpen, setIsDemandModalOpen] = useState(false);
  const [demandCrop, setDemandCrop] = useState('Nuwara Eliya Carrots');
  const [demandQty, setDemandQty] = useState(5000);
  const [demandPrice, setDemandPrice] = useState(370);
  const [demandDeadline, setDemandDeadline] = useState('2026-10-10');
  const [demandNotes, setDemandNotes] = useState('Grade A washed crates needed for supermarket central distribution.');

  const [directPurchaseItem, setDirectPurchaseItem] = useState<ProductionListing | null>(null);

  const filteredMarketplace = productions.filter((p) => {
    const matchesSearch =
      p.cropType.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.variety.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.district.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.listingCode.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesGrade = selectedGrade === 'all' || p.qualityGrade === selectedGrade;
    const matchesDistrict = selectedDistrict === 'all' || p.district === selectedDistrict;

    return matchesSearch && matchesGrade && matchesDistrict;
  });

  const handleBidSubmit = (prodId: string, currentMin: number) => {
    const inputVal = bidInputs[prodId] || currentMin + 5;
    setPlacedBids((prev) => ({ ...prev, [prodId]: inputVal }));

    // Soft-close rule: extend auction by 2 minutes if placed in final 5 minutes
    setProductions((prev) =>
      prev.map((p) => {
        if (p.id === prodId && p.activeAuction) {
          const newEndsIn =
            p.activeAuction.endsInMinutes <= 5
              ? p.activeAuction.endsInMinutes + 2
              : p.activeAuction.endsInMinutes;

          return {
            ...p,
            activeAuction: {
              ...p.activeAuction,
              currentHighestBid: inputVal,
              bidCount: p.activeAuction.bidCount + 1,
              endsInMinutes: newEndsIn,
              highestBidderName: 'Keells Food Products (You)'
            }
          };
        }
        return p;
      })
    );

    setSuccessToast(`Bid of Rs. ${inputVal}/kg placed! Soft-close timer extended by +2m if near deadline.`);
    setTimeout(() => setSuccessToast(null), 5000);
  };

  const handleCreateDemand = (e: React.FormEvent) => {
    e.preventDefault();
    const newDem: DemandRequest = {
      id: `dem-${Date.now()}`,
      buyerName: 'Rohan Jayasuriya',
      buyerCompany: 'Keells Food Products PLC',
      cropType: demandCrop,
      quantityNeededKg: Number(demandQty),
      fulfilledKg: 0,
      targetPriceKg: Number(demandPrice),
      deadline: demandDeadline,
      district: 'Colombo Central Hub',
      status: 'open',
      notes: demandNotes
    };

    setDemands([newDem, ...demands]);
    setIsDemandModalOpen(false);
    setSuccessToast(`Forward sourcing demand for ${newDem.cropType} published to producer clusters!`);
    setTimeout(() => setSuccessToast(null), 5000);
  };

  const handleConfirmDirectPurchase = () => {
    if (!directPurchaseItem) return;
    const farmerName = directPurchaseItem.farmerName;
    setDirectPurchaseItem(null);
    setSuccessToast(`Direct contract inquiry for ${directPurchaseItem.cropType} sent to ${farmerName}!`);
    setTimeout(() => setSuccessToast(null), 5000);
  };

  return (
    <div className="space-y-6">
      {/* Clean Page Header */}
      <div className="flex flex-col justify-between gap-4 border-b border-zinc-200 pb-5 sm:flex-row sm:items-center dark:border-zinc-800">
        <div>
          <div className="flex items-center gap-2 text-xs text-zinc-500 dark:text-zinc-400">
            <span>AgriLink</span>
            <span>/</span>
            <span className="font-semibold text-emerald-700 dark:text-emerald-400">Wholesale Procurement</span>
            <span>•</span>
            <span>Keells Food Products PLC</span>
          </div>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50 sm:text-3xl">
            Live Produce Marketplace & Bidding
          </h1>
          <p className="mt-0.5 text-xs text-zinc-500 dark:text-zinc-400 sm:text-sm">
            Source graded agricultural batches directly from farmgate clusters with soft-close auction bidding.
          </p>
        </div>

        <div className="flex shrink-0 items-center gap-2.5">
          <button
            type="button"
            onClick={() => setIsDemandModalOpen(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-emerald-700 px-4 py-2 text-xs font-semibold text-white shadow-xs transition hover:bg-emerald-800"
          >
            <Plus className="h-4 w-4" />
            <span>Post Sourcing Demand</span>
          </button>
        </div>
      </div>

      {successToast && (
        <div className="flex items-center justify-between rounded-xl bg-emerald-50 border border-emerald-200 p-4 text-xs font-semibold text-emerald-900 dark:bg-emerald-950/60 dark:border-emerald-800 dark:text-emerald-200">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
            <span>{successToast}</span>
          </div>
          <button
            type="button"
            onClick={() => setSuccessToast(null)}
            className="text-emerald-700 dark:text-emerald-400 hover:underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Metrics Row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Active Live Bids"
          value={`${Object.keys(placedBids).length > 0 ? Object.keys(placedBids).length : 4} Batches`}
          subtitle="2 closing within 45 mins"
          icon={Gavel}
        />
        <StatCard
          title="In-Transit Cargo"
          value="6,300 kg"
          subtitle="2 consignments on road"
          icon={Truck}
        />
        <StatCard
          title="Monthly Procurement"
          value="Rs. 4.82M"
          change={{
            value: '-18.5%',
            isPositive: true,
            label: 'logistics savings'
          }}
          icon={ShoppingBag}
        />
        <StatCard
          title="Fulfillment Accuracy"
          value="98.6%"
          badge="Verified Buyer"
          subtitle="Inspection pass rate"
          icon={ShieldCheck}
        />
      </div>

      {/* Marketplace Section */}
      {(activeTab === 'overview' || activeTab === 'marketplace') && (
        <section className="space-y-4">
          <div className="flex flex-col justify-between gap-3 md:flex-row md:items-center">
            <div>
              <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                <ShoppingBag className="h-4 w-4 text-emerald-600" />
                Live Farm Batches & Transparent Auctions
              </h2>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                Bid directly on verified harvest listings with guaranteed delivery schedules
              </p>
            </div>

            {/* Filter Controls */}
            <div className="flex flex-wrap items-center gap-2">
              <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
                {['all', 'A', 'B'].map((g) => (
                  <button
                    key={g}
                    type="button"
                    onClick={() => setSelectedGrade(g)}
                    className={`rounded-lg px-2.5 py-1 text-xs font-medium transition ${
                      selectedGrade === g
                        ? 'bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900'
                        : 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-400'
                    }`}
                  >
                    {g === 'all' ? 'All Grades' : `Grade ${g}`}
                  </button>
                ))}
              </div>

              <div className="flex items-center gap-1 border-l border-zinc-200 pl-2 dark:border-zinc-800">
                <span className="text-xs text-zinc-400">District:</span>
                <select
                  value={selectedDistrict}
                  onChange={(e) => setSelectedDistrict(e.target.value)}
                  className="rounded-lg border border-zinc-200 bg-white px-2.5 py-1 text-xs text-zinc-800 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-200"
                >
                  <option value="all">All Districts</option>
                  <option value="Anuradhapura">Anuradhapura</option>
                  <option value="Nuwara Eliya">Nuwara Eliya</option>
                  <option value="Matale">Matale</option>
                  <option value="Jaffna">Jaffna</option>
                  <option value="Badulla">Badulla</option>
                </select>
              </div>
            </div>
          </div>

          {filteredMarketplace.length === 0 ? (
            <EmptyState
              title="No produce batches found"
              description="No batches match your selected grade and district filters."
              onReset={() => {
                setSelectedGrade('all');
                setSelectedDistrict('all');
              }}
            />
          ) : (
            <div className="grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3">
              {filteredMarketplace.map((item) => {
                const auc = item.activeAuction;
                const currentBid = placedBids[item.id] || (auc ? auc.currentHighestBid : item.minAcceptablePriceKg);
                const isMyBid = !!placedBids[item.id];

                return (
                  <div
                    key={item.id}
                    className="flex flex-col justify-between rounded-xl border border-zinc-200 bg-white p-5 shadow-xs transition hover:border-zinc-300 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-zinc-700"
                  >
                    <div>
                      <div className="flex items-start justify-between">
                        <GradeBadge grade={item.qualityGrade} />
                        <div className="flex items-center gap-1 text-[11px] text-zinc-500">
                          <MapPin className="h-3 w-3 text-zinc-400" />
                          <span>{item.district}</span>
                        </div>
                      </div>

                      <h3 className="mt-2.5 text-base font-bold text-zinc-900 dark:text-zinc-100">
                        {item.cropType}
                      </h3>
                      <p className="text-xs text-zinc-500 dark:text-zinc-400">{item.variety}</p>

                      <p className="mt-2 line-clamp-2 text-xs leading-relaxed text-zinc-600 dark:text-zinc-400">
                        {item.description}
                      </p>

                      <div className="mt-4 grid grid-cols-2 gap-2 rounded-lg bg-zinc-50 p-2.5 text-xs dark:bg-zinc-800/40">
                        <div>
                          <span className="text-[10px] text-zinc-400 uppercase">Quantity</span>
                          <p className="font-mono font-bold text-zinc-800 dark:text-zinc-200">
                            {item.quantityKg.toLocaleString()} kg
                          </p>
                        </div>
                        <div>
                          <span className="text-[10px] text-zinc-400 uppercase">Harvest Date</span>
                          <p className="font-medium text-zinc-700 dark:text-zinc-300">
                            {item.harvestDate}
                          </p>
                        </div>
                      </div>

                      <div className="mt-3 flex items-baseline justify-between">
                        <span className="text-xs text-zinc-500">Current Lead Price:</span>
                        <span className="font-mono text-base font-bold text-emerald-700 dark:text-emerald-400">
                          Rs. {currentBid}/kg
                        </span>
                      </div>

                      {auc && (
                        <div className="mt-1 space-y-1">
                          <div className="flex items-center justify-between text-[11px] text-amber-600 dark:text-amber-400">
                            <span className="flex items-center gap-1">
                              <Clock className="h-3 w-3" /> Closes in {auc.endsInMinutes}m
                            </span>
                            <span>{auc.bidCount} bids placed</span>
                          </div>
                          <p className="text-[10px] text-zinc-400">
                            ⏱️ Soft-close enabled: late bids under 5m extend clock by +2m
                          </p>
                        </div>
                      )}
                    </div>

                    <div className="mt-5 border-t border-zinc-100 pt-3 dark:border-zinc-800">
                      {auc ? (
                        <div className="space-y-2">
                          <div className="flex items-center gap-2">
                            <input
                              type="number"
                              defaultValue={currentBid + 5}
                              onChange={(e) =>
                                setBidInputs({ ...bidInputs, [item.id]: Number(e.target.value) })
                              }
                              className="w-24 rounded-lg border border-zinc-200 px-2.5 py-1.5 text-xs font-semibold dark:border-zinc-700 dark:bg-zinc-800"
                            />
                            <button
                              type="button"
                              onClick={() => handleBidSubmit(item.id, currentBid)}
                              className="flex-1 rounded-lg bg-zinc-900 py-1.5 text-xs font-semibold text-white transition hover:bg-zinc-800 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
                            >
                              {isMyBid ? 'Increase Bid' : 'Place Bid'}
                            </button>
                          </div>
                          {isMyBid && (
                            <p className="text-center text-[10px] text-emerald-600 font-medium">
                              ✓ Your bid of Rs. {placedBids[item.id]}/kg is active
                            </p>
                          )}
                        </div>
                      ) : (
                        <button
                          type="button"
                          onClick={() => setDirectPurchaseItem(item)}
                          className="w-full rounded-lg bg-emerald-700 py-2 text-xs font-semibold text-white transition hover:bg-emerald-800"
                        >
                          Send Purchase Interest
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>
      )}

      {/* Demands Tab */}
      {(activeTab === 'overview' || activeTab === 'demands') && (
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                <FileSpreadsheet className="h-4 w-4 text-emerald-600" />
                Active Procurement Demands (Forward Contracts)
              </h2>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                Published sourcing requirements broadcasted to farmer clusters
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            {demands.map((demand) => {
              const progress = Math.round((demand.fulfilledKg / demand.quantityNeededKg) * 100);

              return (
                <div
                  key={demand.id}
                  className="rounded-xl border border-zinc-200 bg-white p-5 shadow-xs dark:border-zinc-800 dark:bg-zinc-900"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="text-base font-bold text-zinc-900 dark:text-zinc-100">
                        {demand.cropType}
                      </h3>
                      <p className="text-xs text-zinc-500">
                        Target Price: Rs. {demand.targetPriceKg}/kg | Deadline: {demand.deadline}
                      </p>
                    </div>
                    <StatusBadge status={demand.status} />
                  </div>

                  <p className="mt-2 text-xs text-zinc-600 dark:text-zinc-400">
                    {demand.notes}
                  </p>

                  <div className="mt-4 space-y-1.5">
                    <div className="flex justify-between text-xs font-medium">
                      <span className="text-zinc-500">Fulfillment Progress:</span>
                      <span className="font-mono text-zinc-800 dark:text-zinc-200">
                        {demand.fulfilledKg.toLocaleString()} / {demand.quantityNeededKg.toLocaleString()} kg ({progress}%)
                      </span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-zinc-100 dark:bg-zinc-800">
                      <div
                        className="h-full bg-emerald-600 transition-all duration-300"
                        style={{ width: `${progress}%` }}
                      />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      )}

      {/* Orders & Tracking Tab */}
      {(activeTab === 'overview' || activeTab === 'orders') && (
        <section className="space-y-4">
          <div>
            <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <Boxes className="h-4 w-4 text-emerald-600" />
              Procurement Orders & Cold-Chain Tracking
            </h2>
            <p className="text-xs text-zinc-500 dark:text-zinc-400">
              Live waybill status from farmgate loading to distribution center delivery
            </p>
          </div>

          <div className="overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-xs dark:border-zinc-800 dark:bg-zinc-900">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b border-zinc-200 bg-zinc-50 text-[11px] font-semibold text-zinc-500 uppercase tracking-wider dark:border-zinc-800 dark:bg-zinc-800/50 dark:text-zinc-400">
                  <tr>
                    <th className="px-4 py-3">Order Code</th>
                    <th className="px-4 py-3">Produce Item</th>
                    <th className="px-4 py-3">Farmer Source</th>
                    <th className="px-4 py-3">Quantity</th>
                    <th className="px-4 py-3">Amount</th>
                    <th className="px-4 py-3">Payment</th>
                    <th className="px-4 py-3">Waybill Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-100 dark:divide-zinc-800/60">
                  {MOCK_ORDERS.map((ord) => (
                    <tr
                      key={ord.id}
                      className="transition-colors hover:bg-zinc-50/70 dark:hover:bg-zinc-800/40"
                    >
                      <td className="px-4 py-3 font-mono font-medium text-zinc-600 dark:text-zinc-400">
                        {ord.orderCode}
                      </td>
                      <td className="px-4 py-3 font-semibold text-zinc-900 dark:text-zinc-100">
                        {ord.cropType}
                      </td>
                      <td className="px-4 py-3 text-zinc-600 dark:text-zinc-400">
                        {ord.farmerName}
                      </td>
                      <td className="px-4 py-3 font-mono text-zinc-800 dark:text-zinc-200">
                        {ord.quantityKg.toLocaleString()} kg
                      </td>
                      <td className="px-4 py-3 font-mono font-semibold text-zinc-900 dark:text-zinc-100">
                        Rs. {ord.totalAmount.toLocaleString()}
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge status={ord.paymentStatus} />
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge status={ord.orderStatus} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      )}

      {/* Post Sourcing Demand Modal */}
      <ActionModal
        isOpen={isDemandModalOpen}
        onClose={() => setIsDemandModalOpen(false)}
        title="Post Forward Sourcing Demand"
        subtitle="Broadcast your wholesale crop requirement to registered producer unions"
      >
        <form onSubmit={handleCreateDemand} className="space-y-4">
          <div>
            <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
              Crop Required
            </label>
            <input
              type="text"
              required
              value={demandCrop}
              onChange={(e) => setDemandCrop(e.target.value)}
              className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Quantity Needed (kg)
              </label>
              <input
                type="number"
                required
                value={demandQty}
                onChange={(e) => setDemandQty(Number(e.target.value))}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Target Price (Rs./kg)
              </label>
              <input
                type="number"
                required
                value={demandPrice}
                onChange={(e) => setDemandPrice(Number(e.target.value))}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
              Delivery Deadline
            </label>
            <input
              type="date"
              required
              value={demandDeadline}
              onChange={(e) => setDemandDeadline(e.target.value)}
              className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
            />
          </div>

          <div>
            <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
              Specifications & Quality Notes
            </label>
            <textarea
              rows={3}
              value={demandNotes}
              onChange={(e) => setDemandNotes(e.target.value)}
              className="mt-1 w-full rounded-lg border border-zinc-200 p-2.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
            />
          </div>

          <div className="mt-5 flex justify-end gap-2 border-t border-zinc-100 pt-3 dark:border-zinc-800">
            <button
              type="button"
              onClick={() => setIsDemandModalOpen(false)}
              className="rounded-lg border border-zinc-200 px-4 py-2 text-xs font-medium text-zinc-600 hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-emerald-700 px-4 py-2 text-xs font-semibold text-white hover:bg-emerald-800"
            >
              Publish Demand
            </button>
          </div>
        </form>
      </ActionModal>

      {/* Direct Purchase Interest Modal */}
      {directPurchaseItem && (
        <ActionModal
          isOpen={!!directPurchaseItem}
          onClose={() => setDirectPurchaseItem(null)}
          title={`Send Purchase Request: ${directPurchaseItem.cropType}`}
          subtitle={`Farmer: ${directPurchaseItem.farmerName} (${directPurchaseItem.district})`}
        >
          <div className="space-y-3 text-xs">
            <p className="text-zinc-600 dark:text-zinc-400">
              You are sending a direct contract inquiry to purchase this {directPurchaseItem.quantityKg.toLocaleString()} kg batch at the reserve price of Rs. {directPurchaseItem.minAcceptablePriceKg}/kg.
            </p>
            <div className="rounded-lg bg-zinc-50 p-3 dark:bg-zinc-800">
              <div className="flex justify-between">
                <span>Batch Code:</span>
                <span className="font-mono font-semibold">{directPurchaseItem.listingCode}</span>
              </div>
              <div className="flex justify-between mt-1">
                <span>Estimated Batch Total:</span>
                <span className="font-mono font-bold text-emerald-700 dark:text-emerald-400">
                  Rs. {directPurchaseItem.projectedRevenue.toLocaleString()}
                </span>
              </div>
            </div>

            <div className="mt-4 flex justify-end gap-2 border-t border-zinc-100 pt-3 dark:border-zinc-800">
              <button
                type="button"
                onClick={() => setDirectPurchaseItem(null)}
                className="rounded-lg border border-zinc-200 px-3 py-1.5 font-medium text-zinc-600 dark:border-zinc-700 dark:text-zinc-300"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmDirectPurchase}
                className="rounded-lg bg-emerald-700 px-4 py-1.5 font-semibold text-white hover:bg-emerald-800"
              >
                Confirm & Dispatch Request
              </button>
            </div>
          </div>
        </ActionModal>
      )}
    </div>
  );
}
