import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/constants/sri_lanka_geo.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/logic/crop_planning_aggregation.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class GovernmentCropPlanningScreen extends ConsumerStatefulWidget {
  const GovernmentCropPlanningScreen({super.key});

  @override
  ConsumerState<GovernmentCropPlanningScreen> createState() =>
      _GovernmentCropPlanningScreenState();
}

class _GovernmentCropPlanningScreenState
    extends ConsumerState<GovernmentCropPlanningScreen> {
  String? _crop;
  String? _district;
  int? _month;

  @override
  Widget build(BuildContext context) {
    final allPlans = ref.watch(appDataProvider).cropPlans;
    final filtered = filterCropPlans(
      allPlans,
      cropType: _crop,
      district: _district,
      month: _month,
    );
    final byCrop = aggregateCropPlans(filtered, groupBy: CropPlanGroupBy.crop);
    final byDistrict =
        aggregateCropPlans(filtered, groupBy: CropPlanGroupBy.district);
    final byDs =
        aggregateCropPlans(filtered, groupBy: CropPlanGroupBy.dsDivision);
    final byVillage =
        aggregateCropPlans(filtered, groupBy: CropPlanGroupBy.village);
    final byPeriod =
        aggregateCropPlans(filtered, groupBy: CropPlanGroupBy.period);
    final insights = cropDemandInsights(
      plans: filtered,
      demands: ref.watch(appDataProvider).demands,
    );

    final farmerCount = filtered.map((p) => p.farmerId).toSet().length;
    final totalAcres =
        filtered.fold<double>(0, (sum, p) => sum + p.areaAcres);

    final districtItems = [
      ...SriLankaGeo.districts.map((d) => d.name),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crop planning insights',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggregated farmer cultivation plans by crop, period, and geography. Individual farmer identities are not shown.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          AppDropdownField<String>(
            label: 'Crop',
            value: _crop ?? 'All crops',
            items: const ['All crops', ...AppConstants.cropTypes],
            onChanged: (v) => setState(() {
              _crop = v == null || v == 'All crops' ? null : v;
            }),
          ),
          const SizedBox(height: 12),
          AppDropdownField<String>(
            label: 'District',
            value: _district ?? 'All districts',
            items: ['All districts', ...districtItems],
            onChanged: (v) => setState(() {
              _district = v == null || v == 'All districts' ? null : v;
            }),
          ),
          const SizedBox(height: 12),
          AppDropdownField<String>(
            label: 'Cultivation month',
            value: _month == null ? 'All months' : SriLankaGeo.monthLabel(_month!),
            items: ['All months', ...SriLankaGeo.months],
            onChanged: (v) => setState(() {
              if (v == null || v == 'All months') {
                _month = null;
              } else {
                _month = SriLankaGeo.months.indexOf(v) + 1;
              }
            }),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                label: 'Farmers planning',
                value: '$farmerCount',
                icon: Icons.groups_outlined,
                color: AppColors.government,
              ),
              StatCard(
                label: 'Est. land area',
                value: '${totalAcres.toStringAsFixed(1)} ac',
                icon: Icons.landscape_outlined,
                color: AppColors.primary,
              ),
              StatCard(
                label: 'Active plans',
                value: '${filtered.length}',
                icon: Icons.assignment_outlined,
                color: AppColors.info,
              ),
              StatCard(
                label: 'Crops covered',
                value: '${byCrop.length}',
                icon: Icons.grass,
                color: AppColors.farmer,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Crop-wise cultivation plans'),
          const SizedBox(height: 12),
          if (byCrop.isEmpty)
            const Text('No plans match the selected filters.')
          else ...[
            SizedBox(
              height: 220,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _AreaBarChart(rows: byCrop),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...byCrop.map(_aggregateTile),
          ],
          const SizedBox(height: 24),
          const SectionHeader(title: 'District-wise crop distribution'),
          const SizedBox(height: 12),
          if (byDistrict.isEmpty)
            const Text('No district distribution for these filters.')
          else
            ...byDistrict.map(
              (row) => _aggregateTile(
                row,
                subtitle:
                    '${row.district} · ${SriLankaGeo.monthLabel(row.cultivationMonth)} ${row.cultivationYear}',
              ),
            ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Expected cultivation periods'),
          const SizedBox(height: 12),
          if (byPeriod.isEmpty)
            const Text('No period data.')
          else
            ...byPeriod.map(
              (row) => _aggregateTile(
                row,
                subtitle:
                    '${SriLankaGeo.monthLabel(row.cultivationMonth)} ${row.cultivationYear}',
              ),
            ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Geographic distribution'),
          const SizedBox(height: 8),
          Text(
            'DS Division',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...byDs.take(12).map(
                (row) => _aggregateTile(
                  row,
                  subtitle: '${row.dsDivision}, ${row.district}',
                ),
              ),
          const SizedBox(height: 16),
          Text(
            'Village',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...byVillage.take(12).map(
                (row) => _aggregateTile(
                  row,
                  subtitle: '${row.village} · ${row.dsDivision}, ${row.district}',
                ),
              ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Demand and supply insights'),
          const SizedBox(height: 8),
          Text(
            'Compares planned cultivation (estimated yield) with open marketplace demand for the same crop.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            const Text('No demand or plan data to compare.')
          else
            ...insights.map(_insightCard),
        ],
      ),
    );
  }

  Widget _aggregateTile(CropPlanAggregate row, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          title: Text(
            row.cropType,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle ??
                '${row.farmerCount} farmers · ${row.totalAreaAcres.toStringAsFixed(1)} acres · ~${row.estimatedYieldKg.toStringAsFixed(0)} kg',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${row.farmerCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.government,
                ),
              ),
              const Text(
                'farmers',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _insightCard(CropDemandInsight insight) {
    final color = switch (insight.signal) {
      CropBalanceSignal.surplusRisk => AppColors.warning,
      CropBalanceSignal.demandGap => AppColors.error,
      CropBalanceSignal.balanced => AppColors.success,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      insight.cropType,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(label: insight.signal.label, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(insight.message),
              const SizedBox(height: 8),
              Text(
                '${insight.farmerCount} farmers · ${insight.plannedAreaAcres.toStringAsFixed(1)} acres · demand ${insight.openDemandKg.toStringAsFixed(0)} kg',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaBarChart extends StatelessWidget {
  const _AreaBarChart({required this.rows});

  final List<CropPlanAggregate> rows;

  @override
  Widget build(BuildContext context) {
    final data = rows.take(6).toList();
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data
            .map((d) => d.totalAreaAcres)
            .reduce((a, b) => a > b ? a : b) *
        1.3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 1 : maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index].cropType,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)}ac',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          data.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].totalAreaAcres,
                color: AppColors.government,
                width: 18,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
