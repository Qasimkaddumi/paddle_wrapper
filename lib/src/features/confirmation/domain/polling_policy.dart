import 'dart:math' as math;

/// Controls how often and for how long a payment confirmation polls.
class PollingPolicy {
  /// Creates a policy. All durations must be positive and [backoffFactor]
  /// must be at least 1.
  const PollingPolicy({
    this.initialInterval = const Duration(seconds: 2),
    this.maxInterval = const Duration(seconds: 10),
    this.backoffFactor = 1.5,
    this.timeout = const Duration(minutes: 2),
    this.maxAttempts,
    this.retryOnError = true,
  }) : assert(backoffFactor >= 1, 'backoffFactor must be at least 1'),
       assert(
         maxAttempts == null || maxAttempts > 0,
         'maxAttempts must be > 0',
       );

  /// Delay after the first attempt.
  final Duration initialInterval;

  /// Upper bound for any delay between two attempts.
  final Duration maxInterval;

  /// Multiplier applied to the delay after every attempt.
  final double backoffFactor;

  /// Total time budget, measured from the first attempt.
  final Duration timeout;

  /// Maximum number of fetches, or `null` for no limit (only [timeout]).
  final int? maxAttempts;

  /// Whether a failing fetch is retried instead of ending the stream.
  final bool retryOnError;

  /// Returns the delay to wait after the 1-based [attempt]:
  /// `initialInterval * backoffFactor^(attempt - 1)`, capped at
  /// [maxInterval].
  Duration delayAfter(int attempt) {
    assert(attempt >= 1, 'attempt is 1-based');
    final scaled =
        initialInterval.inMicroseconds *
        math.pow(backoffFactor, attempt - 1).toDouble();
    if (scaled >= maxInterval.inMicroseconds) return maxInterval;
    return Duration(microseconds: scaled.round());
  }
}
