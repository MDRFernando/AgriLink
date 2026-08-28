import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:intl/intl.dart';

class FarmerProductionDetailScreen extends ConsumerWidget {
  const FarmerProductionDetailScreen({super.key, required this.productionId});

  final String productionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final production = ref.read(appDataProvider.notifier).getProduction(productionId);

    if (production == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Production')),
        body: const EmptyStateView(
          icon: Icons.error_outline,
          title: 'Production not found',
          message: 'This production listing may have been removed.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(production.cropType)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductionCard(production: production),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Update Status'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductionStatus.values.map((status) {
                final isSelected = production.status == status;
                return FilterChip(
                  label: Text(status.label),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(appDataProvider.notifier).updateProductionStatus(
                          productionId,
                          status,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status updated to ${status.label}')),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Details'),
            const SizedBox(height: 12),
            _DetailRow(label: 'Quantity', value: '${production.quantity} ${production.unit}'),
            _DetailRow(
              label: 'Harvest Date',
              value: DateFormat('MMMM d, yyyy').format(production.harvestDate),
            ),
            _DetailRow(label: 'Region', value: production.region),
            _DetailRow(label: 'Location', value: production.location),
            if (production.notes != null)
              _DetailRow(label: 'Notes', value: production.notes!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
