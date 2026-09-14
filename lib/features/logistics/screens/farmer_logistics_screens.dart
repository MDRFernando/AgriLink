import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/features/logistics/widgets/logistics_ui.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

class FarmerOrdersTab extends ConsumerWidget {
  const FarmerOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(farmerOrdersProvider);
    final jobs = ref.watch(logisticsProvider).jobs;
    if (orders.isEmpty) {
      return const EmptyStateView(
        icon: Icons.inventory,
        title: 'No paid orders',
        message: 'When a buyer pays for your produce, pickup details appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final order = orders[i];
        TransportJob? job;
        try {
          job = jobs.firstWhere((j) => j.orderId == order.id);
        } catch (_) {}
        return Card(
          child: ListTile(
            leading: CropThumb(cropType: order.product),
            title: Text('${order.buyerName} — ${order.product}'),
            subtitle: Text(
              '${order.code} • ${lkr.format(order.productTotal)}\n'
              '${job == null ? 'Awaiting transport' : '${job.transporterName ?? 'Matching'} • ${job.vehicleNumber ?? ''}'}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/farmer/orders/${order.id}'),
          ),
        );
      },
    );
  }
}

class FarmerOrderDetailScreen extends ConsumerWidget {
  const FarmerOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MarketOrder? order;
    try {
      order = ref.watch(farmerOrdersProvider).firstWhere((o) => o.id == orderId);
    } catch (_) {}
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const EmptyStateView(
          icon: Icons.inventory,
          title: 'Order not found',
          message: 'This pickup is no longer available.',
        ),
      );
    }
    final current = order;
    TransportJob? job;
    try {
      job = ref.watch(logisticsProvider).jobs.firstWhere((j) => j.orderId == orderId);
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: Text(current.code)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrderSummaryCard(order: current, job: job),
          if (job?.transporterId != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: AppColors.transporter),
                title: Text(job!.transporterName ?? ''),
                subtitle: Text('Vehicle ${job.vehicleNumber}\nPickup ${job.etaPickup} → ${job.deliveryCity}'),
                isThreeLine: true,
              ),
            ),
          ],
          if (job != null) ...[
            const SizedBox(height: 16),
            LogisticsTimeline(job: job),
            const SizedBox(height: 16),
            if (job.status == TransportStatus.arrivedAtPickup ||
                job.status == TransportStatus.waitingPickup)
              AppButton(
                label: 'Products handed over',
                onPressed: () {
                  ref.read(logisticsProvider.notifier).farmerHandover(job!.id, current.quantityKg);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Handover recorded with quantity and time.')),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
