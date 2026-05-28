/// Firebase request interceptor for the ALPACA application.
///
/// Provides logging, retry logic, timeout handling, and exception
/// mapping for all Firebase operations (Firestore, Auth, Storage).
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/utils/result.dart';

/// Configuration for the Firebase interceptor.
class FirebaseInterceptorConfig {
  /// Creates a [FirebaseInterceptorConfig].
  const FirebaseInterceptorConfig({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 30),
    this.enableLogging = true,
    this.retryableErrorCodes = const [
      'unavailable',
      'deadline-exceeded',
      'resource-exhausted',
      'aborted',
      'internal',
    ],
  });

  /// Maximum number of retry attempts for failed requests.
  final int maxRetries;

  /// Base delay between retry attempts (uses exponential backoff).
  final Duration retryDelay;

  /// Timeout duration for Firebase operations.
  final Duration timeout;

  /// Whether to log all requests and responses.
  final bool enableLogging;

  /// Firebase error codes that are eligible for retry.
  final List<String> retryableErrorCodes;
}

/// Interceptor for Firebase requests providing logging, retry, and error handling.
///
/// Wraps Firebase operations with:
/// - Request/response logging
/// - Error logging with stack traces
/// - Configurable retry logic with exponential backoff
/// - Timeout handling
/// - Exception mapping to typed [AppException]s
/// - Generic [Result<T>] return type
///
/// Usage:
/// ```dart
/// final interceptor = FirebaseInterceptor();
///
/// final result = await interceptor.execute<DocumentSnapshot>(
///   operation: 'getUser',
///   action: () => firestore.collection('users').doc(uid).get(),
/// );
///
/// result.when(
///   success: (snapshot) => print(snapshot.data()),
///   failure: (error) => print(error.message),
/// );
/// ```
class FirebaseInterceptor {
  /// Creates a [FirebaseInterceptor] with optional configuration.
  FirebaseInterceptor({
    FirebaseInterceptorConfig? config,
    Logger? logger,
  })  : _config = config ?? const FirebaseInterceptorConfig(),
        _logger = logger ?? Logger();

  final FirebaseInterceptorConfig _config;
  final Logger _logger;

