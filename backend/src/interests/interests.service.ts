import { Injectable } from '@nestjs/common';
import { InterestStatus, UserRole } from '@prisma/client';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '../common/constants';
import { SafeUser } from '../common/types';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateInterestDto,
  UpdateInterestStatusDto,
} from './dto/interest.dto';

@Injectable()
export class InterestsService {
  constructor(private prisma: PrismaService) {}

  private mapInterest(interest: {
    id: string;
    quantity: number;
    message: string | null;
    status: InterestStatus;
    createdAt: Date;
    productionId: string;
    business: { id: string; name: string | null; organizationName: string | null };
    production: { cropType: string; unit: string };
  }) {
    return {
      id: interest.id,
      businessId: interest.business.id,
      businessName:
        interest.business.organizationName ??
        interest.business.name ??
        'Unknown Business',
      productionId: interest.productionId,
      cropType: interest.production.cropType,
      quantity: interest.quantity,
      unit: interest.production.unit,
      status: interest.status,
      createdAt: interest.createdAt.toISOString(),
      message: interest.message,
    };
  }

  async findMine(businessId: string) {
    const interests = await this.prisma.purchaseInterest.findMany({
      where: { businessId },
      include: {
        business: { select: { id: true, name: true, organizationName: true } },
        production: { select: { cropType: true, unit: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return interests.map((i) => this.mapInterest(i));
  }

  async findReceived(farmerId: string) {
    const interests = await this.prisma.purchaseInterest.findMany({
      where: { production: { farmerId } },
      include: {
        business: { select: { id: true, name: true, organizationName: true } },
        production: { select: { cropType: true, unit: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return interests.map((i) => this.mapInterest(i));
  }

  async create(user: SafeUser, dto: CreateInterestDto) {
    if (user.role !== UserRole.business) {
      throw new ForbiddenException('Only businesses can express interest');
    }

    const production = await this.prisma.production.findUnique({
      where: { id: dto.productionId },
    });
    if (!production) throw new NotFoundException('Production not found');
    if (dto.quantity > production.quantity) {
      throw new BadRequestException(
        `Quantity cannot exceed available ${production.quantity} ${production.unit}`,
      );
    }

    const interest = await this.prisma.purchaseInterest.create({
      data: {
        businessId: user.id,
        productionId: dto.productionId,
        quantity: dto.quantity,
        message: dto.message,
      },
      include: {
        business: { select: { id: true, name: true, organizationName: true } },
        production: { select: { cropType: true, unit: true } },
      },
    });

    return this.mapInterest(interest);
  }

  async updateStatus(
    user: SafeUser,
    id: string,
    dto: UpdateInterestStatusDto,
  ) {
    const interest = await this.prisma.purchaseInterest.findUnique({
      where: { id },
      include: { production: true },
    });
    if (!interest) throw new NotFoundException('Interest not found');
    if (interest.production.farmerId !== user.id) {
      throw new ForbiddenException('Only the farmer can respond to interests');
    }
    if (interest.status !== InterestStatus.pending) {
      throw new BadRequestException('Interest has already been processed');
    }

    if (
      dto.status !== InterestStatus.accepted &&
      dto.status !== InterestStatus.rejected
    ) {
      throw new BadRequestException('Status must be accepted or rejected');
    }

    const updated = await this.prisma.purchaseInterest.update({
      where: { id },
      data: { status: dto.status },
      include: {
        business: { select: { id: true, name: true, organizationName: true } },
        production: { select: { cropType: true, unit: true } },
      },
    });

    return this.mapInterest(updated);
  }
}
