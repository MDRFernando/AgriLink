import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const SizedBox(height: 16),
              const AgriLinkLogo(size: 56),
              const SizedBox(height: 16),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role to get started',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              _RoleCard(
                role: UserRole.farmer,
                color: AppColors.farmer,
                icon: Icons.agriculture,
                onTap: () => _selectRole(context, ref, UserRole.farmer),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role: UserRole.business,
                color: AppColors.business,
                icon: Icons.storefront,
                onTap: () => _selectRole(context, ref, UserRole.business),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role: UserRole.transporter,
                color: AppColors.transporter,
                icon: Icons.local_shipping,
                onTap: () => _selectRole(context, ref, UserRole.transporter),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role: UserRole.government,
                color: AppColors.government,
                icon: Icons.account_balance,
                onTap: () => _selectRole(context, ref, UserRole.government),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Already have an account? Sign in'),
                ),
              ),
              ],
            ),
          ),
        ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final UserRole role;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
