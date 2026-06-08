/// Custom exception classes for the ALPACA application.
///
/// Provides a hierarchy of typed exceptions for consistent
/// error handling throughout the app.
library;

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Base application exception.
///
/// All custom exceptions extend this class to provide
/// a consistent interface for error handling.
class AppException extends Equatable implements Exception {
  /// Creates an [AppException] with a [message] and optional [code] and [stackTrace].
  const AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  /// Human-readable error message.
  final String message;

  /// Machine-readable error code for programmatic handling.
  final String? code;

  /// The original exception that caused this error, if any.
  final Object? originalException;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Exception for network-related errors.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Koneksi jaringan bermasalah. Periksa koneksi internet Anda.',
    super.code = 'NETWORK_ERROR',
    super.originalException,
    this.statusCode,
  });

  /// HTTP status code, if applicable.
  final int? statusCode;

  /// No internet connection.
  factory NetworkException.noConnection() => const NetworkException(
        message: 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
        code: 'NO_CONNECTION',
      );

  /// Request timeout.
  factory NetworkException.timeout() => const NetworkException(
        message: 'Permintaan melebihi batas waktu. Silakan coba lagi.',
        code: 'TIMEOUT',
      );

  /// Server error.
  factory NetworkException.serverError([int? statusCode]) => NetworkException(
        message: 'Terjadi kesalahan pada server. Silakan coba lagi nanti.',
        code: 'SERVER_ERROR',
        statusCode: statusCode,
      );

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Exception for authentication-related errors.
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalException,
  });

  /// Invalid credentials.
  factory AuthException.invalidCredentials() => const AuthException(
        message: 'Email atau kata sandi salah.',
        code: 'INVALID_CREDENTIALS',
      );

  /// User not found.
  factory AuthException.userNotFound() => const AuthException(
        message: 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.',
        code: 'USER_NOT_FOUND',
      );

  /// Email already in use.
  factory AuthException.emailAlreadyInUse() => const AuthException(
        message: 'Email sudah terdaftar. Silakan gunakan email lain.',
        code: 'EMAIL_ALREADY_IN_USE',
      );

  /// Weak password.
  factory AuthException.weakPassword() => const AuthException(
        message: 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter.',
        code: 'WEAK_PASSWORD',
      );

  /// Session expired.
  factory AuthException.sessionExpired() => const AuthException(
        message: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
        code: 'SESSION_EXPIRED',
      );

  /// Unauthorized access.
  factory AuthException.unauthorized() => const AuthException(
        message: 'Anda tidak memiliki akses untuk melakukan tindakan ini.',
        code: 'UNAUTHORIZED',
      );

  /// Too many requests.
  factory AuthException.tooManyRequests() => const AuthException(
        message: 'Terlalu banyak percobaan. Silakan coba lagi nanti.',
        code: 'TOO_MANY_REQUESTS',
      );
}

/// Exception for data/storage-related errors.
class DataException extends AppException {
  const DataException({
    required super.message,
    super.code = 'DATA_ERROR',
    super.originalException,
  });

  /// Document not found.
  factory DataException.notFound([String? entity]) => DataException(
        message: '${entity ?? 'Data'} tidak ditemukan.',
        code: 'NOT_FOUND',
      );

  /// Permission denied.
  factory DataException.permissionDenied() => const DataException(
        message: 'Anda tidak memiliki izin untuk mengakses data ini.',
        code: 'PERMISSION_DENIED',
      );

  /// Data validation failed.
  factory DataException.validationFailed(String detail) => DataException(
        message: 'Validasi gagal: $detail',
        code: 'VALIDATION_FAILED',
      );

  /// Duplicate entry.
  factory DataException.duplicate([String? entity]) => DataException(
        message: '${entity ?? 'Data'} sudah ada.',
        code: 'DUPLICATE',
      );

  /// Storage quota exceeded.
  factory DataException.quotaExceeded() => const DataException(
        message: 'Kuota penyimpanan telah habis.',
        code: 'QUOTA_EXCEEDED',
      );
}

