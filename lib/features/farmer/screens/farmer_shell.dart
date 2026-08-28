import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/role_scaffold.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/features/farmer/screens/farmer_demand_screen.dart';
import 'package:my_app/features/logistics/screens/farmer_logistics_screens.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class FarmerShell extends ConsumerStatefulWidget {
  const FarmerShell({super.key});

  @override
  ConsumerState<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends ConsumerState<FarmerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Farmer Dashboard',
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.farmerAddProduction),
              icon: const Icon(Icons.add),
              label: const Text('Add Production'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grass_outlined), selectedIcon: Icon(Icons.grass), label: 'Productions'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake), label: 'Interests'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Demand'),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _FarmerOverviewTab(),
          _FarmerProductionsTab(),
          FarmerOrdersTab(),
          _FarmerInterestsTab(),
          FarmerDemandScreen(),
        ],
      ),
    );
  }
}

class _FarmerOverviewTab extends ConsumerWidget {
  const _FarmerOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).profile;
    final productions = ref.watch(farmerProductionsProvider);
    final interests = ref.watch(farmerInterestsProvider);
    final pendingInterests =
        interests.where((i) => i.status == InterestStatus.pending).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${profile?.name.isNotEmpty == true ? profile!.name : 'Farmer'}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            profile?.region ?? 'Manage your agricultural production',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                label: 'Active Productions',
                value: '${productions.length}',
                icon: Icons.grass,
                color: AppColors.farmer,
              ),
              StatCard(
                label: 'Pending Interests',
                value: '$pendingInterests',
                icon: Icons.handshake,
                color: AppColors.accent,
              ),
              StatCard(
                label: 'Available Listings',
                value: '${productions.where((p) => p.status == ProductionStatus.available).length}',
                icon: Icons.store,
                color: AppColors.success,
              ),
              StatCard(
                label: 'Open Demands',
                value: '${ref.watch(appDataProvider).demands.where((d) => d.status == DemandStatus.open).length}',
                icon: Icons.trending_up,
                color: AppColors.business,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recent Productions'),
          const SizedBox(height: 12),
          if (productions.isEmpty)
            const EmptyStateView(
              icon: Icons.grass,
              title: 'No productions yet',
              message: 'Add your first crop listing to connect with buyers.',
            )
          else
            ...productions.take(3).map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProductionCard(
                      production: p,
                      onTap: () => context.push('/farmer/production/${p.id}'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _FarmerProductionsTab extends ConsumerWidget {
  const _FarmerProductionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productions = ref.watch(farmerProductionsProvider);

    if (productions.isEmpty) {
      return EmptyStateView(
        icon: Icons.grass,
        title: 'No productions yet',
        message: 'Start by adding details about your crops and harvest schedule.',
        actionLabel: 'Add Production',
        onAction: () => context.push(AppRoutes.farmerAddProduction),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: productions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final production = productions[index];
        return ProductionCard(
          production: production,
          onTap: () => context.push('/farmer/production/${production.id}'),
        );
      },
    );
  }
}

class _FarmerInterestsTab extends ConsumerWidget {
  const _FarmerInterestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(farmerInterestsProvider);

    if (interests.isEmpty) {
      return const EmptyStateView(
        icon: Icons.handshake,
        title: 'No purchase interests yet',
        message: 'When businesses express interest in your crops, they will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: interests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final interest = interests[index];
        return InterestCard(
          interest: interest,
          showActions: true,
          onAccept: () {
            ref.read(appDataProvider.notifier).updateInterestStatus(
                  interest.id,
                  InterestStatus.accepted,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Interest accepted')),
            );
          },
          onReject: () {
            ref.read(appDataProvider.notifier).updateInterestStatus(
                  interest.id,
                  InterestStatus.rejected,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Interest rejected')),
            );
          },
        );
      },
    );
  }
}
