import '../../../core/paddle_exception.dart';

/// Thrown when a payment is not confirmed within the polling budget of a
/// `PollingPolicy` (timeout or `maxAttempts`).
class PaymentConfirmationTimeoutException extends PaddleException {
  /// Creates the exception.
  const PaymentConfirmationTimeoutException({
    required this.transactionId,
    required this.attempts,
    this.lastStatus,
  }) : super(
         'Transaction $transactionId was not confirmed after $attempts attempt(s).',
       );

  /// The transaction that was being polled.
  final String transactionId;

  /// How many fetches were made before giving up.
  final int attempts;

  /// The last status returned by the fetcher, or `null` if every fetch
  /// failed.
  final Object? lastStatus;
}
