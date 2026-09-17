import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/core/widgets/role_scaffold.dart';
import 'package:my_app/features/business/screens/business_demand_screen.dart';
import 'package:my_app/features/business/screens/marketplace_screen.dart';
import 'package:my_app/features/logistics/screens/buyer_delivery_screens.dart';
import 'package:my_app/features/marketplace/widgets/market_visibility_panel.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

class BusinessShell extends ConsumerStatefulWidget {
  const BusinessShell({super.key});

  @override
  ConsumerState<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends ConsumerState<BusinessShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = ref.read(authProvider).profile?.role;
      ref.read(appDataProvider.notifier).syncFromApi(role);
      ref.read(logisticsProvider.notifier).syncOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Buyer Dashboard',
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 2) {
            ref.read(logisticsProvider.notifier).syncOrders();
            ref.read(appDataProvider.notifier).refreshBids(UserRole.business);
          }
          if (i == 3) {
            ref.read(appDataProvider.notifier).refreshBids(UserRole.business);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Marketplace'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.gavel_outlined), selectedIcon: Icon(Icons.gavel), label: 'Bids'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Demand'),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _BusinessOverviewTab(),
          MarketplaceScreen(),
          BuyerOrdersTab(),
          _BuyerBidsTab(),
          BusinessDemandScreen(),
        ],
      ),
    );
  }
}

class _BusinessOverviewTab extends ConsumerWidget {
  const _BusinessOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).profile;
    final available = ref.watch(availableProductionsProvider);
    final myBids = ref.watch(buyerBidsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WelcomeBanner(
            title: 'Hello, ${profile?.displayName.isNotEmpty == true ? profile!.displayName : 'Buyer'}!',
            subtitle: profile?.isIndividualBuyer == true
                ? 'Individual buyer · View listings, place bids, and arrange delivery'
                : profile?.isCompanyBuyer == true
                    ? 'Company / Business buyer · View listings, place bids, and arrange farm-to-business delivery'
                    : 'View listings, place bids, and arrange farm-to-business delivery',
          ),
          if (ref.watch(buyerOrdersProvider).any((o) => o.orderStatus == OrderStatus.deliveryRequired)) ...[
            const SizedBox(height: 16),
            const Card(
              color: AppColors.surfaceVariant,
              child: ListTile(
                leading: Icon(Icons.local_shipping, color: AppColors.transporter),
                title: Text('Your products are ready to be delivered.'),
                subtitle: Text('Open the Orders tab to choose AgriLink Transport.'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ResponsiveStatGrid(
            children: [
              StatCard(
                label: 'Open listings',
                value: '${available.length}',
                icon: Icons.inventory_2,
                color: AppColors.business,
              ),
              StatCard(
                label: 'My bids',
                value: '${myBids.length}',
                icon: Icons.gavel,
                color: AppColors.accent,
              ),
              StatCard(
                label: 'Orders',
                value: '${ref.watch(buyerOrdersProvider).length}',
                icon: Icons.local_shipping,
                color: AppColors.success,
              ),
              StatCard(
                label: 'Verified',
                value: profile?.isVerified == true ? 'Yes' : 'No',
                icon: Icons.verified_user,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const MarketVisibilityPanel(title: 'Shared supply visibility'),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Featured Supply',
            actionLabel: 'View All',
            onAction: () => context.push(AppRoutes.businessMarketplace),
          ),
          const SizedBox(height: 12),
          ResponsiveWrapGrid(
            children: [
              for (final p in available.take(3))
                ProductionCard(
                  production: p,
                  onTap: () => context.push('/business/production/${p.id}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuyerBidsTab extends ConsumerWidget {
  const _BuyerBidsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bids = ref.watch(buyerBidsProvider);
    final lkr = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    if (bids.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(appDataProvider.notifier).refreshBids(UserRole.business),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            EmptyStateView(
              icon: Icons.gavel,
              title: 'No bids yet',
              message: 'Open a listing in the marketplace and place a bid. Status updates appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(appDataProvider.notifier).refreshBids(UserRole.business),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final bid = bids[index];
          return Card(
            child: ListTile(
              leading: CropThumb(cropType: bid.cropType),
              title: Text(bid.cropType, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${bid.quantity.toStringAsFixed(0)} ${bid.unit}\n'
                '${lkr.format(bid.amount)}/${bid.unit}  ·  Total: ${lkr.format(bid.totalAmount)}',
              ),
              isThreeLine: true,
              trailing: StatusChip(
                label: bid.status.label,
                color: switch (bid.status) {
                  BidStatus.pending => AppColors.accent,
                  BidStatus.accepted => AppColors.success,
                  BidStatus.declined => AppColors.error,
                  BidStatus.expired => AppColors.textSecondary,
                },
              ),
              onTap: () => context.push('/business/production/${bid.listingId}'),
            ),
          );
        },
      ),
    );
  }
}
