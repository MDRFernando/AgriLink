import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/core/widgets/crop_image.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(authProvider).selectedRole;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.roleSelection),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final form = _LoginForm(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            selectedRole: selectedRole,
            isLoading: _isLoading,
            onSubmit: _login,
          );

          if (wide) {
            return Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 12, 24),
                    child: _LoginAgricultureVisual(),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 12, 48, 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final bannerHeight = (constraints.maxHeight * 0.28).clamp(168.0, 232.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: bannerHeight,
                  width: double.infinity,
                  child: const _LoginAgricultureVisual(),
                ),
                const SizedBox(height: 28),
                form,
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final auth = ref.read(authProvider);
    await ref.read(appDataProvider.notifier).syncFromApi(auth.profile?.role);
    await ref.read(logisticsProvider.notifier).syncOrders();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (auth.profile?.isVerified ?? false) {
      switch (auth.profile!.role) {
        case UserRole.farmer:
          context.go(AppRoutes.farmerHome);
        case UserRole.business:
          context.go(AppRoutes.businessHome);
        case UserRole.transporter:
          context.go(AppRoutes.transporterHome);
        case UserRole.government:
          context.go(AppRoutes.governmentHome);
        case UserRole.admin:
          context.go(AppRoutes.adminHome);
      }
    } else {
      context.go(AppRoutes.profileSetup);
    }
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.selectedRole,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final UserRole? selectedRole;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AgriLinkLogo(size: 56),
          const SizedBox(height: 24),
          Text(
            'Sign In',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (selectedRole != null) ...[
            const SizedBox(height: 8),
            Text(
              'Signing in as ${selectedRole!.label}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Password',
            controller: passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (v) =>
                v == null || v.isEmpty ? 'Password is required' : null,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text("Don't have an account? Register"),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginAgricultureVisual extends StatelessWidget {
  const _LoginAgricultureVisual();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CropImage(
                  cropType: 'Tea',
                  fit: BoxFit.cover,
                  width: width,
                  height: height,
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x221B5E20),
                        Color(0x991B5E20),
                        Color(0xCC1B5E20),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: 20,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Text(
                          'SRI LANKAN FARMING',
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppConstants.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppConstants.appTagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
