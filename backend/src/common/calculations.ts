/**
 * Bit App research-grade financial calculations.
 *
 * All functions treat missing/zero denominators as null — never fabricate %.
 * Currency is LKR; prices are per kg unless noted.
 *
 * Gross Revenue = winningBidPricePerKg × quantityKg
 * Net Farmer Income = Gross Revenue − transport − harvest − platform − other
 * Income Improvement = bitAppNet − traditionalNet
 * Income Improvement % = (improvement / traditionalNet) × 100  (null if traditionalNet ≤ 0)
 *
 * Intermediary Dependency Index (IDI)
 * -----------------------------------
 * IDI = intermediaryChannelValue / (intermediaryChannelValue + directChannelValue)
 * Range [0, 1]. Lower IDI ⇒ less dependence on collectors/wholesalers.
 * If total value is 0, returns null (insufficient evidence).
 */

export type MoneyInputs = {
  winningBidPricePerKg: number;
  quantityKg: number;
  transportationCost: number;
  harvestingCost: number;
  platformCharges: number;
  otherCosts: number;
};

export function grossRevenue(pricePerKg: number, quantityKg: number): number {
  if (!isFinite(pricePerKg) || !isFinite(quantityKg) || quantityKg < 0) {
    return 0;
  }
  return round2(pricePerKg * quantityKg);
}

export function netFarmerIncome(input: MoneyInputs): number {
  const gross = grossRevenue(input.winningBidPricePerKg, input.quantityKg);
  const costs =
    nz(input.transportationCost) +
    nz(input.harvestingCost) +
    nz(input.platformCharges) +
    nz(input.otherCosts);
  return round2(gross - costs);
}

export function incomeImprovement(
  bitAppNet: number,
  traditionalNet: number,
): number {
  return round2(bitAppNet - traditionalNet);
}

export function incomeImprovementPercent(
  bitAppNet: number,
  traditionalNet: number,
): number | null {
  if (!isFinite(traditionalNet) || traditionalNet <= 0) return null;
  return round2(((bitAppNet - traditionalNet) / traditionalNet) * 100);
}

export function intermediaryDependencyIndex(
  intermediaryChannelValue: number,
  directChannelValue: number,
): number | null {
  const inter = Math.max(0, nz(intermediaryChannelValue));
  const direct = Math.max(0, nz(directChannelValue));
  const total = inter + direct;
  if (total <= 0) return null;
  return round4(inter / total);
}

export function estimatedTransportCost(params: {
  distanceKm: number;
  quantityKg: number;
  ratePerKm: number;
  ratePerKg: number;
  minimumFee: number;
}): number {
  const distanceComponent = nz(params.distanceKm) * nz(params.ratePerKm);
  const quantityComponent = nz(params.quantityKg) * nz(params.ratePerKg);
  const raw = distanceComponent + quantityComponent;
  return round2(Math.max(nz(params.minimumFee), raw));
}

export function haversineKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return round2(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

export function minValidBid(highestBid: number, increment: number): number {
  return round2(highestBid + increment);
}

export function isBidValid(params: {
  amount: number;
  highestBid: number;
  increment: number;
  openingBid: number;
}): boolean {
  const floor = Math.max(
    params.openingBid,
    minValidBid(params.highestBid, params.increment),
  );
  // First bid may equal opening bid when no bids yet (highestBid === 0).
  if (params.highestBid <= 0) {
    return params.amount >= params.openingBid;
  }
  return params.amount >= floor;
}

function nz(n: number): number {
  return !isFinite(n) || n < 0 ? 0 : n;
}

export function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

export function round4(n: number): number {
  return Math.round(n * 10000) / 10000;
}

export type VehicleKind = 'pickup' | 'small_lorry' | 'medium_lorry' | 'large_lorry';

const VEHICLE_CAPACITY: Record<VehicleKind, number> = {
  pickup: 500,
  small_lorry: 1500,
  medium_lorry: 5000,
  large_lorry: 15000,
};

export function requiredVehicleType(quantityKg: number): VehicleKind {
  if (quantityKg <= 400) return 'pickup';
  if (quantityKg <= 1500) return 'small_lorry';
  if (quantityKg <= 5000) return 'medium_lorry';
  return 'large_lorry';
}

export function vehicleCapacityKg(type: VehicleKind): number {
  return VEHICLE_CAPACITY[type];
}

export function vehicleMeetsCapacity(type: VehicleKind, quantityKg: number): boolean {
  return VEHICLE_CAPACITY[type] >= quantityKg;
}

export function computeTransportQuote(params: {
  distanceKm: number;
  quantityKg: number;
  baseCharge: number;
  perKm: number;
  perKg: number;
  loadingFee: number;
  fuelSurchargePercent: number;
}): number {
  const raw =
    nz(params.baseCharge) +
    nz(params.distanceKm) * nz(params.perKm) +
    nz(params.quantityKg) * nz(params.perKg) +
    nz(params.loadingFee);
  const withFuel = raw * (1 + nz(params.fuelSurchargePercent) / 100);
  return round2(withFuel);
}
