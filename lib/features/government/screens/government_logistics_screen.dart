import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/features/logistics/widgets/logistics_ui.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

class GovernmentLogisticsScreen extends ConsumerWidget {
  const GovernmentLogisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logisticsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Farm-to-business logistics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: 160, child: StatCard(label: 'Orders', value: '${state.orders.length}', icon: Icons.receipt, color: AppColors.business)),
            SizedBox(width: 160, child: StatCard(label: 'Active jobs', value: '${state.jobs.where((j) => j.status != TransportStatus.completed).length}', icon: Icons.local_shipping, color: AppColors.transporter)),
            SizedBox(width: 160, child: StatCard(label: 'Disputes', value: '${state.issues.where((i) => i.status == DisputeReviewStatus.open).length}', icon: Icons.report, color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Transport pricing (admin-configurable)', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...state.pricingRules.map((rule) => _PricingTile(rule: rule)),
        const SizedBox(height: 24),
        const Text('Transport requests', style: TextStyle(fontWeight: FontWeight.w700)),
        ...state.jobs.map(
          (j) => ListTile(
            title: Text('${j.code} • ${j.product}'),
            subtitle: Text('${j.pickupCity} → ${j.deliveryCity} • ${j.status.label}'),
            trailing: Text(lkr.format(j.estimatedCost)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Delivery disputes', style: TextStyle(fontWeight: FontWeight.w700)),
        if (state.issues.isEmpty) const Text('No open disputes.'),
        ...state.issues.map(
          (i) => Card(
            child: ListTile(
              title: Text('${i.type.name} • ${formatKg(i.quantityKg)}'),
              subtitle: Text('${i.description}\n${i.status.name}'),
              isThreeLine: true,
              trailing: i.status == DisputeReviewStatus.open
                  ? TextButton(
                      onPressed: () => ref.read(logisticsProvider.notifier).resolveIssue(i.id, DisputeReviewStatus.resolved),
                      child: const Text('Resolve'),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PricingTile extends ConsumerWidget {
  const _PricingTile({required this.rule});
  final TransportPricingRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(rule.vehicleType.label),
        subtitle: Text(
          'Base ${lkr.format(rule.baseCharge)} + ${rule.perKm}/km + ${rule.perKg}/kg + load ${lkr.format(rule.loadingFee)} + fuel ${rule.fuelSurchargePercent}%',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final base = await _edit(context, 'Base charge', rule.baseCharge);
            if (base == null || !context.mounted) return;
            ref.read(logisticsProvider.notifier).updatePricing(rule.copyWith(baseCharge: base));
          },
        ),
      ),
    );
  }

  Future<double?> _edit(BuildContext context, String label, double value) async {
    final c = TextEditingController(text: value.toStringAsFixed(0));
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(controller: c, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(c.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
