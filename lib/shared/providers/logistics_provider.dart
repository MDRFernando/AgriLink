import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class LogisticsState {
  const LogisticsState({
    required this.orders,
    required this.addresses,
    required this.jobs,
    required this.transporters,
    required this.issues,
    required this.notifications,
    required this.pricingRules,
  });

  final List<MarketOrder> orders;
  final List<DeliveryAddress> addresses;
  final List<TransportJob> jobs;
  final List<TransporterOption> transporters;
  final List<DeliveryIssue> issues;
  final List<AppNotificationItem> notifications;
  final List<TransportPricingRule> pricingRules;

  LogisticsState copyWith({
    List<MarketOrder>? orders,
    List<DeliveryAddress>? addresses,
    List<TransportJob>? jobs,
    List<TransporterOption>? transporters,
    List<DeliveryIssue>? issues,
    List<AppNotificationItem>? notifications,
    List<TransportPricingRule>? pricingRules,
  }) {
    return LogisticsState(
      orders: orders ?? this.orders,
      addresses: addresses ?? this.addresses,
      jobs: jobs ?? this.jobs,
      transporters: transporters ?? this.transporters,
      issues: issues ?? this.issues,
      notifications: notifications ?? this.notifications,
      pricingRules: pricingRules ?? this.pricingRules,
    );
  }
}

VehicleType requiredVehicleFor(double kg) {
  if (kg <= 400) return VehicleType.pickup;
  if (kg <= 1500) return VehicleType.smallLorry;
  if (kg <= 5000) return VehicleType.mediumLorry;
  return VehicleType.largeLorry;
}

double quoteTransport({
  required double distanceKm,
  required double quantityKg,
  required VehicleType vehicle,
  List<TransportPricingRule>? rules,
}) {
  final rule = (rules ?? defaultPricingRules).firstWhere(
    (r) => r.vehicleType == vehicle,
    orElse: () => defaultPricingRules.first,
  );
  final raw = rule.baseCharge +
      distanceKm * rule.perKm +
      quantityKg * rule.perKg +
      rule.loadingFee;
  return ((raw * (1 + rule.fuelSurchargePercent / 100)) * 100).round() / 100;
}

const defaultPricingRules = [
  TransportPricingRule(vehicleType: VehicleType.pickup, baseCharge: 1500, perKm: 35, perKg: 3),
  TransportPricingRule(vehicleType: VehicleType.smallLorry, baseCharge: 2500, perKm: 40, perKg: 2),
  TransportPricingRule(vehicleType: VehicleType.mediumLorry, baseCharge: 3500, perKm: 45, perKg: 1.5),
  TransportPricingRule(vehicleType: VehicleType.largeLorry, baseCharge: 5000, perKm: 55, perKg: 1),
];

class LogisticsNotifier extends StateNotifier<LogisticsState> {
  LogisticsNotifier() : super(_seed());

