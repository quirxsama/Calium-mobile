import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';

/// Provides the application-wide [ThemeData].
///
/// Only a dark OLED variant is supported – matching the Calium web project.
class AppTheme {
  AppTheme._();

  static final ThemeData _darkTheme = _buildDarkTheme();

  /// The single dark theme used across the entire app (memoized for performance).
  static ThemeData darkTheme() => _darkTheme;

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,

      // ── Colour Scheme ──────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.accentCrimson,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        error: AppColors.accentCrimson,
        onError: AppColors.textPrimary,
        outline: AppColors.border,
      ),

      // ── App Bar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
        ),
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),

      // ── Card ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),

      // ── Elevated Button ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTypography.titleSmall,
        ),
      ),

      // ── Text Theme ─────────────────────────────────────────────────────
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelSmall: AppTypography.caption,
      ),

      // ── Misc ───────────────────────────────────────────────────────────
      splashColor: AppColors.primaryGlow,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.border,
    );
  }
}
