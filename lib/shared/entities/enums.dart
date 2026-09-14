enum UserRole { farmer, business, government, transporter, admin }

enum BuyerType { company, individual }

extension BuyerTypeX on BuyerType {
  String get label {
    switch (this) {
      case BuyerType.company:
        return 'Company / Business';
      case BuyerType.individual:
        return 'Individual Buyer';
    }
  }

  String get description {
    switch (this) {
      case BuyerType.company:
        return 'Buying for a shop, supermarket, or registered business';
      case BuyerType.individual:
        return 'Buying for personal or household use';
    }
  }
}

enum TransporterType { company, individual }

extension TransporterTypeX on TransporterType {
  String get label {
    switch (this) {
      case TransporterType.company:
        return 'Transport Company / Business';
      case TransporterType.individual:
        return 'Individual Transport Provider';
    }
  }

  String get description {
    switch (this) {
      case TransporterType.company:
        return 'Providing transport as a registered company';
      case TransporterType.individual:
        return 'Providing transport independently, without a company';
    }
  }
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.business:
        return 'Buyer';
      case UserRole.government:
        return 'Government Authority';
      case UserRole.transporter:
        return 'Transport Partner';
      case UserRole.admin:
        return 'Platform Administrator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.farmer:
        return 'List produce and register cultivation plans for the season';
      case UserRole.business:
        return 'View supply, place competitive bids, and arrange delivery';
      case UserRole.government:
        return 'View aggregated crop plans, regional supply, and anonymized reports';
      case UserRole.transporter:
        return 'Accept farm pickup jobs and deliver to buyers';
      case UserRole.admin:
        return 'Moderate listings and resolve disputes';
    }
  }
}

enum QualityGrade { a, b, c }

extension QualityGradeX on QualityGrade {
  String get label {
    switch (this) {
      case QualityGrade.a:
        return 'Grade A';
      case QualityGrade.b:
        return 'Grade B';
      case QualityGrade.c:
        return 'Grade C';
    }
  }
}

/// Time-bounded ascending auction states from the Bit App research (Ch. 5.2).
enum ListingAuctionStatus {
  open,
  expiredPendingClose,
  awaitingFarmerConfirmation,
  expiredNoSale,
  sold,
  cancelled,
  hidden,
}

extension ListingAuctionStatusX on ListingAuctionStatus {
  String get label {
    switch (this) {
      case ListingAuctionStatus.open:
        return 'Bidding open';
      case ListingAuctionStatus.expiredPendingClose:
        return 'Window closed — pending close';
      case ListingAuctionStatus.awaitingFarmerConfirmation:
        return 'Awaiting your confirmation';
      case ListingAuctionStatus.expiredNoSale:
        return 'Expired — no sale';
      case ListingAuctionStatus.sold:
        return 'Sold';
      case ListingAuctionStatus.cancelled:
        return 'Cancelled';
      case ListingAuctionStatus.hidden:
        return 'Hidden by moderator';
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

enum CropPlanStatus { planned, cultivating, harvested, cancelled }

extension CropPlanStatusX on CropPlanStatus {
  String get label {
    switch (this) {
      case CropPlanStatus.planned:
        return 'Planned';
      case CropPlanStatus.cultivating:
        return 'Cultivating';
      case CropPlanStatus.harvested:
        return 'Harvested';
      case CropPlanStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum CultivationSeason { maha, yala, offSeason }

extension CultivationSeasonX on CultivationSeason {
  String get label {
    switch (this) {
      case CultivationSeason.maha:
        return 'Maha';
      case CultivationSeason.yala:
        return 'Yala';
      case CultivationSeason.offSeason:
        return 'Off-season';
    }
  }
}

enum CropBalanceSignal { surplusRisk, demandGap, balanced }

extension CropBalanceSignalX on CropBalanceSignal {
  String get label {
    switch (this) {
      case CropBalanceSignal.surplusRisk:
        return 'Surplus risk';
      case CropBalanceSignal.demandGap:
        return 'Demand gap';
      case CropBalanceSignal.balanced:
        return 'Balanced';
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
