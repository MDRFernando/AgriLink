import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/logic/bidding_logic.dart';

class AggregatedReport {
  const AggregatedReport({
    required this.region,
    required this.cropType,
    required this.period,
    required this.suppressed,
    this.totalQuantity,
    this.avgPrice,
    this.contributorCount,
    this.unit = 'kg',
    this.reason,
    this.alertType = SupplyAlertType.stable,
  });

  final String region;
  final String cropType;
  final String period;
  final bool suppressed;
  final double? totalQuantity;
  final double? avgPrice;
  final int? contributorCount;
  final String unit;
  final String? reason;
  final SupplyAlertType alertType;
}

class ClearingTransaction {
  const ClearingTransaction({
    required this.region,
    required this.cropType,
    required this.period,
    required this.farmerId,
    required this.clearingPrice,
  });

  final String region;
  final String cropType;
  final String period;
  final String farmerId;
  final double clearingPrice;
}

String reportPeriod(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

/// Chapter 5.3 — k-anonymity suppression (k = 5).
AggregatedReport generateAggregatedReport({
  required String region,
  required String cropType,
  required String period,
  required List<Production> listings,
  required List<ClearingTransaction> transactions,
  int kThreshold = BidEngine.kAnonymityThreshold,
}) {
  final inCell = listings.where((listing) {
    if (listing.moderated || listing.auctionStatus == ListingAuctionStatus.hidden) {
      return false;
    }
    final listingPeriod = reportPeriod(listing.createdAt ?? listing.harvestDate);
    return listing.region == region &&
        listing.cropType == cropType &&
        listingPeriod == period;
  }).toList();

  final farmers = inCell.map((l) => l.farmerId).toSet();
  if (farmers.length < kThreshold) {
    return AggregatedReport(
      region: region,
      cropType: cropType,
      period: period,
      suppressed: true,
      reason: 'Insufficient contributors to preserve anonymity',
    );
  }

  final totalQuantity = inCell.fold<double>(0, (sum, l) => sum + l.quantity);
  final prices = transactions
      .where((t) =>
          t.region == region && t.cropType == cropType && t.period == period)
      .map((t) => t.clearingPrice)
      .toList();
  final avgPrice = prices.isEmpty
      ? null
      : prices.reduce((a, b) => a + b) / prices.length;

  return AggregatedReport(
    region: region,
    cropType: cropType,
    period: period,
    suppressed: false,
    totalQuantity: totalQuantity,
    avgPrice: avgPrice,
    contributorCount: farmers.length,
    unit: inCell.first.unit,
    alertType: _alert(totalQuantity),
  );
}

List<AggregatedReport> generateAllAggregatedReports({
  required List<Production> listings,
  required List<ClearingTransaction> transactions,
  int kThreshold = BidEngine.kAnonymityThreshold,
}) {
  final keys = <String>{};
  for (final listing in listings) {
    if (listing.moderated || listing.auctionStatus == ListingAuctionStatus.hidden) {
      continue;
    }
    final period = reportPeriod(listing.createdAt ?? listing.harvestDate);
    keys.add('${listing.region}::${listing.cropType}::$period');
  }
  return keys.map((key) {
    final parts = key.split('::');
    return generateAggregatedReport(
      region: parts[0],
      cropType: parts[1],
      period: parts[2],
      listings: listings,
      transactions: transactions,
      kThreshold: kThreshold,
    );
  }).toList()
    ..sort((a, b) => '${a.region}${a.cropType}'.compareTo('${b.region}${b.cropType}'));
}

SupplyAlertType _alert(double quantity) {
  if (quantity <= 0) return SupplyAlertType.stable;
  if (quantity < 5000) return SupplyAlertType.shortage;
  if (quantity > 20000) return SupplyAlertType.surplus;
  return SupplyAlertType.stable;
}

/// Back-compat alias for UI that still imports AggregatedCell.
typedef AggregatedCell = AggregatedReport;
