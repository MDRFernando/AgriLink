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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orgController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedRegion;
  BuyerType? _buyerType;
  TransporterType? _transporterType;
  bool _buyerTypeError = false;
  bool _transporterTypeError = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _nameController.text = profile?.name ?? '';
    _emailController.text = profile?.email ?? '';
    _phoneController.text = profile?.phone ?? '';
    _orgController.text = profile?.organizationName ?? '';
    _addressController.text = profile?.address ?? '';
    _selectedRegion = profile?.region;
    _buyerType = profile?.buyerType;
    _transporterType = profile?.transporterType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).selectedRole ?? UserRole.farmer;
    final isBuyer = role == UserRole.business;
    final isTransporter = role == UserRole.transporter;
    final usesWhiteSurface = isBuyer || isTransporter;

    return Scaffold(
      backgroundColor: usesWhiteSurface ? AppColors.surface : AppColors.background,
      appBar: AppBar(
        title: Text(
          isBuyer
              ? 'Complete Buyer Profile'
              : isTransporter
                  ? 'Complete Transport Profile'
                  : 'Complete Your Profile',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBuyer
                    ? 'Tell us how you buy produce'
                    : isTransporter
                        ? 'Tell us how you provide transport'
                        : 'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isBuyer
                    ? 'Company buyers and individual buyers can both use AgriLink.'
                    : isTransporter
                        ? 'Transport companies and individual providers can both use AgriLink.'
                        : 'This helps connect you with the right marketplace participants.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              if (isBuyer) ...[
                Text(
                  'How are you buying?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _TypeChoiceSelector(
                  children: [
                    _TypeChoiceCard(
                      title: BuyerType.company.label,
                      description: BuyerType.company.description,
                      icon: Icons.storefront_outlined,
                      selected: _buyerType == BuyerType.company,
                      onTap: () => setState(() {
                        _buyerType = BuyerType.company;
                        _buyerTypeError = false;
                      }),
                    ),
                    _TypeChoiceCard(
                      title: BuyerType.individual.label,
                      description: BuyerType.individual.description,
                      icon: Icons.person_outline,
                      selected: _buyerType == BuyerType.individual,
                      onTap: () => setState(() {
                        _buyerType = BuyerType.individual;
                        _buyerTypeError = false;
                        _orgController.clear();
                      }),
                    ),
                  ],
                ),
                if (_buyerTypeError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Buyer type is required',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
              ],
              if (isTransporter) ...[
                Text(
                  'How do you provide transport?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _TypeChoiceSelector(
                  children: [
                    _TypeChoiceCard(
                      title: TransporterType.company.label,
                      description: TransporterType.company.description,
                      icon: Icons.local_shipping_outlined,
                      selected: _transporterType == TransporterType.company,
                      onTap: () => setState(() {
                        _transporterType = TransporterType.company;
                        _transporterTypeError = false;
                      }),
                    ),
                    _TypeChoiceCard(
                      title: TransporterType.individual.label,
                      description: TransporterType.individual.description,
                      icon: Icons.person_outline,
                      selected: _transporterType == TransporterType.individual,
                      onTap: () => setState(() {
                        _transporterType = TransporterType.individual;
                        _transporterTypeError = false;
                        _orgController.clear();
                      }),
                    ),
                  ],
                ),
                if (_transporterTypeError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Transport provider type is required',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
              ],
              AppTextField(
                label: 'Full Name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              if (isBuyer) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  readOnly: true,
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: isBuyer ? 'Contact Number' : 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Phone is required' : null,
              ),
              if (isBuyer && _buyerType == BuyerType.company) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Company Name',
                  controller: _orgController,
                  prefixIcon: Icons.business_outlined,
                  validator: (v) {
                    if (_buyerType == BuyerType.company &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
              ],
              if (isTransporter && _transporterType == TransporterType.company) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Company Name',
                  controller: _orgController,
                  prefixIcon: Icons.business_outlined,
                  validator: (v) {
                    if (_transporterType == TransporterType.company &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
              ],
              if (role == UserRole.government || role == UserRole.admin) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Agency Name',
                  controller: _orgController,
                  prefixIcon: Icons.business_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Organization name is required' : null,
                ),
              ],
              if (isBuyer) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Address',
                  controller: _addressController,
                  prefixIcon: Icons.home_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Address is required' : null,
                ),
              ],
              const SizedBox(height: 16),
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
    final role = ref.read(authProvider).selectedRole ?? UserRole.farmer;
    final isBuyer = role == UserRole.business;
    final isTransporter = role == UserRole.transporter;

    if (isBuyer && _buyerType == null) {
      setState(() => _buyerTypeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select how you are buying')),
      );
      return;
    }

    if (isTransporter && _transporterType == null) {
      setState(() => _transporterTypeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select how you provide transport')),
      );
      return;
    }

    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a region')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final hideCompany = (isBuyer && _buyerType == BuyerType.individual) ||
        (isTransporter && _transporterType == TransporterType.individual);

    ref.read(authProvider.notifier).completeProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          organizationName: hideCompany
              ? null
              : (_orgController.text.trim().isEmpty
                  ? null
                  : _orgController.text.trim()),
          region: _selectedRegion,
          address: isBuyer ? _addressController.text.trim() : null,
          buyerType: isBuyer ? _buyerType : null,
          transporterType: isTransporter ? _transporterType : null,
        );

    final profileRole = ref.read(authProvider).profile?.role ?? UserRole.farmer;
    switch (profileRole) {
      case UserRole.business:
        context.go(AppRoutes.businessHome);
      case UserRole.government:
        context.go(AppRoutes.governmentHome);
      case UserRole.admin:
        context.go(AppRoutes.adminHome);
      case UserRole.transporter:
        context.go(AppRoutes.transporterHome);
      case UserRole.farmer:
        context.go(AppRoutes.farmerHome);
    }
  }
}

class _TypeChoiceSelector extends StatelessWidget {
  const _TypeChoiceSelector({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 360;
        if (stacked) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class _TypeChoiceCard extends StatelessWidget {
  const _TypeChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceVariant : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textHint,
                size: 22,
              ),
              const SizedBox(height: 10),
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 26,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
