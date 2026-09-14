import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class CropPlanListScreen extends ConsumerWidget {
  const CropPlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(farmerCropPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crop planning')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.farmerCropPlanNew),
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
      ),
      body: plans.isEmpty
          ? EmptyStateView(
              icon: Icons.calendar_month_outlined,
              title: 'No cultivation plans yet',
              message:
                  'Register the crop, season, area, and location you intend to cultivate. Aggregated plans help government agricultural planning.',
              actionLabel: 'Register a plan',
              onAction: () => context.push(AppRoutes.farmerCropPlanNew),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _CropPlanCard(
                  plan: plan,
                  onTap: () =>
                      context.push('/farmer/crop-plans/${plan.id}'),
                );
              },
            ),
    );
  }
}

class _CropPlanCard extends StatelessWidget {
  const _CropPlanCard({required this.plan, required this.onTap});

  final CropPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CropImage(cropType: plan.cropType, height: 140),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.cropType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      StatusChip(
                        label: plan.status.label,
                        color: plan.status == CropPlanStatus.cancelled
                            ? AppColors.error
                            : plan.status == CropPlanStatus.cultivating
                                ? AppColors.success
                                : AppColors.farmer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.periodLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.areaAcres.toStringAsFixed(1)} acres · ${plan.locationLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
