import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orgController = TextEditingController();
  String? _selectedRegion;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).selectedRole ?? UserRole.farmer;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'This helps connect you with the right marketplace participants.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Full Name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              if (role != UserRole.farmer)
                AppTextField(
                  label: role == UserRole.business
                      ? 'Company Name'
                      : role == UserRole.transporter
                          ? 'Transport Company'
                          : 'Agency Name',
                  controller: _orgController,
                  prefixIcon: Icons.business_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Organization name is required' : null,
                ),
              if (role != UserRole.farmer) const SizedBox(height: 16),
              AppDropdownField<String>(
                label: 'Region',
                value: _selectedRegion,
                prefixIcon: Icons.location_on_outlined,
                items: AppConstants.regions,
                onChanged: (v) => setState(() => _selectedRegion = v),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Continue',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a region')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).completeProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          organizationName: _orgController.text.trim().isEmpty
              ? null
              : _orgController.text.trim(),
          region: _selectedRegion,
        );

    final role = ref.read(authProvider).profile?.role ?? UserRole.farmer;
    switch (role) {
      case UserRole.business:
        context.go(AppRoutes.businessHome);
      case UserRole.government:
        context.go(AppRoutes.governmentHome);
      case UserRole.transporter:
        context.go(AppRoutes.transporterHome);
      case UserRole.farmer:
        context.go(AppRoutes.farmerHome);
    }
  }
}
