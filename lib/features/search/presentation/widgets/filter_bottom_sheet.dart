import 'package:flutter/material.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    this.initialGenreId,
    this.initialType,
    required this.onApply,
    super.key,
  });

  final String? initialGenreId;
  final String? initialType;
  final void Function(String? genreId, String? type) onApply;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedGenreId;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedGenreId = widget.initialGenreId;
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.borderRadiusLg),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtrele', style: AppTypography.headlineMedium),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedGenreId = null;
                        _selectedType = null;
                      });
                    },
                    child: Text(
                      'Sıfırla',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Format / Type
              Text('Format', style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _buildTypeChip('series', 'Anime Dizisi'),
                  _buildTypeChip('movie', 'Anime Filmi'),
                  _buildTypeChip('trdub', 'Türkçe Dublaj'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Genres
              Text('Türler', style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: ApiConstants.genreIds.entries.map((entry) {
                  final idStr = entry.value.toString();
                  final isSelected = _selectedGenreId == idStr;

                  return FilterChip(
                    label: Text(entry.key.replaceAll('_', ' ')),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusSm,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedGenreId = selected ? idStr : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedGenreId, _selectedType);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                  child: const Text('Filtreleri Uygula'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String typeKey, String label) {
    final isSelected = _selectedType == typeKey;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 0.5,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? typeKey : null;
        });
      },
    );
  }
}
