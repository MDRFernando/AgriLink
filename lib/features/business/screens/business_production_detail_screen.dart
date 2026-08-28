import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';
import 'package:intl/intl.dart';

class BusinessProductionDetailScreen extends ConsumerStatefulWidget {
  const BusinessProductionDetailScreen({super.key, required this.productionId});

  final String productionId;

  @override
  ConsumerState<BusinessProductionDetailScreen> createState() =>
      _BusinessProductionDetailScreenState();
}

class _BusinessProductionDetailScreenState
    extends ConsumerState<BusinessProductionDetailScreen> {
  final _quantityController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final production =
        ref.watch(appDataProvider.notifier).getProduction(widget.productionId);

    if (production == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Production')),
        body: const EmptyStateView(
          icon: Icons.error_outline,
          title: 'Production not found',
          message: 'This listing may no longer be available.',
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
            Text(
              'Express Purchase Interest',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let the farmer know you are interested in purchasing this supply.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Quantity Needed',
              controller: _quantityController,
              keyboardType: TextInputType.number,
              hint: 'Max ${production.quantity.toStringAsFixed(0)} ${production.unit}',
              prefixIcon: Icons.scale,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Message (optional)',
              controller: _messageController,
              maxLines: 3,
              hint: 'Delivery requirements, pricing notes...',
            ),
            const SizedBox(height: 16),
            AppButton(
              label: production.cropType == 'Banana' && production.quantity == 500
                  ? 'Buy / Accept winning bid — LKR 90,000'
                  : 'Buy now at listed quantity',
              icon: Icons.shopping_bag,
              onPressed: () => _buy(production),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Submit Interest',
              icon: Icons.send,
              isOutlined: true,
              onPressed: () => _submitInterest(production),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Supply Details'),
            const SizedBox(height: 12),
            _DetailRow(label: 'Farmer', value: production.farmerName),
            _DetailRow(
              label: 'Available',
              value: '${production.quantity} ${production.unit}',
            ),
            _DetailRow(
              label: 'Harvest Date',
              value: DateFormat('MMMM d, yyyy').format(production.harvestDate),
            ),
            _DetailRow(label: 'Location', value: '${production.location}, ${production.region}'),
            if (production.notes != null)
              _DetailRow(label: 'Notes', value: production.notes!),
          ],
        ),
      ),
    );
  }

  void _buy(Production production) {
    final qty = double.tryParse(_quantityController.text) ?? production.quantity;
    if (qty <= 0 || qty > production.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity within the listing.')),
      );
      return;
    }
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;
    final unitPrice = production.cropType == 'Banana' ? 180.0 : 150.0;
    final order = ref.read(logisticsProvider.notifier).createBuyOrder(
          production: production,
          buyer: profile,
          quantityKg: qty,
          unitPrice: unitPrice,
        );
    context.push('/business/orders/${order.id}/pay');
  }

  void _submitInterest(Production production) {
    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    if (qty > production.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantity cannot exceed ${production.quantity} ${production.unit}',
          ),
        ),
      );
      return;
    }

    final profile = ref.read(authProvider).profile;
    final interest = PurchaseInterest(
      id: 'int-${DateTime.now().millisecondsSinceEpoch}',
      businessId: profile?.id ?? 'business-demo',
      businessName: profile?.organizationName ?? profile?.name ?? 'Demo Business',
      productionId: production.id,
      cropType: production.cropType,
      quantity: qty,
      unit: production.unit,
      status: InterestStatus.pending,
      createdAt: DateTime.now(),
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
    );

    ref.read(appDataProvider.notifier).addInterest(interest);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interest submitted successfully')),
    );
    context.pop();
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
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
