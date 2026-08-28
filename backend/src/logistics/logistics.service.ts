import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  DeliveryMethod,
  NotificationAudience,
  OrderStatus,
  PaymentStatus,
  TransportStatus,
  UserRole,
  VehicleType,
} from '@prisma/client';
import {
  computeTransportQuote,
  haversineKm,
  requiredVehicleType,
  vehicleCapacityKg,
  vehicleMeetsCapacity,
} from '../common/calculations';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { SafeUser } from '../common/types';
import {
  ConfirmDeliveryDto,
  ConfirmTransportDto,
  CreateAddressDto,
  CreateDisputeDto,
  CreateTransportRequestDto,
  HandoverDto,
  PricingRuleDto,
  RateTransporterDto,
  TrackingUpdateDto,
} from './dto/logistics.dto';

const OPEN_JOBS: TransportStatus[] = [
  TransportStatus.requested,
  TransportStatus.matching,
];

@Injectable()
export class LogisticsService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  async listAddresses(buyerId: string) {
    return this.prisma.deliveryAddress.findMany({
      where: { buyerId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createAddress(buyerId: string, dto: CreateAddressDto) {
    return this.prisma.deliveryAddress.create({
      data: { ...dto, buyerId, isDefault: true },
    });
  }

  async quote(orderId: string, deliveryLat?: number, deliveryLng?: number) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { transportation: true },
    });
    if (!order) throw new NotFoundException('Order not found');

    const farmer = await this.prisma.farmerProfile.findUnique({
      where: { userId: order.farmerId },
    });
    const production = await this.prisma.production.findUnique({
      where: { id: order.productionId },
    });

    const pickupLat = farmer?.lat ?? 7.4863;
    const pickupLng = farmer?.lng ?? 80.3623;
    const dLat = deliveryLat ?? 6.9271;
    const dLng = deliveryLng ?? 79.8612;
    const distanceKm = haversineKm(pickupLat, pickupLng, dLat, dLng);
    const vehicle = requiredVehicleType(order.quantityKg);
    const rule = await this.getRule(vehicle as VehicleType);
    const estimatedCost = computeTransportQuote({
      distanceKm,
      quantityKg: order.quantityKg,
      baseCharge: rule.baseCharge,
      perKm: rule.perKm,
      perKg: rule.perKg,
      loadingFee: rule.loadingFee,
      fuelSurchargePercent: rule.fuelSurchargePercent,
    });

    return {
      orderId,
      product: production?.cropType ?? 'Produce',
      quantityKg: order.quantityKg,
      pickup: {
        label: production?.location ?? farmer?.farmLocation ?? 'Farm',
        city: production?.region ?? 'Kurunegala',
        lat: pickupLat,
        lng: pickupLng,
      },
      distanceKm,
      requiredVehicleType: vehicle,
      requiredCapacityKg: vehicleCapacityKg(vehicle),
      estimatedCost,
      productTotal: order.winningPriceKg * order.quantityKg,
    };
  }

