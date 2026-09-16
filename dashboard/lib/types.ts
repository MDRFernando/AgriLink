export type UserRole = 'farmer' | 'buyer' | 'transporter' | 'government';

export type QualityGrade = 'A' | 'B' | 'C';

export type ProductionStatus = 
  | 'planned' 
  | 'growing' 
  | 'readyForHarvest' 
  | 'available' 
  | 'sold' 
  | 'expired';

export type AuctionStatus = 'scheduled' | 'open' | 'closed' | 'cancelled';

export type OrderStatus = 
  | 'pending_farmer' 
  | 'pending_buyer' 
  | 'confirmed' 
  | 'payment_pending' 
  | 'paid' 
  | 'in_transit' 
  | 'delivered' 
  | 'completed' 
  | 'cancelled'
  | 'disputed';

export type TransportStatus = 
  | 'requested' 
  | 'assigned' 
  | 'arrived_at_pickup' 
  | 'loaded' 
  | 'in_transit' 
  | 'delivered' 
  | 'buyer_confirmed' 
  | 'completed';

export type VehicleType = 'pickup' | 'small_lorry' | 'medium_lorry' | 'large_lorry';

export interface ProductionListing {
  id: string;
  listingCode: string;
  farmerName: string;
  farmerPhone: string;
  cropType: string;
  variety: string;
  category: 'Vegetables' | 'Paddy & Rice' | 'Fruits' | 'Spices';
  quantityKg: number;
  qualityGrade: QualityGrade;
  harvestDate: string;
  region: string;
  district: string;
  status: ProductionStatus;
  minAcceptablePriceKg: number;
  traditionalFarmgatePriceKg: number;
  projectedRevenue: number;
  description: string;
  activeAuction?: {
    id: string;
    openingBid: number;
    currentHighestBid: number;
    bidCount: number;
    endsInMinutes: number;
    status: AuctionStatus;
    highestBidderName?: string;
  };
}

export interface DemandRequest {
  id: string;
  buyerName: string;
  buyerCompany: string;
  cropType: string;
  quantityNeededKg: number;
  fulfilledKg: number;
  targetPriceKg: number;
  deadline: string;
  district: string;
  status: 'open' | 'fulfilled' | 'closed';
  notes: string;
}

export interface OrderItem {
  id: string;
  orderCode: string;
  cropType: string;
  variety: string;
  quantityKg: number;
  pricePerKg: number;
  totalAmount: number;
  farmerName: string;
  buyerName: string;
  transporterName?: string;
  orderStatus: OrderStatus;
  paymentStatus: 'pending' | 'sandbox_paid' | 'settled';
  deliveryMethod: 'bit_app_transport' | 'own_transport';
  createdAt: string;
  pickupLocation: string;
  deliveryLocation: string;
  disputeNotes?: string;
}

export interface TransportJob {
  id: string;
  requestCode: string;
  product: string;
  quantityKg: number;
  requiredVehicle: VehicleType;
  pickupDistrict: string;
  pickupAddress: string;
  farmerName: string;
  farmerPhone: string;
  deliveryDistrict: string;
  deliveryAddress: string;
  buyerName: string;
  distanceKm: number;
  estimatedEarnings: number;
  status: TransportStatus;
  driverName?: string;
  vehicleNumber?: string;
  updatedAt: string;
  otpCode?: string;
}

export interface Vehicle {
  id: string;
  vehicleNumber: string;
  vehicleType: VehicleType;
  capacityKg: number;
  status: 'active' | 'on_trip' | 'maintenance';
  currentDriver: string;
  fuelEfficiencyKmPerL: number;
}

export interface CropPlan {
  id: string;
  cropType: string;
  season: 'Maha 2026' | 'Yala 2026' | 'Off-Season';
  areaAcres: number;
  expectedYieldKg: number;
  district: string;
  dsDivision: string;
  status: 'planned' | 'cultivating' | 'harvested';
  sowingDate: string;
  harvestTargetDate: string;
}

export interface MarketPriceIndex {
  id: string;
  cropType: string;
  variety: string;
  district: string;
  grade: QualityGrade;
  currentPriceKg: number;
  yesterdayPriceKg: number;
  weeklyHighKg: number;
  weeklyLowKg: number;
  source: 'DEMO_SEED' | 'TRANSACTION_DERIVED';
  recordedOn: string;
}

export interface DistrictSupplyMetric {
  district: string;
  province: string;
  majorCrops: string[];
  totalCultivatedAcres: number;
  projectedHarvestTonnes: number;
  activeFarmers: number;
  marketDemandTonnes: number;
  supplyDeficitSurplusTonnes: number; // positive = surplus, negative = deficit
}

export interface VerificationRequest {
  id: string;
  applicantName: string;
  applicantRole: 'buyer' | 'transporter';
  organizationName: string;
  brnOrNic: string;
  district: string;
  submittedAt: string;
  documents: string[];
  status: 'pending' | 'approved' | 'rejected';
}
