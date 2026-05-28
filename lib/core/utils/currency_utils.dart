/// Indonesian Rupiah currency formatting utilities.
///
/// Provides consistent currency formatting for the ALPACA application.
library;

import 'package:intl/intl.dart';

/// Currency formatting utilities for Indonesian Rupiah (IDR).
///
/// Usage:
/// ```dart
/// print(CurrencyUtils.format(150000)); // "Rp150.000"
/// print(CurrencyUtils.formatCompact(1500000)); // "Rp1,5 jt"
/// print(CurrencyUtils.parse("150.000")); // 150000.0
/// ```
abstract final class CurrencyUtils {
  /// Standard Rupiah formatter with symbol.
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Rupiah formatter with decimal places.
  static final NumberFormat _currencyFormatDecimal = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 2,
  );

  /// Number formatter without currency symbol.
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'id_ID');

  /// Number formatter with decimals.
  static final NumberFormat _numberFormatDecimal =
      NumberFormat('#,##0.##', 'id_ID');

  // ─── Formatting Methods ──────────────────────────────────────────────

  /// Formats a number as Indonesian Rupiah.
  ///
  /// Example: `format(150000)` returns `"Rp150.000"`
  static String format(num amount) {
    return _currencyFormat.format(amount);
  }

  /// Formats a number as Rupiah with decimal places.
  ///
  /// Example: `formatDecimal(150000.50)` returns `"Rp150.000,50"`
  static String formatDecimal(num amount) {
    return _currencyFormatDecimal.format(amount);
  }

  /// Formats a number without currency symbol.
  ///
  /// Example: `formatNumber(150000)` returns `"150.000"`
  static String formatNumber(num amount) {
    return _numberFormat.format(amount);
  }

  /// Formats a number without currency symbol, with decimals.
  ///
  /// Example: `formatNumberDecimal(150000.5)` returns `"150.000,5"`
  static String formatNumberDecimal(num amount) {
    return _numberFormatDecimal.format(amount);
  }

  /// Formats a number in compact form with Indonesian abbreviations.
  ///
  /// Examples:
  /// - `formatCompact(1500)` returns `"Rp1,5 rb"`
  /// - `formatCompact(1500000)` returns `"Rp1,5 jt"`
  /// - `formatCompact(1500000000)` returns `"Rp1,5 M"`
  static String formatCompact(num amount) {
    if (amount.abs() >= 1000000000) {
      final value = amount / 1000000000;
      return 'Rp${_formatCompactValue(value)} M';
    }
    if (amount.abs() >= 1000000) {
      final value = amount / 1000000;
      return 'Rp${_formatCompactValue(value)} jt';
    }
    if (amount.abs() >= 1000) {
      final value = amount / 1000;
      return 'Rp${_formatCompactValue(value)} rb';
    }
    return format(amount);
  }

  /// Formats a compact value, removing unnecessary decimals.
  static String _formatCompactValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    // Use comma as decimal separator for Indonesian locale.
    final formatted = value.toStringAsFixed(1);
    return formatted.replaceAll('.', ',');
  }

  /// Formats a price range.
  ///
  /// Example: `formatRange(50000, 150000)` returns `"Rp50.000 - Rp150.000"`
  static String formatRange(num min, num max) {
    return '${format(min)} - ${format(max)}';
  }

  /// Formats with a "+" or "-" prefix for transaction display.
  ///
  /// Example:
  /// - `formatSigned(50000)` returns `"+Rp50.000"`
  /// - `formatSigned(-50000)` returns `"-Rp50.000"`
  static String formatSigned(num amount) {
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix${format(amount.abs())}';
  }

  /// Formats as "Gratis" if zero, otherwise formats normally.
  static String formatOrFree(num amount) {
    if (amount == 0) return 'Gratis';
    return format(amount);
  }

  // ─── Parsing Methods ─────────────────────────────────────────────────

  /// Parses a formatted currency string back to a number.
  ///
  /// Handles strings with or without the "Rp" prefix.
  /// Returns `null` if parsing fails.
  ///
  /// Examples:
  /// - `parse("Rp150.000")` returns `150000.0`
  /// - `parse("150.000")` returns `150000.0`
  /// - `parse("150000")` returns `150000.0`
  static double? parse(String value) {
    try {
      // Remove currency symbol and whitespace.
      String cleaned = value.trim().replaceAll('Rp', '').trim();

      // Handle empty string.
      if (cleaned.isEmpty) return null;

      // Remove thousand separators (dots in Indonesian format).
      // Replace comma decimal separator with dot.
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');

      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Parses a currency string, returning 0 if parsing fails.
  static double parseOrZero(String value) {
    return parse(value) ?? 0.0;
  }

  // ─── Validation Methods ──────────────────────────────────────────────

  /// Returns true if the string is a valid currency amount.
  static bool isValidAmount(String value) {
    return parse(value) != null;
  }

  /// Returns true if the amount is within a valid range for Rupiah.
  static bool isValidPrice(num amount) {
    return amount >= 0 && amount <= 999999999999; // Max ~1 trillion
  }

  // ─── Calculation Helpers ─────────────────────────────────────────────

  /// Calculates discount percentage.
  ///
  /// Returns the percentage as an integer (e.g., 25 for 25%).
  static int calculateDiscountPercent(num originalPrice, num discountedPrice) {
    if (originalPrice <= 0) return 0;
    final discount = ((originalPrice - discountedPrice) / originalPrice) * 100;
    return discount.round();
  }

  /// Formats a discount percentage.
  ///
  /// Example: `formatDiscount(25)` returns `"-25%"`
  static String formatDiscount(int percent) {
    return '-$percent%';
  }

  /// Calculates and formats the savings amount.
  ///
  /// Example: `formatSavings(200000, 150000)` returns `"Hemat Rp50.000"`
  static String formatSavings(num originalPrice, num discountedPrice) {
    final savings = originalPrice - discountedPrice;
    if (savings <= 0) return '';
    return 'Hemat ${format(savings)}';
  }
}
