'use client';

import React, { useState } from 'react';
import {
  Truck,
  MapPin,
  Clock,
  Compass,
  CheckCircle2,
  AlertTriangle,
  ArrowRight,
  ShieldCheck,
  Fuel,
  KeyRound,
  FileCheck2,
  DollarSign,
  Plus,
  Users
} from 'lucide-react';
import { StatCard } from '../common/StatCard';
import { StatusBadge, Badge } from '../common/Badge';
import { ActionModal } from '../common/ActionModal';
import { EmptyState } from '../common/EmptyState';
import { TransportJob, TransportStatus, Vehicle, VehicleType } from '@/lib/types';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getTransporterDataAction,
  updateTransportStatusAction,
  createVehicleAction,
} from '@/app/actions/transporterActions';

interface TransporterViewProps {
  activeTab: string;
  searchQuery: string;
}

const STATUS_STEPS: TransportStatus[] = [
  'assigned',
  'arrived_at_pickup',
  'loaded',
  'in_transit',
  'delivered',
  'buyer_confirmed'
];

export function TransporterView({ activeTab, searchQuery }: TransporterViewProps) {
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['transporterData'],
    queryFn: () => getTransporterDataAction(),
  });

  const jobs = data?.jobs || [];
  const fleet = data?.fleet || [];

  const [recentAcceptanceMsg, setRecentAcceptanceMsg] = useState<string | null>(null);

  // New Vehicle Modal State
  const [isNewVehicleModalOpen, setIsNewVehicleModalOpen] = useState(false);
  const [newPlate, setNewPlate] = useState('WP-LD-7732');
  const [newType, setNewType] = useState<VehicleType>('small_lorry');
  const [newCapacity, setNewCapacity] = useState(3000);
  const [newDriver, setNewDriver] = useState('Ananda Kumara');

  const updateStatusMutation = useMutation({
    mutationFn: ({
      jobId,
      status,
      driverName,
      vehicleNumber,
    }: {
      jobId: string;
      status: TransportStatus;
      driverName?: string;
      vehicleNumber?: string;
    }) => updateTransportStatusAction(jobId, status, driverName, vehicleNumber),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['transporterData'] });
    },
  });

  const createVehicleMutation = useMutation({
    mutationFn: createVehicleAction,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['transporterData'] });
      setIsNewVehicleModalOpen(false);
    },
  });

  const filteredJobs = jobs.filter((j) => {
    return (
      j.requestCode.toLowerCase().includes(searchQuery.toLowerCase()) ||
      j.product.toLowerCase().includes(searchQuery.toLowerCase()) ||
      j.pickupDistrict.toLowerCase().includes(searchQuery.toLowerCase()) ||
      j.deliveryDistrict.toLowerCase().includes(searchQuery.toLowerCase()) ||
      j.farmerName.toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  const activeFleetCount = fleet.filter((v) => v.status !== 'maintenance').length;
  const deploymentRatio = fleet.length > 0 ? Math.round((activeFleetCount / fleet.length) * 100) : 100;

  const handleAcceptJob = (jobId: string) => {
    const assignedVeh = fleet.find((v) => v.status === 'active') || fleet[0];
    const driver = assignedVeh?.currentDriver || 'Carrier Driver';
    const plate = assignedVeh?.vehicleNumber || 'WP-LC-4421';

    updateStatusMutation.mutate({
      jobId,
      status: 'assigned',
      driverName: driver,
      vehicleNumber: plate,
    });
    setRecentAcceptanceMsg(`Freight Job Accepted! Assigned to Vehicle ${plate} and Driver ${driver}.`);
    setTimeout(() => setRecentAcceptanceMsg(null), 6000);
  };

  const handleAdvanceStatus = (jobId: string) => {
    const j = jobs.find((x) => x.id === jobId);
    if (!j) return;
    const currentIndex = STATUS_STEPS.indexOf(j.status);
    if (currentIndex < STATUS_STEPS.length - 1) {
      const nextStatus = STATUS_STEPS[currentIndex + 1];
      updateStatusMutation.mutate({ jobId, status: nextStatus });
    }
  };

  const handleCreateVehicle = async (e: React.FormEvent) => {
    e.preventDefault();
    await createVehicleMutation.mutateAsync({
      vehicleNumber: newPlate,
      vehicleType: newType,
      capacityKg: Number(newCapacity),
    });
  };

  return (
    <div className="space-y-6">
      {/* Clean Page Header */}
      <div className="flex flex-col justify-between gap-4 border-b border-zinc-200 pb-5 sm:flex-row sm:items-center dark:border-zinc-800">
        <div>
          <div className="flex items-center gap-2 text-xs text-zinc-500 dark:text-zinc-400">
            <span>AgriLink</span>
            <span>/</span>
            <span className="font-semibold text-emerald-700 dark:text-emerald-400">Logistics & Fleet</span>
            <span>•</span>
            <span>Carrier Freight Desk</span>
          </div>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50 sm:text-3xl">
            Agricultural Transport Dispatch
          </h1>
          <p className="mt-0.5 text-xs text-zinc-500 dark:text-zinc-400 sm:text-sm">
            Coordinate farmgate collections, track live highway waybills, and execute cold-chain delivery proofs.
          </p>
        </div>

        <div className="flex shrink-0 items-center gap-2.5">
          <button
            type="button"
            onClick={() => setIsNewVehicleModalOpen(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-emerald-700 px-4 py-2 text-xs font-semibold text-white shadow-xs transition hover:bg-emerald-800"
          >
            <Plus className="h-4 w-4" />
            <span>Register Vehicle</span>
          </button>
        </div>
      </div>

      {recentAcceptanceMsg && (
        <div className="flex items-center justify-between rounded-xl bg-emerald-50 border border-emerald-200 p-4 text-xs font-semibold text-emerald-900 dark:bg-emerald-950/60 dark:border-emerald-800 dark:text-emerald-200">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
            <span>{recentAcceptanceMsg}</span>
          </div>
          <button
            type="button"
            onClick={() => setRecentAcceptanceMsg(null)}
            className="text-emerald-700 dark:text-emerald-400 hover:underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Metrics Row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Active On-Road Trips"
          value={jobs.filter((j) => j.status === 'in_transit' || j.status === 'assigned').length.toString()}
          subtitle="Real-time GPS tracking"
          icon={Truck}
        />
        <StatCard
          title="Available Cargo Jobs"
          value={jobs.filter((j) => j.status === 'requested').length.toString()}
          subtitle="Ready for fleet allocation"
          icon={Compass}
        />
        <StatCard
          title="Active Fleet Utilization"
          value={`${activeFleetCount} / ${fleet.length} Units`}
          badge={`${deploymentRatio}% Deployed`}
          subtitle="Lorries and pickups in service"
          icon={Fuel}
        />
        <StatCard
          title="Freight Revenue (Month)"
          value="Rs. 206.9K"
          change={{
            value: '+12.5%',
            isPositive: true,
            label: 'route efficiency gain'
          }}
          icon={DollarSign}
        />
      </div>

      {/* Active Trips with Stepper */}
      {(activeTab === 'overview' || activeTab === 'active_trips') && (
        <section className="space-y-4">
          <div>
            <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <Truck className="h-4 w-4 text-emerald-600" />
              Active Trips & Live Waybill Progression
            </h2>
            <p className="text-xs text-zinc-500 dark:text-zinc-400">
              Simulate dispatch milestones from farmgate pickup to buyer handoff
            </p>
          </div>

          {filteredJobs.filter((j) => j.status !== 'requested').length === 0 ? (
            <EmptyState
              title="No active trips found"
              description="No active consignments match your current search query."
            />
          ) : (
            <div className="space-y-4">
              {filteredJobs
                .filter((j) => j.status !== 'requested')
                .map((job) => {
                  const currentStepIndex = STATUS_STEPS.indexOf(job.status);
                  const isCompleted = job.status === 'buyer_confirmed' || job.status === 'delivered';

                  return (
                    <div
                      key={job.id}
                      className="rounded-xl border border-zinc-200 bg-white p-5 shadow-xs transition hover:border-zinc-300 dark:border-zinc-800 dark:bg-zinc-900"
                    >
                      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-xs font-semibold text-zinc-500">
                              {job.requestCode}
                            </span>
                            <StatusBadge status={job.status} />
                          </div>
                          <h3 className="mt-1 text-base font-bold text-zinc-900 dark:text-zinc-100">
                            {job.product}
                          </h3>
                          <p className="text-xs text-zinc-500">
                            Vehicle: <span className="font-mono font-medium text-zinc-700 dark:text-zinc-300">{job.vehicleNumber}</span> | Driver: {job.driverName}
                          </p>
                        </div>

                        <div className="flex items-center gap-4 text-left sm:text-right">
                          <div>
                            <span className="text-[10px] text-zinc-400 uppercase">Trip Payout</span>
                            <p className="font-mono text-base font-bold text-emerald-700 dark:text-emerald-400">
                              Rs. {job.estimatedEarnings.toLocaleString()}
                            </p>
                          </div>
                          {job.otpCode && (
                            <div className="rounded-lg bg-zinc-100 px-3 py-1.5 text-center dark:bg-zinc-800">
                              <span className="text-[10px] text-zinc-400 uppercase flex items-center justify-center gap-1">
                                <KeyRound className="h-3 w-3" /> Delivery OTP
                              </span>
                              <span className="font-mono text-xs font-bold tracking-wider text-zinc-900 dark:text-zinc-100">
                                {job.otpCode}
                              </span>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Route Details Bar */}
                      <div className="mt-4 grid grid-cols-1 gap-2 rounded-lg border border-zinc-100 bg-zinc-50 p-3 text-xs sm:grid-cols-2 dark:border-zinc-800 dark:bg-zinc-800/40">
                        <div>
                          <span className="text-[10px] font-semibold text-zinc-400 uppercase">
                            📍 Origin (Farm Gate)
                          </span>
                          <p className="font-medium text-zinc-900 dark:text-zinc-100">
                            {job.pickupAddress}
                          </p>
                          <p className="text-[11px] text-zinc-500">
                            Farmer: {job.farmerName} ({job.farmerPhone})
                          </p>
                        </div>
                        <div>
                          <span className="text-[10px] font-semibold text-zinc-400 uppercase">
                            🏁 Destination (Wholesale Buyer)
                          </span>
                          <p className="font-medium text-zinc-900 dark:text-zinc-100">
                            {job.deliveryAddress}
                          </p>
                          <p className="text-[11px] text-zinc-500">Buyer: {job.buyerName}</p>
                        </div>
                      </div>

                      {/* Progress Stepper */}
                      <div className="mt-5">
                        <div className="grid grid-cols-6 gap-1 text-center">
                          {STATUS_STEPS.map((step, idx) => {
                            const isDone = idx <= currentStepIndex;
                            const isCurrent = idx === currentStepIndex;

                            return (
                              <div key={step} className="space-y-1">
                                <div
                                  className={`h-2 w-full rounded-full transition-colors ${
                                    isDone
                                      ? 'bg-emerald-600'
                                      : 'bg-zinc-200 dark:bg-zinc-800'
                                  }`}
                                />
                                <p
                                  className={`text-[10px] font-medium capitalize truncate ${
                                    isCurrent
                                      ? 'font-bold text-emerald-700 dark:text-emerald-400'
                                      : isDone
                                      ? 'text-zinc-700 dark:text-zinc-300'
                                      : 'text-zinc-400'
                                  }`}
                                >
                                  {step.replace(/_/g, ' ')}
                                </p>
                              </div>
                            );
                          })}
                        </div>
                      </div>

                      {/* Status Action Button */}
                      <div className="mt-4 flex items-center justify-between border-t border-zinc-100 pt-3 dark:border-zinc-800">
                        <span className="text-xs text-zinc-400">Updated: {job.updatedAt}</span>
                        {!isCompleted ? (
                          <button
                            type="button"
                            onClick={() => handleAdvanceStatus(job.id)}
                            className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-700 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-emerald-800"
                          >
                            <span>Advance to Next Milestone</span>
                            <ArrowRight className="h-3.5 w-3.5" />
                          </button>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600">
                            <CheckCircle2 className="h-4 w-4" /> Trip Successfully Completed
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
            </div>
          )}
        </section>
      )}

      {/* Available Freight Jobs Marketplace */}
      {(activeTab === 'overview' || activeTab === 'available_jobs') && (
        <section className="space-y-4">
          <div>
            <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <Compass className="h-4 w-4 text-emerald-600" />
              Open Farm Cargo Requests (Freight Marketplace)
            </h2>
            <p className="text-xs text-zinc-500 dark:text-zinc-400">
              Direct transport orders posted by farmers and buyers awaiting vehicle allocation
            </p>
          </div>

          {filteredJobs.filter((j) => j.status === 'requested').length === 0 ? (
            <EmptyState
              title="No open freight requests"
              description="All farmgate collection orders are currently allocated to carriers."
            />
          ) : (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              {filteredJobs
                .filter((j) => j.status === 'requested')
                .map((job) => (
                  <div
                    key={job.id}
                    className="rounded-xl border border-zinc-200 bg-white p-5 shadow-xs dark:border-zinc-800 dark:bg-zinc-900"
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <span className="font-mono text-xs font-semibold text-zinc-500">
                          {job.requestCode}
                        </span>
                        <h3 className="mt-1 text-base font-bold text-zinc-900 dark:text-zinc-100">
                          {job.product}
                        </h3>
                      </div>
                      <Badge variant="warning">Open for Bid</Badge>
                    </div>

                    <div className="mt-4 space-y-2 text-xs">
                      <div className="flex justify-between">
                        <span className="text-zinc-400">Pickup:</span>
                        <span className="font-medium text-zinc-800 dark:text-zinc-200">
                          {job.pickupAddress}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-zinc-400">Delivery:</span>
                        <span className="font-medium text-zinc-800 dark:text-zinc-200">
                          {job.deliveryAddress}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-zinc-400">Distance & Vehicle:</span>
                        <span>
                          {job.distanceKm} km ({job.requiredVehicle.replace('_', ' ')})
                        </span>
                      </div>
                      <div className="flex items-baseline justify-between border-t border-zinc-100 pt-2 text-sm font-semibold dark:border-zinc-800">
                        <span>Offered Carrier Fee:</span>
                        <span className="font-mono text-emerald-700 dark:text-emerald-400">
                          Rs. {job.estimatedEarnings.toLocaleString()}
                        </span>
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => handleAcceptJob(job.id)}
                      className="mt-4 w-full rounded-lg bg-zinc-900 py-2 text-xs font-semibold text-white transition hover:bg-zinc-800 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
                    >
                      Accept Freight Job
                    </button>
                  </div>
                ))}
            </div>
          )}
        </section>
      )}

      {/* Fleet Management Tab */}
      {(activeTab === 'overview' || activeTab === 'fleet') && (
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                <Users className="h-4 w-4 text-emerald-600" />
                Registered Commercial Fleet
              </h2>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                Vehicles certified for agricultural and cold-chain produce carriage
              </p>
            </div>
          </div>

          <div className="overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-xs dark:border-zinc-800 dark:bg-zinc-900">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-zinc-200 bg-zinc-50 text-[11px] font-semibold text-zinc-500 uppercase tracking-wider dark:border-zinc-800 dark:bg-zinc-800/50 dark:text-zinc-400">
                <tr>
                  <th className="px-4 py-3">Vehicle Number</th>
                  <th className="px-4 py-3">Classification</th>
                  <th className="px-4 py-3">Capacity</th>
                  <th className="px-4 py-3">Current Driver</th>
                  <th className="px-4 py-3">Efficiency</th>
                  <th className="px-4 py-3">Deployment Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-100 dark:divide-zinc-800/60">
                {fleet.map((veh) => (
                  <tr key={veh.id} className="hover:bg-zinc-50/70 dark:hover:bg-zinc-800/40">
                    <td className="px-4 py-3 font-mono font-bold text-zinc-900 dark:text-zinc-100">
                      {veh.vehicleNumber}
                    </td>
                    <td className="px-4 py-3 capitalize">
                      {veh.vehicleType.replace('_', ' ')}
                    </td>
                    <td className="px-4 py-3 font-mono">
                      {veh.capacityKg.toLocaleString()} kg
                    </td>
                    <td className="px-4 py-3 text-zinc-700 dark:text-zinc-300">
                      {veh.currentDriver}
                    </td>
                    <td className="px-4 py-3 font-mono text-zinc-500">
                      {veh.fuelEfficiencyKmPerL} km/L
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={veh.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {/* Register Vehicle Modal */}
      <ActionModal
        isOpen={isNewVehicleModalOpen}
        onClose={() => setIsNewVehicleModalOpen(false)}
        title="Register Commercial Freight Vehicle"
        subtitle="Add a lorry or pickup to your AgriLink logistics fleet"
      >
        <form onSubmit={handleCreateVehicle} className="space-y-4">
          <div>
            <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
              Vehicle Plate Number
            </label>
            <input
              type="text"
              required
              value={newPlate}
              onChange={(e) => setNewPlate(e.target.value)}
              className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs font-mono dark:border-zinc-700 dark:bg-zinc-800"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Vehicle Type
              </label>
              <select
                value={newType}
                onChange={(e) => setNewType(e.target.value as VehicleType)}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-2.5 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              >
                <option value="pickup">Pickup (1.5T)</option>
                <option value="small_lorry">Small Lorry (2.5T - 3.5T)</option>
                <option value="medium_lorry">Medium Lorry (5T - 7T)</option>
                <option value="large_lorry">Large Lorry (10T+)</option>
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Payload Capacity (kg)
              </label>
              <input
                type="number"
                required
                value={newCapacity}
                onChange={(e) => setNewCapacity(Number(e.target.value))}
                className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
              Assigned Driver Name
            </label>
            <input
              type="text"
              required
              value={newDriver}
              onChange={(e) => setNewDriver(e.target.value)}
              className="mt-1 w-full rounded-lg border border-zinc-200 px-3 py-1.5 text-xs dark:border-zinc-700 dark:bg-zinc-800"
            />
          </div>

          <div className="mt-5 flex justify-end gap-2 border-t border-zinc-100 pt-3 dark:border-zinc-800">
            <button
              type="button"
              onClick={() => setIsNewVehicleModalOpen(false)}
              className="rounded-lg border border-zinc-200 px-4 py-2 text-xs font-medium text-zinc-600 hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-emerald-700 px-4 py-2 text-xs font-semibold text-white hover:bg-emerald-800"
            >
              Confirm Registration
            </button>
          </div>
        </form>
      </ActionModal>
    </div>
  );
}