  static LogisticsState _seed() {
    const banana = MarketOrder(
      id: 'ord-5421',
      code: 'ORD-005421',
      buyerId: 'business-demo',
      farmerId: 'farmer-sunil',
      farmerName: 'Sunil Perera',
      buyerName: 'ABC Supermarket',
      product: 'Banana',
      quantityKg: 500,
      unitPrice: 180,
      orderStatus: OrderStatus.deliveryRequired,
      productPaymentStatus: PaymentRecordStatus.paid,
      pickupLabel: "Sunil Perera's Farm",
      pickupCity: 'Kurunegala',
    );

    const address = DeliveryAddress(
      id: 'addr-abc',
      buyerId: 'business-demo',
      businessName: 'ABC Supermarket',
      contactPerson: 'Nimal Jayasuriya',
      phone: '0771239876',
      address: '123 Main Street, Colombo',
      city: 'Colombo',
      instructions: 'Unload at the rear goods bay.',
    );

    const transporters = [
      TransporterOption(
        id: 'transporter-demo',
        name: 'Ruwan Fernando',
        company: 'ABC Logistics',
        phone: '0777771111',
        vehicleNumber: 'NW-1234',
        vehicleType: VehicleType.mediumLorry,
        capacityKg: 5000,
        rating: 4.8,
        distanceToPickupKm: 12,
        driverName: 'Ruwan Fernando',
      ),
      TransporterOption(
        id: 'transporter-2',
        name: 'Saman Perera',
        company: 'GreenHaul Lanka',
        phone: '0777772222',
        vehicleNumber: 'WP-8890',
        vehicleType: VehicleType.smallLorry,
        capacityKg: 1500,
        rating: 4.4,
        distanceToPickupKm: 28,
        driverName: 'Saman Perera',
      ),
    ];

    return LogisticsState(
      orders: const [banana],
      addresses: const [address],
      jobs: const [],
      transporters: transporters,
      issues: const [],
      pricingRules: defaultPricingRules,
      notifications: [
        AppNotificationItem(
          id: 'n1',
          userId: 'business-demo',
          title: 'Payment successful',
          body: 'Your products are ready to be delivered.',
          createdAt: DateTime.now(),
        ),
        AppNotificationItem(
          id: 'n2',
          userId: 'farmer-sunil',
          title: 'Order purchased',
          body: 'ABC Supermarket paid LKR 90,000 for 500 kg Banana.',
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  void notify(String userId, String title, String body) {
    state = state.copyWith(
      notifications: [
        AppNotificationItem(
          id: 'n-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          title: title,
          body: body,
          createdAt: DateTime.now(),
        ),
        ...state.notifications,
      ],
    );
  }

  MarketOrder createBuyOrder({
    required Production production,
    required UserProfile buyer,
    required double quantityKg,
    required double unitPrice,
  }) {
    final order = MarketOrder(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      code: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      buyerId: buyer.id,
      farmerId: production.farmerId,
      farmerName: production.farmerName,
      buyerName: buyer.organizationName ?? buyer.name,
      product: production.cropType,
      quantityKg: quantityKg,
      unitPrice: unitPrice,
      orderStatus: OrderStatus.confirmed,
      productPaymentStatus: PaymentRecordStatus.pending,
      pickupLabel: production.location,
      pickupCity: production.region,
    );
    state = state.copyWith(orders: [order, ...state.orders]);
    notify(production.farmerId, 'Order purchased', '${order.buyerName} wants ${order.product}.');
    return order;
  }

  void payProduct(String orderId, String method) {
    state = state.copyWith(
      orders: state.orders
          .map(
            (o) => o.id == orderId
                ? o.copyWith(
                    orderStatus: OrderStatus.deliveryRequired,
                    productPaymentStatus: PaymentRecordStatus.paid,
                  )
                : o,
          )
          .toList(),
    );
    final order = state.orders.firstWhere((o) => o.id == orderId);
    notify(order.buyerId, 'Payment successful', 'Your products are ready to be delivered.');
    notify(order.farmerId, 'Payment confirmed', 'Product payment received via $method.');
  }

  void chooseOwnTransport(String orderId) {
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? o.copyWith(orderStatus: OrderStatus.completed) : o)
          .toList(),
    );
  }

  TransportJob createTransportRequest({
    required MarketOrder order,
    required DeliveryAddress address,
  }) {
    final vehicle = requiredVehicleFor(order.quantityKg);
    const distanceKm = 94.0;
    final cost = quoteTransport(
      distanceKm: distanceKm,
      quantityKg: order.quantityKg,
      vehicle: vehicle,
      rules: state.pricingRules,
    );
    final job = TransportJob(
      id: 'tr-${DateTime.now().millisecondsSinceEpoch}',
      code: 'TR-${(state.jobs.length + 125).toString().padLeft(6, '0')}',
      orderId: order.id,
      buyerId: order.buyerId,
      farmerId: order.farmerId,
      product: order.product,
      quantityKg: order.quantityKg,
      pickupLabel: order.pickupLabel,
      pickupCity: order.pickupCity,
      deliveryLabel: '${address.businessName}, ${address.address}',
      deliveryCity: address.city,
      vehicleType: vehicle,
      distanceKm: distanceKm,
      estimatedCost: cost,
      status: TransportStatus.matching,
      method: DeliveryMethod.bitAppTransport,
      pickupLat: order.pickupLat,
      pickupLng: order.pickupLng,
      deliveryLat: address.latitude,
      deliveryLng: address.longitude,
      currentLat: order.pickupLat,
      currentLng: order.pickupLng,
      etaPickup: '10:00 AM',
      etaDelivery: '2:00 PM',
      tracking: [
        TrackingPoint(status: TransportStatus.requested, timestamp: DateTime.now()),
        TrackingPoint(status: TransportStatus.matching, timestamp: DateTime.now()),
      ],
    );
    state = state.copyWith(jobs: [job, ...state.jobs]);
    notify(order.buyerId, 'Transport request created', '${job.code} is matching lorries.');
    notify(order.farmerId, 'Delivery arranged', 'Buyer requested AgriLink transport.');
    for (final t in state.transporters.where((t) => t.capacityKg >= order.quantityKg)) {
      notify(t.id, 'New transport request', '${job.code}: ${order.product} ${order.quantityKg} kg, ${order.pickupCity} → ${address.city}');
    }
    return job;
  }

  void addAddress(DeliveryAddress address) {
    state = state.copyWith(addresses: [address, ...state.addresses]);
  }

  List<TransporterOption> matchesFor(TransportJob job) {
    final list = state.transporters
        .where((t) =>
            t.capacityKg >= job.quantityKg &&
            !job.rejectedTransporterIds.contains(t.id))
        .toList()
      ..sort((a, b) {
        final scoreA = a.rating * 20 - a.distanceToPickupKm;
        final scoreB = b.rating * 20 - b.distanceToPickupKm;
        return scoreB.compareTo(scoreA);
      });
    return list;
  }

  void rejectJob(String jobId, String transporterId) {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    _patchJob(
      jobId,
      job.copyWith(
        rejectedTransporterIds: [...job.rejectedTransporterIds, transporterId],
      ),
    );
    notify(transporterId, 'Job declined', '${job.code} was returned to the matching pool.');
  }

  void updatePricing(TransportPricingRule rule) {
    state = state.copyWith(
      pricingRules: state.pricingRules
          .map((r) => r.vehicleType == rule.vehicleType ? rule : r)
          .toList(),
    );
  }

  void rateTransporter(String jobId, int rating) {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    _patchJob(jobId, job.copyWith(buyerRating: rating));
    notify(job.transporterId ?? '', 'New rating', 'Buyer rated this delivery $rating/5.');
  }

  void acceptJob(String jobId, TransporterOption transporter) {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    if (transporter.capacityKg < job.quantityKg) {
      throw StateError('Vehicle capacity is insufficient');
    }
    if (job.transporterId != null) {
      throw StateError('Job already assigned');
    }
    _patchJob(
      jobId,
      job.copyWith(
        status: TransportStatus.waitingPickup,
        transporterId: transporter.id,
        transporterName: transporter.company,
        vehicleNumber: transporter.vehicleNumber,
        driverName: transporter.driverName,
        tracking: [
          ...job.tracking,
          TrackingPoint(status: TransportStatus.assigned, timestamp: DateTime.now()),
          TrackingPoint(status: TransportStatus.accepted, timestamp: DateTime.now()),
          TrackingPoint(status: TransportStatus.waitingPickup, timestamp: DateTime.now()),
        ],
      ),
    );
    notify(job.buyerId, 'Transporter accepted', '${transporter.company} accepted ${job.code}. Confirm transport to proceed.');
    notify(job.farmerId, 'Transporter assigned', 'Vehicle ${transporter.vehicleNumber} will collect your produce.');
    notify(transporter.id, 'Job accepted', 'Head to ${job.pickupCity} for pickup.');
  }

  void confirmTransport(String jobId, String method) {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    _patchJob(
      jobId,
      job.copyWith(transportPaymentStatus: PaymentRecordStatus.paid),
    );
    notify(job.transporterId ?? '', 'Transport confirmed', 'Transport fee paid separately from product payment. Proceed to farm.');
    notify(job.buyerId, 'Transporter assigned', 'Tracking is now live.');
  }

  void advanceTransport(String jobId, TransportStatus next, {double? lat, double? lng, String? note}) {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    var orderStatus = state.orders.firstWhere((o) => o.id == job.orderId).orderStatus;
    if (next == TransportStatus.inTransit) {
      orderStatus = OrderStatus.inTransit;
      notify(job.buyerId, 'Delivery in progress', 'Produce has left the farm.');
      notify(job.farmerId, 'Products picked up', 'Handover recorded.');
    }
    if (next == TransportStatus.arrivedAtDestination) {
      notify(job.buyerId, 'Your order has arrived', 'Please verify quantity and condition.');
    }
    if (next == TransportStatus.arrivedAtPickup) {
      notify(job.farmerId, 'Transporter arriving', 'Lorry is at the farm gate.');
    }
    _patchJob(
      jobId,
      job.copyWith(
        status: next,
        currentLat: lat ?? job.currentLat,
        currentLng: lng ?? job.currentLng,
        tracking: [
          ...job.tracking,
          TrackingPoint(status: next, timestamp: DateTime.now(), lat: lat, lng: lng, note: note),
        ],
      ),
    );
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == job.orderId ? o.copyWith(orderStatus: orderStatus) : o)
          .toList(),
    );
  }

