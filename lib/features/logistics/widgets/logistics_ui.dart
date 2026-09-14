import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';

final lkr = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

String formatKg(double kg) => '${kg.toStringAsFixed(0)} kg';

class MoneyRow extends StatelessWidget {
  const MoneyRow({super.key, required this.label, required this.amount, this.emphasize = false});

  final String label;
  final double amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400))),
          Text(lkr.format(amount), style: TextStyle(fontWeight: FontWeight.w700, color: emphasize ? AppColors.primary : null)),
        ],
      ),
    );
  }
}

class LogisticsTimeline extends StatelessWidget {
  const LogisticsTimeline({super.key, required this.job});

  final TransportJob job;

  static const stages = [
    TransportStatus.requested,
    TransportStatus.assigned,
    TransportStatus.accepted,
    TransportStatus.waitingPickup,
    TransportStatus.arrivedAtPickup,
    TransportStatus.loaded,
    TransportStatus.inTransit,
    TransportStatus.arrivedAtDestination,
    TransportStatus.delivered,
    TransportStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = stages.indexOf(job.status);
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    i <= currentIndex ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: i <= currentIndex ? AppColors.success : AppColors.textHint,
                    size: 20,
                  ),
                  if (i < stages.length - 1)
                    Container(
                      width: 2,
                      height: 22,
                      color: i < currentIndex ? AppColors.success : AppColors.divider,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    stages[i].label,
                    style: TextStyle(
                      fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w400,
                      color: i <= currentIndex ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class RouteMapPreview extends StatelessWidget {
  const RouteMapPreview({super.key, required this.job});

  final TransportJob job;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _RoutePainter(job: job),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: StatusChip(label: job.status.label, color: AppColors.transporter),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Text(
                'ETA ${job.etaDelivery ?? '2:00 PM'}  •  ${job.distanceKm.toStringAsFixed(0)} km',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.job});

  final TransportJob job;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF1B4D3E);
    canvas.drawRect(Offset.zero & size, bg);
    final road = Paint()
      ..color = const Color(0xFF81C784)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final start = Offset(size.width * 0.18, size.height * 0.7);
    final end = Offset(size.width * 0.82, size.height * 0.28);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.1, end.dx, end.dy);
    canvas.drawPath(path, road);

    final farm = Paint()..color = AppColors.farmer;
    final buyer = Paint()..color = AppColors.business;
    canvas.drawCircle(start, 8, farm);
    canvas.drawCircle(end, 8, buyer);

    final t = switch (job.status) {
      TransportStatus.inTransit => 0.55,
      TransportStatus.arrivedAtDestination || TransportStatus.delivered || TransportStatus.completed => 0.95,
      TransportStatus.loaded => 0.18,
      _ => 0.08,
    };
    final metric = path.computeMetrics().first;
    final pos = metric.getTangentForOffset(metric.length * t)?.position ?? start;
    canvas.drawCircle(pos, 10, Paint()..color = AppColors.transporter);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.job.status != job.status;
}

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.order, this.job});

  final MarketOrder order;
  final TransportJob? job;

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
                CropThumb(cropType: order.product, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${order.product} — ${formatKg(order.quantityKg)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                StatusChip(label: order.orderStatus.label, color: AppColors.business),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.code}  •  ${order.farmerName}'),
            const SizedBox(height: 8),
            MoneyRow(label: 'Product (${lkr.format(order.unitPrice)}/kg)', amount: order.productTotal),
            if (job != null) MoneyRow(label: 'Transport (separate)', amount: job!.estimatedCost),
            if (job != null)
              MoneyRow(label: 'Total to business', amount: order.productTotal + job!.estimatedCost, emphasize: true),
            const Divider(),
            Text('Pickup: ${order.pickupLabel}, ${order.pickupCity}'),
            if (job != null) Text('Delivery: ${job!.deliveryLabel}'),
          ],
        ),
      ),
    );
  }
}
