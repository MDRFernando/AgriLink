import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/features/marketplace/widgets/market_visibility_panel.dart';

class GovernmentReportsScreen extends ConsumerWidget {
  const GovernmentReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aggregated government reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pre-aggregated, anonymized supply only (FR-10). Individual farmer and transaction records are never queryable from this account.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          const MarketVisibilityPanel(
            title: 'Regional supply report (k = 5)',
          ),
        ],
      ),
    );
  }
}
