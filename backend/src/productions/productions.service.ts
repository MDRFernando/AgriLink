import { Injectable } from '@nestjs/common';
import {
  AuctionStatus,
  ProductionStatus,
  QualityGrade,
  UserRole,
} from '@prisma/client';
import { ListingCodeService } from '../common/listing-code.service';
import {
  ForbiddenException,
  NotFoundException,
} from '../common/constants';
import { SafeUser } from '../common/types';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateProductionDto,
  ProductionQueryDto,
  UpdateProductionDto,
  UpdateProductionStatusDto,
} from './dto/production.dto';

@Injectable()
export class ProductionsService {
  constructor(
    private prisma: PrismaService,
    private listingCodes: ListingCodeService,
  ) {}

  mapProduction(production: {
    id: string;
    listingCode: string | null;
    farmerId: string;
    cropType: string;
    variety: string | null;
    category: string | null;
    quantity: number;
    unit: string;
    harvestDate: Date;
    region: string;
    location: string;
    status: ProductionStatus;
    notes: string | null;
    qualityGrade: QualityGrade;
    minAcceptablePrice: number | null;
    preferredDeliveryLocation: string | null;
    description: string | null;
    imagesJson: string | null;
    createdAt: Date;
    farmer: { name: string | null };
    auction?: {
      id: string;
      openingBid: number;
      minBid: number;
      minIncrement: number;
      startTime: Date;
      endTime: Date;
      status: AuctionStatus;
      bids?: { amount: number; buyerId: string; createdAt: Date; id: string }[];
    } | null;
  }) {
    const bids = production.auction?.bids ?? [];
    const highest = bids.reduce((m, b) => Math.max(m, b.amount), 0);
    return {
      id: production.id,
      listingCode: production.listingCode,
      farmerId: production.farmerId,
      farmerName: production.farmer.name ?? 'Unknown Farmer',
      cropType: production.cropType,
      variety: production.variety,
      category: production.category,
      quantity: production.quantity,
      unit: production.unit,
      harvestDate: production.harvestDate.toISOString(),
      region: production.region,
      location: production.location,
      status: production.status,
      notes: production.notes,
      qualityGrade: production.qualityGrade,
      minAcceptablePrice: production.minAcceptablePrice,
      preferredDeliveryLocation: production.preferredDeliveryLocation,
      description: production.description,
      imagesJson: production.imagesJson,
      createdAt: production.createdAt.toISOString(),
      auction: production.auction
        ? {
            id: production.auction.id,
            openingBid: production.auction.openingBid,
            minBid: production.auction.minBid,
            minIncrement: production.auction.minIncrement,
            startTime: production.auction.startTime.toISOString(),
            endTime: production.auction.endTime.toISOString(),
            status: production.auction.status,
            highestBid: highest || production.auction.openingBid,
            bidderCount: new Set(bids.map((b) => b.buyerId)).size,
            bidCount: bids.length,
          }
        : null,
    };
  }

  private include = {
    farmer: { select: { name: true } },
    auction: { include: { bids: true } },
  };

  async findAll(query: ProductionQueryDto) {
    const where: Record<string, unknown> = {};

    if (query.cropType) where.cropType = query.cropType;
    if (query.region) where.region = query.region;
    if (query.status) where.status = query.status;
    if (query.qualityGrade) where.qualityGrade = query.qualityGrade;
    if (query.search) {
      where.OR = [
        { cropType: { contains: query.search } },
        { location: { contains: query.search } },
        { listingCode: { contains: query.search } },
        { farmer: { name: { contains: query.search } } },
      ];
    }

    const productions = await this.prisma.production.findMany({
      where,
      include: this.include,
      orderBy: { harvestDate: 'asc' },
    });

    return productions.map((p) => this.mapProduction(p));
  }

  async findAvailable(query: ProductionQueryDto) {
    return this.findAll({
      ...query,
      status: undefined,
    }).then((items) =>
      items.filter((p) =>
        ['available', 'readyForHarvest'].includes(p.status),
      ),
    );
  }

  async findMine(farmerId: string) {
    const productions = await this.prisma.production.findMany({
      where: { farmerId },
      include: this.include,
      orderBy: { createdAt: 'desc' },
    });
    return productions.map((p) => this.mapProduction(p));
  }

  async findOne(id: string) {
    const production = await this.prisma.production.findFirst({
      where: { OR: [{ id }, { listingCode: id }] },
      include: this.include,
    });
    if (!production) throw new NotFoundException('Production not found');
    return this.mapProduction(production);
  }

  async create(farmer: SafeUser, dto: CreateProductionDto) {
    if (farmer.role !== UserRole.farmer) {
      throw new ForbiddenException('Only farmers can create productions');
    }

    const listingCode = await this.listingCodes.nextCode();
    const minPrice = dto.minAcceptablePrice ?? 0;
    const opening = dto.openingBid ?? minPrice;
    const increment = dto.minIncrement ?? 5;
    const end = dto.auctionEndTime
      ? new Date(dto.auctionEndTime)
      : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    const production = await this.prisma.production.create({
      data: {
        listingCode,
        farmerId: farmer.id,
        cropType: dto.cropType,
        variety: dto.variety,
        category: dto.category ?? 'Vegetables',
        quantity: dto.quantity,
        unit: dto.unit,
        harvestDate: new Date(dto.harvestDate),
        region: dto.region,
        location: dto.location,
        status: dto.status,
        notes: dto.notes,
        qualityGrade: dto.qualityGrade ?? QualityGrade.B,
        minAcceptablePrice: minPrice || null,
        preferredDeliveryLocation: dto.preferredDeliveryLocation,
        description: dto.description ?? dto.notes,
        imagesJson: dto.imagesJson,
        auction: {
          create: {
            openingBid: opening,
            minBid: minPrice || opening,
            minIncrement: increment,
            startTime: new Date(),
            endTime: end,
            status: AuctionStatus.open,
          },
        },
      },
      include: this.include,
    });

    return this.mapProduction(production);
  }

  async update(user: SafeUser, id: string, dto: UpdateProductionDto) {
    const production = await this.prisma.production.findUnique({
      where: { id },
    });
    if (!production) throw new NotFoundException('Production not found');
    if (production.farmerId !== user.id) {
      throw new ForbiddenException('You can only edit your own productions');
    }

    const updated = await this.prisma.production.update({
      where: { id },
      data: {
        ...dto,
        harvestDate: dto.harvestDate ? new Date(dto.harvestDate) : undefined,
      },
      include: this.include,
    });

    return this.mapProduction(updated);
  }

  async updateStatus(
    user: SafeUser,
    id: string,
    dto: UpdateProductionStatusDto,
  ) {
    const production = await this.prisma.production.findUnique({
      where: { id },
    });
    if (!production) throw new NotFoundException('Production not found');
    if (production.farmerId !== user.id) {
      throw new ForbiddenException('You can only update your own productions');
    }

    const updated = await this.prisma.production.update({
      where: { id },
      data: { status: dto.status },
      include: this.include,
    });

    return this.mapProduction(updated);
  }
}
