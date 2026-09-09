import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

/// Chapter 5.2 close_expired_listings — scheduled job (every minute).
final auctionCloseJobProvider = Provider<void>((ref) {
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    ref.read(appDataProvider.notifier).closeExpiredAuctions(
          notify: ref.read(logisticsProvider.notifier).notify,
        );
  });
  ref.onDispose(timer.cancel);
});
