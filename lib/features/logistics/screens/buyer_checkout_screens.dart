import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/features/logistics/widgets/logistics_ui.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

MarketOrder? _order(WidgetRef ref, String id) {
  try {
    return ref.watch(logisticsProvider).orders.firstWhere((o) => o.id == id);
  } catch (_) {
    return null;
  }
}

TransportJob? _jobForOrder(WidgetRef ref, String orderId) {
  try {
    return ref.watch(logisticsProvider).jobs.firstWhere((j) => j.orderId == orderId);
  } catch (_) {
    return null;
  }
}

class BuyerPaymentScreen extends ConsumerStatefulWidget {
  const BuyerPaymentScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<BuyerPaymentScreen> createState() => _BuyerPaymentScreenState();
}

class _BuyerPaymentScreenState extends ConsumerState<BuyerPaymentScreen> {
  String _method = 'Card';

  @override
  Widget build(BuildContext context) {
    final order = _order(ref, widget.orderId);
    if (order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Product Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrderSummaryCard(order: order),
          const SizedBox(height: 16),
          const Text('Pay for produce only. Transport is billed separately if you use AgriLink Transport.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          for (final m in ['Cash', 'Card', 'Bank Transfer'])
            ListTile(
              leading: Icon(_method == m ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primary),
              title: Text(m),
              onTap: () => setState(() => _method = m),
            ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Pay ${lkr.format(order.productTotal)}',
            onPressed: () {
              ref.read(logisticsProvider.notifier).payProduct(order.id, _method);
              context.go('/business/orders/${order.id}/delivery');
            },
          ),
        ],
      ),
    );
  }
}

