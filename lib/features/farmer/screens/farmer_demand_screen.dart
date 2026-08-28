import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class FarmerDemandScreen extends ConsumerWidget {
  const FarmerDemandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demands = ref.watch(appDataProvider).demands
        .where((d) => d.status == DemandStatus.open)
        .toList();

    if (demands.isEmpty) {
      return const EmptyStateView(
        icon: Icons.campaign,
        title: 'No open demand',
        message: 'Business and government demand requests will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: demands.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => DemandCard(demand: demands[index]),
    );
  }
}
