/// Color constants for the ALPACA application.
///
/// Uses green and earth-tone colors suitable for an agrarian
/// and culinary tourism platform.
library;

import 'package:flutter/material.dart';

/// Application color palette.
///
/// The color scheme is inspired by nature and agriculture:
/// - Primary: Deep green (representing growth and agriculture)
/// - Secondary: Warm earth brown (representing soil and nature)
/// - Tertiary: Golden amber (representing harvest and warmth)
abstract final class AppColors {
  // ─── Primary Green Palette ───────────────────────────────────────────

  /// Primary green - main brand color.
  static const Color primary = Color(0xFF2E7D32);

  /// Light variant of primary.
  static const Color primaryLight = Color(0xFF60AD5E);

  /// Dark variant of primary.
  static const Color primaryDark = Color(0xFF005005);

  /// Primary container color for Material 3.
  static const Color primaryContainer = Color(0xFFA5D6A7);

  /// On primary container color.
  static const Color onPrimaryContainer = Color(0xFF002204);

  // ─── Secondary Earth Brown Palette ───────────────────────────────────

  /// Secondary color - warm earth brown.
  static const Color secondary = Color(0xFF6D4C41);

  /// Light variant of secondary.
  static const Color secondaryLight = Color(0xFF9C786C);

  /// Dark variant of secondary.
  static const Color secondaryDark = Color(0xFF40241A);

  /// Secondary container color for Material 3.
  static const Color secondaryContainer = Color(0xFFD7CCC8);

  /// On secondary container color.
  static const Color onSecondaryContainer = Color(0xFF1B0E0A);

  // ─── Tertiary Golden Amber Palette ───────────────────────────────────

  /// Tertiary color - golden amber (harvest).
  static const Color tertiary = Color(0xFFF9A825);

  /// Light variant of tertiary.
  static const Color tertiaryLight = Color(0xFFFFD95A);

  /// Dark variant of tertiary.
  static const Color tertiaryDark = Color(0xFFC17900);

  /// Tertiary container color for Material 3.
  static const Color tertiaryContainer = Color(0xFFFFECB3);

  /// On tertiary container color.
  static const Color onTertiaryContainer = Color(0xFF261900);

  // ─── Neutral Palette ─────────────────────────────────────────────────

  /// Background color.
  static const Color background = Color(0xFFFCFDF6);

  /// Surface color.
  static const Color surface = Color(0xFFFCFDF6);

  /// Surface variant.
  static const Color surfaceVariant = Color(0xFFE0E4D6);

  /// On surface color.
  static const Color onSurface = Color(0xFF1A1C18);

  /// On surface variant.
  static const Color onSurfaceVariant = Color(0xFF43483E);

  /// Outline color.
  static const Color outline = Color(0xFF73796D);

  /// Outline variant.
  static const Color outlineVariant = Color(0xFFC3C8BB);

  // ─── Semantic Colors ─────────────────────────────────────────────────

  /// Success color.
  static const Color success = Color(0xFF388E3C);

  /// Success container.
  static const Color successContainer = Color(0xFFC8E6C9);

  /// Warning color.
  static const Color warning = Color(0xFFF57C00);

  /// Warning container.
  static const Color warningContainer = Color(0xFFFFE0B2);

  /// Error color.
  static const Color error = Color(0xFFD32F2F);

  /// Error container.
  static const Color errorContainer = Color(0xFFFFCDD2);

  /// On error color.
  static const Color onError = Color(0xFFFFFFFF);

  /// Info color.
  static const Color info = Color(0xFF1976D2);

  /// Info container.
  static const Color infoContainer = Color(0xFFBBDEFB);

  // ─── Additional UI Colors ────────────────────────────────────────────

  /// Divider color.
  static const Color divider = Color(0xFFE0E0E0);

  /// Disabled color.
  static const Color disabled = Color(0xFFBDBDBD);

  /// Shadow color.
  static const Color shadow = Color(0x1A000000);

  /// Scrim color for overlays.
  static const Color scrim = Color(0x52000000);

  /// Shimmer base color for loading states.
  static const Color shimmerBase = Color(0xFFE0E0E0);

  /// Shimmer highlight color for loading states.
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ─── Dark Theme Colors ───────────────────────────────────────────────

  /// Dark theme background.
  static const Color darkBackground = Color(0xFF1A1C18);

  /// Dark theme surface.
  static const Color darkSurface = Color(0xFF1A1C18);

  /// Dark theme surface variant.
  static const Color darkSurfaceVariant = Color(0xFF43483E);

  /// Dark theme on surface.
  static const Color darkOnSurface = Color(0xFFE2E3DC);

  /// Dark theme primary container.
  static const Color darkPrimaryContainer = Color(0xFF1B5E20);

  /// Dark theme secondary container.
  static const Color darkSecondaryContainer = Color(0xFF4E342E);

  /// Dark theme tertiary container.
  static const Color darkTertiaryContainer = Color(0xFFE65100);
}
