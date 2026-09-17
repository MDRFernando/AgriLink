import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/cards.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
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
  final _quantityController = TextEditingController();
  bool _submitting = false;
  bool _loadingListing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadListing());
  }

  Future<void> _loadListing() async {
    final existing =
        ref.read(appDataProvider.notifier).getProduction(widget.productionId);
    if (existing == null) {
      setState(() => _loadingListing = true);
    }
    await ref
        .read(appDataProvider.notifier)
        .refreshListingAndBuyerBids(widget.productionId);
    if (!mounted) return;
    setState(() => _loadingListing = false);
  }

  @override
  void dispose() {
    _bidController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Production? _listing() {
    for (final production in ref.watch(appDataProvider).productions) {
      if (production.id == widget.productionId) return production;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final production = _listing();
    final myBids = ref.watch(buyerListingBidsProvider(widget.productionId));
    final profile = ref.watch(authProvider).profile;
    final lkr = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    if (production == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listing')),
        body: _loadingListing
            ? const Center(child: CircularProgressIndicator())
            : const EmptyStateView(
                icon: Icons.error_outline,
                title: 'Listing not found',
                message: 'This listing may no longer be available.',
              ),
      );
    }

    final isBuyer = profile?.role == UserRole.business;
    final windowOpen = production.auctionStatus == ListingAuctionStatus.open &&
        production.quantity > 0 &&
        (production.status == ProductionStatus.available ||
            production.status == ProductionStatus.readyForHarvest) &&
        (production.biddingWindowEnd == null ||
            DateTime.now().isBefore(production.biddingWindowEnd!));
    final canPlaceBid = isBuyer && windowOpen && profile != null;
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final amount = double.tryParse(_bidController.text.trim()) ?? 0;
    final total = quantity > 0 && amount > 0 ? quantity * amount : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(production.cropType)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductionCard(production: production),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Listing details'),
            const SizedBox(height: 12),
            _DetailRow(label: 'Crop', value: production.cropType),
            _DetailRow(label: 'Farmer', value: production.farmerName),
            _DetailRow(
              label: 'Available quantity',
              value: '${production.quantity.toStringAsFixed(0)} ${production.unit}',
            ),
            _DetailRow(
              label: 'Starting price',
              value: '${lkr.format(production.reservePrice)}/${production.unit}',
            ),
            _DetailRow(
              label: 'Location',
              value: '${production.location}, ${production.region}',
            ),
            _DetailRow(
              label: 'Bid closing',
              value: production.biddingWindowEnd == null
                  ? 'When the listing is closed'
                  : DateFormat('MMM d, yyyy HH:mm')
                      .format(production.biddingWindowEnd!),
            ),
            const SizedBox(height: 24),
            Text(
              'Place a bid',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              canPlaceBid
                  ? 'Enter the quantity you want and your price per ${production.unit}. The farmer will review your offer.'
                  : _closedReason(production, isBuyer),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (canPlaceBid) ...[
              const SizedBox(height: 16),
              AppTextField(
                label: 'Quantity',
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.scale,
                hint: 'Enter quantity',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Bid Price Per Unit',
                controller: _bidController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.gavel,
                hint: 'Enter bid price',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text(
                'Total Bid Value',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                total > 0 ? lkr.format(total) : 'Rs. 0',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Place Bid',
                icon: Icons.send,
                isLoading: _submitting,
                onPressed: _submitting ? null : () => _submit(production),
              ),
            ],
            const SizedBox(height: 24),
            const SectionHeader(title: 'Your bids'),
            const SizedBox(height: 12),
            if (myBids.isEmpty)
              const Text('You have not placed a bid on this listing yet.')
            else
              ...myBids.map((b) => _BuyerBidTile(bid: b, lkr: lkr)),
          ],
        ),
      ),
    );
  }

  String _closedReason(Production production, bool isBuyer) {
    if (!isBuyer) {
      return 'Only buyers can place bids on listings.';
    }
    if (production.status == ProductionStatus.sold ||
        production.auctionStatus == ListingAuctionStatus.sold) {
      return 'This listing has been sold and is no longer open for bidding.';
    }
    if (production.status == ProductionStatus.expired ||
        production.auctionStatus == ListingAuctionStatus.expiredNoSale) {
      return 'This listing has expired and is no longer open for bidding.';
    }
    if (production.quantity <= 0) {
      return 'No remaining quantity is available.';
    }
    if (production.biddingWindowEnd != null &&
        DateTime.now().isAfter(production.biddingWindowEnd!)) {
      return 'The bidding window has closed.';
    }
    return 'Bidding is closed on this listing.';
  }

  Future<void> _submit(Production production) async {
    final quantity = double.tryParse(_quantityController.text.trim());
    final amount = double.tryParse(_bidController.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a quantity greater than zero')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid bid price')),
      );
      return;
    }
    if (quantity > production.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity exceeds available stock')),
      );
      return;
    }
    final profile = ref.read(authProvider).profile;
    if (profile == null || profile.role != UserRole.business) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in as a buyer to place a bid')),
      );
      return;
    }

    setState(() => _submitting = true);
    final error = await ref.read(appDataProvider.notifier).placeBid(
          listing: production,
          buyer: profile,
          amount: amount,
          quantity: quantity,
          notify: ref.read(logisticsProvider.notifier).notify,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _bidController.clear();
    _quantityController.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bid placed successfully. The farmer will review your offer.')),
    );
  }
}

class _BuyerBidTile extends StatelessWidget {
  const _BuyerBidTile({required this.bid, required this.lkr});

  final MarketBid bid;
  final NumberFormat lkr;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
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
      ),
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
            width: 140,
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
