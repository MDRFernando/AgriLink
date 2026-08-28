import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class BusinessInterestsScreen extends ConsumerWidget {
  const BusinessInterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(businessInterestsProvider);

    if (interests.isEmpty) {
      return const EmptyStateView(
        icon: Icons.handshake,
        title: 'No interests yet',
        message: 'Browse the marketplace and express interest in available supply.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: interests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => InterestCard(interest: interests[index]),
    );
  }
}
