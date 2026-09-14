import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String? _cropFilter;
  String? _regionFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var productions = ref.watch(availableProductionsProvider);

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      productions = productions
          .where((p) =>
              p.cropType.toLowerCase().contains(query) ||
              p.farmerName.toLowerCase().contains(query) ||
              p.location.toLowerCase().contains(query))
          .toList();
    }
    if (_cropFilter != null) {
      productions = productions.where((p) => p.cropType == _cropFilter).toList();
    }
    if (_regionFilter != null) {
      productions = productions.where((p) => p.region == _regionFilter).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search crops, farmers, locations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _FilterChip(
                label: _cropFilter ?? 'Crop Type',
                onTap: () => _showCropFilter(),
                isActive: _cropFilter != null,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _regionFilter ?? 'Region',
                onTap: () => _showRegionFilter(),
                isActive: _regionFilter != null,
              ),
              if (_cropFilter != null || _regionFilter != null) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Clear'),
                  onPressed: () => setState(() {
                    _cropFilter = null;
                    _regionFilter = null;
                  }),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: productions.isEmpty
              ? const EmptyStateView(
                  icon: Icons.store,
                  title: 'No matching supply',
                  message: 'Try adjusting your filters or check back later.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ResponsiveWrapGrid(
                    children: [
                      for (final production in productions)
                        ProductionCard(
                          production: production,
                          onTap: () => context.push(
                            '/business/production/${production.id}',
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _showCropFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: AppConstants.cropTypes
              .map(
                (crop) => ListTile(
                  leading: CropThumb(cropType: crop, size: 44, radius: 12),
                  title: Text(crop),
                  onTap: () {
                    setState(() => _cropFilter = crop);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showRegionFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: AppConstants.regions
              .map(
                (region) => ListTile(
                  title: Text(region),
                  onTap: () {
                    setState(() => _regionFilter = region);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    required this.isActive,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(
        Icons.filter_list,
        size: 18,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
      backgroundColor: isActive ? AppColors.surfaceVariant : null,
      onPressed: onTap,
    );
  }
}
