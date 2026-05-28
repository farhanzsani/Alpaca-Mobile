/// Global error handler for the ALPACA application.
///
/// Converts raw exceptions into user-friendly [AppException] instances
/// and provides centralized error logging.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_exception.dart';

/// Global error handler that converts exceptions to user-friendly messages.
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e, stackTrace) {
///   final appException = ErrorHandler.handle(e, stackTrace);
///   // Show appException.message to user
/// }
/// ```
abstract final class ErrorHandler {
  /// Converts any exception to a typed [AppException].
  ///
  /// Handles common exception types and provides appropriate
  /// user-facing messages in Indonesian.
  static AppException handle(Object error, [StackTrace? stackTrace]) {
    _logError(error, stackTrace);

    // Already an AppException, return as-is.
    if (error is AppException) {
      return error;
    }

    // Network/IO exceptions.
    if (error is SocketException) {
      return NetworkException.noConnection();
    }

    if (error is TimeoutException) {
      return NetworkException.timeout();
    }

    if (error is HttpException) {
      return const NetworkException(
        message: 'Terjadi kesalahan HTTP. Silakan coba lagi.',
        code: 'HTTP_ERROR',
      );
    }

    // Format exceptions.
    if (error is FormatException) {
      return AppException(
        message: 'Format data tidak valid: ${error.message}',
        code: 'FORMAT_ERROR',
        originalException: error,
      );
    }

    // Type errors.
    if (error is TypeError) {
      return AppException(
        message: 'Terjadi kesalahan tipe data.',
        code: 'TYPE_ERROR',
        originalException: error,
      );
    }

    // Range errors.
    if (error is RangeError) {
      return AppException(
        message: 'Nilai di luar rentang yang diizinkan.',
        code: 'RANGE_ERROR',
        originalException: error,
      );
    }

    // State errors.
    if (error is StateError) {
      return AppException(
        message: 'Operasi tidak valid pada kondisi saat ini.',
        code: 'STATE_ERROR',
        originalException: error,
      );
    }

    // Unhandled exceptions.
    if (error is Exception) {
      return AppException(
        message: 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.',
        code: 'UNKNOWN_ERROR',
        originalException: error,
      );
    }

    // Errors (non-Exception throwables).
    return AppException(
      message: 'Terjadi kesalahan sistem. Silakan hubungi dukungan.',
      code: 'SYSTEM_ERROR',
      originalException: error,
    );
  }

  /// Returns a user-friendly error message string from any exception.
  ///
  /// Convenience method that extracts just the message.
  static String getMessage(Object error, [StackTrace? stackTrace]) {
    return handle(error, stackTrace).message;
  }

  /// Determines if an error is a network-related issue.
  static bool isNetworkError(Object error) {
    if (error is NetworkException) return true;
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    return false;
  }

  /// Determines if an error is an authentication issue.
  static bool isAuthError(Object error) {
    if (error is AuthException) return true;
    return false;
  }

  /// Determines if the error is retryable.
  ///
  /// Network errors and timeouts are generally retryable.
  /// Auth errors and validation errors are not.
  static bool isRetryable(Object error) {
    if (error is NetworkException) return true;
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is AuthException) return false;
    if (error is DataException) {
      return error.code == 'NOT_FOUND' || error.code == 'QUOTA_EXCEEDED'
          ? false
          : true;
    }
    return false;
  }

  /// Logs the error for debugging purposes.
  ///
  /// In debug mode, prints to console. In release mode,
  /// this is where you would send to a crash reporting service
  /// (e.g., Firebase Crashlytics).
  static void _logError(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('ERROR: $error');
      if (stackTrace != null) {
        debugPrint('STACK TRACE:\n$stackTrace');
      }
      debugPrint('═══════════════════════════════════════════════════');
    }
    // TODO: In production, report to Firebase Crashlytics:
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Sets up global error handling for the Flutter app.
  ///
  /// Call this in `main()` before `runApp()`:
  /// ```dart
  /// void main() {
  ///   ErrorHandler.initialize();
  ///   runApp(const MyApp());
  /// }
  /// ```
  static void initialize() {
    // Handle Flutter framework errors.
    FlutterError.onError = (FlutterErrorDetails details) {
      _logError(details.exception, details.stack);
      if (kReleaseMode) {
        // Report to crash analytics in production.
        // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    // Handle errors outside of Flutter framework (async errors).
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _logError(error, stack);
      if (kReleaseMode) {
        // Report to crash analytics in production.
        // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }
}
