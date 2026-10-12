import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/features/confirmation/domain/payment_confirmation.dart';
import 'package:paddle_wrapper/src/features/confirmation/domain/payment_confirmation_exception.dart';
import 'package:paddle_wrapper/src/features/confirmation/domain/polling_policy.dart';

bool _isFinal(String status) => status == 'paid' || status == 'failed';

class _TransientError implements Exception {
  const _TransientError();
}

/// Scripted backend: each fetch consumes the next entry, and the last entry
/// repeats forever. Entries are either a status [String] or an [Exception].
/// The fake delay advances the fake clock instead of waiting.
class _FakeBackend {
  _FakeBackend(this.script);

  final List<Object> script;
  final List<String> requestedIds = [];
  final List<Duration> delays = [];
  DateTime now = DateTime(2026, 1, 1);

  Future<String> fetch(String transactionId) async {
    requestedIds.add(transactionId);
    final index = requestedIds.length - 1;
    final step = script[index < script.length ? index : script.length - 1];
    if (step is Exception) throw step;
    return step as String;
  }

  Future<void> delay(Duration duration) async {
    delays.add(duration);
    now = now.add(duration);
  }

  DateTime clock() => now;
}

PaymentConfirmation<String> _confirmation(
  _FakeBackend backend, {
  PollingPolicy policy = const PollingPolicy(),
}) => PaymentConfirmation<String>(
  fetchStatus: backend.fetch,
  isFinal: _isFinal,
  policy: policy,
  delay: backend.delay,
  clock: backend.clock,
);

