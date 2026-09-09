import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import {
  AuctionStatus,
  NotificationAudience,
  OrderStatus,
  ProductionStatus,
  UserRole,
  VerificationStatus,
} from '@prisma/client';
import {
  estimatedTransportCost,
  haversineKm,
  minValidBid,
} from '../common/calculations';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SafeUser } from '../common/types';

@Injectable()
export class AuctionsService implements OnModuleInit {
  private timer?: ReturnType<typeof setInterval>;

  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  onModuleInit() {
    this.timer = setInterval(() => {
      this.closeExpired().catch(() => undefined);
    }, 30_000);
  }

  async getByProduction(productionId: string) {
    const auction = await this.prisma.auction.findUnique({
      where: { productionId },
      include: {
        bids: { include: { buyer: { select: { id: true, name: true, organizationName: true } } }, orderBy: { createdAt: 'desc' } },
        production: true,
      },
    });
    if (!auction) throw new NotFoundException('Auction not found');
    return this.serialize(auction);
  }

  async placeBid(user: SafeUser, productionId: string, amount: number) {
    if (user.role !== UserRole.business) {
      throw new ForbiddenException('Only buyers can bid');
    }

    const buyer = await this.prisma.buyerProfile.findUnique({
      where: { userId: user.id },
    });
    if (!buyer || buyer.verificationStatus !== VerificationStatus.approved) {
      throw new ForbiddenException('Only verified buyers can participate in bidding');
    }

    await this.closeExpired();

    const auction = await this.prisma.auction.findUnique({
      where: { productionId },
      include: { bids: true, production: true },
    });
    if (!auction) throw new NotFoundException('Auction not found');
    if (auction.status !== AuctionStatus.open) {
      throw new BadRequestException('Listing is not open for bidding');
    }
    if (auction.endTime < new Date()) {
      await this.closeAuction(auction.id);
      throw new BadRequestException('Bidding window has closed');
    }
    if (auction.production.farmerId === user.id) {
      throw new ForbiddenException('Farmers cannot bid on their own listings');
    }

    const highest = auction.bids.reduce((m, b) => Math.max(m, b.amount), 0);
    const reserve = auction.minBid;
    const minimumAcceptable = highest + auction.minIncrement;
    if (amount < minimumAcceptable) {
      throw new BadRequestException(`Bid must be at least ${minimumAcceptable}`);
    }
    if (amount < reserve) {
      throw new BadRequestException("Bid is below farmer's reserve price");
    }

    const bid = await this.prisma.bid.create({
      data: { auctionId: auction.id, buyerId: user.id, amount },
    });

    await this.prisma.auditLog.create({
      data: {
        actorId: user.id,
        action: 'BID_PLACED',
        entityType: 'Bid',
        entityId: bid.id,
        metadata: JSON.stringify({ productionId, amount }),
      },
    });

    await this.notifications.notify(
      auction.production.farmerId,
      NotificationAudience.farmer,
      'new_highest_bid',
      `Rs. ${amount}/kg on ${auction.production.listingCode ?? auction.production.cropType}`,
    );

    for (const other of auction.bids) {
      if (other.buyerId !== user.id && other.amount < amount) {
        await this.notifications.notify(
          other.buyerId,
          NotificationAudience.buyer,
          'Your bid was surpassed',
          `A higher bid of Rs. ${amount}/kg was placed.`,
        );
      }
    }

    return this.getByProduction(productionId);
  }

  async closeExpired() {
    const due = await this.prisma.auction.findMany({
      where: { status: AuctionStatus.open, endTime: { lte: new Date() } },
      include: { bids: { orderBy: { amount: 'desc' } }, production: true },
    });

    for (const auction of due) {
      await this.closeAuction(auction.id);
    }
  }

