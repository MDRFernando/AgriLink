import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/role_scaffold.dart';
import 'package:my_app/features/logistics/widgets/logistics_ui.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

class TransporterShell extends ConsumerStatefulWidget {
  const TransporterShell({super.key});

  @override
  ConsumerState<TransporterShell> createState() => _TransporterShellState();
}

class _TransporterShellState extends ConsumerState<TransporterShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Transporter Dashboard',
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'My runs'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Earnings'),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _AvailableJobsTab(),
          _MyRunsTab(),
          _EarningsTab(),
        ],
      ),
    );
  }
}

class _AvailableJobsTab extends ConsumerWidget {
  const _AvailableJobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(openJobsProvider);
    if (jobs.isEmpty) {
      return const EmptyStateView(
        icon: Icons.local_shipping,
        title: 'No open pickup jobs',
        message: 'When a buyer requests AgriLink Transport, matching jobs appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _JobCard(job: jobs[i], open: true),
    );
  }
}

class _MyRunsTab extends ConsumerWidget {
  const _MyRunsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(myTransportJobsProvider);
    if (jobs.isEmpty) {
      return const EmptyStateView(
        icon: Icons.route,
        title: 'No assigned runs',
        message: 'Accept a job to start farm pickup and live tracking.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _JobCard(job: jobs[i], open: false),
    );
  }
}

class _EarningsTab extends ConsumerWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(myTransportJobsProvider);
    final paid = jobs.where((j) => j.transportPaymentStatus == PaymentRecordStatus.paid);
    final total = paid.fold<double>(0, (s, j) => s + j.estimatedCost);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatCard(label: 'Settled transport fees', value: lkr.format(total), icon: Icons.payments, color: AppColors.transporter),
        const SizedBox(height: 16),
        ...paid.map(
          (j) => ListTile(
            title: Text(j.code),
            subtitle: Text('${j.pickupCity} → ${j.deliveryCity}'),
            trailing: Text(lkr.format(j.estimatedCost)),
          ),
        ),
      ],
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job, required this.open});
  final TransportJob job;
  final bool open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${job.code}  •  ${job.product} ${formatKg(job.quantityKg)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${job.pickupCity} → ${job.deliveryCity}  •  ${job.distanceKm.toStringAsFixed(0)} km'),
            Text('Required ${job.vehicleType.label}  •  Fee ${lkr.format(job.estimatedCost)}'),
            Text('Pickup ${job.etaPickup ?? '10:00 AM'}'),
            const SizedBox(height: 12),
            if (open)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final tid = ref.read(authProvider).profile?.id ?? 'transporter-demo';
                        ref.read(logisticsProvider.notifier).rejectJob(job.id, tid);
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final t = ref.read(logisticsProvider).transporters.firstWhere(
                              (x) => x.id == (ref.read(authProvider).profile?.id ?? 'transporter-demo'),
                              orElse: () => ref.read(logisticsProvider).transporters.first,
                            );
                        try {
                          ref.read(logisticsProvider.notifier).acceptJob(job.id, t);
                          context.push('/transporter/jobs/${job.id}');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      },
                      child: const Text('Accept job'),
                    ),
                  ),
                ],
              )
            else
              FilledButton(
                onPressed: () => context.push('/transporter/jobs/${job.id}'),
                child: const Text('Open run'),
              ),
          ],
        ),
      ),
    );
  }
}

class TransporterJobDetailScreen extends ConsumerWidget {
  const TransporterJobDetailScreen({super.key, required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(logisticsProvider).jobs.firstWhere((j) => j.id == jobId);
    final next = _nextStatus(job.status);

    return Scaffold(
      appBar: AppBar(title: Text(job.code)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RouteMapPreview(job: job),
          const SizedBox(height: 12),
          Text('${job.product} ${formatKg(job.quantityKg)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          Text('Pickup ${job.pickupLabel}, ${job.pickupCity}'),
          Text('Drop ${job.deliveryLabel}'),
          const SizedBox(height: 16),
          LogisticsTimeline(job: job),
          const SizedBox(height: 16),
          if (next != null)
            AppButton(
              label: 'Mark: ${next.label}',
              onPressed: () {
                ref.read(logisticsProvider.notifier).advanceTransport(
                      job.id,
                      next,
                      lat: job.currentLat,
                      lng: job.currentLng,
                    );
              },
            ),
        ],
      ),
    );
  }

  TransportStatus? _nextStatus(TransportStatus current) {
    return switch (current) {
      TransportStatus.waitingPickup => TransportStatus.arrivedAtPickup,
      TransportStatus.loaded => TransportStatus.inTransit,
      TransportStatus.inTransit => TransportStatus.arrivedAtDestination,
      TransportStatus.arrivedAtDestination => TransportStatus.delivered,
      _ => null,
    };
  }
}
