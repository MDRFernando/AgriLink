import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class BusinessDemandScreen extends ConsumerWidget {
  const BusinessDemandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demands = ref.watch(appDataProvider).demands;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Post Demand Request',
            icon: Icons.add,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demand posting will connect to backend in next phase'),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: demands.isEmpty
              ? const EmptyStateView(
                  icon: Icons.campaign,
                  title: 'No demand requests',
                  message: 'Post what crops you need and connect with farmers.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: demands.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final demand = demands[index];
                    if (demand.requesterRole != UserRole.business &&
                        demand.requesterRole != UserRole.government) {
                      return const SizedBox.shrink();
                    }
                    return DemandCard(demand: demand);
                  },
                ),
        ),
      ],
    );
  }
}
