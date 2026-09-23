import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appDataProvider.notifier).syncFromApi(UserRole.farmer);
      ref.read(logisticsProvider.notifier).syncOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Farmer Dashboard',
      actions: [
        IconButton(
          tooltip: 'Ask AgriLink',
          onPressed: () => context.push(AppRoutes.farmerChat),
          icon: const Icon(Icons.forum_outlined),
        ),
      ],
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.farmerAddProduction),
              icon: const Icon(Icons.add),
              label: const Text('List produce'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 3) {
            ref.read(appDataProvider.notifier).refreshBids(UserRole.farmer);
          }
        },
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
        ref.watch(farmerBidsProvider).where((b) => b.status == BidStatus.pending).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WelcomeBanner(
            title:
                'Hello, ${profile?.name.isNotEmpty == true ? profile!.name : 'Farmer'}!',
            subtitle: profile?.region ?? 'Manage your agricultural production',
          ),
          const SizedBox(height: 24),
          ResponsiveStatGrid(
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
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.forum_outlined, color: AppColors.farmer),
              title: const Text(
                'Ask AgriLink',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'General how-to for listings, bids, crop plans, demand, and orders. No personal farm data is used.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.farmerChat),
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
            ResponsiveWrapGrid(
              children: [
                for (final p in productions.take(3))
                  ProductionCard(
                    production: p,
                    onTap: () => context.push('/farmer/production/${p.id}'),
                  ),
              ],
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ResponsiveWrapGrid(
        children: [
          for (final production in productions)
            ProductionCard(
              production: production,
              onTap: () => context.push('/farmer/production/${production.id}'),
            ),
        ],
      ),
    );
  }
}

class _FarmerBidsTab extends ConsumerWidget {
  const _FarmerBidsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bids = ref.watch(farmerBidsProvider);

    if (bids.isEmpty) {
      return const EmptyStateView(
        icon: Icons.gavel,
        title: 'No bids yet',
        message: 'When buyers bid on your listings, they appear here. You can review, accept, or decline each offer.',
      );
    }

    final lkr = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
    final pending = bids.where((b) => b.status == BidStatus.pending).toList();
    final others = bids.where((b) => b.status != BidStatus.pending).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Text(
            'Bids to review',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          for (final bid in pending) _FarmerBidCard(bid: bid, lkr: lkr),
          const SizedBox(height: 16),
        ],
        if (others.isNotEmpty) ...[
          Text(
            pending.isEmpty ? 'Bids received' : 'Earlier bids',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          for (final bid in others) _FarmerBidCard(bid: bid, lkr: lkr),
        ],
      ],
    );
  }
}

class _FarmerBidCard extends ConsumerWidget {
  const _FarmerBidCard({required this.bid, required this.lkr});

  final MarketBid bid;
  final NumberFormat lkr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Production? listing;
    for (final p in ref.watch(appDataProvider).productions) {
      if (p.id == bid.listingId) {
        listing = p;
        break;
      }
    }
    final closing = bid.biddingWindowEnd ?? listing?.biddingWindowEnd;
    final canAct = bid.status == BidStatus.pending &&
        listing != null &&
        listing.farmerId == bid.farmerId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CropThumb(cropType: bid.cropType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.cropType,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        bid.buyerName,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: bid.status.label,
                  color: _bidStatusColor(bid.status),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text('${bid.quantity.toStringAsFixed(0)} ${bid.unit}'),
                Text('${lkr.format(bid.amount)}/${bid.unit}'),
                Text(
                  'Total ${lkr.format(bid.totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (closing != null) ...[
              const SizedBox(height: 6),
              Text(
                'Bid closing ${DateFormat('MMM d, HH:mm').format(closing)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            AppButton(
              label: 'View Details',
              isOutlined: true,
              onPressed: () => _showDetails(context, listing),
            ),
            if (canAct) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Accept',
                      onPressed: () => _accept(context, ref, listing!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Decline',
                      isOutlined: true,
                      onPressed: () => _decline(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Production? listing) {
    final closing = bid.biddingWindowEnd ?? listing?.biddingWindowEnd;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${bid.cropType} bid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detail('Buyer', bid.buyerName),
              _detail('Quantity', '${bid.quantity.toStringAsFixed(0)} ${bid.unit}'),
              _detail('Bid price', '${lkr.format(bid.amount)}/${bid.unit}'),
              _detail('Total value', lkr.format(bid.totalAmount)),
              _detail('Status', bid.status.label),
              _detail(
                'Placed',
                DateFormat('MMM d, yyyy HH:mm').format(bid.createdAt),
              ),
              if (closing != null)
                _detail(
                  'Bid closing',
                  DateFormat('MMM d, yyyy HH:mm').format(closing),
                ),
              if (listing != null)
                _detail(
                  'Available now',
                  '${listing.quantity.toStringAsFixed(0)} ${listing.unit}',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref, Production listing) async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;
    if (profile.id != listing.farmerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only accept bids on your own listings')),
      );
      return;
    }

    final error = await ref.read(appDataProvider.notifier).acceptBid(
          bidId: bid.id,
          farmerId: profile.id,
          notify: ref.read(logisticsProvider.notifier).notify,
        );
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (AgriLinkApi.instance.hasToken) {
      await ref.read(logisticsProvider.notifier).syncOrders();
    } else {
      final buyer = UserProfile(
        id: bid.buyerId,
        name: bid.buyerName,
        email: '',
        phone: '',
        role: UserRole.business,
        organizationName: bid.buyerName,
        isVerified: true,
      );
      ref.read(logisticsProvider.notifier).createBuyOrder(
            production: listing,
            buyer: buyer,
            quantityKg: bid.quantity,
            unitPrice: bid.amount,
            acceptedBidId: bid.id,
          );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bid accepted. An order was created for this quantity.'),
      ),
    );
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;
    final error = await ref.read(appDataProvider.notifier).declineBid(
          bidId: bid.id,
          farmerId: profile.id,
          notify: ref.read(logisticsProvider.notifier).notify,
        );
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bid declined')),
    );
  }

  static Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

Color _bidStatusColor(BidStatus status) {
  switch (status) {
    case BidStatus.pending:
      return AppColors.accent;
    case BidStatus.accepted:
      return AppColors.success;
    case BidStatus.declined:
      return AppColors.error;
    case BidStatus.expired:
      return AppColors.textSecondary;
  }
}
