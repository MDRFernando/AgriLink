import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/constants/sri_lanka_geo.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class CropPlanFormScreen extends ConsumerStatefulWidget {
  const CropPlanFormScreen({super.key, this.planId});

  final String? planId;

  @override
  ConsumerState<CropPlanFormScreen> createState() => _CropPlanFormScreenState();
}

class _CropPlanFormScreenState extends ConsumerState<CropPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  final _yieldController = TextEditingController();

  String? _cropType;
  String? _province;
  String? _district;
  String? _dsDivision;
  String? _village;
  CultivationSeason? _season;
  CropPlanStatus _status = CropPlanStatus.planned;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  CropPlan? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.planId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _loadExisting() {
    final plans = ref.read(appDataProvider).cropPlans;
    final match = plans.where((p) => p.id == widget.planId).toList();
    if (match.isEmpty) return;
    final plan = match.first;
    setState(() {
      _existing = plan;
      _cropType = plan.cropType;
      _province = plan.province;
      _district = plan.district;
      _dsDivision = plan.dsDivision;
      _village = plan.village;
      _season = plan.season;
      _status = plan.status;
      _month = plan.cultivationMonth;
      _year = plan.cultivationYear;
      _areaController.text = plan.areaAcres.toString();
      _notesController.text = plan.locationNotes ?? '';
      if (plan.expectedYieldKg != null) {
        _yieldController.text = plan.expectedYieldKg!.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _areaController.dispose();
    _notesController.dispose();
    _yieldController.dispose();
    super.dispose();
  }

  List<String> get _districtNames => _province == null
      ? const []
      : SriLankaGeo.districtsForProvince(_province!)
          .map((d) => d.name)
          .toList();

  List<String> get _dsNames {
    final district = SriLankaGeo.districtByName(_district ?? '');
    return district?.dsDivisions.map((d) => d.name).toList() ?? const [];
  }

  List<String> get _villageNames {
    final district = SriLankaGeo.districtByName(_district ?? '');
    final ds = district?.dsDivisions
        .where((d) => d.name == _dsDivision)
        .toList();
    if (ds == null || ds.isEmpty) return const [];
    return ds.first.villages;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_cropType == null ||
        _province == null ||
        _district == null ||
        _dsDivision == null ||
        _village == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select crop and full location')),
      );
      return;
    }

    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    final area = double.parse(_areaController.text);
    final yieldText = _yieldController.text.trim();
    final yieldKg = yieldText.isEmpty ? null : double.tryParse(yieldText);

    if (_existing != null) {
      ref.read(appDataProvider.notifier).updateCropPlan(
            _existing!.copyWith(
              cropType: _cropType,
              cultivationYear: _year,
              cultivationMonth: _month,
              season: _season,
              clearSeason: _season == null,
              areaAcres: area,
              province: _province,
              district: _district,
              dsDivision: _dsDivision,
              village: _village,
              locationNotes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              expectedYieldKg: yieldKg,
              status: _status,
            ),
          );
    } else {
      ref.read(appDataProvider.notifier).addCropPlan(
            CropPlan(
              id: 'plan-${DateTime.now().millisecondsSinceEpoch}',
              farmerId: profile.id,
              farmerName: profile.name.isEmpty ? 'Farmer' : profile.name,
              cropType: _cropType!,
              cultivationYear: _year,
              cultivationMonth: _month,
              season: _season,
              areaAcres: area,
              province: _province!,
              district: _district!,
              dsDivision: _dsDivision!,
              village: _village!,
              locationNotes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              expectedYieldKg: yieldKg,
              status: _status,
              createdAt: DateTime.now(),
            ),
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _existing == null
              ? 'Cultivation plan registered'
              : 'Cultivation plan updated',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(4, (i) => DateTime.now().year + i - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Register crop plan' : 'Edit crop plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you intend to cultivate?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your plan stays private as an individual record. Government users only see aggregated counts by village, DS Division, and district.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              AppDropdownField<String>(
                label: 'Crop',
                value: _cropType,
                prefixIcon: Icons.grass,
                items: AppConstants.cropTypes,
                onChanged: (v) => setState(() => _cropType = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppDropdownField<int>(
                      label: 'Month',
                      value: _month,
                      items: List<int>.generate(12, (i) => i + 1),
                      itemLabel: SriLankaGeo.monthLabel,
                      prefixIcon: Icons.calendar_today_outlined,
                      onChanged: (v) {
                        if (v != null) setState(() => _month = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdownField<int>(
                      label: 'Year',
                      value: _year,
                      items: years,
                      onChanged: (v) {
                        if (v != null) setState(() => _year = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppDropdownField<String>(
                label: 'Season (optional)',
                value: _season?.label ?? 'Not specified',
                items: const ['Not specified', 'Maha', 'Yala', 'Off-season'],
                onChanged: (v) => setState(() {
                  if (v == null || v == 'Not specified') {
                    _season = null;
                  } else if (v == 'Maha') {
                    _season = CultivationSeason.maha;
                  } else if (v == 'Yala') {
                    _season = CultivationSeason.yala;
                  } else {
                    _season = CultivationSeason.offSeason;
                  }
                }),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Cultivation area (acres)',
                controller: _areaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.square_foot,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid area';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Expected yield (kg, optional)',
                controller: _yieldController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.scale_outlined,
              ),
              const SizedBox(height: 24),
              Text(
                'Cultivation location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              AppDropdownField<String>(
                label: 'Province',
                value: _province,
                prefixIcon: Icons.map_outlined,
                items: SriLankaGeo.provinces,
                onChanged: (v) => setState(() {
                  _province = v;
                  _district = null;
                  _dsDivision = null;
                  _village = null;
                }),
              ),
              const SizedBox(height: 16),
              AppDropdownField<String>(
                label: 'District',
                value: _district,
                items: _districtNames,
                onChanged: (v) => setState(() {
                  _district = v;
                  _dsDivision = null;
                  _village = null;
                }),
              ),
              const SizedBox(height: 16),
              AppDropdownField<String>(
                label: 'DS Division',
                value: _dsDivision,
                items: _dsNames,
                onChanged: (v) => setState(() {
                  _dsDivision = v;
                  _village = null;
                }),
              ),
              const SizedBox(height: 16),
              AppDropdownField<String>(
                label: 'Village',
                value: _village,
                items: _villageNames,
                onChanged: (v) => setState(() => _village = v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Location notes (optional)',
                controller: _notesController,
                maxLines: 2,
                prefixIcon: Icons.notes_outlined,
              ),
              if (_existing != null) ...[
                const SizedBox(height: 16),
                AppDropdownField<CropPlanStatus>(
                  label: 'Status',
                  value: _status,
                  items: CropPlanStatus.values,
                  itemLabel: (s) => s.label,
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: _existing == null ? 'Save plan' : 'Update plan',
                icon: Icons.save_outlined,
                onPressed: _save,
              ),
              if (_existing != null &&
                  _existing!.status != CropPlanStatus.cancelled) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Cancel this plan',
                  isOutlined: true,
                  onPressed: () {
                    ref
                        .read(appDataProvider.notifier)
                        .cancelCropPlan(_existing!.id);
                    context.pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
