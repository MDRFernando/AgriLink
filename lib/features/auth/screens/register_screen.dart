import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(authProvider).selectedRole;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.roleSelection),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AgriLinkLogo(size: 56),
              const SizedBox(height: 24),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (selectedRole != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Registering as ${selectedRole.label}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 32),
              AppTextField(
                label: 'Full Name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                controller: _emailController,
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
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Register',
                isLoading: _isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 16),
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
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          register: true,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await ref.read(appDataProvider.notifier).syncFromApi(
          ref.read(authProvider).profile?.role,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final auth = ref.read(authProvider);
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