  async createRequest(user: SafeUser, dto: CreateTransportRequestDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: dto.orderId },
      include: { transportation: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (order.buyerId !== user.id) throw new ForbiddenException();
    if (
      order.status !== OrderStatus.delivery_required &&
      order.status !== OrderStatus.paid
    ) {
      throw new BadRequestException('Order is not awaiting delivery');
    }

    const existing = await this.prisma.transportRequest.findFirst({
      where: {
        orderId: order.id,
        status: { not: TransportStatus.cancelled },
      },
    });
    if (existing) {
      throw new BadRequestException('A transport request already exists for this order');
    }

    if (dto.deliveryMethod === DeliveryMethod.own_transport) {
      const code = await this.nextCode();
      const request = await this.prisma.transportRequest.create({
        data: {
          requestCode: code,
          orderId: order.id,
          buyerId: order.buyerId,
          farmerId: order.farmerId,
          pickupLabel: order.transportation?.farmerLocation ?? 'Farm',
          pickupCity: 'Farm',
          deliveryLabel: 'Buyer arranged',
          deliveryCity: 'Own transport',
          product: 'Produce',
          quantityKg: order.quantityKg,
          requiredVehicleType: requiredVehicleType(order.quantityKg) as VehicleType,
          requiredCapacityKg: order.quantityKg,
          distanceKm: order.transportation?.distanceKm ?? 0,
          estimatedCost: 0,
          deliveryMethod: DeliveryMethod.own_transport,
          status: TransportStatus.completed,
        },
      });
      await this.track(request.id, TransportStatus.completed, user.id, 'Own transport selected');
      return request;
    }

    const q = await this.quote(order.id);
    let address = dto.deliveryAddressId
      ? await this.prisma.deliveryAddress.findUnique({
          where: { id: dto.deliveryAddressId },
        })
      : null;
    if (address && address.buyerId !== user.id) throw new ForbiddenException();

    const code = await this.nextCode();
    const request = await this.prisma.transportRequest.create({
      data: {
        requestCode: code,
        orderId: order.id,
        buyerId: order.buyerId,
        farmerId: order.farmerId,
        deliveryAddressId: address?.id,
        pickupLabel: q.pickup.label,
        pickupCity: q.pickup.city,
        pickupLat: q.pickup.lat,
        pickupLng: q.pickup.lng,
        deliveryLabel: address
          ? `${address.businessName}, ${address.address}`
          : 'Buyer location',
        deliveryCity: address?.city ?? 'Colombo',
        deliveryLat: address?.latitude ?? 6.9271,
        deliveryLng: address?.longitude ?? 79.8612,
        product: q.product,
        quantityKg: order.quantityKg,
        requiredVehicleType: q.requiredVehicleType as VehicleType,
        requiredCapacityKg: q.requiredCapacityKg,
        preferredPickupDate: dto.preferredPickupDate
          ? new Date(dto.preferredPickupDate)
          : undefined,
        preferredPickupTime: dto.preferredPickupTime,
        distanceKm: q.distanceKm,
        estimatedCost: q.estimatedCost,
        status: TransportStatus.matching,
      },
    });

    await this.track(request.id, TransportStatus.requested, user.id, 'Transport requested');
    await this.track(request.id, TransportStatus.matching, user.id, 'Matching transporters');

    await this.notifications.notify(
      order.buyerId,
      NotificationAudience.buyer,
      'Transport request created',
      `${code} is looking for a suitable lorry.`,
    );
    await this.notifications.notify(
      order.farmerId,
      NotificationAudience.farmer,
      'Delivery arranged',
      `Buyer requested Bit App transport for your order.`,
    );

    await this.prisma.auditLog.create({
      data: {
        actorId: user.id,
        action: 'TRANSPORT_REQUESTED',
        entityType: 'TransportRequest',
        entityId: request.id,
        metadata: JSON.stringify({ code, orderId: order.id }),
      },
    });

    return this.getRequest(user, request.id);
  }

  async match(user: SafeUser, requestId: string) {
    const request = await this.mustGetRequest(requestId);
    this.assertParty(user, request);

    const transporters = await this.prisma.transporterProfile.findMany({
      where: { availabilityStatus: 'available' },
      include: { vehicles: true, user: true },
    });

    const scored = transporters
      .map((t) => {
        const vehicle = t.vehicles.find(
          (v) =>
            v.status === 'active' &&
            vehicleMeetsCapacity(v.vehicleType as never, request.quantityKg),
        );
        if (!vehicle) return null;
        const dist =
          t.lat != null && t.lng != null && request.pickupLat != null && request.pickupLng != null
            ? haversineKm(t.lat, t.lng, request.pickupLat, request.pickupLng)
            : 40;
        const score = t.rating * 20 - dist + (vehicle.capacityKg >= request.quantityKg * 1.2 ? 5 : 0);
        return {
          transporterId: t.userId,
          name: t.user.name,
          company: t.company,
          rating: t.rating,
          phone: t.user.phone,
          vehicle: {
            id: vehicle.id,
            number: vehicle.vehicleNumber,
            type: vehicle.vehicleType,
            capacityKg: vehicle.capacityKg,
          },
          distanceToPickupKm: dist,
          estimatedCost: request.estimatedCost,
          score,
        };
      })
      .filter((x): x is NonNullable<typeof x> => x != null)
      .sort((a, b) => b.score - a.score);

    return { requestId, matches: scored };
  }

  async availableJobs(user: SafeUser) {
    if (user.role !== UserRole.transporter) throw new ForbiddenException();
    const profile = await this.prisma.transporterProfile.findUnique({
      where: { userId: user.id },
      include: { vehicles: true },
    });
    if (!profile) throw new ForbiddenException();

    const jobs = await this.prisma.transportRequest.findMany({
      where: {
        status: { in: OPEN_JOBS },
        deliveryMethod: DeliveryMethod.bit_app_transport,
      },
      include: { order: true },
      orderBy: { createdAt: 'desc' },
    });

    return jobs.filter((job) =>
      profile.vehicles.some(
        (v) =>
          v.status === 'active' &&
          vehicleMeetsCapacity(v.vehicleType as never, job.quantityKg),
      ),
    );
  }

