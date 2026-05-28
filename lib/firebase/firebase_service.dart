/// Base Firebase service with centralized error handling, logging, and retry logic.
///
/// All Firebase service classes extend this base class to inherit
/// consistent error handling and retry mechanisms for transient failures.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/utils/result.dart';

/// Base class for all Firebase services.
///
/// Provides:
/// - Centralized error handling via [handleException]
/// - Retry logic for transient failures via [retryOperation]
/// - Structured logging via [logger]
///
/// Usage:
/// ```dart
/// class MyService extends FirebaseService {
///   Future<Result<String>> fetchData() => guardedCall(() async {
///     final doc = await firestore.collection('data').doc('id').get();
///     return doc.data()!['value'] as String;
///   });
/// }
/// ```
abstract class FirebaseService {
  FirebaseService({Logger? logger}) : logger = logger ?? Logger();

  /// Logger instance for structured logging.
  final Logger logger;

  /// Default maximum number of retry attempts for transient failures.
  static const int defaultMaxRetries = 3;

  /// Default initial delay between retries (doubles with each attempt).
  static const Duration defaultRetryDelay = Duration(milliseconds: 500);

  /// Set of Firebase error codes considered transient and eligible for retry.
  static const Set<String> _transientErrorCodes = {
    'unavailable',
    'deadline-exceeded',
    'resource-exhausted',
    'aborted',
    'internal',
  };

  /// Wraps a Firebase operation in try-catch and returns a [Result].
  ///
  /// Catches Firebase-specific exceptions and converts them to typed
  /// [AppException]s using [FirebaseExceptionHandler].
  ///
  /// [operation] - The async operation to execute.
  /// [operationName] - A descriptive name for logging purposes.
  Future<Result<T>> guardedCall<T>(
    Future<T> Function() operation, {
    String operationName = 'Firebase operation',
  }) async {
    try {
      logger.d('$operationName: started');
      final result = await operation();
      logger.d('$operationName: completed successfully');
      return Result.success(result);
    } on FirebaseAuthException catch (e, st) {
      logger.e('$operationName: FirebaseAuthException', error: e, stackTrace: st);
      return Result.failure(FirebaseExceptionHandler.handleAuth(e));
    } on FirebaseException catch (e, st) {
      logger.e('$operationName: FirebaseException', error: e, stackTrace: st);
      return Result.failure(FirebaseExceptionHandler.handleFirestore(e));
    } on AppException catch (e, st) {
      logger.e('$operationName: AppException', error: e, stackTrace: st);
      return Result.failure(e);
    } catch (e, st) {
      logger.e('$operationName: unexpected error', error: e, stackTrace: st);
      return Result.failure(
        AppException(
          message: 'Terjadi kesalahan yang tidak terduga: ${e.toString()}',
          code: 'UNKNOWN_ERROR',
          originalException: e,
        ),
      );
    }
  }

  /// Executes an operation with automatic retry for transient failures.
  ///
  /// Uses exponential backoff between retries. Only retries errors
  /// with codes in [_transientErrorCodes].
  ///
  /// [operation] - The async operation to execute.
  /// [operationName] - A descriptive name for logging purposes.
  /// [maxRetries] - Maximum number of retry attempts.
  /// [retryDelay] - Initial delay between retries (doubles each attempt).
  Future<Result<T>> retryOperation<T>(
    Future<T> Function() operation, {
    String operationName = 'Firebase operation',
    int maxRetries = defaultMaxRetries,
    Duration retryDelay = defaultRetryDelay,
  }) async {
    int attempts = 0;
    Duration currentDelay = retryDelay;

    while (true) {
      attempts++;
      try {
        logger.d('$operationName: attempt $attempts/$maxRetries');
        final result = await operation();
        logger.d('$operationName: completed successfully on attempt $attempts');
        return Result.success(result);
      } on FirebaseAuthException catch (e, st) {
        logger.e(
          '$operationName: FirebaseAuthException on attempt $attempts',
          error: e,
          stackTrace: st,
        );
        return Result.failure(FirebaseExceptionHandler.handleAuth(e));
      } on FirebaseException catch (e, st) {
        if (attempts >= maxRetries || !_isTransientError(e.code)) {
          logger.e(
            '$operationName: non-retryable FirebaseException on attempt $attempts',
            error: e,
            stackTrace: st,
          );
          return Result.failure(FirebaseExceptionHandler.handleFirestore(e));
        }
        logger.w(
          '$operationName: transient error on attempt $attempts, '
          'retrying in ${currentDelay.inMilliseconds}ms',
          error: e,
        );
        await Future<void>.delayed(currentDelay);
        currentDelay *= 2;
      } on AppException catch (e, st) {
        logger.e('$operationName: AppException on attempt $attempts', error: e, stackTrace: st);
        return Result.failure(e);
      } catch (e, st) {
        if (attempts >= maxRetries) {
          logger.e(
            '$operationName: unexpected error on final attempt $attempts',
            error: e,
            stackTrace: st,
          );
          return Result.failure(
            AppException(
              message: 'Terjadi kesalahan yang tidak terduga: ${e.toString()}',
              code: 'UNKNOWN_ERROR',
              originalException: e,
            ),
          );
        }
        logger.w(
          '$operationName: unexpected error on attempt $attempts, '
          'retrying in ${currentDelay.inMilliseconds}ms',
          error: e,
        );
        await Future<void>.delayed(currentDelay);
        currentDelay *= 2;
      }
    }
  }

  /// Determines if a Firebase error code represents a transient failure.
  bool _isTransientError(String code) => _transientErrorCodes.contains(code);

  /// Handles exceptions and converts them to [AppException].
  ///
  /// Useful for manual exception handling outside of [guardedCall].
  AppException handleException(Object error, [StackTrace? stackTrace]) {
    if (error is FirebaseAuthException) {
      return FirebaseExceptionHandler.handleAuth(error);
    } else if (error is FirebaseException) {
      return FirebaseExceptionHandler.handleFirestore(error);
    } else if (error is AppException) {
      return error;
    } else {
      return AppException(
        message: 'Terjadi kesalahan yang tidak terduga: ${error.toString()}',
        code: 'UNKNOWN_ERROR',
        originalException: error,
      );
    }
  }
}
