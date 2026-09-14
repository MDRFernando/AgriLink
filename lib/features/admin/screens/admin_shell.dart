import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/core/widgets/role_scaffold.dart';
import 'package:my_app/features/government/screens/government_logistics_screen.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Platform administration',
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Disputes',
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _ListingModerationTab(),
          GovernmentLogisticsScreen(),
        ],
      ),
    );
  }
}

class _ListingModerationTab extends ConsumerWidget {
  const _ListingModerationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(appDataProvider).productions;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Hide listings that are fraudulent or misdescribed (FR-11).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          );
        }
        final listing = listings[index - 1];
        return Card(
          child: ListTile(
            leading: CropThumb(cropType: listing.cropType),
            title: Text('${listing.cropType} · ${listing.farmerName}'),
            subtitle: Text(
              '${listing.quantity.toStringAsFixed(0)} ${listing.unit} · ${listing.auctionStatus.label}',
            ),
            trailing: TextButton(
              onPressed: () {
                ref.read(appDataProvider.notifier).moderateListing(
                      listing.id,
                      hidden: !listing.moderated,
                    );
              },
              child: Text(listing.moderated ? 'Restore' : 'Hide'),
            ),
          ),
        );
      },
    );
  }
}
