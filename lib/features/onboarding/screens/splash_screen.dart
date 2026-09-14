import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/features/onboarding/welcome_style.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      if (auth.profile?.isVerified ?? false) {
        return;
      }
      context.go(AppRoutes.profileSetup);
      return;
    }

    context.go(AppRoutes.roleSelection);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WelcomeStyle.cream,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AgriLinkLogo(size: 52),
              const SizedBox(height: 28),
              Text(
                AppConstants.appName,
                style: WelcomeStyle.display.copyWith(
                  fontSize: 42,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 48,
                height: 1,
                color: WelcomeStyle.gold,
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appTagline,
                style: const TextStyle(
                  color: WelcomeStyle.muted,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
