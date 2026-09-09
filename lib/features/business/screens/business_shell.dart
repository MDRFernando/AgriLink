import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/role_scaffold.dart';
import 'package:my_app/features/business/screens/business_demand_screen.dart';
import 'package:my_app/features/business/screens/business_interests_screen.dart';
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
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Buyer Dashboard',
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Marketplace'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake), label: 'Interests'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Demand'),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _BusinessOverviewTab(),
          MarketplaceScreen(),
          BuyerOrdersTab(),
          BusinessInterestsScreen(),
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
    final myBids = ref
        .watch(appDataProvider)
        .bids
        .where((b) => b.buyerId == profile?.id)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${profile?.organizationName ?? profile?.name ?? 'Business'}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'View listings, place bids, and arrange farm-to-business delivery',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
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
          ...available.take(3).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductionCard(
                    production: p,
                    onTap: () => context.push('/business/production/${p.id}'),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
