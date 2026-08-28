import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { DemandStatus } from '@prisma/client';

export class CreateDemandDto {
  @IsString()
  cropType!: string;

  @IsNumber()
  @Min(0.01)
  quantityNeeded!: number;

  @IsString()
  unit!: string;

  @IsDateString()
  deadline!: string;

  @IsString()
  region!: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateDemandStatusDto {
  @IsEnum(DemandStatus)
  status!: DemandStatus;
}

export class DemandQueryDto {
  @IsOptional()
  @IsString()
  cropType?: string;

  @IsOptional()
  @IsString()
  region?: string;

  @IsOptional()
  @IsEnum(DemandStatus)
  status?: DemandStatus;
}
