import 'package:my_app/shared/entities/enums.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.organizationName,
    this.region,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? organizationName;
  final String? region;
  final bool isVerified;

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? organizationName,
    String? region,
    bool? isVerified,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      organizationName: organizationName ?? this.organizationName,
      region: region ?? this.region,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class Production {
  const Production({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropType,
    required this.quantity,
    required this.unit,
    required this.harvestDate,
    required this.region,
    required this.location,
    required this.status,
    this.notes,
    this.createdAt,
    this.qualityGrade = QualityGrade.b,
    this.reservePrice = 0,
    this.minIncrement = 5,
    this.biddingWindowEnd,
    this.auctionStatus = ListingAuctionStatus.open,
    this.currentHighestBid = 0,
    this.currentHighestBidderId,
    this.moderated = false,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String cropType;
  final double quantity;
  final String unit;
  final DateTime harvestDate;
  final String region;
  final String location;
  final ProductionStatus status;
  final String? notes;
  final DateTime? createdAt;
  final QualityGrade qualityGrade;
  final double reservePrice;
  final double minIncrement;
  final DateTime? biddingWindowEnd;
  final ListingAuctionStatus auctionStatus;
  final double currentHighestBid;
  final String? currentHighestBidderId;
  final bool moderated;

  Production copyWith({
    String? cropType,
    double? quantity,
    String? unit,
    DateTime? harvestDate,
    String? region,
    String? location,
    ProductionStatus? status,
    String? notes,
    QualityGrade? qualityGrade,
    double? reservePrice,
    double? minIncrement,
    DateTime? biddingWindowEnd,
    ListingAuctionStatus? auctionStatus,
    double? currentHighestBid,
    String? currentHighestBidderId,
    bool? moderated,
    bool clearHighestBidder = false,
  }) {
    return Production(
      id: id,
      farmerId: farmerId,
      farmerName: farmerName,
      cropType: cropType ?? this.cropType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      harvestDate: harvestDate ?? this.harvestDate,
      region: region ?? this.region,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      reservePrice: reservePrice ?? this.reservePrice,
      minIncrement: minIncrement ?? this.minIncrement,
      biddingWindowEnd: biddingWindowEnd ?? this.biddingWindowEnd,
      auctionStatus: auctionStatus ?? this.auctionStatus,
      currentHighestBid: currentHighestBid ?? this.currentHighestBid,
      currentHighestBidderId: clearHighestBidder
          ? null
          : (currentHighestBidderId ?? this.currentHighestBidderId),
      moderated: moderated ?? this.moderated,
    );
  }
}

class MarketBid {
  const MarketBid({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.buyerName,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String buyerName;
  final double amount;
  final DateTime createdAt;
}

class DemandRequest {
  const DemandRequest({
    required this.id,
    required this.requesterName,
    required this.requesterRole,
    required this.cropType,
    required this.quantityNeeded,
    required this.unit,
    required this.deadline,
    required this.region,
    required this.status,
    this.notes,
  });

  final String id;
  final String requesterName;
  final UserRole requesterRole;
  final String cropType;
  final double quantityNeeded;
  final String unit;
  final DateTime deadline;
  final String region;
  final DemandStatus status;
  final String? notes;
}

class PurchaseInterest {
  const PurchaseInterest({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.productionId,
    required this.cropType,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.createdAt,
    this.message,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String productionId;
  final String cropType;
  final double quantity;
  final String unit;
  final InterestStatus status;
  final DateTime createdAt;
  final String? message;

  PurchaseInterest copyWith({InterestStatus? status}) {
    return PurchaseInterest(
      id: id,
      businessId: businessId,
      businessName: businessName,
      productionId: productionId,
      cropType: cropType,
      quantity: quantity,
      unit: unit,
      status: status ?? this.status,
      createdAt: createdAt,
      message: message,
    );
  }
}

class CropPlan {
  const CropPlan({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropType,
    required this.cultivationYear,
    required this.cultivationMonth,
    required this.areaAcres,
    required this.province,
    required this.district,
    required this.dsDivision,
    required this.village,
    this.season,
    this.locationNotes,
    this.expectedYieldKg,
    this.status = CropPlanStatus.planned,
    this.createdAt,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String cropType;
  final int cultivationYear;
  final int cultivationMonth;
  final CultivationSeason? season;
  final double areaAcres;
  final String province;
  final String district;
  final String dsDivision;
  final String village;
  final String? locationNotes;
  final double? expectedYieldKg;
  final CropPlanStatus status;
  final DateTime? createdAt;

  String get periodLabel {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = (cultivationMonth >= 1 && cultivationMonth <= 12)
        ? months[cultivationMonth - 1]
        : 'Month $cultivationMonth';
    final seasonBit = season == null ? '' : ' · ${season!.label}';
    return '$month $cultivationYear$seasonBit';
  }

  String get locationLabel => '$village, $dsDivision, $district';

  CropPlan copyWith({
    String? cropType,
    int? cultivationYear,
    int? cultivationMonth,
    CultivationSeason? season,
    bool clearSeason = false,
    double? areaAcres,
    String? province,
    String? district,
    String? dsDivision,
    String? village,
    String? locationNotes,
    double? expectedYieldKg,
    CropPlanStatus? status,
  }) {
    return CropPlan(
      id: id,
      farmerId: farmerId,
      farmerName: farmerName,
      cropType: cropType ?? this.cropType,
      cultivationYear: cultivationYear ?? this.cultivationYear,
      cultivationMonth: cultivationMonth ?? this.cultivationMonth,
      season: clearSeason ? null : (season ?? this.season),
      areaAcres: areaAcres ?? this.areaAcres,
      province: province ?? this.province,
      district: district ?? this.district,
      dsDivision: dsDivision ?? this.dsDivision,
      village: village ?? this.village,
      locationNotes: locationNotes ?? this.locationNotes,
      expectedYieldKg: expectedYieldKg ?? this.expectedYieldKg,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class CropPlanAggregate {
  const CropPlanAggregate({
    required this.cropType,
    required this.province,
    required this.district,
    required this.dsDivision,
    required this.village,
    required this.cultivationYear,
    required this.cultivationMonth,
    required this.farmerCount,
    required this.totalAreaAcres,
    required this.estimatedYieldKg,
    required this.planCount,
  });

  final String cropType;
  final String province;
  final String district;
  final String dsDivision;
  final String village;
  final int cultivationYear;
  final int cultivationMonth;
  final int farmerCount;
  final double totalAreaAcres;
  final double estimatedYieldKg;
  final int planCount;
}

class CropDemandInsight {
  const CropDemandInsight({
    required this.cropType,
    required this.farmerCount,
    required this.plannedAreaAcres,
    required this.estimatedSupplyKg,
    required this.openDemandKg,
    required this.signal,
    required this.message,
  });

  final String cropType;
  final int farmerCount;
  final double plannedAreaAcres;
  final double estimatedSupplyKg;
  final double openDemandKg;
  final CropBalanceSignal signal;
  final String message;
}

class RegionalAnalytics {
  const RegionalAnalytics({
    required this.region,
    required this.cropType,
    required this.totalQuantity,
    required this.unit,
    required this.farmerCount,
    required this.alertType,
  });

  final String region;
  final String cropType;
  final double totalQuantity;
  final String unit;
  final int farmerCount;
  final SupplyAlertType alertType;
}

class CropTrend {
  const CropTrend({
    required this.month,
    required this.quantity,
  });

  final String month;
  final double quantity;
}

class MarketOrder {
  const MarketOrder({
    required this.id,
    required this.code,
    required this.buyerId,
    required this.farmerId,
    required this.farmerName,
    required this.buyerName,
    required this.product,
    required this.quantityKg,
    required this.unitPrice,
    required this.orderStatus,
    required this.productPaymentStatus,
    this.pickupLabel = '',
    this.pickupCity = '',
    this.pickupLat = 7.4863,
    this.pickupLng = 80.3623,
  });

  final String id;
  final String code;
  final String buyerId;
  final String farmerId;
  final String farmerName;
  final String buyerName;
  final String product;
  final double quantityKg;
  final double unitPrice;
  final OrderStatus orderStatus;
  final PaymentRecordStatus productPaymentStatus;
  final String pickupLabel;
  final String pickupCity;
  final double pickupLat;
  final double pickupLng;

  double get productTotal => quantityKg * unitPrice;

  MarketOrder copyWith({
    OrderStatus? orderStatus,
    PaymentRecordStatus? productPaymentStatus,
  }) {
    return MarketOrder(
      id: id,
      code: code,
      buyerId: buyerId,
      farmerId: farmerId,
      farmerName: farmerName,
      buyerName: buyerName,
      product: product,
      quantityKg: quantityKg,
      unitPrice: unitPrice,
      orderStatus: orderStatus ?? this.orderStatus,
      productPaymentStatus: productPaymentStatus ?? this.productPaymentStatus,
      pickupLabel: pickupLabel,
      pickupCity: pickupCity,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
    );
  }
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.buyerId,
    required this.businessName,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.city,
    this.latitude = 6.9271,
    this.longitude = 79.8612,
    this.instructions,
  });

  final String id;
  final String buyerId;
  final String businessName;
  final String contactPerson;
  final String phone;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String? instructions;
}

class TransporterOption {
  const TransporterOption({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.capacityKg,
    required this.rating,
    required this.distanceToPickupKm,
    required this.driverName,
  });

  final String id;
  final String name;
  final String company;
  final String phone;
  final String vehicleNumber;
  final VehicleType vehicleType;
  final double capacityKg;
  final double rating;
  final double distanceToPickupKm;
  final String driverName;
}

class TrackingPoint {
  const TrackingPoint({
    required this.status,
    required this.timestamp,
    this.lat,
    this.lng,
    this.note,
  });

  final TransportStatus status;
  final DateTime timestamp;
  final double? lat;
  final double? lng;
  final String? note;
}

class TransportJob {
  const TransportJob({
    required this.id,
    required this.code,
    required this.orderId,
    required this.buyerId,
    required this.farmerId,
    required this.product,
    required this.quantityKg,
    required this.pickupLabel,
    required this.pickupCity,
    required this.deliveryLabel,
    required this.deliveryCity,
    required this.vehicleType,
    required this.distanceKm,
    required this.estimatedCost,
    required this.status,
    required this.method,
    this.transporterId,
    this.transporterName,
    this.vehicleNumber,
    this.driverName,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
    this.currentLat,
    this.currentLng,
    this.etaPickup,
    this.etaDelivery,
    this.tracking = const [],
    this.deliveredQty,
    this.transportPaymentStatus,
    this.rejectedTransporterIds = const [],
    this.buyerRating,
  });

  final String id;
  final String code;
  final String orderId;
  final String buyerId;
  final String farmerId;
  final String product;
  final double quantityKg;
  final String pickupLabel;
  final String pickupCity;
  final String deliveryLabel;
  final String deliveryCity;
  final VehicleType vehicleType;
  final double distanceKm;
  final double estimatedCost;
  final TransportStatus status;
  final DeliveryMethod method;
  final String? transporterId;
  final String? transporterName;
  final String? vehicleNumber;
  final String? driverName;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final double? currentLat;
  final double? currentLng;
  final String? etaPickup;
  final String? etaDelivery;
  final List<TrackingPoint> tracking;
  final double? deliveredQty;
  final PaymentRecordStatus? transportPaymentStatus;
  final List<String> rejectedTransporterIds;
  final int? buyerRating;

  TransportJob copyWith({
    TransportStatus? status,
    String? transporterId,
    String? transporterName,
    String? vehicleNumber,
    String? driverName,
    double? currentLat,
    double? currentLng,
    List<TrackingPoint>? tracking,
    double? deliveredQty,
    PaymentRecordStatus? transportPaymentStatus,
    List<String>? rejectedTransporterIds,
    int? buyerRating,
  }) {
    return TransportJob(
      id: id,
      code: code,
      orderId: orderId,
      buyerId: buyerId,
      farmerId: farmerId,
      product: product,
      quantityKg: quantityKg,
      pickupLabel: pickupLabel,
      pickupCity: pickupCity,
      deliveryLabel: deliveryLabel,
      deliveryCity: deliveryCity,
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      estimatedCost: estimatedCost,
      status: status ?? this.status,
      method: method,
      transporterId: transporterId ?? this.transporterId,
      transporterName: transporterName ?? this.transporterName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      etaPickup: etaPickup,
      etaDelivery: etaDelivery,
      tracking: tracking ?? this.tracking,
      deliveredQty: deliveredQty ?? this.deliveredQty,
      transportPaymentStatus: transportPaymentStatus ?? this.transportPaymentStatus,
      rejectedTransporterIds: rejectedTransporterIds ?? this.rejectedTransporterIds,
      buyerRating: buyerRating ?? this.buyerRating,
    );
  }
}

class DeliveryIssue {
  const DeliveryIssue({
    required this.id,
    required this.orderId,
    required this.transportId,
    required this.type,
    required this.quantityKg,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String transportId;
  final DisputeKind type;
  final double quantityKg;
  final String description;
  final DisputeReviewStatus status;
  final DateTime createdAt;
}

class TransportPricingRule {
  const TransportPricingRule({
    required this.vehicleType,
    required this.baseCharge,
    required this.perKm,
    required this.perKg,
    this.loadingFee = 500,
    this.fuelSurchargePercent = 5,
  });

  final VehicleType vehicleType;
  final double baseCharge;
  final double perKm;
  final double perKg;
  final double loadingFee;
  final double fuelSurchargePercent;

  TransportPricingRule copyWith({
    double? baseCharge,
    double? perKm,
    double? perKg,
    double? loadingFee,
    double? fuelSurchargePercent,
  }) {
    return TransportPricingRule(
      vehicleType: vehicleType,
      baseCharge: baseCharge ?? this.baseCharge,
      perKm: perKm ?? this.perKm,
      perKg: perKg ?? this.perKg,
      loadingFee: loadingFee ?? this.loadingFee,
      fuelSurchargePercent: fuelSurchargePercent ?? this.fuelSurchargePercent,
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
}
