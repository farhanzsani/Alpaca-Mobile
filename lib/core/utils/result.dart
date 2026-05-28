/// Generic Result type implementing the Success/Failure pattern.
///
/// Provides a type-safe way to handle operations that can either
/// succeed with a value or fail with an exception.
library;

import 'package:equatable/equatable.dart';

import '../exceptions/app_exception.dart';

/// A sealed class representing the result of an operation.
///
/// Usage:
/// ```dart
/// Future<Result<User>> getUser(String id) async {
///   try {
///     final user = await repository.fetchUser(id);
///     return Result.success(user);
///   } catch (e, st) {
///     return Result.failure(ErrorHandler.handle(e, st));
///   }
/// }
///
/// // Consuming:
/// final result = await getUser('123');
/// result.when(
///   success: (user) => print(user.name),
///   failure: (error) => print(error.message),
/// );
/// ```
sealed class Result<T> extends Equatable {
  const Result._();

  /// Creates a successful result with [data].
  factory Result.success(T data) = Success<T>;

  /// Creates a failure result with an [exception].
  factory Result.failure(AppException exception) = Failure<T>;

  /// Whether this result is a success.
  bool get isSuccess => this is Success<T>;

  /// Whether this result is a failure.
  bool get isFailure => this is Failure<T>;

  /// Returns the data if success, or null if failure.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// Returns the exception if failure, or null if success.
  AppException? get exceptionOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final exception) => exception,
      };

  /// Pattern matches on the result, calling the appropriate callback.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final exception) => failure(exception),
    };
  }

  /// Maps the success value to a new type.
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Result.success(transform(data)),
      Failure<T>(:final exception) => Result.failure(exception),
    };
  }

  /// Flat maps the success value to a new Result.
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => transform(data),
      Failure<T>(:final exception) => Result.failure(exception),
    };
  }

  /// Executes [action] if the result is a success.
  Result<T> onSuccess(void Function(T data) action) {
    if (this case Success<T>(:final data)) {
      action(data);
    }
    return this;
  }

  /// Executes [action] if the result is a failure.
  Result<T> onFailure(void Function(AppException exception) action) {
    if (this case Failure<T>(:final exception)) {
      action(exception);
    }
    return this;
  }

  /// Returns the data if success, or the [defaultValue] if failure.
  T getOrElse(T defaultValue) => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => defaultValue,
      };

  /// Returns the data if success, or computes a value from the exception.
  T getOrHandle(T Function(AppException exception) handler) => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>(:final exception) => handler(exception),
      };
}

/// Represents a successful result containing [data].
final class Success<T> extends Result<T> {
  /// Creates a [Success] with the given [data].
  const Success(this.data) : super._();

  /// The success value.
  final T data;

  @override
  List<Object?> get props => [data];

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed result containing an [exception].
final class Failure<T> extends Result<T> {
  /// Creates a [Failure] with the given [exception].
  const Failure(this.exception) : super._();

  /// The failure exception.
  final AppException exception;

  @override
  List<Object?> get props => [exception];

  @override
  String toString() => 'Failure(${exception.message})';
}

/// Extension to convert a Future into a Result.
extension FutureResultExtension<T> on Future<T> {
  /// Wraps a Future in a Result, catching any exceptions.
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        AppException(
          message: e.toString(),
          code: 'UNKNOWN_ERROR',
          originalException: e,
        ),
      );
    }
  }
}