void main() {
  group('PollingPolicy', () {
    test('delayAfter grows by backoffFactor and is capped at maxInterval', () {
      const policy = PollingPolicy();

      expect(policy.delayAfter(1), const Duration(seconds: 2));
      expect(policy.delayAfter(2), const Duration(seconds: 3));
      expect(policy.delayAfter(3), const Duration(milliseconds: 4500));
      expect(policy.delayAfter(4), const Duration(milliseconds: 6750));
      expect(policy.delayAfter(10), const Duration(seconds: 10));
      expect(policy.delayAfter(1000), const Duration(seconds: 10));
    });

    test('delayAfter with factor 1 stays at the initial interval', () {
      const policy = PollingPolicy(
        initialInterval: Duration(milliseconds: 500),
        backoffFactor: 1,
      );

      expect(policy.delayAfter(1), const Duration(milliseconds: 500));
      expect(policy.delayAfter(7), const Duration(milliseconds: 500));
    });

    test('rejects invalid values', () {
      expect(
        () => PollingPolicy(backoffFactor: 0.5),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PollingPolicy(maxAttempts: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PaymentConfirmation.watch', () {
    test('emits a final status on the first try without delaying', () async {
      final backend = _FakeBackend(['paid']);

      final statuses = await _confirmation(backend).watch('txn_1').toList();

      expect(statuses, ['paid']);
      expect(backend.requestedIds, ['txn_1']);
      expect(backend.delays, isEmpty);
    });

    test(
      'polls until final with growing delays capped at maxInterval',
      () async {
        final backend = _FakeBackend([
          'pending',
          'pending',
          'pending',
          'pending',
          'pending',
          'pending',
          'paid',
        ]);
        final policy = PollingPolicy(
          initialInterval: const Duration(seconds: 1),
          backoffFactor: 2,
          maxInterval: const Duration(seconds: 5),
          timeout: const Duration(hours: 1),
        );

        final statuses = await _confirmation(
          backend,
          policy: policy,
        ).watch('txn_1').toList();

        expect(statuses, [
          'pending',
          'pending',
          'pending',
          'pending',
          'pending',
          'pending',
          'paid',
        ]);
        expect(backend.delays, [
          const Duration(seconds: 1),
          const Duration(seconds: 2),
          const Duration(seconds: 4),
          const Duration(seconds: 5),
          const Duration(seconds: 5),
          const Duration(seconds: 5),
        ]);
      },
    );

    test('retries transient fetch errors without emitting them', () async {
      final backend = _FakeBackend([
        const _TransientError(),
        'pending',
        const _TransientError(),
        'failed',
      ]);

      final statuses = await _confirmation(backend).watch('txn_1').toList();

      expect(statuses, ['pending', 'failed']);
      expect(backend.requestedIds.length, 4);
    });

    test('propagates the fetch error when retryOnError is false', () async {
      final backend = _FakeBackend([
        'pending',
        const _TransientError(),
        'paid',
      ]);
      final policy = PollingPolicy(retryOnError: false);

      final stream = _confirmation(backend, policy: policy).watch('txn_1');

      await expectLater(stream.toList(), throwsA(isA<_TransientError>()));
      expect(backend.requestedIds.length, 2);
    });

    test('times out with the last status once the timeout elapses', () async {
      final backend = _FakeBackend(['pending']);
      final policy = PollingPolicy(
        initialInterval: const Duration(seconds: 2),
        maxInterval: const Duration(seconds: 2),
        timeout: const Duration(seconds: 10),
      );

      await expectLater(
        _confirmation(backend, policy: policy).watch('txn_1').toList(),
        throwsA(
          isA<PaymentConfirmationTimeoutException>()
              .having((e) => e.transactionId, 'transactionId', 'txn_1')
              .having((e) => e.attempts, 'attempts', 6)
              .having((e) => e.lastStatus, 'lastStatus', 'pending'),
        ),
      );
      expect(backend.requestedIds.length, 6);
      expect(
        backend.delays.fold(Duration.zero, (a, b) => a + b),
        const Duration(seconds: 10),
      );
    });

    test('does not sleep past the timeout deadline', () async {
      final backend = _FakeBackend(['pending']);
      final policy = PollingPolicy(
        initialInterval: const Duration(seconds: 4),
        maxInterval: const Duration(seconds: 4),
        backoffFactor: 1,
        timeout: const Duration(seconds: 6),
      );

      await expectLater(
        _confirmation(backend, policy: policy).watch('txn_1').toList(),
        throwsA(isA<PaymentConfirmationTimeoutException>()),
      );
      expect(backend.delays, [
        const Duration(seconds: 4),
        const Duration(seconds: 2),
      ]);
    });

    test(
      'stops after maxAttempts even when the timeout has not elapsed',
      () async {
        final backend = _FakeBackend(['pending']);
        final policy = PollingPolicy(maxAttempts: 3);

        await expectLater(
          _confirmation(backend, policy: policy).watch('txn_1').toList(),
          throwsA(
            isA<PaymentConfirmationTimeoutException>().having(
              (e) => e.attempts,
              'attempts',
              3,
            ),
          ),
        );
        expect(backend.requestedIds.length, 3);
        expect(backend.delays.length, 2);
      },
    );

    test('timeout carries a null lastStatus when every fetch failed', () async {
      final backend = _FakeBackend([const _TransientError()]);
      final policy = PollingPolicy(maxAttempts: 2);

      await expectLater(
        _confirmation(backend, policy: policy).watch('txn_1').toList(),
        throwsA(
          isA<PaymentConfirmationTimeoutException>().having(
            (e) => e.lastStatus,
            'lastStatus',
            isNull,
          ),
        ),
      );
    });

    test('cancelling the subscription stops fetching', () async {
      final backend = _FakeBackend(['pending']);
      final policy = PollingPolicy(maxAttempts: 100);
      final received = <String>[];
      final done = Completer<void>();
      late StreamSubscription<String> subscription;

      subscription = _confirmation(backend, policy: policy)
          .watch('txn_1')
          .listen((status) {
            received.add(status);
            if (received.length == 3) {
              subscription.cancel();
              done.complete();
            }
          });
      await done.future;
      await Future<void>.delayed(Duration.zero);
      final fetchesAtCancel = backend.requestedIds.length;

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(received, ['pending', 'pending', 'pending']);
      expect(backend.requestedIds.length, fetchesAtCancel);
      expect(fetchesAtCancel, 3);
    });

    test('throws ArgumentError synchronously for an empty transactionId', () {
      final backend = _FakeBackend(['paid']);

      expect(() => _confirmation(backend).watch(''), throwsArgumentError);
      expect(backend.requestedIds, isEmpty);
    });
  });

  group('PaymentConfirmation.waitFor', () {
    test('completes with the first final status', () async {
      final backend = _FakeBackend(['pending', 'pending', 'failed']);

      final status = await _confirmation(backend).waitFor('txn_1');

      expect(status, 'failed');
      expect(backend.requestedIds.length, 3);
    });

    test('completes with an error on timeout', () async {
      final backend = _FakeBackend(['pending']);
      final policy = PollingPolicy(maxAttempts: 2);

      await expectLater(
        _confirmation(backend, policy: policy).waitFor('txn_1'),
        throwsA(isA<PaymentConfirmationTimeoutException>()),
      );
    });

    test('rejects an empty transactionId', () async {
      final backend = _FakeBackend(['paid']);

      await expectLater(
        _confirmation(backend).waitFor(''),
        throwsArgumentError,
      );
    });
  });
}
