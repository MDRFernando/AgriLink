import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/logic/bidding_logic.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

class BusinessProductionDetailScreen extends ConsumerStatefulWidget {
  const BusinessProductionDetailScreen({super.key, required this.productionId});

  final String productionId;

  @override
  ConsumerState<BusinessProductionDetailScreen> createState() =>
      _BusinessProductionDetailScreenState();
}

class _BusinessProductionDetailScreenState
    extends ConsumerState<BusinessProductionDetailScreen> {
  final _bidController = TextEditingController();

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final production =
        ref.watch(appDataProvider.notifier).getProduction(widget.productionId);
    final history = ref.watch(listingBidsProvider(widget.productionId));
    final lkr = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

    if (production == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listing')),
        body: const EmptyStateView(
          icon: Icons.error_outline,
          title: 'Listing not found',
          message: 'This listing may no longer be available.',
        ),
      );
    }

    final minNext = BidEngine.minimumAcceptable(
      currentHighestBid: production.currentHighestBid,
      minIncrement: production.minIncrement,
    );
    final windowOpen = production.auctionStatus == ListingAuctionStatus.open &&
        (production.biddingWindowEnd == null ||
            DateTime.now().isBefore(production.biddingWindowEnd!));

    return Scaffold(
      appBar: AppBar(title: Text(production.cropType)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductionCard(production: production),
            const SizedBox(height: 24),
            Text(
              'Place a bid',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              windowOpen
                  ? 'Increment floor ${lkr.format(minNext)}/kg; reserve ${lkr.format(production.reservePrice)}/kg. Window ends '
                      '${production.biddingWindowEnd == null ? 'when closed' : DateFormat('MMM d, HH:mm').format(production.biddingWindowEnd!)}.'
                  : 'Bidding is closed on this listing.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Your bid (LKR / kg)',
              controller: _bidController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.gavel,
              hint: minNext.toStringAsFixed(0),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Submit bid',
              icon: Icons.send,
              onPressed: windowOpen ? () => _submit(production) : null,
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Bid history'),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Text('No bids yet. Be the first at or above the reserve.')
            else
              ...history.map(
                (b) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(b.buyerName),
                  subtitle: Text(DateFormat('MMM d, HH:mm').format(b.createdAt)),
                  trailing: Text(
                    '${lkr.format(b.amount)}/kg',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Supply details'),
            const SizedBox(height: 12),
            _DetailRow(label: 'Farmer', value: production.farmerName),
            _DetailRow(label: 'Grade', value: production.qualityGrade.label),
            _DetailRow(
              label: 'Available',
              value: '${production.quantity} ${production.unit}',
            ),
            _DetailRow(
              label: 'Reserve',
              value: '${lkr.format(production.reservePrice)}/kg',
            ),
            _DetailRow(
              label: 'Harvest',
              value: DateFormat('MMMM d, yyyy').format(production.harvestDate),
            ),
            _DetailRow(
              label: 'Location',
              value: '${production.location}, ${production.region}',
            ),
            if (production.notes != null)
              _DetailRow(label: 'Notes', value: production.notes!),
          ],
        ),
      ),
    );
  }

  void _submit(Production production) {
    final amount = double.tryParse(_bidController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a bid amount')),
      );
      return;
    }
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;
    final error = ref.read(appDataProvider.notifier).placeBid(
          listing: production,
          buyer: profile,
          amount: amount,
          notify: ref.read(logisticsProvider.notifier).notify,
        );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _bidController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bid placed. The farmer and other bidders will be notified.')),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