  void farmerHandover(String jobId, double qty) {
    advanceTransport(
      jobId,
      TransportStatus.loaded,
      note: 'Products handed over: $qty kg',
    );
  }

  void confirmDelivery({
    required String jobId,
    required double deliveredQty,
    String? receivedBy,
  }) {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    final full = deliveredQty >= job.quantityKg - 0.01;
    _patchJob(
      jobId,
      job.copyWith(
        status: full ? TransportStatus.completed : TransportStatus.delivered,
        deliveredQty: deliveredQty,
        tracking: [
          ...job.tracking,
          TrackingPoint(status: TransportStatus.delivered, timestamp: DateTime.now(), note: receivedBy),
          if (full)
            TrackingPoint(status: TransportStatus.completed, timestamp: DateTime.now()),
        ],
      ),
    );
    state = state.copyWith(
      orders: state.orders
          .map(
            (o) => o.id == job.orderId
                ? o.copyWith(orderStatus: full ? OrderStatus.completed : OrderStatus.disputed)
                : o,
          )
          .toList(),
    );
    notify(job.farmerId, 'Delivery completed', full ? 'Buyer confirmed full delivery.' : 'Buyer reported a short delivery.');
    if (job.transporterId != null) {
      notify(job.transporterId!, 'Delivery confirmed', 'Transport settlement recorded.');
    }
  }

