import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/shared/logic/aggregation_logic.dart';
import 'package:my_app/shared/logic/bidding_logic.dart';
import 'package:my_app/shared/providers/app_providers.dart';

/// FR-03 two-way visibility — Chapter 5.3 / 5.5.
class MarketVisibilityPanel extends ConsumerWidget {
  const MarketVisibilityPanel({super.key, this.title = 'Market visibility'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = ref.watch(aggregatedSupplyProvider);
    final demands = ref.watch(appDataProvider).demands;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Anonymized stock and indicative prices. Cells with fewer than ${BidEngine.kAnonymityThreshold} farmers are suppressed.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        if (cells.isEmpty)
          const Text('No published supply aggregates yet.')
        else
          ...cells.map((cell) => _CellCard(cell: cell)),
        const SizedBox(height: 16),
        Text(
          'Buyer demand (open requests)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...demands.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CropThumb(cropType: d.cropType, size: 36, radius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${d.cropType} · ${d.quantityNeeded.toStringAsFixed(0)} ${d.unit} · ${d.region}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CellCard extends StatelessWidget {
  const _CellCard({required this.cell});

  final AggregatedReport cell;

  @override
  Widget build(BuildContext context) {
    final lkr = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
    return Card(
      child: ListTile(
        leading: CropThumb(cropType: cell.cropType),
        title: Text('${cell.cropType} · ${cell.region}'),
        subtitle: Text(
          cell.suppressed
              ? (cell.reason ?? 'Insufficient contributors to preserve anonymity')
              : '${cell.period} · ${cell.totalQuantity!.toStringAsFixed(0)} ${cell.unit} · ${cell.contributorCount} farmers'
                  '${cell.avgPrice == null ? '' : ' · avg clearing ${lkr.format(cell.avgPrice)}/kg'}',
        ),
      ),
    );
  }
}
