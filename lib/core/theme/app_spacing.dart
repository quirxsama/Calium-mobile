/// Spatial design tokens for padding, gaps, and border radii.
///
/// Using a consistent spacing scale avoids magic numbers throughout the
/// widget tree and makes future design tweaks a single-file change.
abstract class AppSpacing {
  // ─── Scale ────────────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // ─── Layout ───────────────────────────────────────────────────────────
  static const double screenPadding = 16;
  static const double cardPadding = 12;
  static const double sectionGap = 24;

  // ─── Border Radii ─────────────────────────────────────────────────────
  static const double borderRadiusSm = 8;
  static const double borderRadiusMd = 12;
  static const double borderRadiusLg = 16;
  static const double borderRadiusXl = 20;

  // ─── Poster ───────────────────────────────────────────────────────────
  static const double posterWidth = 130.0;
  static const double posterAspectRatio = 0.7;
}
