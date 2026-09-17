import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/features/onboarding/welcome_style.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  static const roles = [
    _RoleVisual(
      role: UserRole.farmer,
      imageUrl:
          'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1400&q=80',
      icon: Icons.agriculture,
      fallbackColor: Color(0xFF3E6B3A),
    ),
    _RoleVisual(
      role: UserRole.business,
      imageUrl:
          'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=1400&q=80',
      icon: Icons.shopping_cart_outlined,
      fallbackColor: Color(0xFF8A4B2F),
    ),
    _RoleVisual(
      role: UserRole.transporter,
      imageUrl:
          'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?auto=format&fit=crop&w=1400&q=80',
      icon: Icons.local_shipping_outlined,
      fallbackColor: Color(0xFF2F4A5C),
    ),
    _RoleVisual(
      role: UserRole.government,
      cropType: 'Tea',
      icon: Icons.agriculture_outlined,
      fallbackColor: Color(0xFF2F4A35),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WelcomeStyle.paper,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 740;
          final heroHeight = compact
              ? (constraints.maxHeight * 0.38).clamp(200.0, 250.0)
              : (constraints.maxHeight * 0.52).clamp(360.0, 560.0);
          final roles = _RoleSection(
            onSelect: (role) => _selectRole(context, ref, role),
            onSignIn: () => context.go(AppRoutes.login),
          );

          if (compact) {
            return Column(
              children: [
                SizedBox(
                  height: heroHeight,
                  child: _Hero(onSignIn: () => context.go(AppRoutes.login)),
                ),
                Expanded(child: SingleChildScrollView(child: roles)),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: heroHeight,
                  child: _Hero(onSignIn: () => context.go(AppRoutes.login)),
                ),
              ),
              SliverToBoxAdapter(child: roles),
            ],
          );
        },
      ),
    );
  }

  void _selectRole(BuildContext context, WidgetRef ref, UserRole role) {
    ref.read(authProvider.notifier).selectRole(role);
    if (role == UserRole.farmer) {
      context.go(AppRoutes.register);
    } else {
      context.go(AppRoutes.login);
    }
  }
}

class _RoleSection extends StatelessWidget {
  const _RoleSection({required this.onSelect, required this.onSignIn});

  final ValueChanged<UserRole> onSelect;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHOOSE YOUR ROLE', style: WelcomeStyle.eyebrow),
              const SizedBox(height: 10),
              Text(
                'Four ways to enter the marketplace.',
                style: WelcomeStyle.display.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the path that matches how you work with farms and markets.',
                style: TextStyle(
                  color: WelcomeStyle.muted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ResponsiveWrapGrid(
                minTileWidth: 240,
                maxColumns: 4,
                spacing: 18,
                children: [
                  for (final visual in RoleSelectionScreen.roles)
                    _RoleCard(
                      visual: visual,
                      onTap: () => onSelect(visual.role),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: onSignIn,
                  style: TextButton.styleFrom(foregroundColor: WelcomeStyle.ink),
                  child: const Text('Already have an account? Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight < 280;
        final titleSize = tight
            ? 28.0
            : (MediaQuery.sizeOf(context).width < 380 ? 30.0 : 42.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            const CropImage(cropType: 'Produce', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x661B1916),
                    Color(0x991B1916),
                    Color(0xCC1B1916),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 4, 24, tight ? 12 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppConstants.appName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 3.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: onSignIn,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(letterSpacing: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!tight) ...[
                      const Text(
                        'SRI LANKAN HARVEST, CONNECTED',
                        style: TextStyle(
                          color: WelcomeStyle.gold,
                          fontSize: 11,
                          letterSpacing: 3.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      'Welcome to AgriLink',
                      style: WelcomeStyle.display.copyWith(
                        color: Colors.white,
                        fontSize: titleSize,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(width: 44, height: 1, color: WelcomeStyle.gold),
                    const SizedBox(height: 10),
                    Text(
                      AppConstants.appTagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: tight ? 14 : 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoleVisual {
  const _RoleVisual({
    required this.role,
    this.imageUrl,
    this.cropType,
    required this.icon,
    required this.fallbackColor,
  });

  final UserRole role;
  final String? imageUrl;
  final String? cropType;
  final IconData icon;
  final Color fallbackColor;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.visual,
    required this.onTap,
  });

  final _RoleVisual visual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: visual.fallbackColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 0.78,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              _RoleBackdrop(visual: visual),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x99000000),
                      Color(0xCC000000),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(visual.icon, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      visual.role.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WelcomeStyle.display.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      visual.role.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBackdrop extends StatelessWidget {
  const _RoleBackdrop({required this.visual});

  final _RoleVisual visual;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: visual.fallbackColor,
      child: visual.cropType != null
          ? CropImage(cropType: visual.cropType!, fit: BoxFit.cover)
          : Image.network(
              visual.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return ColoredBox(color: visual.fallbackColor);
              },
              errorBuilder: (_, __, ___) => ColoredBox(
                color: visual.fallbackColor,
                child: Icon(
                  visual.icon,
                  color: Colors.white.withValues(alpha: 0.28),
                  size: 64,
                ),
              ),
            ),
    );
  }
}
