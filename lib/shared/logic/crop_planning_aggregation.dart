import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';

/// Indicative farmgate yields (kg per acre) used only for planning insights.
const Map<String, double> typicalYieldKgPerAcre = {
  'Rice': 2200,
  'Wheat': 1500,
  'Maize': 1800,
  'Potato': 8000,
  'Tomato': 12000,
  'Onion': 6000,
  'Tea': 800,
  'Coconut': 3500,
  'Chilli': 2500,
  'Banana': 8000,
};

double estimatedYieldKg({required String cropType, required double areaAcres, double? reportedYieldKg}) {
  if (reportedYieldKg != null && reportedYieldKg > 0) return reportedYieldKg;
  final rate = typicalYieldKgPerAcre[cropType] ?? 2000;
  return areaAcres * rate;
}

bool _isActivePlan(CropPlan plan) =>
    plan.status == CropPlanStatus.planned ||
    plan.status == CropPlanStatus.cultivating;

List<CropPlan> filterCropPlans(
  List<CropPlan> plans, {
  String? cropType,
  String? district,
  String? dsDivision,
  String? village,
  int? month,
  int? year,
  bool activeOnly = true,
}) {
  return plans.where((plan) {
    if (activeOnly && !_isActivePlan(plan)) return false;
    if (cropType != null && cropType.isNotEmpty && plan.cropType != cropType) {
      return false;
    }
    if (district != null && district.isNotEmpty && plan.district != district) {
      return false;
    }
    if (dsDivision != null &&
        dsDivision.isNotEmpty &&
        plan.dsDivision != dsDivision) {
      return false;
    }
    if (village != null && village.isNotEmpty && plan.village != village) {
      return false;
    }
    if (month != null && plan.cultivationMonth != month) return false;
    if (year != null && plan.cultivationYear != year) return false;
    return true;
  }).toList();
}

List<CropPlanAggregate> aggregateCropPlans(
  List<CropPlan> plans, {
  required CropPlanGroupBy groupBy,
}) {
  final grouped = <String, _Bucket>{};

  for (final plan in plans) {
    final key = switch (groupBy) {
      CropPlanGroupBy.crop => plan.cropType,
      CropPlanGroupBy.district => '${plan.district}::${plan.cropType}',
      CropPlanGroupBy.dsDivision =>
        '${plan.district}::${plan.dsDivision}::${plan.cropType}',
      CropPlanGroupBy.village =>
        '${plan.district}::${plan.dsDivision}::${plan.village}::${plan.cropType}',
      CropPlanGroupBy.period =>
        '${plan.cultivationYear}-${plan.cultivationMonth}::${plan.cropType}',
    };
    final bucket = grouped.putIfAbsent(
      key,
      () => _Bucket(
        cropType: plan.cropType,
        province: plan.province,
        district: plan.district,
        dsDivision: plan.dsDivision,
        village: plan.village,
        year: plan.cultivationYear,
        month: plan.cultivationMonth,
      ),
    );
    bucket.farmers.add(plan.farmerId);
    bucket.planCount += 1;
    bucket.area += plan.areaAcres;
    bucket.yieldKg += estimatedYieldKg(
      cropType: plan.cropType,
      areaAcres: plan.areaAcres,
      reportedYieldKg: plan.expectedYieldKg,
    );
  }

  final result = grouped.values
      .map(
        (b) => CropPlanAggregate(
          cropType: b.cropType,
          province: b.province,
          district: b.district,
          dsDivision: b.dsDivision,
          village: b.village,
          cultivationYear: b.year,
          cultivationMonth: b.month,
          farmerCount: b.farmers.length,
          totalAreaAcres: b.area,
          estimatedYieldKg: b.yieldKg,
          planCount: b.planCount,
        ),
      )
      .toList()
    ..sort((a, b) => b.totalAreaAcres.compareTo(a.totalAreaAcres));
  return result;
}

List<CropDemandInsight> cropDemandInsights({
  required List<CropPlan> plans,
  required List<DemandRequest> demands,
}) {
  final active = filterCropPlans(plans);
  final crops = <String>{
    ...active.map((p) => p.cropType),
    ...demands
        .where((d) => d.status == DemandStatus.open)
        .map((d) => d.cropType),
  };

  final insights = <CropDemandInsight>[];
  for (final crop in crops) {
    final cropPlans = active.where((p) => p.cropType == crop).toList();
    final farmers = cropPlans.map((p) => p.farmerId).toSet().length;
    final area = cropPlans.fold<double>(0, (sum, p) => sum + p.areaAcres);
    final supply = cropPlans.fold<double>(
      0,
      (sum, p) =>
          sum +
          estimatedYieldKg(
            cropType: p.cropType,
            areaAcres: p.areaAcres,
            reportedYieldKg: p.expectedYieldKg,
          ),
    );
    final demandKg = demands
        .where((d) => d.status == DemandStatus.open && d.cropType == crop)
        .fold<double>(0, (sum, d) => sum + d.quantityNeeded);

    CropBalanceSignal signal;
    String message;
    if (supply == 0 && demandKg == 0) {
      continue;
    } else if (demandKg == 0 && supply > 0) {
      signal = CropBalanceSignal.surplusRisk;
      message =
          '$farmers farmer(s) plan ${area.toStringAsFixed(1)} acres of $crop with no matching open buyer demand.';
    } else if (supply == 0 && demandKg > 0) {
      signal = CropBalanceSignal.demandGap;
      message =
          'Open demand of ${demandKg.toStringAsFixed(0)} ${demands.first.unit} for $crop has no matching cultivation plans.';
    } else {
      final ratio = supply / demandKg;
      if (ratio >= 1.4) {
        signal = CropBalanceSignal.surplusRisk;
        message =
            'Planned $crop supply (~${supply.toStringAsFixed(0)} kg) is well above registered demand (${demandKg.toStringAsFixed(0)} kg).';
      } else if (ratio <= 0.7) {
        signal = CropBalanceSignal.demandGap;
        message =
            'Registered $crop demand (${demandKg.toStringAsFixed(0)} kg) exceeds planned supply (~${supply.toStringAsFixed(0)} kg).';
      } else {
        signal = CropBalanceSignal.balanced;
        message =
            'Planned $crop supply (~${supply.toStringAsFixed(0)} kg) is broadly in line with open demand (${demandKg.toStringAsFixed(0)} kg).';
      }
    }

    insights.add(
      CropDemandInsight(
        cropType: crop,
        farmerCount: farmers,
        plannedAreaAcres: area,
        estimatedSupplyKg: supply,
        openDemandKg: demandKg,
        signal: signal,
        message: message,
      ),
    );
  }

  insights.sort((a, b) => b.plannedAreaAcres.compareTo(a.plannedAreaAcres));
  return insights;
}

enum CropPlanGroupBy { crop, district, dsDivision, village, period }

class _Bucket {
  _Bucket({
    required this.cropType,
    required this.province,
    required this.district,
    required this.dsDivision,
    required this.village,
    required this.year,
    required this.month,
  });

  final String cropType;
  final String province;
  final String district;
  final String dsDivision;
  final String village;
  final int year;
  final int month;
  final Set<String> farmers = {};
  int planCount = 0;
  double area = 0;
  double yieldKg = 0;
}