  async closeAuction(auctionId: string) {
    const auction = await this.prisma.auction.findUnique({
      where: { id: auctionId },
      include: { bids: { orderBy: { amount: 'desc' } }, production: true },
    });
    if (!auction || auction.status !== AuctionStatus.open) return null;

    const winning = auction.bids[0] ?? null;
    const reserve = auction.minBid;
    const qualifies = !!winning && winning.amount >= reserve;

    await this.prisma.auction.update({
      where: { id: auctionId },
      data: {
        status: AuctionStatus.closed,
        closedAt: new Date(),
        winningBidId: qualifies ? winning!.id : null,
      },
    });

    if (!qualifies) {
      await this.prisma.production.update({
        where: { id: auction.productionId },
        data: { status: ProductionStatus.expired },
      });
      await this.notifications.notify(
        auction.production.farmerId,
        NotificationAudience.farmer,
        'listing_expired',
        'No bid met your reserve price before the window closed.',
      );
      return { closed: true, winner: null };
    }

    const farmer = await this.prisma.farmerProfile.findUnique({
      where: { userId: auction.production.farmerId },
    });
    const buyer = await this.prisma.buyerProfile.findUnique({
      where: { userId: winning.buyerId },
    });

    let distanceKm = 18;
    if (farmer?.lat && farmer?.lng && buyer?.lat && buyer?.lng) {
      distanceKm = haversineKm(farmer.lat, farmer.lng, buyer.lat, buyer.lng);
    }

    const transportCost = estimatedTransportCost({
      distanceKm,
      quantityKg: auction.production.quantity,
      ratePerKm: 80,
      ratePerKg: 2,
      minimumFee: 1500,
    });

    const order = await this.prisma.order.create({
      data: {
        auctionId: auction.id,
        productionId: auction.productionId,
        farmerId: auction.production.farmerId,
        buyerId: winning.buyerId,
        winningPriceKg: winning.amount,
        quantityKg: auction.production.quantity,
        status: OrderStatus.pending_farmer,
        events: {
          create: {
            status: OrderStatus.pending_farmer,
            actorId: winning.buyerId,
            action: 'AUCTION_CLOSED',
            remarks: 'Winning bid identified; awaiting farmer confirmation',
          },
        },
        transportation: {
          create: {
            farmerLocation: auction.production.location,
            buyerLocation: buyer?.location,
            distanceKm,
            quantityKg: auction.production.quantity,
            estimatedCost: transportCost,
            vehicleRequirement:
              auction.production.quantity > 1000 ? 'Lorry' : 'Pickup / van',
            deliveryDate: auction.production.harvestDate,
          },
        },
      },
    });

    await this.notifications.notify(
      auction.production.farmerId,
      NotificationAudience.farmer,
      'listing_closed_winner',
      `Winning bid Rs. ${winning.amount}/kg. Please confirm the order.`,
    );
    await this.notifications.notify(
      winning.buyerId,
      NotificationAudience.buyer,
      'You won an auction',
      `You won ${auction.production.cropType} at Rs. ${winning.amount}/kg.`,
    );

    return { closed: true, winner: winning, orderId: order.id };
  }

  private serialize(auction: {
    id: string;
    productionId: string;
    openingBid: number;
    minBid: number;
    minIncrement: number;
    startTime: Date;
    endTime: Date;
    status: AuctionStatus;
    winningBidId: string | null;
    bids: {
      id: string;
      amount: number;
      createdAt: Date;
      buyerId: string;
      buyer: { name: string | null; organizationName: string | null };
    }[];
    production: { cropType: string; listingCode: string | null; quantity: number };
  }) {
    const highest = auction.bids.reduce((m, b) => Math.max(m, b.amount), 0);
    return {
      id: auction.id,
      productionId: auction.productionId,
      listingCode: auction.production.listingCode,
      cropType: auction.production.cropType,
      quantityKg: auction.production.quantity,
      openingBid: auction.openingBid,
      minBid: auction.minBid,
      minIncrement: auction.minIncrement,
      highestBid: highest || auction.openingBid,
      minNextBid:
        highest > 0
          ? minValidBid(highest, auction.minIncrement)
          : auction.openingBid,
      bidderCount: new Set(auction.bids.map((b) => b.buyerId)).size,
      startTime: auction.startTime.toISOString(),
      endTime: auction.endTime.toISOString(),
      status: auction.status,
      winningBidId: auction.winningBidId,
      history: auction.bids.map((b) => ({
        id: b.id,
        buyerId: b.buyerId,
        buyerName: b.buyer.organizationName ?? b.buyer.name,
        amount: b.amount,
        createdAt: b.createdAt.toISOString(),
      })),
    };
  }
}
