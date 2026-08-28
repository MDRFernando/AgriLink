import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { ProductionStatus, QualityGrade } from '@prisma/client';

export class CreateProductionDto {
  @IsString()
  cropType!: string;

  @IsNumber()
  @Min(0.01)
  quantity!: number;

  @IsString()
  unit!: string;

  @IsDateString()
  harvestDate!: string;

  @IsString()
  region!: string;

  @IsString()
  location!: string;

  @IsEnum(ProductionStatus)
  status!: ProductionStatus;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  variety?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsEnum(QualityGrade)
  qualityGrade?: QualityGrade;

  @IsOptional()
  @IsNumber()
  @Min(0)
  minAcceptablePrice?: number;

  @IsOptional()
  @IsString()
  preferredDeliveryLocation?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  imagesJson?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  openingBid?: number;

  @IsOptional()
  @IsNumber()
  @Min(0.01)
  minIncrement?: number;

  @IsOptional()
  @IsDateString()
  auctionEndTime?: string;
}

export class UpdateProductionDto {
  @IsOptional()
  @IsString()
  cropType?: string;

  @IsOptional()
  @IsNumber()
  @Min(0.01)
  quantity?: number;

  @IsOptional()
  @IsString()
  unit?: string;

  @IsOptional()
  @IsDateString()
  harvestDate?: string;

  @IsOptional()
  @IsString()
  region?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  variety?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsEnum(QualityGrade)
  qualityGrade?: QualityGrade;

  @IsOptional()
  @IsNumber()
  @Min(0)
  minAcceptablePrice?: number;

  @IsOptional()
  @IsString()
  preferredDeliveryLocation?: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateProductionStatusDto {
  @IsEnum(ProductionStatus)
  status!: ProductionStatus;
}

export class ProductionQueryDto {
  @IsOptional()
  @IsString()
  cropType?: string;

  @IsOptional()
  @IsString()
  region?: string;

  @IsOptional()
  @IsEnum(ProductionStatus)
  status?: ProductionStatus;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsEnum(QualityGrade)
  qualityGrade?: QualityGrade;
}
