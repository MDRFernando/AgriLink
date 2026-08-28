import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/role_scaffold.dart';
import 'package:my_app/features/government/screens/government_alerts_screen.dart';
import 'package:my_app/features/government/screens/government_analytics_screen.dart';
import 'package:my_app/features/government/screens/government_logistics_screen.dart';
import 'package:my_app/features/government/screens/government_reports_screen.dart';
import 'package:my_app/shared/data/mock_data.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
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
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning_amber), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Logistics'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Reports'),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _GovernmentOverviewTab(),
          GovernmentAnalyticsScreen(),
          GovernmentAlertsScreen(),
          GovernmentLogisticsScreen(),
          GovernmentReportsScreen(),
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
    final productions = ref.watch(appDataProvider).productions;
    final analytics = MockData.regionalAnalytics;
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
          Text(
            profile?.organizationName ?? 'Ministry of Agriculture',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            profile?.region ?? 'National agricultural oversight',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                label: 'Total Listings',
                value: '${productions.length}',
                icon: Icons.grass,
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
          const SectionHeader(title: 'Regional Overview'),
          const SizedBox(height: 12),
          ...analytics.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