class DeliveryMethodScreen extends ConsumerWidget {
  const DeliveryMethodScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = _order(ref, orderId);
    if (order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Receive your products')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your products are ready to be delivered.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('How would you like to receive your products?'),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping, color: AppColors.transporter, size: 36),
              title: const Text('AgriLink Transport', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Find a transporter — we match a lorry to the farm.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/business/orders/$orderId/address'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.agriculture, color: AppColors.farmer, size: 36),
              title: const Text('Own Transport', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('I will arrange my own vehicle to the farm.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(logisticsProvider.notifier).chooseOwnTransport(orderId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Own transport recorded. Collect from the farm.')),
                );
                context.go('/business');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryAddressScreen extends ConsumerStatefulWidget {
  const DeliveryAddressScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends ConsumerState<DeliveryAddressScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _biz;
  late final TextEditingController _contact;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final addresses = ref.read(logisticsProvider).addresses;
    final existing = addresses.isEmpty ? null : addresses.first;
    final profile = ref.read(authProvider).profile;
    _biz = TextEditingController(text: existing?.businessName ?? profile?.organizationName ?? 'ABC Supermarket');
    _contact = TextEditingController(text: existing?.contactPerson ?? profile?.name ?? 'Nimal Jayasuriya');
    _phone = TextEditingController(text: existing?.phone ?? profile?.phone ?? '0771239876');
    _address = TextEditingController(text: existing?.address ?? '123 Main Street, Colombo');
    _city = TextEditingController(text: existing?.city ?? 'Colombo');
    _notes = TextEditingController(text: existing?.instructions ?? 'Unload at the rear goods bay.');
  }

  @override
  void dispose() {
    _biz.dispose();
    _contact.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order(ref, widget.orderId);
    if (order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery location')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.surfaceVariant,
              child: ListTile(
                leading: const Icon(Icons.agriculture, color: AppColors.farmer),
                title: const Text('Pickup (from farmer — not editable)'),
                subtitle: Text('${order.pickupLabel}\n${order.pickupCity}'),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Business name', controller: _biz, validator: _req),
            const SizedBox(height: 12),
            AppTextField(label: 'Contact person', controller: _contact, validator: _req),
            const SizedBox(height: 12),
            AppTextField(label: 'Contact number', controller: _phone, validator: _req),
            const SizedBox(height: 12),
            AppTextField(label: 'Delivery address', controller: _address, validator: _req),
            const SizedBox(height: 12),
            AppTextField(label: 'City', controller: _city, validator: _req),
            const SizedBox(height: 12),
            AppTextField(label: 'Delivery instructions', controller: _notes, maxLines: 2),
            const SizedBox(height: 20),
            AppButton(
              label: 'Find a transporter',
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                final profile = ref.read(authProvider).profile;
                final address = DeliveryAddress(
                  id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                  buyerId: profile?.id ?? 'business-demo',
                  businessName: _biz.text.trim(),
                  contactPerson: _contact.text.trim(),
                  phone: _phone.text.trim(),
                  address: _address.text.trim(),
                  city: _city.text.trim(),
                  instructions: _notes.text.trim(),
                );
                ref.read(logisticsProvider.notifier).addAddress(address);
                ref.read(logisticsProvider.notifier).createTransportRequest(order: order, address: address);
                context.go('/business/orders/${order.id}/transport');
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;
}

class TransportMatchesScreen extends ConsumerWidget {
  const TransportMatchesScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = _order(ref, orderId);
    final job = _jobForOrder(ref, orderId);
    if (order == null || job == null) {
      return const Scaffold(body: Center(child: Text('Transport request not found')));
    }
    final matches = ref.watch(logisticsProvider.notifier).matchesFor(job);
    final vehicle = requiredVehicleFor(order.quantityKg);

    return Scaffold(
      appBar: AppBar(title: Text(job.code)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrderSummaryCard(order: order, job: job),
          const SizedBox(height: 12),
          Text('Required vehicle: ${vehicle.label} (capacity check enforced)',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Kurunegala → ${job.deliveryCity}  •  ~${job.distanceKm.toStringAsFixed(0)} km'),
          const SizedBox(height: 16),
          if (matches.isEmpty)
            const EmptyStateView(
              icon: Icons.local_shipping,
              title: 'Waiting for a lorry',
              message: 'Suitable transporters have been notified. Ask a transporter to accept, then confirm here.',
            )
          else
            ...matches.map((t) {
              final assigned = job.transporterId == t.id;
              return Card(
                child: ListTile(
                  title: Text(t.company, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${t.vehicleType.label} • ${t.vehicleNumber}\n'
                    '${t.capacityKg.toStringAsFixed(0)} kg capacity • ${t.distanceToPickupKm.toStringAsFixed(0)} km from farm • ${t.rating}★',
                  ),
                  isThreeLine: true,
                  trailing: assigned
                      ? FilledButton(
                          onPressed: () => context.go('/business/jobs/${job.id}/confirm'),
                          child: const Text('Review'),
                        )
                      : Text(lkr.format(job.estimatedCost)),
                ),
              );
            }),
          if (job.transporterId != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Review & confirm transport',
              onPressed: () => context.go('/business/jobs/${job.id}/confirm'),
            ),
          ],
        ],
      ),
    );
  }
}

class TransportConfirmScreen extends ConsumerWidget {
  const TransportConfirmScreen({super.key, required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logistics = ref.watch(logisticsProvider);
    TransportJob? job;
    try {
      job = logistics.jobs.firstWhere((j) => j.id == jobId);
    } catch (_) {}
    if (job == null) return const Scaffold(body: Center(child: Text('Job not found')));
    final order = logistics.orders.firstWhere((o) => o.id == job!.orderId);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm transport')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrderSummaryCard(order: order, job: job),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.transporterName ?? 'Transporter', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Vehicle ${job.vehicleNumber} • ${job.vehicleType.label}'),
                  Text('Driver ${job.driverName}'),
                  Text('Pickup ${job.etaPickup}  •  Delivery ${job.etaDelivery}'),
                  const SizedBox(height: 8),
                  const Text('Product payment and transport payment are recorded as separate transactions.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Confirm transport ${lkr.format(job.estimatedCost)}',
            onPressed: job.transporterId == null
                ? null
                : () {
                    ref.read(logisticsProvider.notifier).confirmTransport(job!.id, 'Card');
                    context.go('/business/tracking/${job.id}');
                  },
          ),
        ],
      ),
    );
  }
}
