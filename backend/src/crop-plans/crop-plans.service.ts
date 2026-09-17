import { Injectable } from '@nestjs/common';
import { CropPlanStatus, DemandStatus, Prisma } from '@prisma/client';
import { BadRequestException, ForbiddenException, NotFoundException } from '../common/constants';
import { assertValidLocation, estimatedYieldKg } from '../common/geo';
import { SafeUser } from '../common/types';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateCropPlanDto,
  CropPlanQueryDto,
  UpdateCropPlanDto,
} from './dto/crop-plan.dto';

const ACTIVE: CropPlanStatus[] = [
  CropPlanStatus.planned,
  CropPlanStatus.cultivating,
];

@Injectable()
export class CropPlansService {
  constructor(private prisma: PrismaService) {}

  findMine(farmerId: string) {
    return this.prisma.cropPlan.findMany({
      where: { farmerId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(user: SafeUser, dto: CreateCropPlanDto) {
    this.assertLocation(dto);
    return this.prisma.cropPlan.create({
      data: {
        farmerId: user.id,
        cropType: dto.cropType,
        cultivationYear: dto.cultivationYear,
        cultivationMonth: dto.cultivationMonth,
        season: dto.season,
        areaAcres: dto.areaAcres,
        province: dto.province,
        district: dto.district,
        dsDivision: dto.dsDivision,
        village: dto.village,
        locationNotes: dto.locationNotes,
        expectedYieldKg: dto.expectedYieldKg,
      },
    });
  }

  async update(user: SafeUser, id: string, dto: UpdateCropPlanDto) {
    const plan = await this.prisma.cropPlan.findUnique({ where: { id } });
    if (!plan) throw new NotFoundException('Crop plan not found');
    if (plan.farmerId !== user.id) {
      throw new ForbiddenException('You can only update your own crop plans');
    }
    const next = {
      province: dto.province ?? plan.province,
      district: dto.district ?? plan.district,
      dsDivision: dto.dsDivision ?? plan.dsDivision,
      village: dto.village ?? plan.village,
    };
    this.assertLocation(next);
    return this.prisma.cropPlan.update({ where: { id }, data: dto });
  }

  async cancel(user: SafeUser, id: string) {
    return this.update(user, id, { status: CropPlanStatus.cancelled });
  }

  async aggregates(query: CropPlanQueryDto) {
    const plans = await this.loadFiltered(query);
    const groupBy = query.groupBy ?? 'crop';
    const grouped = new Map<
      string,
      {
        cropType: string;
        province: string;
        district: string;
        dsDivision: string;
        village: string;
        year: number;
        month: number;
        farmers: Set<string>;
        area: number;
        yieldKg: number;
        planCount: number;
      }
    >();

    for (const plan of plans) {
      const key =
        groupBy === 'district'
          ? `${plan.district}::${plan.cropType}`
          : groupBy === 'dsDivision'
            ? `${plan.district}::${plan.dsDivision}::${plan.cropType}`
            : groupBy === 'village'
              ? `${plan.district}::${plan.dsDivision}::${plan.village}::${plan.cropType}`
              : groupBy === 'period'
                ? `${plan.cultivationYear}-${plan.cultivationMonth}::${plan.cropType}`
                : plan.cropType;
      const bucket = grouped.get(key) ?? {
        cropType: plan.cropType,
        province: plan.province,
        district: plan.district,
        dsDivision: plan.dsDivision,
        village: plan.village,
        year: plan.cultivationYear,
        month: plan.cultivationMonth,
        farmers: new Set<string>(),
        area: 0,
        yieldKg: 0,
        planCount: 0,
      };
      bucket.farmers.add(plan.farmerId);
      bucket.area += plan.areaAcres;
      bucket.yieldKg += estimatedYieldKg(
        plan.cropType,
        plan.areaAcres,
        plan.expectedYieldKg,
      );
      bucket.planCount += 1;
      grouped.set(key, bucket);
    }

    return Array.from(grouped.values())
      .map((b) => ({
        cropType: b.cropType,
        province: b.province,
        district: b.district,
        dsDivision: b.dsDivision,
        village: b.village,
        cultivationYear: b.year,
        cultivationMonth: b.month,
        farmerCount: b.farmers.size,
        totalAreaAcres: b.area,
        estimatedYieldKg: b.yieldKg,
        planCount: b.planCount,
      }))
      .sort((a, b) => b.totalAreaAcres - a.totalAreaAcres);
  }

  async dashboard(query: CropPlanQueryDto) {
    const plans = await this.loadFiltered(query);
    const farmers = new Set(plans.map((p) => p.farmerId));
    const acres = plans.reduce((sum, p) => sum + p.areaAcres, 0);
    const [byCrop, byDistrict, byPeriod, insights] = await Promise.all([
      this.aggregates({ ...query, groupBy: 'crop' }),
      this.aggregates({ ...query, groupBy: 'district' }),
      this.aggregates({ ...query, groupBy: 'period' }),
      this.insights(query),
    ]);
    return {
      farmerCount: farmers.size,
      planCount: plans.length,
      totalAreaAcres: acres,
      cropsCovered: byCrop.length,
      byCrop,
      byDistrict,
      byPeriod,
      insights,
    };
  }

  async insights(query: CropPlanQueryDto) {
    const plans = await this.loadFiltered(query);
    const demands = await this.prisma.demandRequest.findMany({
      where: { status: DemandStatus.open },
    });
    const crops = new Set([
      ...plans.map((p) => p.cropType),
      ...demands.map((d) => d.cropType),
    ]);
    const result = [];
    for (const crop of crops) {
      const cropPlans = plans.filter((p) => p.cropType === crop);
      const farmerCount = new Set(cropPlans.map((p) => p.farmerId)).size;
      const area = cropPlans.reduce((sum, p) => sum + p.areaAcres, 0);
      const supply = cropPlans.reduce(
        (sum, p) =>
          sum + estimatedYieldKg(p.cropType, p.areaAcres, p.expectedYieldKg),
        0,
      );
      const openDemandKg = demands
        .filter((d) => d.cropType === crop)
        .reduce((sum, d) => sum + d.quantityNeeded, 0);
      if (supply === 0 && openDemandKg === 0) continue;

      let signal: 'surplusRisk' | 'demandGap' | 'balanced';
      let message: string;
      if (openDemandKg === 0 && supply > 0) {
        signal = 'surplusRisk';
        message = `${farmerCount} farmer(s) plan ${area.toFixed(1)} acres of ${crop} with no matching open buyer demand.`;
      } else if (supply === 0 && openDemandKg > 0) {
        signal = 'demandGap';
        message = `Open demand of ${openDemandKg} kg for ${crop} has no matching cultivation plans.`;
      } else {
        const ratio = supply / openDemandKg;
        if (ratio >= 1.4) {
          signal = 'surplusRisk';
          message = `Planned ${crop} supply (~${Math.round(supply)} kg) is well above registered demand (${openDemandKg} kg).`;
        } else if (ratio <= 0.7) {
          signal = 'demandGap';
          message = `Registered ${crop} demand (${openDemandKg} kg) exceeds planned supply (~${Math.round(supply)} kg).`;
        } else {
          signal = 'balanced';
          message = `Planned ${crop} supply (~${Math.round(supply)} kg) is broadly in line with open demand (${openDemandKg} kg).`;
        }
      }
      result.push({
        cropType: crop,
        farmerCount,
        plannedAreaAcres: area,
        estimatedSupplyKg: supply,
        openDemandKg,
        signal,
        message,
      });
    }
    return result.sort((a, b) => b.plannedAreaAcres - a.plannedAreaAcres);
  }

  private async loadFiltered(query: CropPlanQueryDto) {
    const where: Prisma.CropPlanWhereInput = {
      status: { in: ACTIVE },
    };
    if (query.cropType) where.cropType = query.cropType;
    if (query.district) where.district = query.district;
    if (query.dsDivision) where.dsDivision = query.dsDivision;
    if (query.village) where.village = query.village;
    if (query.month) where.cultivationMonth = query.month;
    if (query.year) where.cultivationYear = query.year;
    return this.prisma.cropPlan.findMany({ where });
  }

  private assertLocation(input: {
    province: string;
    district: string;
    dsDivision: string;
    village: string;
  }) {
    if (!assertValidLocation(input)) {
      throw new BadRequestException(
        'Province, district, DS Division, and village do not match',
      );
    }
  }
}