  void reportIssue({
    required String jobId,
    required DisputeKind type,
    required double quantityKg,
    required String description,
  }) {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    final issue = DeliveryIssue(
      id: 'dsp-${DateTime.now().millisecondsSinceEpoch}',
      orderId: job.orderId,
      transportId: job.id,
      type: type,
      quantityKg: quantityKg,
      description: description,
      status: DisputeReviewStatus.open,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      issues: [issue, ...state.issues],
      orders: state.orders
          .map((o) => o.id == job.orderId ? o.copyWith(orderStatus: OrderStatus.disputed) : o)
          .toList(),
    );
  }

  void resolveIssue(String id, DisputeReviewStatus status) {
    state = state.copyWith(
      issues: state.issues
          .map(
            (i) => i.id == id
                ? DeliveryIssue(
                    id: i.id,
                    orderId: i.orderId,
                    transportId: i.transportId,
                    type: i.type,
                    quantityKg: i.quantityKg,
                    description: i.description,
                    status: status,
                    createdAt: i.createdAt,
                  )
                : i,
          )
          .toList(),
    );
  }

  void _patchJob(String id, TransportJob job) {
    state = state.copyWith(
      jobs: state.jobs.map((j) => j.id == id ? job : j).toList(),
    );
  }
}

final logisticsProvider =
    StateNotifierProvider<LogisticsNotifier, LogisticsState>((ref) {
  return LogisticsNotifier();
});

final buyerOrdersProvider = Provider<List<MarketOrder>>((ref) {
  final id = ref.watch(authProvider).profile?.id ?? 'business-demo';
  return ref.watch(logisticsProvider).orders.where((o) => o.buyerId == id).toList();
});

final farmerOrdersProvider = Provider<List<MarketOrder>>((ref) {
  final id = ref.watch(authProvider).profile?.id;
  if (id == null) return const [];
  return ref.watch(logisticsProvider).orders.where((o) => o.farmerId == id).toList();
});

final openJobsProvider = Provider<List<TransportJob>>((ref) {
  final tid = ref.watch(authProvider).profile?.id ?? 'transporter-demo';
  return ref
      .watch(logisticsProvider)
      .jobs
      .where((j) =>
          j.transporterId == null &&
          !j.rejectedTransporterIds.contains(tid) &&
          (j.status == TransportStatus.matching || j.status == TransportStatus.requested))
      .toList();
});

final myTransportJobsProvider = Provider<List<TransportJob>>((ref) {
  final id = ref.watch(authProvider).profile?.id ?? 'transporter-demo';
  return ref.watch(logisticsProvider).jobs.where((j) => j.transporterId == id).toList();
});

final myNotificationsProvider = Provider<List<AppNotificationItem>>((ref) {
  final id = ref.watch(authProvider).profile?.id;
  final role = ref.watch(authProvider).profile?.role;
  final fallback = switch (role) {
    UserRole.farmer => id ?? '',
    UserRole.transporter => 'transporter-demo',
    UserRole.government => 'gov-demo',
    UserRole.admin => 'admin-demo',
    _ => 'business-demo',
  };
  final userId = id ?? fallback;
  return ref.watch(logisticsProvider).notifications.where((n) => n.userId == userId).toList();
});
