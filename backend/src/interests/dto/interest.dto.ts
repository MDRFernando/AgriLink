import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { InterestStatus } from '@prisma/client';

export class CreateInterestDto {
  @IsString()
  productionId!: string;

  @IsNumber()
  @Min(0.01)
  quantity!: number;

  @IsOptional()
  @IsString()
  message?: string;
}

export class UpdateInterestStatusDto {
  @IsEnum(InterestStatus)
  status!: InterestStatus;
}
