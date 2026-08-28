import { Injectable } from '@nestjs/common';
import { DemandStatus, UserRole } from '@prisma/client';
import {
  ForbiddenException,
  NotFoundException,
} from '../common/constants';
import { SafeUser } from '../common/types';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateDemandDto,
  DemandQueryDto,
  UpdateDemandStatusDto,
} from './dto/demand.dto';

@Injectable()
export class DemandsService {
  constructor(private prisma: PrismaService) {}

  private mapDemand(demand: {
    id: string;
    cropType: string;
    quantityNeeded: number;
    unit: string;
    deadline: Date;
    region: string;
    status: DemandStatus;
    notes: string | null;
    requester: { name: string | null; organizationName: string | null; role: UserRole };
  }) {
    return {
      id: demand.id,
      requesterName:
        demand.requester.organizationName ??
        demand.requester.name ??
        'Unknown',
      requesterRole: demand.requester.role,
      cropType: demand.cropType,
      quantityNeeded: demand.quantityNeeded,
      unit: demand.unit,
      deadline: demand.deadline.toISOString(),
      region: demand.region,
      status: demand.status,
      notes: demand.notes,
    };
  }

  async findAll(query: DemandQueryDto) {
    const where: Record<string, unknown> = {};
    if (query.cropType) where.cropType = query.cropType;
    if (query.region) where.region = query.region;
    if (query.status) where.status = query.status;

    const demands = await this.prisma.demandRequest.findMany({
      where,
      include: {
        requester: {
          select: { name: true, organizationName: true, role: true },
        },
      },
      orderBy: { deadline: 'asc' },
    });

    return demands.map((d) => this.mapDemand(d));
  }

  async findMine(userId: string) {
    const demands = await this.prisma.demandRequest.findMany({
      where: { requesterId: userId },
      include: {
        requester: {
          select: { name: true, organizationName: true, role: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return demands.map((d) => this.mapDemand(d));
  }

  async create(user: SafeUser, dto: CreateDemandDto) {
    if (user.role === UserRole.farmer) {
      throw new ForbiddenException('Farmers cannot post demand requests');
    }

    const demand = await this.prisma.demandRequest.create({
      data: {
        requesterId: user.id,
        cropType: dto.cropType,
        quantityNeeded: dto.quantityNeeded,
        unit: dto.unit,
        deadline: new Date(dto.deadline),
        region: dto.region,
        notes: dto.notes,
      },
      include: {
        requester: {
          select: { name: true, organizationName: true, role: true },
        },
      },
    });

    return this.mapDemand(demand);
  }

  async updateStatus(
    user: SafeUser,
    id: string,
    dto: UpdateDemandStatusDto,
  ) {
    const demand = await this.prisma.demandRequest.findUnique({
      where: { id },
    });
    if (!demand) throw new NotFoundException('Demand not found');
    if (demand.requesterId !== user.id) {
      throw new ForbiddenException('You can only update your own demands');
    }

    const updated = await this.prisma.demandRequest.update({
      where: { id },
      data: { status: dto.status },
      include: {
        requester: {
          select: { name: true, organizationName: true, role: true },
        },
      },
    });

    return this.mapDemand(updated);
  }
}
