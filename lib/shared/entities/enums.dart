enum UserRole { farmer, business, government, transporter }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.business:
        return 'Business Buyer';
      case UserRole.government:
        return 'Admin';
      case UserRole.transporter:
        return 'Transporter';
    }
  }

  String get description {
    switch (this) {
      case UserRole.farmer:
        return 'List your crops and connect with buyers directly';
      case UserRole.business:
        return 'Discover supply, bid, and arrange farm-to-business delivery';
      case UserRole.government:
        return 'Monitor production, transport, and delivery disputes';
      case UserRole.transporter:
        return 'Accept farm pickup jobs and deliver to businesses';
    }
  }
}

enum ProductionStatus {
  planned,
  growing,
  readyForHarvest,
  available,
  sold,
  expired,
}

extension ProductionStatusX on ProductionStatus {
  String get label {
    switch (this) {
      case ProductionStatus.planned:
        return 'Planned';
      case ProductionStatus.growing:
        return 'Growing';
      case ProductionStatus.readyForHarvest:
        return 'Ready for Harvest';
      case ProductionStatus.available:
        return 'Available';
      case ProductionStatus.sold:
        return 'Sold';
      case ProductionStatus.expired:
        return 'Expired';
    }
  }
}

enum InterestStatus { pending, accepted, rejected }

extension InterestStatusX on InterestStatus {
  String get label {
    switch (this) {
      case InterestStatus.pending:
        return 'Pending';
      case InterestStatus.accepted:
        return 'Accepted';
      case InterestStatus.rejected:
        return 'Rejected';
    }
  }
}

enum DemandStatus { open, fulfilled, closed }

extension DemandStatusX on DemandStatus {
  String get label {
    switch (this) {
      case DemandStatus.open:
        return 'Open';
      case DemandStatus.fulfilled:
        return 'Fulfilled';
      case DemandStatus.closed:
        return 'Closed';
    }
  }
}

enum SupplyAlertType { shortage, surplus, stable }

extension SupplyAlertTypeX on SupplyAlertType {
  String get label {
    switch (this) {
      case SupplyAlertType.shortage:
        return 'Shortage';
      case SupplyAlertType.surplus:
        return 'Surplus';
      case SupplyAlertType.stable:
        return 'Stable';
    }
  }
}

enum OrderStatus {
  pending,
  confirmed,
  paid,
  deliveryRequired,
  inTransit,
  delivered,
  completed,
  cancelled,
  disputed,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.deliveryRequired:
        return 'Delivery Required';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.disputed:
        return 'Disputed';
    }
  }
}

enum PaymentRecordStatus { pending, paid, failed, refunded, partiallyRefunded }

extension PaymentRecordStatusX on PaymentRecordStatus {
  String get label {
    switch (this) {
      case PaymentRecordStatus.pending:
        return 'Pending';
      case PaymentRecordStatus.paid:
        return 'Paid';
      case PaymentRecordStatus.failed:
        return 'Failed';
      case PaymentRecordStatus.refunded:
        return 'Refunded';
      case PaymentRecordStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }
}

enum DeliveryMethod { bitAppTransport, ownTransport }

enum VehicleType { pickup, smallLorry, mediumLorry, largeLorry }

extension VehicleTypeX on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.pickup:
        return 'Pickup';
      case VehicleType.smallLorry:
        return 'Small Lorry';
      case VehicleType.mediumLorry:
        return 'Medium Lorry';
      case VehicleType.largeLorry:
        return 'Large Lorry';
    }
  }

  double get capacityKg {
    switch (this) {
      case VehicleType.pickup:
        return 500;
      case VehicleType.smallLorry:
        return 1500;
      case VehicleType.mediumLorry:
        return 5000;
      case VehicleType.largeLorry:
        return 15000;
    }
  }
}

enum TransportStatus {
  requested,
  matching,
  assigned,
  accepted,
  waitingPickup,
  arrivedAtPickup,
  loaded,
  inTransit,
  arrivedAtDestination,
  delivered,
  buyerConfirmed,
  completed,
  cancelled,
}

extension TransportStatusX on TransportStatus {
  String get label {
    switch (this) {
      case TransportStatus.requested:
        return 'Transport Requested';
      case TransportStatus.matching:
        return 'Matching';
      case TransportStatus.assigned:
        return 'Transporter Assigned';
      case TransportStatus.accepted:
        return 'Transporter Accepted';
      case TransportStatus.waitingPickup:
        return 'Waiting for Pickup';
      case TransportStatus.arrivedAtPickup:
        return 'Arrived at Farm';
      case TransportStatus.loaded:
        return 'Products Loaded';
      case TransportStatus.inTransit:
        return 'In Transit';
      case TransportStatus.arrivedAtDestination:
        return 'Arrived at Buyer';
      case TransportStatus.delivered:
        return 'Products Delivered';
      case TransportStatus.buyerConfirmed:
        return 'Buyer Confirmed';
      case TransportStatus.completed:
        return 'Completed';
      case TransportStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum DisputeKind { partialDelivery, damaged, missing, other }

enum DisputeReviewStatus { open, underReview, resolved, rejected }
