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

class BuyerOrdersTab extends ConsumerWidget {
  const BuyerOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(buyerOrdersProvider);
    final jobs = ref.watch(logisticsProvider).jobs;
    if (orders.isEmpty) {
      return const EmptyStateView(
        icon: Icons.receipt_long,
        title: 'No orders yet',
        message: 'Accept a winning bid from the marketplace to start farm-to-business delivery.',
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
            title: Text('${order.product} • ${formatKg(order.quantityKg)}'),
            subtitle: Text('${order.code} • ${order.orderStatus.label}\nProduct ${lkr.format(order.productTotal)}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (order.orderStatus == OrderStatus.confirmed ||
                  order.productPaymentStatus == PaymentRecordStatus.pending) {
                context.push('/business/orders/${order.id}/pay');
              } else if (order.orderStatus == OrderStatus.deliveryRequired && job == null) {
                context.push('/business/orders/${order.id}/delivery');
              } else if (job != null && job.transportPaymentStatus != PaymentRecordStatus.paid) {
                context.push('/business/orders/${order.id}/transport');
              } else if (job != null) {
                context.push('/business/tracking/${job.id}');
              }
            },
          ),
        );
      },
    );
  }
}

class DeliveryTrackingScreen extends ConsumerWidget {
  const DeliveryTrackingScreen({super.key, required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logistics = ref.watch(logisticsProvider);
    TransportJob? job;
    try {
      job = logistics.jobs.firstWhere((j) => j.id == jobId);
    } catch (_) {}
    if (job == null) return const Scaffold(body: Center(child: Text('Tracking not found')));
    final order = logistics.orders.firstWhere((o) => o.id == job!.orderId);

    return Scaffold(
      appBar: AppBar(title: Text('Track ${job.code}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RouteMapPreview(job: job),
          const SizedBox(height: 12),
          OrderSummaryCard(order: order, job: job),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping, color: AppColors.transporter),
              title: Text(job.transporterName ?? 'Matching transporter'),
              subtitle: Text(
                job.vehicleNumber == null
                    ? 'Waiting for assignment'
                    : '${job.vehicleType.label} • ${job.vehicleNumber}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Delivery lifecycle', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          LogisticsTimeline(job: job),
          const SizedBox(height: 16),
          if (job.status == TransportStatus.arrivedAtDestination ||
              job.status == TransportStatus.delivered)
            AppButton(
              label: 'Confirm delivery',
              onPressed: () => context.push('/business/jobs/${job!.id}/receive'),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push('/business/jobs/${job!.id}/issue'),
            child: const Text('Report partial delivery or damage'),
          ),
        ],
      ),
    );
  }
}

class ConfirmDeliveryScreen extends ConsumerStatefulWidget {
  const ConfirmDeliveryScreen({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ConfirmDeliveryScreen> createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends ConsumerState<ConfirmDeliveryScreen> {
  late final TextEditingController _qty;
  late final TextEditingController _receivedBy;
  late final TextEditingController _otp;
  int _stars = 5;

  @override
  void initState() {
    super.initState();
    final job = ref.read(logisticsProvider).jobs.firstWhere((j) => j.id == widget.jobId);
    _qty = TextEditingController(text: job.quantityKg.toStringAsFixed(0));
    _receivedBy = TextEditingController();
    _otp = TextEditingController();
  }

  @override
  void dispose() {
    _qty.dispose();
    _receivedBy.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(logisticsProvider).jobs.firstWhere((j) => j.id == widget.jobId);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm delivery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ordered ${formatKg(job.quantityKg)}. Enter quantity received.'),
          const SizedBox(height: 12),
          AppTextField(label: 'Delivered quantity (kg)', controller: _qty, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppTextField(label: 'Received by', controller: _receivedBy),
          const SizedBox(height: 12),
          AppTextField(label: 'OTP (optional proof)', controller: _otp, hint: '6-digit gate code'),
          const SizedBox(height: 16),
          const Text('Rate transporter'),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(i <= _stars ? Icons.star : Icons.star_border, color: AppColors.accent),
                ),
            ],
          ),
          AppButton(
            label: 'Confirm delivery',
            onPressed: () {
              final qty = double.tryParse(_qty.text) ?? 0;
              ref.read(logisticsProvider.notifier).confirmDelivery(
                    jobId: job.id,
                    deliveredQty: qty,
                    receivedBy: _receivedBy.text.trim(),
                  );
              ref.read(logisticsProvider.notifier).rateTransporter(job.id, _stars);
              if (qty < job.quantityKg) {
                context.push('/business/jobs/${job.id}/issue');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delivery completed. Transport settlement recorded.')),
                );
                context.go('/business');
              }
            },
          ),
        ],
      ),
    );
  }
}

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  DisputeKind _kind = DisputeKind.partialDelivery;
  final _qty = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(logisticsProvider).jobs.firstWhere((j) => j.id == widget.jobId);
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery issue')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CropThumb(cropType: job.product, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${job.product} ordered ${formatKg(job.quantityKg)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DisputeKind>(
            initialValue: _kind,
            items: DisputeKind.values
                .map((k) => DropdownMenuItem(value: k, child: Text(k.name)))
                .toList(),
            onChanged: (v) => setState(() => _kind = v ?? _kind),
            decoration: const InputDecoration(labelText: 'Issue type'),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Affected quantity (kg)', controller: _qty, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppTextField(label: 'Description / evidence notes', controller: _desc, maxLines: 4),
          const SizedBox(height: 16),
          AppButton(
            label: 'Submit dispute',
            onPressed: () {
              ref.read(logisticsProvider.notifier).reportIssue(
                    jobId: job.id,
                    type: _kind,
                    quantityKg: double.tryParse(_qty.text) ?? 0,
                    description: _desc.text.trim(),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dispute opened. Order stays incomplete until admin review.')),
              );
              context.go('/business');
            },
          ),
        ],
      ),
    );
  }
}
