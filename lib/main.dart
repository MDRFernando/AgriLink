import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/bootstrap/url_strategy_stub.dart'
    if (dart.library.html) 'package:my_app/core/bootstrap/url_strategy_web.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/router/app_router.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/shared/providers/auction_runtime.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  runApp(const ProviderScope(child: AgriLinkApp()));
}

/// Root widget for the AgriLink farmer / buyer / government marketplace.
class AgriLinkApp extends ConsumerWidget {
  const AgriLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(routerProvider);
    ref.watch(auctionCloseJobProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) {
          return const Material(
            color: AppColors.primary,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.textPrimary),
          child: child,
        );
      },
    );
  }
}
