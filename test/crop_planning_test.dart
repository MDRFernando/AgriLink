import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/logic/crop_planning_aggregation.dart';

void main() {
  CropPlan plan({
    required String id,
    required String farmerId,
    required String crop,
    required String district,
    required String ds,
    required String village,
    required double acres,
    int month = 10,
  }) {
    return CropPlan(
      id: id,
      farmerId: farmerId,
      farmerName: farmerId,
      cropType: crop,
      cultivationYear: 2026,
      cultivationMonth: month,
      areaAcres: acres,
      province: 'North Western Province',
      district: district,
      dsDivision: ds,
      village: village,
    );
  }

  test('aggregates banana plans by district and counts distinct farmers', () {
    final plans = [
      plan(
        id: '1',
        farmerId: 'a',
        crop: 'Banana',
        district: 'Kurunegala',
        ds: 'Kurunegala',
        village: 'Wehera',
        acres: 2,
      ),
      plan(
        id: '2',
        farmerId: 'b',
        crop: 'Banana',
        district: 'Kurunegala',
        ds: 'Polgahawela',
        village: 'Alawwa',
        acres: 3,
      ),
      plan(
        id: '3',
        farmerId: 'a',
        crop: 'Banana',
        district: 'Kurunegala',
        ds: 'Kurunegala',
        village: 'Wehera',
        acres: 1,
      ),
    ];

    final byDistrict = aggregateCropPlans(
      plans,
      groupBy: CropPlanGroupBy.district,
    );

    expect(byDistrict, hasLength(1));
    expect(byDistrict.first.farmerCount, 2);
    expect(byDistrict.first.totalAreaAcres, 6);
    expect(byDistrict.first.cropType, 'Banana');
  });

  test('flags surplus when planned banana supply dwarfs open demand', () {
    final plans = [
      plan(
        id: '1',
        farmerId: 'a',
        crop: 'Banana',
        district: 'Kurunegala',
        ds: 'Kurunegala',
        village: 'Wehera',
        acres: 4,
      ),
    ];
    final demands = [
      DemandRequest(
        id: 'd1',
        requesterName: 'Buyer',
        requesterRole: UserRole.business,
        cropType: 'Banana',
        quantityNeeded: 1000,
        unit: 'kg',
        deadline: DateTime(2026, 12, 1),
        region: 'Western Province',
        status: DemandStatus.open,
      ),
    ];

    final insights = cropDemandInsights(plans: plans, demands: demands);
    expect(insights, isNotEmpty);
    expect(insights.first.signal, CropBalanceSignal.surplusRisk);
  });
}