  async myJobs(user: SafeUser) {
    if (user.role !== UserRole.transporter) throw new ForbiddenException();
    return this.prisma.transportRequest.findMany({
      where: { transporterId: user.id },
      include: { order: true, vehicle: true, tracking: { orderBy: { createdAt: 'asc' } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async acceptJob(user: SafeUser, requestId: string) {
    if (user.role !== UserRole.transporter) throw new ForbiddenException();
    const request = await this.mustGetRequest(requestId);
    if (!OPEN_JOBS.includes(request.status)) {
      throw new BadRequestException('Job is no longer available');
    }
    if (request.transporterId) {
      throw new BadRequestException('Job already assigned');
    }

    const profile = await this.prisma.transporterProfile.findUnique({
      where: { userId: user.id },
      include: { vehicles: true, user: true },
    });
    const vehicle = profile?.vehicles.find(
      (v) =>
        v.status === 'active' &&
        vehicleMeetsCapacity(v.vehicleType as never, request.quantityKg),
    );
    if (!vehicle) {
      throw new BadRequestException('Vehicle capacity is insufficient for this load');
    }

    const updated = await this.prisma.transportRequest.update({
      where: { id: requestId },
      data: {
        transporterId: user.id,
        vehicleId: vehicle.id,
        driverName: profile?.user.name,
        status: TransportStatus.accepted,
      },
    });

    await this.track(requestId, TransportStatus.assigned, user.id, 'Transporter assigned');
    await this.track(requestId, TransportStatus.accepted, user.id, 'Job accepted');
    await this.track(requestId, TransportStatus.waiting_pickup, user.id, 'Waiting for pickup');

    await this.prisma.transportRequest.update({
      where: { id: requestId },
      data: { status: TransportStatus.waiting_pickup },
    });

    await this.notifications.notify(
      request.buyerId,
      NotificationAudience.buyer,
      'Transporter accepted',
      `${profile?.company ?? 'A transporter'} accepted ${request.requestCode}. Confirm to proceed.`,
    );
    await this.notifications.notify(
      request.farmerId,
      NotificationAudience.farmer,
      'Transporter assigned',
      `Vehicle ${vehicle.vehicleNumber} will collect your produce.`,
    );
    await this.notifications.notify(
      user.id,
      NotificationAudience.transporter,
      'Job accepted',
      `You accepted ${request.requestCode}. Head to pickup when ready.`,
    );

    return updated;
  }

  async confirmTransport(user: SafeUser, requestId: string, dto: ConfirmTransportDto) {
    const request = await this.mustGetRequest(requestId);
    if (request.buyerId !== user.id) throw new ForbiddenException();
    if (!request.transporterId) {
      throw new BadRequestException('No transporter has accepted this job yet');
    }
    if (dto.transporterId !== request.transporterId) {
      throw new BadRequestException('Selected transporter does not match the assigned job');
    }
    if (await this.prisma.transportPayment.findUnique({ where: { transportRequestId: requestId } })) {
      throw new BadRequestException('Transport payment already recorded');
    }

    const payment = await this.prisma.transportPayment.create({
      data: {
        transportRequestId: requestId,
        buyerId: request.buyerId,
        transporterId: request.transporterId,
        amount: request.estimatedCost,
        paymentMethod: dto.paymentMethod ?? 'card',
        paymentStatus: PaymentStatus.paid,
        reference: `TRPAY-${Date.now()}`,
        paidAt: new Date(),
      },
    });

    await this.prisma.auditLog.create({
      data: {
        actorId: user.id,
        action: 'TRANSPORT_PAYMENT',
        entityType: 'TransportPayment',
        entityId: payment.id,
        metadata: JSON.stringify({ amount: payment.amount, method: payment.paymentMethod }),
      },
    });

    await this.notifications.notify(
      request.transporterId,
      NotificationAudience.transporter,
      'Transport confirmed',
      'Buyer confirmed and paid the transport fee. Proceed to farm pickup.',
    );

    return { request, payment };
  }

  async updateStatus(user: SafeUser, requestId: string, dto: TrackingUpdateDto) {
    const request = await this.mustGetRequest(requestId);
    const isTransporter = request.transporterId === user.id;
    const isFarmer = request.farmerId === user.id;
    const isAdmin = user.role === UserRole.government;
    if (!isTransporter && !isFarmer && !isAdmin) throw new ForbiddenException();

    const updated = await this.prisma.transportRequest.update({
      where: { id: requestId },
      data: { status: dto.status },
    });
    await this.track(requestId, dto.status, user.id, dto.note, dto.latitude, dto.longitude);

    if (dto.status === TransportStatus.in_transit) {
      await this.prisma.order.update({
        where: { id: request.orderId },
        data: {
          status: OrderStatus.in_transit,
          events: {
            create: {
              status: OrderStatus.in_transit,
              actorId: user.id,
              action: 'IN_TRANSIT',
            },
          },
        },
      });
      await this.notifications.notify(
        request.buyerId,
        NotificationAudience.buyer,
        'Delivery in progress',
        'Your produce has left the farm.',
      );
    }

    if (dto.status === TransportStatus.arrived_at_destination) {
      await this.notifications.notify(
        request.buyerId,
        NotificationAudience.buyer,
        'Your order has arrived',
        'Please verify quantity and condition, then confirm delivery.',
      );
    }

    return updated;
  }

  async farmerHandover(user: SafeUser, requestId: string, dto: HandoverDto) {
    const request = await this.mustGetRequest(requestId);
    if (request.farmerId !== user.id) throw new ForbiddenException();

    await this.prisma.transportRequest.update({
      where: { id: requestId },
      data: { status: TransportStatus.loaded },
    });
    await this.track(
      requestId,
      TransportStatus.loaded,
      user.id,
      `Products handed over: ${dto.quantityKg} kg`,
      request.pickupLat ?? undefined,
      request.pickupLng ?? undefined,
    );
    await this.notifications.notify(
      request.buyerId,
      NotificationAudience.buyer,
      'Products picked up',
      'The farmer confirmed handover to the transporter.',
    );
    if (request.transporterId) {
      await this.notifications.notify(
        request.transporterId,
        NotificationAudience.transporter,
        'Pickup confirmed',
        'Proceed to the buyer location.',
      );
    }
    return this.getRequest(user, requestId);
  }

  async confirmDelivery(user: SafeUser, requestId: string, dto: ConfirmDeliveryDto) {
    const request = await this.mustGetRequest(requestId);
    if (request.buyerId !== user.id) throw new ForbiddenException();

    const missing = request.quantityKg - dto.deliveredQuantityKg;
    const full = missing <= 0.01;

    await this.prisma.deliveryProof.create({
      data: {
        transportRequestId: requestId,
        orderedQuantityKg: request.quantityKg,
        deliveredQuantityKg: dto.deliveredQuantityKg,
        receivedBy: dto.receivedBy,
        signature: dto.signature,
        photoUrl: dto.photoUrl,
        otp: dto.otp,
        notes: dto.notes,
      },
    });

    await this.prisma.transportRequest.update({
      where: { id: requestId },
      data: {
        status: full ? TransportStatus.completed : TransportStatus.delivered,
      },
    });
    await this.track(requestId, TransportStatus.delivered, user.id, 'Buyer received goods');
    if (full) {
      await this.track(requestId, TransportStatus.buyer_confirmed, user.id, 'Buyer confirmed');
      await this.track(requestId, TransportStatus.completed, user.id, 'Completed');
      await this.prisma.order.update({
        where: { id: request.orderId },
        data: {
          status: OrderStatus.completed,
          events: {
            create: {
              status: OrderStatus.completed,
              actorId: user.id,
              action: 'DELIVERY_CONFIRMED',
            },
          },
        },
      });
    } else {
      await this.prisma.order.update({
        where: { id: request.orderId },
        data: { status: OrderStatus.disputed },
      });
    }

    await this.notifications.notify(
      request.farmerId,
      NotificationAudience.farmer,
      'Delivery completed',
      full ? 'Buyer confirmed full delivery.' : 'Buyer reported a partial delivery.',
    );

    return this.getRequest(user, requestId);
  }

  async createDispute(user: SafeUser, requestId: string, dto: CreateDisputeDto) {
    const request = await this.mustGetRequest(requestId);
    if (request.buyerId !== user.id) throw new ForbiddenException();

    const dispute = await this.prisma.deliveryDispute.create({
      data: {
        orderId: request.orderId,
        transportRequestId: requestId,
        disputeType: dto.disputeType,
        quantityKg: dto.quantityKg,
        description: dto.description,
        evidenceUrl: dto.evidenceUrl,
        buyerRemarks: dto.buyerRemarks,
      },
    });

    await this.prisma.order.update({
      where: { id: request.orderId },
      data: { status: OrderStatus.disputed },
    });

    return dispute;
  }

  async rate(user: SafeUser, requestId: string, dto: RateTransporterDto) {
    const request = await this.mustGetRequest(requestId);
    if (request.buyerId !== user.id) throw new ForbiddenException();
    if (!request.transporterId) throw new BadRequestException('No transporter to rate');

    const review = await this.prisma.review.create({
      data: {
        reviewerId: user.id,
        revieweeId: request.transporterId,
        orderId: request.orderId,
        rating: dto.rating,
        comment: dto.comment,
      },
    });

    const reviews = await this.prisma.review.findMany({
      where: { revieweeId: request.transporterId },
    });
    const avg = reviews.reduce((s, r) => s + r.rating, 0) / reviews.length;
    await this.prisma.transporterProfile.update({
      where: { userId: request.transporterId },
      data: { rating: Math.round(avg * 10) / 10 },
    });
    return review;
  }

  async listRequests(user: SafeUser) {
    const where =
      user.role === UserRole.farmer
        ? { farmerId: user.id }
        : user.role === UserRole.business
          ? { buyerId: user.id }
          : user.role === UserRole.transporter
            ? { transporterId: user.id }
            : {};
    return this.prisma.transportRequest.findMany({
      where,
      include: {
        vehicle: true,
        payment: true,
        proof: true,
        tracking: { orderBy: { createdAt: 'asc' } },
        disputes: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getRequest(user: SafeUser, id: string) {
    const request = await this.prisma.transportRequest.findUnique({
      where: { id },
      include: {
        vehicle: true,
        payment: true,
        proof: true,
        tracking: { orderBy: { createdAt: 'asc' } },
        disputes: true,
        deliveryAddress: true,
        order: true,
      },
    });
    if (!request) throw new NotFoundException('Transport request not found');
    this.assertParty(user, request);
    return request;
  }

  async adminOverview() {
    const [requests, disputes, payments, rules] = await Promise.all([
      this.prisma.transportRequest.count(),
      this.prisma.deliveryDispute.findMany({ orderBy: { createdAt: 'desc' } }),
      this.prisma.transportPayment.findMany({ orderBy: { createdAt: 'desc' } }),
      this.prisma.transportPricingRule.findMany(),
    ]);
    const active = await this.prisma.transportRequest.findMany({
      where: {
        status: {
          in: [
            TransportStatus.waiting_pickup,
            TransportStatus.arrived_at_pickup,
            TransportStatus.loaded,
            TransportStatus.in_transit,
            TransportStatus.arrived_at_destination,
          ],
        },
      },
    });
    return { requestCount: requests, active, disputes, payments, rules };
  }

  async upsertPricing(dto: PricingRuleDto) {
    return this.prisma.transportPricingRule.upsert({
      where: { vehicleType: dto.vehicleType },
      create: dto,
      update: dto,
    });
  }

  async resolveDispute(id: string, status: 'resolved' | 'rejected', remarks?: string) {
    return this.prisma.deliveryDispute.update({
      where: { id },
      data: { status, adminRemarks: remarks },
    });
  }

  async earnings(user: SafeUser) {
    if (user.role !== UserRole.transporter) throw new ForbiddenException();
    const payments = await this.prisma.transportPayment.findMany({
      where: { transporterId: user.id, paymentStatus: PaymentStatus.paid },
    });
    return {
      completedJobs: payments.length,
      totalLkr: payments.reduce((s, p) => s + p.amount, 0),
      payments,
    };
  }

  private async getRule(vehicleType: VehicleType) {
    const rule = await this.prisma.transportPricingRule.findUnique({
      where: { vehicleType },
    });
    if (rule) return rule;
    return {
      baseCharge: 2500,
      perKm: 45,
      perKg: 2,
      loadingFee: 500,
      fuelSurchargePercent: 5,
    };
  }

  private async nextCode() {
    const year = new Date().getFullYear();
    const seq = await this.prisma.transportSequence.upsert({
      where: { year },
      create: { year, lastNumber: 1 },
      update: { lastNumber: { increment: 1 } },
    });
    return `TR-${String(seq.lastNumber).padStart(6, '0')}`;
  }

  private async track(
    transportRequestId: string,
    status: TransportStatus,
    actorId?: string,
    note?: string,
    latitude?: number,
    longitude?: number,
  ) {
    await this.prisma.deliveryTracking.create({
      data: { transportRequestId, status, actorId, note, latitude, longitude },
    });
  }

  private async mustGetRequest(id: string) {
    const request = await this.prisma.transportRequest.findUnique({ where: { id } });
    if (!request) throw new NotFoundException('Transport request not found');
    return request;
  }

  private assertParty(
    user: SafeUser,
    request: { buyerId: string; farmerId: string; transporterId: string | null },
  ) {
    if (user.role === UserRole.government) return;
    if (
      request.buyerId !== user.id &&
      request.farmerId !== user.id &&
      request.transporterId !== user.id
    ) {
      throw new ForbiddenException();
    }
  }
}
