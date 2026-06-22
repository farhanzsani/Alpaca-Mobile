/// Color constants for the ALPACA application.
///
/// Uses deep natural green and earth-tone colors suitable for an agrarian
/// and culinary tourism platform.
library;

import 'package:flutter/material.dart';

/// Application color palette.
abstract final class AppColors {
  // ─── Primary Green Palette ───────────────────────────────────────────
  static const Color primary = Color(0xFF2A5C45);
  static const Color primaryLight = Color(0xFF4A7C64);
  static const Color primaryDark = Color(0xFF1E3A2F);
  static const Color primaryContainer = Color(0xFFE8F2EC);
  static const Color onPrimaryContainer = Color(0xFF1E3A2F);

  // ─── Secondary Earth Amber Palette ───────────────────────────────────
  static const Color secondary = Color(0xFFC4813A);
  static const Color secondaryLight = Color(0xFFF5E9D8);
  static const Color secondaryDark = Color(0xFF8F5822);
  static const Color secondaryContainer = Color(0xFFF5E9D8);
  static const Color onSecondaryContainer = Color(0xFF5E3914);

  // ─── Tertiary Amber Palette ──────────────────────────────────────────
  static const Color tertiary = Color(0xFFC4813A);
  static const Color tertiaryLight = Color(0xFFF5E9D8);
  static const Color tertiaryDark = Color(0xFF8F5822);
  static const Color tertiaryContainer = Color(0xFFF5E9D8);
  static const Color onTertiaryContainer = Color(0xFF5E3914);

  // ─── Neutral Palette ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF7F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0EDE8);
  static const Color onSurface = Color(0xFF1C1917);
  static const Color onSurfaceVariant = Color(0xFF6B6560);
  static const Color outline = Color(0xFFE2DDD8);
  static const Color outlineVariant = Color(0xFFECE7E2);

  // ─── Semantic Colors ─────────────────────────────────────────────────
  static const Color success = Color(0xFF2A5C45);
  static const Color successContainer = Color(0xFFE8F2EC);
  static const Color warning = Color(0xFFC4813A);
  static const Color warningContainer = Color(0xFFF5E9D8);
  static const Color error = Color(0xFFB04A3A);
  static const Color errorContainer = Color(0xFFFAECEA);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF4A7C64);
  static const Color infoContainer = Color(0xFFE8F2EC);

  // ─── Theme Compatibility Aliases ─────────────────────────────────────
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textTertiary = disabled;
  static const Color border = outline;
  static const Color borderFocus = primary;
  static const Color bg = background;
  static const Color amber = secondary;
  static const Color amberLight = secondaryLight;
  static const Color surfaceMuted = surfaceVariant;
  static const Color successLight = successContainer;
  static const Color errorLight = errorContainer;
  static const Color warningLight = warningContainer;
  static const Color primaryMuted = primaryLight;

  // ─── Additional UI Colors ────────────────────────────────────────────
  static const Color divider = Color(0xFFE2DDD8);
  static const Color disabled = Color(0xFF9E9890);
  static const Color shadow = Color(0x0D1C1917);
  static const Color scrim = Color(0x3D1C1917);
  static const Color shimmerBase = Color(0xFFF0EDE8);
  static const Color shimmerHighlight = Color(0xFFF7F5F0);

  // ─── Dark Theme Colors ───────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF141210);
  static const Color darkSurface = Color(0xFF1C1917);
  static const Color darkSurfaceVariant = Color(0xFF2E2A27);
  static const Color darkOnSurface = Color(0xFFFAF9F6);
  static const Color darkPrimaryContainer = Color(0xFF1E3A2F);
  static const Color darkSecondaryContainer = Color(0xFF5E3914);
  static const Color darkTertiaryContainer = Color(0xFF5E3914);
}
