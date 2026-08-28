import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class AddProductionScreen extends ConsumerStatefulWidget {
  const AddProductionScreen({super.key});

  @override
  ConsumerState<AddProductionScreen> createState() => _AddProductionScreenState();
}

class _AddProductionScreenState extends ConsumerState<AddProductionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _cropType;
  String? _region;
  String? _unit = 'kg';
  ProductionStatus _status = ProductionStatus.planned;
  DateTime _harvestDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _quantityController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Production')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Production Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your crop information to connect with buyers directly.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              AppDropdownField<String>(
                label: 'Crop Type',
                value: _cropType,
                prefixIcon: Icons.grass,
                items: AppConstants.cropTypes,
                onChanged: (v) => setState(() => _cropType = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: 'Expected Quantity',
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.scale,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdownField<String>(
                      label: 'Unit',
                      value: _unit,
                      items: AppConstants.quantityUnits,
                      onChanged: (v) => setState(() => _unit = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppDropdownField<String>(
                label: 'Region',
                value: _region,
                prefixIcon: Icons.map_outlined,
                items: AppConstants.regions,
                onChanged: (v) => setState(() => _region = v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Location (City/Town)',
                controller: _locationController,
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),
              AppDropdownField<ProductionStatus>(
                label: 'Production Status',
                value: _status,
                prefixIcon: Icons.timeline,
                items: ProductionStatus.values,
                itemLabel: (s) => s.label,
                onChanged: (v) => setState(() => _status = v ?? ProductionStatus.planned),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expected Harvest Date'),
                subtitle: Text(
                  '${_harvestDate.day}/${_harvestDate.month}/${_harvestDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notes (optional)',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              AppButton(label: 'Save Production', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) setState(() => _harvestDate = date);
  }

  void _save() {
    if (_cropType == null || _region == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select crop type and region')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(authProvider).profile;
    if (profile == null) return;
    final production = Production(
      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
      farmerId: profile.id,
      farmerName: profile.name.isEmpty ? 'Farmer' : profile.name,
      cropType: _cropType!,
      quantity: double.parse(_quantityController.text),
      unit: _unit!,
      harvestDate: _harvestDate,
      region: _region!,
      location: _locationController.text.trim(),
      status: _status,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    ref.read(appDataProvider.notifier).addProduction(production);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Production added successfully')),
    );
    context.pop();
  }
}
