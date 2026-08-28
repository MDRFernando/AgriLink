import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/data/mock_data.dart';
import 'package:my_app/shared/entities/enums.dart';

class GovernmentAlertsScreen extends StatelessWidget {
  const GovernmentAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = MockData.regionalAnalytics;
    final alerts = analytics
        .where((a) => a.alertType != SupplyAlertType.stable)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supply Alerts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Identify regional shortages and surpluses in real time',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          if (alerts.isEmpty)
            const EmptyStateView(
              icon: Icons.check_circle,
              title: 'All regions stable',
              message: 'No shortage or surplus alerts at this time.',
            )
          else
            ...alerts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: alertTypeColor(item.alertType).withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          item.alertType == SupplyAlertType.shortage
                              ? Icons.trending_down
                              : Icons.trending_up,
                          color: alertTypeColor(item.alertType),
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.alertType.label}: ${item.cropType}',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  StatusChip(
                                    label: item.alertType.label,
                                    color: alertTypeColor(item.alertType),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.region,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Current capacity: ${item.totalQuantity.toStringAsFixed(0)} ${item.unit} '
                                'from ${item.farmerCount} farmers',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Stable Regions'),
          const SizedBox(height: 12),
          ...analytics
              .where((a) => a.alertType == SupplyAlertType.stable)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    leading: const Icon(Icons.check_circle, color: AppColors.info),
                    title: Text(item.region),
                    subtitle: Text('${item.cropType} — ${item.totalQuantity.toStringAsFixed(0)} ${item.unit}'),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