  /// Executes a Firebase operation with logging, retry, and error handling.
  ///
  /// [operation] - A descriptive name for the operation (used in logs).
  /// [action] - The async Firebase operation to execute.
  /// [maxRetries] - Override the default max retries for this operation.
  /// [timeout] - Override the default timeout for this operation.
  ///
  /// Returns a [Result<T>] containing either the success value or an [AppException].
  Future<Result<T>> execute<T>({
    required String operation,
    required Future<T> Function() action,
    int? maxRetries,
    Duration? timeout,
  }) async {
    final effectiveMaxRetries = maxRetries ?? _config.maxRetries;
    final effectiveTimeout = timeout ?? _config.timeout;
    final stopwatch = Stopwatch()..start();

    _logRequest(operation);

    var attempt = 0;
    Object? lastError;
    StackTrace? lastStackTrace;

    while (attempt <= effectiveMaxRetries) {
      try {
        final result = await action().timeout(effectiveTimeout);

        stopwatch.stop();
        _logResponse(operation, stopwatch.elapsedMilliseconds);

        return Result.success(result);
      } on TimeoutException catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        _logError(operation, e, st, attempt, effectiveMaxRetries);

        if (attempt >= effectiveMaxRetries) break;

        attempt++;
        await _waitForRetry(attempt);
      } on FirebaseAuthException catch (e, st) {
        // Auth exceptions are generally not retryable
        stopwatch.stop();
        _logError(operation, e, st, attempt, effectiveMaxRetries);

        final appException = FirebaseExceptionHandler.handleAuth(e);
        return Result.failure(appException);
      } on FirebaseException catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        _logError(operation, e, st, attempt, effectiveMaxRetries);

        // Check if the error is retryable
        if (!_isRetryable(e.code) || attempt >= effectiveMaxRetries) {
          stopwatch.stop();
          final appException = _mapFirebaseException(e);
          return Result.failure(appException);
        }

        attempt++;
        await _waitForRetry(attempt);
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        _logError(operation, e, st, attempt, effectiveMaxRetries);

        if (attempt >= effectiveMaxRetries) break;

        attempt++;
        await _waitForRetry(attempt);
      }
    }

    // All retries exhausted
    stopwatch.stop();
    _logger.e(
      '[$operation] All $effectiveMaxRetries retries exhausted '
      '(${stopwatch.elapsedMilliseconds}ms)',
      error: lastError,
      stackTrace: lastStackTrace,
    );

    return Result.failure(
      _mapUnknownException(lastError, lastStackTrace),
    );
  }

  /// Executes a Firebase operation without retry (single attempt).
  ///
  /// Useful for operations that should not be retried (e.g., writes
  /// that are not idempotent).
  Future<Result<T>> executeOnce<T>({
    required String operation,
    required Future<T> Function() action,
    Duration? timeout,
  }) {
    return execute<T>(
      operation: operation,
      action: action,
      maxRetries: 0,
      timeout: timeout,
    );
  }

  /// Checks if an error code is eligible for retry.
  bool _isRetryable(String? code) {
    if (code == null) return false;
    return _config.retryableErrorCodes.contains(code);
  }

  /// Waits before retrying with exponential backoff.
  Future<void> _waitForRetry(int attempt) async {
    final delay = _config.retryDelay * (1 << (attempt - 1)); // Exponential backoff
    _logger.d('Retrying in ${delay.inMilliseconds}ms (attempt $attempt)');
    await Future<void>.delayed(delay);
  }

  /// Maps a [FirebaseException] to a typed [AppException].
  AppException _mapFirebaseException(FirebaseException e) {
    // Handle Firestore exceptions
    if (e.plugin == 'cloud_firestore') {
      return FirebaseExceptionHandler.handleFirestore(e);
    }

    // Handle Storage exceptions
    if (e.plugin == 'firebase_storage') {
      return _mapStorageException(e);
    }

    // Generic Firebase exception
    return AppException(
      message: e.message ?? 'Terjadi kesalahan Firebase.',
      code: e.code,
      originalException: e,
    );
  }

  /// Maps a Firebase Storage exception to a typed [AppException].
  AppException _mapStorageException(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return DataException.notFound('File');
      case 'unauthorized':
      case 'unauthenticated':
        return AuthException.unauthorized();
      case 'retry-limit-exceeded':
        return NetworkException.timeout();
      case 'canceled':
        return const AppException(
          message: 'Upload dibatalkan.',
          code: 'UPLOAD_CANCELLED',
        );
      case 'invalid-checksum':
        return const MediaException(
          message: 'File rusak saat upload. Silakan coba lagi.',
          code: 'INVALID_CHECKSUM',
        );
      default:
        return AppException(
          message: e.message ?? 'Terjadi kesalahan storage.',
          code: e.code,
          originalException: e,
        );
    }
  }

  /// Maps an unknown exception to an [AppException].
  AppException _mapUnknownException(Object? error, StackTrace? stackTrace) {
    if (error is TimeoutException) {
      return NetworkException.timeout();
    }

    return AppException(
      message: 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.',
      code: 'UNKNOWN_ERROR',
      originalException: error,
    );
  }

  /// Logs an outgoing request.
  void _logRequest(String operation) {
    if (!_config.enableLogging) return;
    _logger.d('[$operation] Request started');
  }

  /// Logs a successful response.
  void _logResponse(String operation, int durationMs) {
    if (!_config.enableLogging) return;
    _logger.d('[$operation] Response received (${durationMs}ms)');
  }

  /// Logs an error during an operation.
  void _logError(
    String operation,
    Object error,
    StackTrace stackTrace,
    int attempt,
    int maxRetries,
  ) {
    if (!_config.enableLogging) return;
    _logger.e(
      '[$operation] Error (attempt ${attempt + 1}/${maxRetries + 1}): $error',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
