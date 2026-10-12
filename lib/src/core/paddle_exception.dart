/// Base type for every error thrown by this package.
abstract class PaddleException implements Exception {
  /// Creates an exception with a human readable [message].
  const PaddleException(this.message);

  /// Human readable description of the problem.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the package is used before `Paddle.initialize` completed.
class PaddleNotInitializedException extends PaddleException {
  /// Creates the exception.
  const PaddleNotInitializedException()
    : super('Paddle is not initialized. Call Paddle.initialize() first.');
}

/// Thrown when the configuration passed to the package is invalid.
class PaddleConfigurationException extends PaddleException {
  /// Creates the exception.
  const PaddleConfigurationException(super.message);
}

/// Thrown when a request (checkout options, preview request, ...) is invalid.
/// Raised before anything is sent to Paddle.js.
class PaddleValidationException extends PaddleException {
  /// Creates the exception.
  const PaddleValidationException(super.message);
}

/// Thrown when the current platform is not supported (anything but web).
class PaddleUnsupportedPlatformException extends PaddleException {
  /// Creates the exception.
  const PaddleUnsupportedPlatformException()
    : super('Paddle.js is only available on Flutter web.');
}

/// Thrown when the Paddle.js script could not be loaded.
class PaddleScriptLoadException extends PaddleException {
  /// Creates the exception.
  const PaddleScriptLoadException(super.message);
}

/// Thrown when a Paddle.js call fails or a returned promise rejects.
class PaddleJsException extends PaddleException {
  /// Creates the exception.
  const PaddleJsException(
    super.message, {
    this.type,
    this.code,
    this.detail,
    this.raw,
  });

  /// Paddle error type, e.g. `request_error`, when provided.
  final String? type;

  /// Paddle error code, e.g. `invalid_field`, when provided.
  final String? code;

  /// Paddle error detail, when provided.
  final String? detail;

  /// Raw error payload as returned by Paddle.js.
  final Object? raw;
}
