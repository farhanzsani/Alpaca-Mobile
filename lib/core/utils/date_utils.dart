/// Date formatting utilities for the ALPACA application.
///
/// Provides consistent date/time formatting using Indonesian locale.
library;

import 'package:intl/intl.dart';

/// Date and time formatting utilities.
///
/// All formatters use the Indonesian locale ('id_ID') by default.
///
/// Usage:
/// ```dart
/// final now = DateTime.now();
/// print(AppDateUtils.formatDate(now)); // "28 Mei 2026"
/// print(AppDateUtils.formatDateTime(now)); // "28 Mei 2026, 14:30"
/// print(AppDateUtils.formatRelative(now)); // "Baru saja"
/// ```
abstract final class AppDateUtils {
  static const String _locale = 'id_ID';

  // ─── Formatters ──────────────────────────────────────────────────────

  /// Full date format: "28 Mei 2026"
  static final DateFormat _fullDate = DateFormat('d MMMM yyyy', _locale);

  /// Short date format: "28 Mei"
  static final DateFormat _shortDate = DateFormat('d MMMM', _locale);

  /// Numeric date format: "28/05/2026"
  static final DateFormat _numericDate = DateFormat('dd/MM/yyyy', _locale);

  /// Date with day name: "Kamis, 28 Mei 2026"
  static final DateFormat _dateWithDay = DateFormat('EEEE, d MMMM yyyy', _locale);

  /// Short date with day: "Kam, 28 Mei"
  static final DateFormat _shortDateWithDay = DateFormat('E, d MMMM', _locale);

  /// Time format: "14:30"
  static final DateFormat _time = DateFormat('HH:mm', _locale);

  /// Time with seconds: "14:30:45"
  static final DateFormat _timeWithSeconds = DateFormat('HH:mm:ss', _locale);

  /// Date and time: "28 Mei 2026, 14:30"
  static final DateFormat _dateTime = DateFormat('d MMMM yyyy, HH:mm', _locale);

  /// Short date and time: "28/05/2026 14:30"
  static final DateFormat _shortDateTime = DateFormat('dd/MM/yyyy HH:mm', _locale);

  /// Month and year: "Mei 2026"
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', _locale);

  /// Short month and year: "Mei '26"
  static final DateFormat _shortMonthYear = DateFormat("MMM ''yy", _locale);

  // ─── Formatting Methods ──────────────────────────────────────────────

  /// Formats a date as "28 Mei 2026".
  static String formatDate(DateTime date) => _fullDate.format(date);

  /// Formats a date as "28 Mei" (without year).
  static String formatShortDate(DateTime date) => _shortDate.format(date);

  /// Formats a date as "28/05/2026".
  static String formatNumericDate(DateTime date) => _numericDate.format(date);

  /// Formats a date as "Kamis, 28 Mei 2026".
  static String formatDateWithDay(DateTime date) => _dateWithDay.format(date);

  /// Formats a date as "Kam, 28 Mei".
  static String formatShortDateWithDay(DateTime date) =>
      _shortDateWithDay.format(date);

  /// Formats time as "14:30".
  static String formatTime(DateTime date) => _time.format(date);

  /// Formats time as "14:30:45".
  static String formatTimeWithSeconds(DateTime date) =>
      _timeWithSeconds.format(date);

  /// Formats as "28 Mei 2026, 14:30".
  static String formatDateTime(DateTime date) => _dateTime.format(date);

  /// Formats as "28/05/2026 14:30".
  static String formatShortDateTime(DateTime date) =>
      _shortDateTime.format(date);

  /// Formats as "Mei 2026".
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// Formats as "Mei '26".
  static String formatShortMonthYear(DateTime date) =>
      _shortMonthYear.format(date);

  // ─── Relative Time ───────────────────────────────────────────────────

  /// Formats a date relative to now in Indonesian.
  ///
  /// Examples:
  /// - "Baru saja" (< 1 minute)
  /// - "5 menit yang lalu"
  /// - "2 jam yang lalu"
  /// - "Kemarin"
  /// - "3 hari yang lalu"
  /// - "28 Mei 2026" (> 7 days)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) {
      return _formatFutureRelative(difference.abs());
    }

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes menit yang lalu';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours jam yang lalu';
    }

    if (difference.inDays == 1) {
      return 'Kemarin';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    }

    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu yang lalu';
    }

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    }

    return formatDate(date);
  }

  /// Formats a future relative time.
  static String _formatFutureRelative(Duration difference) {
    if (difference.inMinutes < 60) {
      return 'Dalam ${difference.inMinutes} menit';
    }

    if (difference.inHours < 24) {
      return 'Dalam ${difference.inHours} jam';
    }

    if (difference.inDays == 1) {
      return 'Besok';
    }

    if (difference.inDays < 7) {
      return 'Dalam ${difference.inDays} hari';
    }

    return 'Dalam ${(difference.inDays / 7).floor()} minggu';
  }

  // ─── Utility Methods ─────────────────────────────────────────────────

  /// Returns true if the date is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Returns true if the date is yesterday.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Returns true if the date is in the current week.
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  /// Returns true if the date is in the current month.
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Returns the start of the day (00:00:00).
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Returns the end of the day (23:59:59.999).
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// Returns the start of the month.
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  /// Returns the end of the month.
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  /// Parses a date string in "dd/MM/yyyy" format.
  static DateTime? parseNumericDate(String dateString) {
    try {
      return _numericDate.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  /// Returns a greeting based on the current time of day.
  ///
  /// - "Selamat Pagi" (05:00 - 10:59)
  /// - "Selamat Siang" (11:00 - 14:59)
  /// - "Selamat Sore" (15:00 - 17:59)
  /// - "Selamat Malam" (18:00 - 04:59)
  static String getGreeting([DateTime? dateTime]) {
    final hour = (dateTime ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}
