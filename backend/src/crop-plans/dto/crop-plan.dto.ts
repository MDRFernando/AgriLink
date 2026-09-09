import { Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { CropPlanStatus, CultivationSeason } from '@prisma/client';

export class CreateCropPlanDto {
  @IsString()
  cropType!: string;

  @Type(() => Number)
  @IsInt()
  cultivationYear!: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(12)
  cultivationMonth!: number;

  @IsOptional()
  @IsEnum(CultivationSeason)
  season?: CultivationSeason;

  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  areaAcres!: number;

  @IsString()
  province!: string;

  @IsString()
  district!: string;

  @IsString()
  dsDivision!: string;

  @IsString()
  village!: string;

  @IsOptional()
  @IsString()
  locationNotes?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  expectedYieldKg?: number;
}

export class UpdateCropPlanDto {
  @IsOptional()
  @IsString()
  cropType?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  cultivationYear?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(12)
  cultivationMonth?: number;

  @IsOptional()
  @IsEnum(CultivationSeason)
  season?: CultivationSeason;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  areaAcres?: number;

  @IsOptional()
  @IsString()
  province?: string;

  @IsOptional()
  @IsString()
  district?: string;

  @IsOptional()
  @IsString()
  dsDivision?: string;

  @IsOptional()
  @IsString()
  village?: string;

  @IsOptional()
  @IsString()
  locationNotes?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  expectedYieldKg?: number;

  @IsOptional()
  @IsEnum(CropPlanStatus)
  status?: CropPlanStatus;
}

export class CropPlanQueryDto {
  @IsOptional()
  @IsString()
  cropType?: string;

  @IsOptional()
  @IsString()
  district?: string;

  @IsOptional()
  @IsString()
  dsDivision?: string;

  @IsOptional()
  @IsString()
  village?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  month?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  year?: number;

  @IsOptional()
  @IsString()
  groupBy?: 'crop' | 'district' | 'dsDivision' | 'village' | 'period';
}
