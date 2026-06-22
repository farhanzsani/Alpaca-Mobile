/// Text style definitions for the ALPACA application.
///
/// Follows Material 3 type scale with custom Google Font configurations.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Application text styles based on Material 3 type scale.
///
/// Brand Display: DM Serif Display
/// Functional Interface: Plus Jakarta Sans
abstract final class AppTextStyles {
  // ─── Display Styles (DM Serif Display) ───────────────────────────────────

  /// Display large - used for brand display.
  static TextStyle get displayLarge => GoogleFonts.dmSerifDisplay(
        fontSize: 52,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: AppColors.onSurface,
      );

  /// Display medium.
  static TextStyle get displayMedium => GoogleFonts.dmSerifDisplay(
        fontSize: 40,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
        color: AppColors.onSurface,
      );

  /// Display small.
  static TextStyle get displaySmall => GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
        color: AppColors.onSurface,
      );

  // ─── Headline Styles (DM Serif Display) ──────────────────────────────────

  /// Headline large - section headers.
  static TextStyle get headlineLarge => GoogleFonts.dmSerifDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.25,
        color: AppColors.onSurface,
      );

  /// Headline medium.
  static TextStyle get headlineMedium => GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.29,
        color: AppColors.onSurface,
      );

  /// Headline small.
  static TextStyle get headlineSmall => GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.onSurface,
      );

  // ─── Title Styles (Inter) ────────────────────────────────────

  /// Title large - card titles, dialog titles.
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
        color: AppColors.onSurface,
      );

  /// Title medium.
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.50,
        color: AppColors.onSurface,
      );

  /// Title small.
  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.onSurface,
      );

  // ─── Body Styles (Inter) ─────────────────────────────────────

  /// Body large - primary body text.
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.50,
        color: AppColors.onSurface,
      );

  /// Body medium - default body text.
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.onSurface,
      );

  /// Body small - secondary body text.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.33,
        color: AppColors.onSurfaceVariant,
      );

  // ─── Label Styles (Inter) ────────────────────────────────────

  /// Label large - button text, prominent labels.
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.onSurface,
      );

  /// Label medium - form labels, tabs.
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.33,
        color: AppColors.onSurface,
      );

  /// Label small - captions, timestamps.
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.45,
        color: AppColors.onSurfaceVariant,
      );

  // ─── Custom Styles (Inter / DM Serif Display) ────────────────

  /// Price text style - used for displaying prices.
  static TextStyle get price => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.secondary,
      );

  /// Price large - used for prominent price displays.
  static TextStyle get priceLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.25,
        color: AppColors.secondary,
      );

  /// Badge text style.
  static TextStyle get badge => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.2,
        color: Colors.white,
      );

  /// Button text style.
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.43,
      );

  /// Input text style for form fields.
  static TextStyle get input => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.50,
        color: AppColors.onSurface,
      );

  /// Hint text style for form fields.
  static TextStyle get hint => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.50,
        color: AppColors.onSurfaceVariant,
      );
}
