import 'dart:ui';

/// Centralised colour palette mirroring the Calium web design tokens.
///
/// Every colour constant here maps 1-to-1 with its CSS-variable counterpart
/// so the mobile and web experiences remain visually consistent.
abstract class AppColors {
  // ─── Backgrounds ──────────────────────────────────────────────────────
  /// OLED-friendly pitch-black background (`--background` on web).
  static const Color background = Color(0xFF0A0A0C);

  /// Card / surface colour (`--card` on web).
  static const Color surfaceDark = Color(0xFF131317);

  /// Elevated surface / muted background (`--muted` on web).
  static const Color surfaceElevated = Color(0xFF1B1C22);

  /// 70 % opacity [surfaceDark] – used for glassmorphism overlays.
  static const Color glassBackground = Color(0xB3131317);

  // ─── Brand ────────────────────────────────────────────────────────────
  /// Rose-500 primary accent (`--primary` on web).
  static const Color primary = Color(0xFFF43F5E);

  /// Semi-transparent glow variant of [primary].
  static const Color primaryGlow = Color(0x66F43F5E);

  /// Rose-600 deeper accent for pressed / active states.
  static const Color accentCrimson = Color(0xFFE11D48);

  // ─── Semantic ─────────────────────────────────────────────────────────
  /// Rating stars / score badges.
  static const Color ratingAmber = Color(0xFFFFB800);

  /// Positive status indicators.
  static const Color successGreen = Color(0xFF00E676);

  // ─── Text ─────────────────────────────────────────────────────────────
  /// High-emphasis text (`--foreground` on web).
  static const Color textPrimary = Color(0xFFF5F5F7);

  /// Medium-emphasis text (`--muted-foreground` on web).
  static const Color textSecondary = Color(0xFFA0A3AE);

  /// Low-emphasis / disabled text.
  static const Color textMuted = Color(0xFF5C6170);

  // ─── Borders ──────────────────────────────────────────────────────────
  /// Subtle border colour (`--border` on web).
  static const Color border = Color(0xFF24262E);

  // ─── Shimmer ──────────────────────────────────────────────────────────
  /// Shimmer base (dark).
  static const Color shimmerBase = Color(0xFF161820);

  /// Shimmer highlight (light sweep).
  static const Color shimmerHighlight = Color(0xFF262936);
}
