/// Functional result type used across the SDK.
///
/// Every fallible operation returns a [Result] instead of throwing, so failures
/// are values the caller can inspect. The public [Besh24Client] facade never
/// leaks exceptions — a network or parsing failure degrades to an [Err].
library;

/// A typed error describing why an SDK operation failed.
sealed class Besh24Error {
  const Besh24Error(this.message);

  /// Human-readable description, safe to log.
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// The network layer failed before a response was received (timeout, DNS, TLS).
final class NetworkError extends Besh24Error {
  /// Creates a network error with an optional [cause].
  const NetworkError(super.message, {this.cause});

  /// The underlying exception, if any.
  final Object? cause;
}

/// The server returned a non-2xx status code.
final class ApiError extends Besh24Error {
  /// Creates an API error for a non-2xx [statusCode].
  const ApiError(super.message, {required this.statusCode, this.body});

  /// HTTP status code returned by the backend.
  final int statusCode;

  /// Raw response body, if any.
  final String? body;
}

/// A response could not be decoded into the expected shape.
final class SerializationError extends Besh24Error {
  /// Creates a serialization error with an optional [cause].
  const SerializationError(super.message, {this.cause});

  /// The underlying exception, if any.
  final Object? cause;
}

/// Local persistence (shared_preferences) failed.
final class StorageError extends Besh24Error {
  /// Creates a storage error with an optional [cause].
  const StorageError(super.message, {this.cause});

  /// The underlying exception, if any.
  final Object? cause;
}

/// The SDK was used incorrectly (e.g. bad configuration or empty input).
final class ValidationError extends Besh24Error {
  /// Creates a validation error.
  const ValidationError(super.message);
}

/// Outcome of a fallible operation: either [Ok] with a value or [Err] with a
/// [Besh24Error].
sealed class Result<T> {
  const Result();

  /// `true` when this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// `true` when this is an [Err].
  bool get isErr => this is Err<T>;

  /// The value when [isOk], otherwise `null`.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// The error when [isErr], otherwise `null`.
  Besh24Error? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final error) => error,
      };

  /// Transforms the success value, preserving an error unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok(transform(value)),
        Err<T>(:final error) => Err(error),
      };
}

/// Successful [Result] carrying a [value].
final class Ok<T> extends Result<T> {
  /// Wraps a successful [value].
  const Ok(this.value);

  /// The produced value.
  final T value;
}

/// Failed [Result] carrying an [error].
final class Err<T> extends Result<T> {
  /// Wraps a failure [error].
  const Err(this.error);

  /// The failure reason.
  final Besh24Error error;
}
