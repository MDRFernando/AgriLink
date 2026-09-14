import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';

class ProductionCard extends StatelessWidget {
  const ProductionCard({
    super.key,
    required this.production,
    this.onTap,
    this.trailing,
  });

  final Production production;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CropImage(cropType: production.cropType, height: 168),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    child: StatusChip(
                      label: production.auctionStatus == ListingAuctionStatus.open
                          ? production.status.label
                          : production.auctionStatus.label,
                      color: _statusColor(production.status),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    production.cropType,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    production.farmerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _InfoItem(
                        icon: Icons.scale,
                        label:
                            '${production.quantity.toStringAsFixed(0)} ${production.unit}',
                      ),
                      _InfoItem(
                        icon: Icons.calendar_today,
                        label: DateFormat('MMM d, yyyy')
                            .format(production.harvestDate),
                      ),
                      _InfoItem(
                        icon: Icons.verified_outlined,
                        label: production.qualityGrade.label,
                      ),
                      _InfoItem(
                        icon: Icons.gavel,
                        label: production.currentHighestBid > 0
                            ? 'LKR ${production.currentHighestBid.toStringAsFixed(0)}/kg'
                            : 'Reserve LKR ${production.reservePrice.toStringAsFixed(0)}/kg',
                      ),
                      _InfoItem(
                        icon: Icons.location_on_outlined,
                        label: '${production.location}, ${production.region}',
                      ),
                    ],
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ProductionStatus status) {
    switch (status) {
      case ProductionStatus.available:
        return AppColors.success;
      case ProductionStatus.readyForHarvest:
        return AppColors.accent;
      case ProductionStatus.growing:
        return AppColors.info;
      case ProductionStatus.planned:
        return AppColors.textSecondary;
      case ProductionStatus.sold:
        return AppColors.primary;
      case ProductionStatus.expired:
        return AppColors.error;
    }
  }
}

class DemandCard extends StatelessWidget {
  const DemandCard({super.key, required this.demand});

  final DemandRequest demand;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CropImage(cropType: demand.cropType, height: 140),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        demand.cropType,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    StatusChip(
                      label: demand.status.label,
                      color: demand.status == DemandStatus.open
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  demand.requesterName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _InfoItem(
                      icon: Icons.scale,
                      label:
                          '${demand.quantityNeeded.toStringAsFixed(0)} ${demand.unit}',
                    ),
                    _InfoItem(
                      icon: Icons.event,
                      label: 'By ${DateFormat('MMM d').format(demand.deadline)}',
                    ),
                    _InfoItem(
                      icon: Icons.location_on_outlined,
                      label: demand.region,
                    ),
                  ],
                ),
                if (demand.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    demand.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InterestCard extends StatelessWidget {
  const InterestCard({
    super.key,
    required this.interest,
    this.onAccept,
    this.onReject,
    this.showActions = false,
  });

  final PurchaseInterest interest;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CropThumb(cropType: interest.cropType, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interest.businessName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${interest.quantity.toStringAsFixed(0)} ${interest.unit} of ${interest.cropType}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: interest.status.label,
                  color: _interestColor(interest.status),
                ),
              ],
            ),
            if (interest.message != null) ...[
              const SizedBox(height: 8),
              Text(
                interest.message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(interest.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            if (showActions && interest.status == InterestStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      child: const Text('Accept'),
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

  Color _interestColor(InterestStatus status) {
    switch (status) {
      case InterestStatus.pending:
        return AppColors.warning;
      case InterestStatus.accepted:
        return AppColors.success;
      case InterestStatus.rejected:
        return AppColors.error;
    }
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

Color alertTypeColor(SupplyAlertType type) {
  switch (type) {
    case SupplyAlertType.shortage:
      return AppColors.error;
    case SupplyAlertType.surplus:
      return AppColors.success;
    case SupplyAlertType.stable:
      return AppColors.info;
  }
}
