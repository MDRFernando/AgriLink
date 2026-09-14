import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/constants/crop_assets.dart';
import 'package:my_app/core/theme/app_colors.dart';

class CropImage extends StatelessWidget {
  const CropImage({
    super.key,
    required this.cropType,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String cropType;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      CropAssets.pathFor(cropType),
      height: height,
      width: width ?? double.infinity,
      fit: fit,
      errorBuilder: (_, __, ___) => Image.asset(
        CropAssets.fallback,
        height: height,
        width: width ?? double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _CropImageFallback(
          cropType: cropType,
          height: height,
          width: width,
        ),
      ),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class CropThumb extends StatelessWidget {
  const CropThumb({
    super.key,
    required this.cropType,
    this.size = 52,
    this.radius = 14,
  });

  final String cropType;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CropImage(
      cropType: cropType,
      height: size,
      width: size,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

class CropTypeSelector extends StatelessWidget {
  const CropTypeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.crops = AppConstants.cropTypes,
  });

  final String? selected;
  final ValueChanged<String> onSelected;
  final List<String> crops;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640
            ? 5
            : constraints.maxWidth >= 420
                ? 4
                : 3;
        final spacing = 12.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final crop in crops)
              SizedBox(
                width: tileWidth,
                child: _CropChoiceCard(
                  cropType: crop,
                  selected: selected == crop,
                  onTap: () => onSelected(crop),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ResponsiveWrapGrid extends StatelessWidget {
  const ResponsiveWrapGrid({
    super.key,
    required this.children,
    this.minTileWidth = 320,
    this.spacing = 16,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = (width / minTileWidth).floor().clamp(1, maxColumns);
        final tileWidth = columns == 1
            ? width
            : (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

class ResponsiveStatGrid extends StatelessWidget {
  const ResponsiveStatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        final spacing = 12.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

class _CropChoiceCard extends StatelessWidget {
  const _CropChoiceCard({
    required this.cropType,
    required this.selected,
    required this.onTap,
  });

  final String cropType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CropImage(
                cropType: cropType,
                height: 86,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(
                  cropType,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropImageFallback extends StatelessWidget {
  const _CropImageFallback({
    required this.cropType,
    this.height,
    this.width,
  });

  final String cropType;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco, color: AppColors.primary, size: 32),
          const SizedBox(height: 4),
          Text(
            cropType,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