/// Exception for file/media-related errors.
class MediaException extends AppException {
  const MediaException({
    required super.message,
    super.code = 'MEDIA_ERROR',
    super.originalException,
  });

  /// File too large.
  factory MediaException.fileTooLarge(int maxSizeMb) => MediaException(
        message: 'Ukuran file melebihi batas maksimum ($maxSizeMb MB).',
        code: 'FILE_TOO_LARGE',
      );

  /// Unsupported format.
  factory MediaException.unsupportedFormat(String format) => MediaException(
        message: 'Format file "$format" tidak didukung.',
        code: 'UNSUPPORTED_FORMAT',
      );

  /// Upload failed.
  factory MediaException.uploadFailed() => const MediaException(
        message: 'Gagal mengunggah file. Silakan coba lagi.',
        code: 'UPLOAD_FAILED',
      );
}

/// Exception for cache-related errors.
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalException,
  });

  /// Cache read failure.
  factory CacheException.readFailed() => const CacheException(
        message: 'Gagal membaca data dari cache.',
        code: 'CACHE_READ_FAILED',
      );

  /// Cache write failure.
  factory CacheException.writeFailed() => const CacheException(
        message: 'Gagal menyimpan data ke cache.',
        code: 'CACHE_WRITE_FAILED',
      );
}

/// Handles Firebase exceptions and converts them to typed [AppException]s.
///
/// Usage:
/// ```dart
/// try {
///   await firebaseAuth.signInWithEmailAndPassword(...);
/// } on FirebaseAuthException catch (e) {
///   throw FirebaseExceptionHandler.handleAuth(e);
/// }
/// ```
abstract final class FirebaseExceptionHandler {
  /// Converts a [FirebaseAuthException] to a typed [AuthException].
  static AuthException handleAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException.invalidCredentials();
      case 'email-already-in-use':
        return AuthException.emailAlreadyInUse();
      case 'weak-password':
        return AuthException.weakPassword();
      case 'too-many-requests':
        return AuthException.tooManyRequests();
      case 'user-disabled':
        return const AuthException(
          message: 'Akun ini telah dinonaktifkan.',
          code: 'USER_DISABLED',
        );
      case 'invalid-email':
        return const AuthException(
          message: 'Format email tidak valid.',
          code: 'INVALID_EMAIL',
        );
      case 'requires-recent-login':
        return AuthException.sessionExpired();
      case 'unknown-error':
      case 'internal':
        return const AuthException(
          message: 'Gagal terhubung ke server autentikasi. '
              'Pastikan Email/Password sudah diaktifkan di Firebase Console '
              'dan periksa koneksi internet Anda.',
          code: 'UNKNOWN_ERROR',
        );
      default:
        return AuthException(
          message: 'Terjadi kesalahan autentikasi: ${e.message}',
          code: e.code,
          originalException: e,
        );
    }
  }

  /// Converts a [FirebaseException] to a typed [AppException].
  static AppException handleFirestore(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return DataException.permissionDenied();
      case 'not-found':
        return DataException.notFound();
      case 'already-exists':
        return DataException.duplicate();
      case 'resource-exhausted':
        return DataException.quotaExceeded();
      case 'unavailable':
        return NetworkException.noConnection();
      case 'deadline-exceeded':
        return NetworkException.timeout();
      case 'cancelled':
        return const AppException(
          message: 'Operasi dibatalkan.',
          code: 'CANCELLED',
        );
      case 'failed-precondition':
        return const AppException(
          message: 'Index database masih dalam proses pembuatan. '
              'Coba lagi dalam beberapa menit.',
          code: 'INDEX_NOT_READY',
        );
      default:
        return AppException(
          message: 'Terjadi kesalahan: ${e.message}',
          code: e.code,
          originalException: e,
        );
    }
  }
}

/// Exception untuk HTTP error dari REST API backend.
class ApiException extends AppException {
  const ApiException({
    required super.message,
    super.code = 'API_ERROR',
    super.originalException,
    this.statusCode,
  });

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}
