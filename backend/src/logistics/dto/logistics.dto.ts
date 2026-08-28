import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { DeliveryMethod, DisputeType, TransportStatus, VehicleType } from '@prisma/client';

export class CreateAddressDto {
  @IsString()
  businessName!: string;

  @IsString()
  contactPerson!: string;

  @IsString()
  phone!: string;

  @IsString()
  address!: string;

  @IsString()
  city!: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsString()
  instructions?: string;
}

export class CreateTransportRequestDto {
  @IsString()
  orderId!: string;

  @IsEnum(DeliveryMethod)
  deliveryMethod!: DeliveryMethod;

  @IsOptional()
  @IsString()
  deliveryAddressId?: string;

  @IsOptional()
  @IsDateString()
  preferredPickupDate?: string;

  @IsOptional()
  @IsString()
  preferredPickupTime?: string;
}

export class ConfirmTransportDto {
  @IsString()
  transporterId!: string;

  @IsOptional()
  @IsString()
  paymentMethod?: string;
}

export class TrackingUpdateDto {
  @IsEnum(TransportStatus)
  status!: TransportStatus;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsString()
  note?: string;
}

export class HandoverDto {
  @IsNumber()
  @Min(0)
  quantityKg!: number;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class ConfirmDeliveryDto {
  @IsNumber()
  @Min(0)
  deliveredQuantityKg!: number;

  @IsOptional()
  @IsString()
  receivedBy?: string;

  @IsOptional()
  @IsString()
  signature?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsString()
  otp?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class CreateDisputeDto {
  @IsEnum(DisputeType)
  disputeType!: DisputeType;

  @IsNumber()
  @Min(0)
  quantityKg!: number;

  @IsString()
  description!: string;

  @IsOptional()
  @IsString()
  evidenceUrl?: string;

  @IsOptional()
  @IsString()
  buyerRemarks?: string;
}

export class PricingRuleDto {
  @IsEnum(VehicleType)
  vehicleType!: VehicleType;

  @IsNumber()
  @Min(0)
  baseCharge!: number;

  @IsNumber()
  @Min(0)
  perKm!: number;

  @IsNumber()
  @Min(0)
  perKg!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  loadingFee?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  fuelSurchargePercent?: number;
}

export class RateTransporterDto {
  @IsNumber()
  @Min(1)
  rating!: number;

  @IsOptional()
  @IsString()
  comment?: string;
}
