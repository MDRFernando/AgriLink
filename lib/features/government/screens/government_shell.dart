import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/core/widgets/role_scaffold.dart';
import 'package:my_app/features/government/screens/government_alerts_screen.dart';
import 'package:my_app/features/government/screens/government_analytics_screen.dart';
import 'package:my_app/features/government/screens/government_crop_planning_screen.dart';
import 'package:my_app/features/government/screens/government_logistics_screen.dart';
import 'package:my_app/shared/data/mock_data.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/logic/crop_planning_aggregation.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class GovernmentShell extends ConsumerStatefulWidget {
  const GovernmentShell({super.key});

  @override
  ConsumerState<GovernmentShell> createState() => _GovernmentShellState();
}

class _GovernmentShellState extends ConsumerState<GovernmentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Government Dashboard',
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.agriculture_outlined), selectedIcon: Icon(Icons.agriculture), label: 'Crop plans'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning_amber), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Logistics'),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _GovernmentOverviewTab(),
          GovernmentCropPlanningScreen(),
          GovernmentAnalyticsScreen(),
          GovernmentAlertsScreen(),
          GovernmentLogisticsScreen(),
        ],
      ),
    );
  }
}

class _GovernmentOverviewTab extends ConsumerWidget {
  const _GovernmentOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).profile;
    final analytics = ref.watch(publishedRegionalAnalyticsProvider);
    final cropPlans = filterCropPlans(ref.watch(appDataProvider).cropPlans);
    final plannedFarmers = cropPlans.map((p) => p.farmerId).toSet().length;
    final plannedAcres =
        cropPlans.fold<double>(0, (sum, p) => sum + p.areaAcres);
    final bananaKurunegala = cropPlans
        .where((p) => p.cropType == 'Banana' && p.district == 'Kurunegala')
        .toList();
    final bananaAcres =
        bananaKurunegala.fold<double>(0, (sum, p) => sum + p.areaAcres);
    final bananaFarmers =
        bananaKurunegala.map((p) => p.farmerId).toSet().length;

    final shortages =
        analytics.where((a) => a.alertType == SupplyAlertType.shortage).length;
    final surpluses =
        analytics.where((a) => a.alertType == SupplyAlertType.surplus).length;

    final totalCapacity = analytics.fold<double>(0, (sum, a) => sum + a.totalQuantity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WelcomeBanner(
            title: profile?.organizationName ?? 'Ministry of Agriculture',
            subtitle: profile?.region ?? 'National agricultural oversight',
          ),
          const SizedBox(height: 8),
          Text(
            'Aggregated and anonymized only. Individual farmer and transaction records are not available to this account.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ResponsiveStatGrid(
            children: [
              StatCard(
                label: 'Published regions',
                value: '${analytics.length}',
                icon: Icons.map,
                color: AppColors.government,
              ),
              StatCard(
                label: 'Regional Capacity',
                value: '${(totalCapacity / 1000).toStringAsFixed(1)}K',
                icon: Icons.warehouse,
                color: AppColors.primary,
              ),
              StatCard(
                label: 'Shortage Alerts',
                value: '$shortages',
                icon: Icons.trending_down,
                color: AppColors.error,
              ),
              StatCard(
                label: 'Surplus Regions',
                value: '$surpluses',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'National crop planning',
            actionLabel: 'Open dashboard',
            onAction: () => context.push(AppRoutes.governmentCropPlanning),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.agriculture, color: AppColors.government),
              title: Text('$plannedFarmers farmers · ${plannedAcres.toStringAsFixed(1)} acres registered'),
              subtitle: Text(
                bananaKurunegala.isEmpty
                    ? 'Filter crop plans by district and month in the Crop plans tab.'
                    : '$bananaFarmers farmers in Kurunegala plan ${bananaAcres.toStringAsFixed(1)} acres of banana.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.governmentCropPlanning),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Production Trend (Rice)',
            actionLabel: 'Details',
            onAction: () => context.push(AppRoutes.governmentAnalytics),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _RiceTrendChart(data: MockData.riceTrend),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Regional Overview',
            actionLabel: 'Reports',
            onAction: () => context.push(AppRoutes.governmentReports),
          ),
          const SizedBox(height: 12),
          ...analytics.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CropThumb(cropType: item.cropType),
                  title: Text(
                    item.region,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${item.cropType} • ${item.farmerCount} farmers'),
                  trailing: StatusChip(
                    label: item.alertType.label,
                    color: alertTypeColor(item.alertType),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiceTrendChart extends StatelessWidget {
  const _RiceTrendChart({required this.data});

  final List<CropTrend> data;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                return Text(
                  data[index].month,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${(value / 1000).toStringAsFixed(0)}K',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].quantity),
            ),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
