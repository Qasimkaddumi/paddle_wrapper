import 'package:flutter/foundation.dart';

import 'payment_confirmation_exception.dart';
import 'polling_policy.dart';

/// Fetches the current status of a transaction from the app's own backend.
typedef PaymentStatusFetcher<T> = Future<T> Function(String transactionId);

/// Returns `true` when [status] is final and polling can stop.
typedef PaymentStatusPredicate<T> = bool Function(T status);

/// Polls the app's backend until a transaction reaches a final status.
///
/// Paddle sends the webhook to your backend, not to the client, so after
/// a checkout completes the app has to wait until its backend reflects the
/// payment. This class does not perform any HTTP itself: you supply the
/// [fetchStatus] function.
///
/// ```dart
/// final confirmation = PaymentConfirmation<OrderStatus>(
///   fetchStatus: (txnId) => myApi.getOrderStatus(txnId),
///   isFinal: (s) => s.isPaid || s.isFailed,
/// );
/// paddle.events.where((e) => e.isCompleted).listen((e) async {
///   final status = await confirmation.waitFor(e.data!.transactionId!);
/// });
/// ```
class PaymentConfirmation<T> {
  /// Creates a confirmation helper.
  ///
  /// [delay] and [clock] exist for tests and default to real time.
  PaymentConfirmation({
    required this.fetchStatus,
    required this.isFinal,
    this.policy = const PollingPolicy(),
    @visibleForTesting Future<void> Function(Duration)? delay,
    @visibleForTesting DateTime Function()? clock,
  }) : _delay = delay ?? ((duration) => Future<void>.delayed(duration)),
       _clock = clock ?? DateTime.now;

  /// Fetches the current status of a transaction.
  final PaymentStatusFetcher<T> fetchStatus;

  /// Decides whether a status ends polling.
  final PaymentStatusPredicate<T> isFinal;

  /// Controls the delays, retries and timeout.
  final PollingPolicy policy;

  final Future<void> Function(Duration) _delay;
  final DateTime Function() _clock;

  /// Emits every status of [transactionId] as it is fetched, then closes
  /// after the first final status.
  ///
  /// The stream fails with a [PaymentConfirmationTimeoutException] when the
  /// policy's timeout or `maxAttempts` is reached first. Cancelling the
  /// subscription stops polling.
  ///
  /// Throws an [ArgumentError] synchronously when [transactionId] is empty.
  Stream<T> watch(String transactionId) {
    if (transactionId.isEmpty) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'must not be empty',
      );
    }
    return _poll(transactionId);
  }

  /// Completes with the first final status of [transactionId].
  ///
  /// Fails like [watch] on timeout or on a fetch error when
  /// `policy.retryOnError` is `false`.
  Future<T> waitFor(String transactionId) async =>
      watch(transactionId).firstWhere(isFinal);

  Stream<T> _poll(String transactionId) async* {
    final deadline = _clock().add(policy.timeout);
    var attempt = 0;
    T? lastStatus;
    while (true) {
      attempt++;
      final fetched = await _tryFetch(transactionId);
      if (fetched != null) {
        final status = fetched.status;
        lastStatus = status;
        yield status;
        if (isFinal(status)) return;
      }

      final now = _clock();
      final outOfAttempts =
          policy.maxAttempts != null && attempt >= policy.maxAttempts!;
      if (outOfAttempts || !now.isBefore(deadline)) {
        throw PaymentConfirmationTimeoutException(
          transactionId: transactionId,
          attempts: attempt,
          lastStatus: lastStatus,
        );
      }

      // Never sleep past the deadline; the next fetch happens at most at it.
      final remaining = deadline.difference(now);
      final wait = policy.delayAfter(attempt);
      await _delay(wait < remaining ? wait : remaining);
    }
  }

  /// Fetches once. Returns `null` when the fetch failed and the error was
  /// swallowed for a retry; rethrows when `policy.retryOnError` is `false`.
  Future<({T status})?> _tryFetch(String transactionId) async {
    try {
      return (status: await fetchStatus(transactionId));
    } on Object catch (error, stackTrace) {
      if (!policy.retryOnError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      return null;
    }
  }
}
