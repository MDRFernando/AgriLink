import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';
import { UserRole } from '@prisma/client';

export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsEnum(UserRole)
  role!: UserRole;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  nic?: string;
}

export class LoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;
}

export class UpdateProfileDto {
  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsString()
  @IsNotEmpty()
  phone!: string;

  @IsOptional()
  @IsString()
  organizationName?: string;

  @IsString()
  @IsNotEmpty()
  region!: string;

  @IsOptional()
  @IsString()
  nic?: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  district?: string;

  @IsOptional()
  @IsString()
  province?: string;

  @IsOptional()
  @IsString()
  farmLocation?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  farmSizeAcres?: number;

  @IsOptional()
  @IsString()
  cropTypesJson?: string;

  @IsOptional()
  @IsString()
  preferredCropsJson?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  estimatedCapacityKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  traditionalFarmgatePriceKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  harvestingCostPerKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  incomeBeforeBitApp?: number;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;

  @IsOptional()
  @IsString()
  nicOrBrn?: string;

  @IsOptional()
  @IsString()
  businessName?: string;

  @IsOptional()
  @IsString()
  businessType?: string;

  @IsOptional()
  @IsString()
  buyerLocation?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  preferredPriceMin?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  preferredPriceMax?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  requiredQuantityKg?: number;
}

export class VerifyBuyerDto {
  @IsEnum(['approved', 'rejected'] as const)
  status!: 'approved' | 'rejected';
}
