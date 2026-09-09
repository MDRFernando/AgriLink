import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/role_scaffold.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/features/farmer/screens/farmer_demand_screen.dart';
import 'package:my_app/features/logistics/screens/farmer_logistics_screens.dart';
import 'package:my_app/features/marketplace/widgets/market_visibility_panel.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

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
              label: const Text('List produce'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grass_outlined), selectedIcon: Icon(Icons.grass), label: 'Listings'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.gavel_outlined), selectedIcon: Icon(Icons.gavel), label: 'Bids'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Demand'),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _FarmerOverviewTab(),
          _FarmerProductionsTab(),
          FarmerOrdersTab(),
          _FarmerBidsTab(),
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
    final pendingBids =
        ref.watch(farmerPendingConfirmationsProvider).length;

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
                label: 'Bids to confirm',
                value: '$pendingBids',
                icon: Icons.gavel,
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
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.calendar_month, color: AppColors.farmer),
              title: const Text(
                'Crop planning',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${ref.watch(farmerCropPlansProvider).length} plan(s) registered. Tell government what you intend to cultivate.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.farmerCropPlans),
            ),
          ),
          const SizedBox(height: 24),
          const MarketVisibilityPanel(title: 'Shared supply visibility'),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Your listings'),
          const SizedBox(height: 12),
          if (productions.isEmpty)
            const EmptyStateView(
              icon: Icons.grass,
              title: 'No listings yet',
              message: 'Publish a listing with crop, grade, reserve price, and bidding window.',
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
        title: 'No listings yet',
        message: 'Start by listing produce with a reserve price and bidding window.',
        actionLabel: 'List produce',
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

class _FarmerBidsTab extends ConsumerWidget {
  const _FarmerBidsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(farmerPendingConfirmationsProvider);
    final myIds = ref.watch(farmerProductionsProvider).map((p) => p.id).toSet();
    final bids = ref
        .watch(appDataProvider)
        .bids
        .where((b) => myIds.contains(b.listingId))
        .toList();

    if (pending.isEmpty && bids.isEmpty) {
      return const EmptyStateView(
        icon: Icons.gavel,
        title: 'No bids yet',
        message: 'When buyers bid on your listings, they appear here. After the window closes you can confirm or decline the highest qualifying bid.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Text(
            'Confirm or decline winning bids',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...pending.map((listing) {
            final winner = bids
                .where((b) => b.listingId == listing.id)
                .fold<MarketBid?>(null, (best, b) {
              if (best == null || b.amount > best.amount) return b;
              return best;
            });
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.cropType,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      winner == null
                          ? 'Highest bid LKR ${listing.currentHighestBid.toStringAsFixed(0)}/kg'
                          : '${winner.buyerName} · LKR ${winner.amount.toStringAsFixed(0)}/kg',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Confirm',
                            onPressed: () {
                              final profile = ref.read(authProvider).profile;
                              if (profile == null) return;
                              ref.read(appDataProvider.notifier).closeExpiredAuctions();
                              ref
                                  .read(appDataProvider.notifier)
                                  .confirmWinningBid(listing.id);
                              final buyerId = listing.currentHighestBidderId;
                              final buyerName = winner?.buyerName ?? 'Buyer';
                              final buyer = UserProfile(
                                id: buyerId ?? 'buyer',
                                name: buyerName,
                                email: '',
                                phone: '',
                                role: UserRole.business,
                                organizationName: buyerName,
                                isVerified: true,
                              );
                              ref.read(logisticsProvider.notifier).createBuyOrder(
                                    production: listing.copyWith(
                                      status: ProductionStatus.sold,
                                    ),
                                    buyer: buyer,
                                    quantityKg: listing.quantity,
                                    unitPrice: listing.currentHighestBid,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bid accepted. A logistics record will be created after produce payment.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            label: 'Decline',
                            isOutlined: true,
                            onPressed: () {
                              ref
                                  .read(appDataProvider.notifier)
                                  .declineWinningBid(listing.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Winning bid declined')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
        Text(
          'Bid activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...bids.map(
          (b) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(b.buyerName),
            subtitle: Text('LKR ${b.amount.toStringAsFixed(0)}/kg'),
          ),
        ),
      ],
    );
  }
}
