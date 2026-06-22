/// ALPACA Design System — Shared Tokens & Theme
///
/// Use these constants across all screens for consistent styling.
/// Based on designGuide.md — premium editorial minimalist aesthetic.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
export 'app_colors.dart';

// ─── Material ThemeData ───────────────────────────────────────────────────────
/// Provides [AppTheme.light] and [AppTheme.dark] for use in [MaterialApp].
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.amber,
          surface: AppColors.surface,
          error: AppColors.error,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
          ),
        ),
        dividerColor: AppColors.border,
        cardColor: AppColors.surface,
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.amber,
          surface: const Color(0xFF1C1917),
          error: AppColors.error,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF141210),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      );
}

// ─── Typography ───────────────────────────────────────────────────────────────
class AppText {
  AppText._();

  // DM Serif Display — brand, titles, headings
  static TextStyle display(
          {double size = 32, Color color = AppColors.textPrimary, double height = 1.2}) =>
      GoogleFonts.dmSerifDisplay(fontSize: size, color: color, height: height);

  // Inter — all UI
  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Convenience shorthands
  static TextStyle sectionHeader({Color color = AppColors.textPrimary}) =>
      ui(size: 15, weight: FontWeight.w700, color: color);

  static TextStyle label({Color color = AppColors.textSecondary}) =>
      ui(size: 12, weight: FontWeight.w500, color: color);

  static TextStyle micro({Color color = AppColors.textTertiary}) =>
      ui(size: 10, weight: FontWeight.w400, color: color);

  static TextStyle price({double size = 17}) =>
      ui(size: size, weight: FontWeight.w700, color: AppColors.amber);

  static TextStyle button() =>
      ui(size: 15, weight: FontWeight.w600, color: Colors.white);
}

// ─── Spacing ─────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const screenH = 24.0; // horizontal screen padding
}

// ─── Shape ───────────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const pill = 100.0;
}

// ─── Shadows ─────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  /// Very subtle shadow for cards
  static List<BoxShadow> card() => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

/// Price tag formatted as "Rp X.XXX"
String formatRupiah(double price) {
  final formatted = price.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp $formatted';
}

/// Category display pill
class AlpacaCategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const AlpacaCategoryPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppText.ui(
            size: 13,
            weight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Full-width primary CTA
class AlpacaPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AlpacaPrimaryButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppText.button()),
                ],
              ),
      ),
    );
  }
}

/// Empty state widget
class AlpacaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AlpacaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, size: 32, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppText.display(size: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppText.ui(
                  size: 14, color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AlpacaPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
