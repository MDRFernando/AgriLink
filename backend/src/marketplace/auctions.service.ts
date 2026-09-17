import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import {
  AuctionStatus,
  BidStatus,
  NotificationAudience,
  OrderStatus,
  ProductionStatus,
  UserRole,
  VerificationStatus,
} from '@prisma/client';
import {
  estimatedTransportCost,
  haversineKm,
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

  async getByProduction(productionId: string, viewer?: SafeUser | null) {
    const auction = await this.prisma.auction.findUnique({
      where: { productionId },
      include: {
        bids: {
          include: {
            buyer: { select: { id: true, name: true, organizationName: true } },
          },
          orderBy: { createdAt: 'desc' },
        },
        production: true,
      },
    });
    if (!auction) throw new NotFoundException('Auction not found');
    return this.serializeAuction(auction, viewer);
  }

  async listForFarmer(user: SafeUser) {
    if (user.role !== UserRole.farmer) {
      throw new ForbiddenException('Only farmers can view received bids');
    }
    await this.closeExpired();
    const bids = await this.prisma.bid.findMany({
      where: { farmerId: user.id },
      include: this.bidInclude,
      orderBy: { createdAt: 'desc' },
    });
    return bids.map((bid) => this.serializeBid(bid));
  }

  async listForBuyer(user: SafeUser) {
    if (user.role !== UserRole.business) {
      throw new ForbiddenException('Only buyers can view their bids');
    }
    await this.closeExpired();
    const bids = await this.prisma.bid.findMany({
      where: { buyerId: user.id },
      include: this.bidInclude,
      orderBy: { createdAt: 'desc' },
    });
    return bids.map((bid) => this.serializeBid(bid));
  }

  async placeBid(
    user: SafeUser,
    productionId: string,
    amount: number,
    quantity: number,
  ) {
    if (user.role !== UserRole.business) {
      throw new ForbiddenException('Only buyers can bid');
    }

    const buyer = await this.prisma.buyerProfile.findUnique({
      where: { userId: user.id },
    });
    if (!buyer) {
      throw new ForbiddenException('Complete your buyer profile before bidding');
    }
    if (
      buyer.verificationStatus !== VerificationStatus.approved &&
      !user.isVerified
    ) {
      throw new ForbiddenException('Only verified buyers can participate in bidding');
    }

    await this.closeExpired();

    if (!Number.isFinite(quantity) || quantity <= 0) {
      throw new BadRequestException('Quantity must be greater than zero');
    }
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new BadRequestException('Enter a valid bid price');
    }

    const auction = await this.prisma.auction.findUnique({
      where: { productionId },
      include: { production: true },
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
    if (
      auction.production.status === ProductionStatus.sold ||
      auction.production.status === ProductionStatus.expired ||
      auction.production.quantity <= 0
    ) {
      throw new BadRequestException('Listing is not open for bidding');
    }
    if (quantity > auction.production.quantity) {
      throw new BadRequestException('Quantity exceeds available stock');
    }

    const reserve = auction.minBid;
    if (amount < reserve) {
      throw new BadRequestException("Bid is below farmer's reserve price");
    }

    const totalAmount = quantity * amount;
    const bid = await this.prisma.bid.create({
      data: {
        auctionId: auction.id,
        productionId: auction.productionId,
        buyerId: user.id,
        farmerId: auction.production.farmerId,
        quantity,
        amount,
        totalAmount,
        status: BidStatus.pending,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        actorId: user.id,
        action: 'BID_PLACED',
        entityType: 'Bid',
        entityId: bid.id,
        metadata: JSON.stringify({ productionId, amount, quantity, totalAmount }),
      },
    });

    await this.notifications.notify(
      auction.production.farmerId,
      NotificationAudience.farmer,
      'new_bid',
      `Rs. ${amount}/kg for ${quantity} ${auction.production.unit} of ${auction.production.listingCode ?? auction.production.cropType}`,
    );

    return this.getByProduction(productionId, user);
  }

  async acceptBid(user: SafeUser, bidId: string) {
    if (user.role !== UserRole.farmer) {
      throw new ForbiddenException('Only farmers can accept bids');
    }

    await this.closeExpired();

    const result = await this.prisma.$transaction(async (tx) => {
      const bid = await tx.bid.findUnique({
        where: { id: bidId },
        include: {
          auction: { include: { production: true } },
          order: true,
        },
      });
      if (!bid) throw new NotFoundException('Bid not found');
      if (bid.farmerId !== user.id) {
        throw new ForbiddenException('You can only accept bids on your own listings');
      }
      if (bid.auction.production.farmerId !== user.id) {
        throw new ForbiddenException('You can only accept bids on your own listings');
      }
      if (bid.status === BidStatus.accepted || bid.order) {
        throw new BadRequestException('This bid has already been accepted');
      }
      if (bid.status !== BidStatus.pending) {
        throw new BadRequestException('Only pending bids can be accepted');
      }

      const production = await tx.production.findUnique({
        where: { id: bid.productionId },
      });
      if (!production) throw new NotFoundException('Listing not found');
      if (bid.quantity > production.quantity) {
        throw new BadRequestException('Quantity exceeds available stock');
      }

      const remaining = production.quantity - bid.quantity;
      if (remaining < 0) {
        throw new BadRequestException('Quantity exceeds available stock');
      }

      await tx.bid.update({
        where: { id: bid.id },
        data: { status: BidStatus.accepted },
      });

      const soldOut = remaining <= 0;
      await tx.production.update({
        where: { id: production.id },
        data: {
          quantity: remaining,
          status: soldOut ? ProductionStatus.sold : production.status,
        },
      });

      if (soldOut) {
        await tx.auction.update({
          where: { id: bid.auctionId },
          data: { status: AuctionStatus.closed, closedAt: new Date() },
        });
        await tx.bid.updateMany({
          where: {
            productionId: production.id,
            status: BidStatus.pending,
            id: { not: bid.id },
          },
          data: { status: BidStatus.expired },
        });
      } else {
        await tx.bid.updateMany({
          where: {
            productionId: production.id,
            status: BidStatus.pending,
            quantity: { gt: remaining },
            id: { not: bid.id },
          },
          data: { status: BidStatus.expired },
        });
      }

      const farmer = await tx.farmerProfile.findUnique({
        where: { userId: production.farmerId },
      });
      const buyer = await tx.buyerProfile.findUnique({
        where: { userId: bid.buyerId },
      });

      let distanceKm = 18;
      if (farmer?.lat && farmer?.lng && buyer?.lat && buyer?.lng) {
        distanceKm = haversineKm(farmer.lat, farmer.lng, buyer.lat, buyer.lng);
      }

      const transportCost = estimatedTransportCost({
        distanceKm,
        quantityKg: bid.quantity,
        ratePerKm: 80,
        ratePerKg: 2,
        minimumFee: 1500,
      });

      const order = await tx.order.create({
        data: {
          auctionId: bid.auctionId,
          acceptedBidId: bid.id,
          productionId: production.id,
          farmerId: production.farmerId,
          buyerId: bid.buyerId,
          winningPriceKg: bid.amount,
          quantityKg: bid.quantity,
          status: OrderStatus.payment_pending,
          farmerConfirmed: true,
          buyerConfirmed: true,
          events: {
            create: {
              status: OrderStatus.payment_pending,
              actorId: user.id,
              action: 'BID_ACCEPTED',
              remarks: 'Farmer accepted the bid; order created',
            },
          },
          transportation: {
            create: {
              farmerLocation: production.location,
              buyerLocation: buyer?.location,
              distanceKm,
              quantityKg: bid.quantity,
              estimatedCost: transportCost,
              vehicleRequirement: bid.quantity > 1000 ? 'Lorry' : 'Pickup / van',
              deliveryDate: production.harvestDate,
            },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          actorId: user.id,
          action: 'BID_ACCEPTED',
          entityType: 'Bid',
          entityId: bid.id,
          metadata: JSON.stringify({ orderId: order.id, remaining }),
        },
      });

      return { orderId: order.id, remaining, soldOut, buyerId: bid.buyerId, cropType: production.cropType, quantity: bid.quantity };
    });

    await this.notifications.notify(
      result.buyerId,
      NotificationAudience.buyer,
      'Bid accepted',
      `Your bid for ${result.quantity} kg of ${result.cropType} was accepted. An order has been created.`,
    );
    await this.notifications.notify(
      user.id,
      NotificationAudience.farmer,
      'Order created',
      `Accepted bid for ${result.quantity} kg of ${result.cropType}.`,
    );

    const accepted = await this.prisma.bid.findUnique({
      where: { id: bidId },
      include: this.bidInclude,
    });
    return {
      bid: accepted ? this.serializeBid(accepted) : null,
      orderId: result.orderId,
      remainingQuantity: result.remaining,
      listingClosed: result.soldOut,
    };
  }

  async declineBid(user: SafeUser, bidId: string) {
    if (user.role !== UserRole.farmer) {
      throw new ForbiddenException('Only farmers can decline bids');
    }

    const bid = await this.prisma.bid.findUnique({
      where: { id: bidId },
      include: { auction: { include: { production: true } } },
    });
    if (!bid) throw new NotFoundException('Bid not found');
    if (bid.farmerId !== user.id || bid.auction.production.farmerId !== user.id) {
      throw new ForbiddenException('You can only decline bids on your own listings');
    }
    if (bid.status !== BidStatus.pending) {
      throw new BadRequestException('Only pending bids can be declined');
    }

    const updated = await this.prisma.bid.update({
      where: { id: bid.id },
      data: { status: BidStatus.declined },
      include: this.bidInclude,
    });

    await this.notifications.notify(
      bid.buyerId,
      NotificationAudience.buyer,
      'Bid declined',
      `The farmer declined your bid for ${bid.auction.production.cropType}.`,
    );

    await this.prisma.auditLog.create({
      data: {
        actorId: user.id,
        action: 'BID_DECLINED',
        entityType: 'Bid',
        entityId: bid.id,
      },
    });

    return this.serializeBid(updated);
  }

  async closeExpired() {
    const due = await this.prisma.auction.findMany({
      where: { status: AuctionStatus.open, endTime: { lte: new Date() } },
    });

    for (const auction of due) {
      await this.closeAuction(auction.id);
    }
  }

  async closeAuction(auctionId: string) {
    const auction = await this.prisma.auction.findUnique({
      where: { id: auctionId },
      include: {
        bids: true,
        production: true,
      },
    });
    if (!auction || auction.status !== AuctionStatus.open) return null;

    const pending = auction.bids.filter((b) => b.status === BidStatus.pending);
    const accepted = auction.bids.some((b) => b.status === BidStatus.accepted);

    await this.prisma.auction.update({
      where: { id: auctionId },
      data: {
        status: AuctionStatus.closed,
        closedAt: new Date(),
      },
    });

    if (!pending.length && !accepted) {
      await this.prisma.production.update({
        where: { id: auction.productionId },
        data: { status: ProductionStatus.expired },
      });
      await this.prisma.bid.updateMany({
        where: { auctionId, status: BidStatus.pending },
        data: { status: BidStatus.expired },
      });
      await this.notifications.notify(
        auction.production.farmerId,
        NotificationAudience.farmer,
        'listing_expired',
        'No pending bids remained when the window closed.',
      );
      return { closed: true, pendingReview: false };
    }

    await this.notifications.notify(
      auction.production.farmerId,
      NotificationAudience.farmer,
      'listing_closed_winner',
      'Bidding closed. Review remaining bids to accept or decline.',
    );
    return { closed: true, pendingReview: pending.length > 0 };
  }

  private bidInclude = {
    buyer: { select: { id: true, name: true, organizationName: true } },
    farmer: { select: { id: true, name: true } },
    auction: {
      include: {
        production: true,
      },
    },
    order: { select: { id: true, status: true } },
  };

  private serializeBid(bid: {
    id: string;
    productionId: string;
    auctionId: string;
    farmerId: string;
    buyerId: string;
    quantity: number;
    amount: number;
    totalAmount: number;
    status: BidStatus;
    createdAt: Date;
    buyer: { name: string | null; organizationName: string | null };
    auction: {
      endTime: Date;
      production: {
        cropType: string;
        listingCode: string | null;
        unit: string;
        quantity: number;
        imagesJson: string | null;
      };
    };
    order: { id: string; status: OrderStatus } | null;
  }) {
    return {
      id: bid.id,
      listingId: bid.productionId,
      productionId: bid.productionId,
      auctionId: bid.auctionId,
      farmerId: bid.farmerId,
      buyerId: bid.buyerId,
      buyerName: bid.buyer.organizationName ?? bid.buyer.name,
      cropType: bid.auction.production.cropType,
      listingCode: bid.auction.production.listingCode,
      cropImage: bid.auction.production.imagesJson,
      quantity: bid.quantity,
      unit: bid.auction.production.unit,
      amount: bid.amount,
      totalAmount: bid.totalAmount,
      status: bid.status,
      createdAt: bid.createdAt.toISOString(),
      biddingWindowEnd: bid.auction.endTime.toISOString(),
      availableQuantity: bid.auction.production.quantity,
      orderId: bid.order?.id ?? null,
      orderStatus: bid.order?.status ?? null,
    };
  }

  private serializeAuction(auction: {
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
      quantity: number;
      totalAmount: number;
      status: BidStatus;
      createdAt: Date;
      buyerId: string;
      buyer: { name: string | null; organizationName: string | null };
    }[];
    production: {
      cropType: string;
      listingCode: string | null;
      quantity: number;
      unit: string;
      farmerId: string;
    };
  },
    viewer?: SafeUser | null,
  ) {
    const isOwner = viewer?.id === auction.production.farmerId;
    const visibleBids = isOwner
      ? auction.bids
      : viewer?.role === UserRole.business
        ? auction.bids.filter((b) => b.buyerId === viewer.id)
        : [];
    const highest = auction.bids.reduce((m, b) => Math.max(m, b.amount), 0);
    return {
      id: auction.id,
      productionId: auction.productionId,
      listingCode: auction.production.listingCode,
      cropType: auction.production.cropType,
      quantityKg: auction.production.quantity,
      unit: auction.production.unit,
      openingBid: auction.openingBid,
      minBid: auction.minBid,
      minIncrement: auction.minIncrement,
      highestBid: highest || auction.openingBid,
      bidderCount: new Set(auction.bids.map((b) => b.buyerId)).size,
      startTime: auction.startTime.toISOString(),
      endTime: auction.endTime.toISOString(),
      status: auction.status,
      winningBidId: isOwner ? auction.winningBidId : null,
      history: visibleBids.map((b) => ({
        id: b.id,
        buyerId: b.buyerId,
        buyerName: b.buyer.organizationName ?? b.buyer.name,
        quantity: b.quantity,
        amount: b.amount,
        totalAmount: b.totalAmount,
        status: b.status,
        createdAt: b.createdAt.toISOString(),
      })),
    };
  }
}
