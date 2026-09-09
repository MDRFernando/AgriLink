import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  NotificationAudience,
  OrderStatus,
  PaymentStatus,
  ProductionStatus,
  UserRole,
} from '@prisma/client';
import {
  grossRevenue,
  incomeImprovement,
  incomeImprovementPercent,
  intermediaryDependencyIndex,
  netFarmerIncome,
} from '../common/calculations';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { SafeUser } from '../common/types';

const FLOW: Record<string, OrderStatus> = {
  farmer_confirm: OrderStatus.pending_buyer,
  buyer_confirm: OrderStatus.payment_pending,
};

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  async listMine(user: SafeUser) {
    const where =
      user.role === UserRole.farmer
        ? { farmerId: user.id }
        : user.role === UserRole.business
          ? { buyerId: user.id }
          : { id: '__none__' };
    return this.prisma.order.findMany({
      where,
      include: {
        transportation: true,
        payment: true,
        events: { orderBy: { createdAt: 'asc' } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getOne(user: SafeUser, id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: {
        transportation: true,
        payment: true,
        events: { orderBy: { createdAt: 'asc' } },
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (user.role === UserRole.government) {
      throw new ForbiddenException();
    }
    if (order.farmerId !== user.id && order.buyerId !== user.id) {
      throw new ForbiddenException();
    }
    return this.withIncome(order);
  }

  async confirm(user: SafeUser, id: string) {
    const order = await this.prisma.order.findUnique({ where: { id } });
    if (!order) throw new NotFoundException('Order not found');

    if (user.id === order.farmerId && !order.farmerConfirmed) {
      const updated = await this.prisma.order.update({
        where: { id },
        data: {
          farmerConfirmed: true,
          status: OrderStatus.pending_buyer,
          events: {
            create: {
              status: OrderStatus.pending_buyer,
              actorId: user.id,
              action: 'FARMER_CONFIRM',
            },
          },
        },
      });
      await this.prisma.production.update({
        where: { id: order.productionId },
        data: { status: ProductionStatus.sold },
      });
      await this.notifications.notify(
        order.buyerId,
        NotificationAudience.buyer,
        'Farmer confirmed',
        'Please confirm the order to proceed to payment.',
      );
      return updated;

    if (user.id === order.buyerId && order.farmerConfirmed && !order.buyerConfirmed) {
      const updated = await this.prisma.order.update({
        where: { id },
        data: {
          buyerConfirmed: true,
          status: OrderStatus.payment_pending,
          events: {
            create: {
              status: OrderStatus.payment_pending,
              actorId: user.id,
              action: 'BUYER_CONFIRM',
            },
          },
        },
      });
      await this.notifications.notify(
        order.farmerId,
        NotificationAudience.farmer,
        'Buyer confirmed',
        'Awaiting sandbox payment.',
      );
      return updated;
    }

    throw new BadRequestException('Confirmation not applicable in current state');
  }

  async decline(user: SafeUser, id: string) {
    const order = await this.prisma.order.findUnique({ where: { id } });
    if (!order) throw new NotFoundException('Order not found');
    if (user.id !== order.farmerId) throw new ForbiddenException();
    if (order.farmerConfirmed) {
      throw new BadRequestException('Order already confirmed');
    }

    const updated = await this.prisma.order.update({
      where: { id },
      data: {
        status: OrderStatus.cancelled,
        events: {
          create: {
            status: OrderStatus.cancelled,
            actorId: user.id,
            action: 'FARMER_DECLINE',
          },
        },
      },
    });
    await this.prisma.production.update({
      where: { id: order.productionId },
      data: { status: ProductionStatus.available },
    });
    await this.notifications.notify(
      order.buyerId,
      NotificationAudience.buyer,
      'Bid declined',
      'The farmer declined the winning bid.',
    );
    return updated;
  }

  async sandboxPay(user: SafeUser, id: string, succeed = true, method = 'card') {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: { transportation: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (order.buyerId !== user.id) throw new ForbiddenException();
    if (order.status !== OrderStatus.payment_pending) {
      throw new BadRequestException('Order is not awaiting payment');
    }
    if (await this.prisma.payment.findUnique({ where: { orderId: id } })) {
      throw new BadRequestException('Payment already recorded for this order');
    }

    const amount = grossRevenue(order.winningPriceKg, order.quantityKg);
    const reference = `PAY-SANDBOX-${Date.now()}`;
    const status = succeed
      ? PaymentStatus.sandbox_success
      : PaymentStatus.sandbox_failed;

    const payment = await this.prisma.payment.create({
      data: {
        orderId: id,
        buyerId: order.buyerId,
        farmerId: order.farmerId,
        amount,
        status,
        reference,
        paidAt: succeed ? new Date() : null,
        receiptNote: `SANDBOX PRODUCT PAYMENT (${method}) — not a real money transfer.`,
      },
    });

    if (succeed) {
      await this.prisma.order.update({
        where: { id },
        data: {
          status: OrderStatus.delivery_required,
          events: {
            create: {
              status: OrderStatus.delivery_required,
              actorId: user.id,
              action: 'PRODUCT_PAID',
              remarks: `${reference} via ${method}`,
            },
          },
        },
      });
      await this.notifications.notify(
        order.farmerId,
        NotificationAudience.farmer,
        'Payment confirmed',
        `Order paid. Awaiting delivery arrangement. Ref ${reference}`,
      );
      await this.notifications.notify(
        order.buyerId,
        NotificationAudience.buyer,
        'Payment successful',
        'Your products are ready to be delivered.',
      );
    }

    return payment;
  }

  async advanceDelivery(user: SafeUser, id: string) {
    const order = await this.prisma.order.findUnique({ where: { id } });
    if (!order) throw new NotFoundException('Order not found');
    if (order.farmerId !== user.id && user.role !== UserRole.government) {
      throw new ForbiddenException();
    }

    const next =
      order.status === OrderStatus.paid
        ? OrderStatus.in_transit
        : order.status === OrderStatus.in_transit
          ? OrderStatus.delivered
          : order.status === OrderStatus.delivered
            ? OrderStatus.completed
            : null;
    if (!next) throw new BadRequestException('Cannot advance delivery from current status');

    return this.prisma.order.update({
      where: { id },
      data: {
        status: next,
        events: {
          create: {
            status: next,
            actorId: user.id,
            action: 'STATUS_ADVANCE',
          },
        },
      },
    });
  }

  async incomeImpact(user: SafeUser, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { transportation: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (user.role === UserRole.government) {
      throw new ForbiddenException();
    }
    if (order.farmerId !== user.id && order.buyerId !== user.id) {
      throw new ForbiddenException();
    }

    const profile = await this.prisma.farmerProfile.findUnique({
      where: { userId: order.farmerId },
    });

    const traditionalPrice = profile?.traditionalFarmgatePriceKg ?? null;
    if (traditionalPrice == null) {
      return {
        dataComplete: false,
        message:
          'Traditional farmgate price is missing (farmer self-report). Income impact is not fabricated.',
      };
    }

    const harvest = (profile?.harvestingCostPerKg ?? 0) * order.quantityKg;
    const transport = order.transportation?.estimatedCost ?? 0;
    const traditionalGross = grossRevenue(traditionalPrice, order.quantityKg);
    const bitGross = grossRevenue(order.winningPriceKg, order.quantityKg);
    const traditionalNet = netFarmerIncome({
      winningBidPricePerKg: traditionalPrice,
      quantityKg: order.quantityKg,
      transportationCost: 0,
      harvestingCost: harvest,
      platformCharges: 0,
      otherCosts: 0,
    });
    const bitNet = netFarmerIncome({
      winningBidPricePerKg: order.winningPriceKg,
      quantityKg: order.quantityKg,
      transportationCost: transport,
      harvestingCost: harvest,
      platformCharges: 0,
      otherCosts: 0,
    });

    return {
      dataComplete: true,
      source: {
        traditionalPrice: 'FARMER_SELF_REPORT',
        bitAppPrice: 'TRANSACTION_DERIVED',
        transport: 'MODELLED_FROM_DISTANCE',
      },
      traditionalSellingPrice: traditionalPrice,
      bitAppSellingPrice: order.winningPriceKg,
      quantityKg: order.quantityKg,
      traditionalRevenue: traditionalGross,
      bitAppRevenue: bitGross,
      transportationCost: transport,
      harvestingCost: harvest,
      traditionalNetIncome: traditionalNet,
      bitAppNetIncome: bitNet,
      incomeDifference: incomeImprovement(bitNet, traditionalNet),
      incomeImprovementPercent: incomeImprovementPercent(bitNet, traditionalNet),
    };
  }

  async intermediaryIndex() {
    const completed = await this.prisma.order.findMany({
      where: { status: { in: [OrderStatus.completed, OrderStatus.delivered, OrderStatus.paid] } },
    });
    const directValue = completed.reduce(
      (s, o) => s + grossRevenue(o.winningPriceKg, o.quantityKg),
      0,
    );
    const observations = await this.prisma.researchObservation.findMany({
      where: { usedIntermediary: true },
    });
    const intermediaryValue = observations.reduce((s, o) => {
      const q = o.quantityKg ?? 0;
      const p = o.traditionalPriceKg ?? 0;
      return s + q * p;
    }, 0);

    return {
      formula:
        'IDI = intermediaryChannelValue / (intermediaryChannelValue + directBitAppValue)',
      intermediaryChannelValue: intermediaryValue,
      directBitAppValue: directValue,
      index: intermediaryDependencyIndex(intermediaryValue, directValue),
      completedDirectOrders: completed.length,
      intermediaryObservations: observations.length,
      note: 'Index is null until both channels have measurable value. No fabricated margins.',
    };
  }

  private withIncome(order: {
    winningPriceKg: number;
    quantityKg: number;
    transportation: { estimatedCost: number } | null;
  }) {
    const gross = grossRevenue(order.winningPriceKg, order.quantityKg);
    const transport = order.transportation?.estimatedCost ?? 0;
    return {
      ...order,
      winningBidValue: gross,
      transportationCost: transport,
      estimatedNetFarmerIncome: netFarmerIncome({
        winningBidPricePerKg: order.winningPriceKg,
        quantityKg: order.quantityKg,
        transportationCost: transport,
        harvestingCost: 0,
        platformCharges: 0,
        otherCosts: 0,
      }),
    };
  }
}
