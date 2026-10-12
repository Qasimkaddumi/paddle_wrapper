import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_event.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_state.dart';
import 'package:paddle_wrapper/src/features/checkout/presentation/paddle_checkout_builder.dart';

CheckoutEvent _event(String name, [Map<String, dynamic>? data]) =>
    CheckoutEvent.fromJson({'name': name, 'data': ?data});

void main() {
  group('CheckoutState', () {
    test('follows the checkout lifecycle', () {
      var state = const CheckoutState();
      expect(state.phase, CheckoutPhase.idle);

      state = state.apply(_event('checkout.loaded', {'currency_code': 'USD'}));
      expect(state.isReady, isTrue);
      expect(state.data?.currencyCode, 'USD');

      state = state.apply(_event('checkout.payment.initiated'));
      expect(state.isProcessingPayment, isTrue);

      state = state.apply(_event('checkout.payment.failed'));
      expect(state.phase, CheckoutPhase.ready);

      state = state.apply(_event('checkout.completed'));
      expect(state.isCompleted, isTrue);

      state = state.apply(_event('checkout.closed'));
      expect(state.phase, CheckoutPhase.closed);
    });

    test('keeps checkout data across error events and clears errors', () {
      var state = const CheckoutState().apply(
        _event('checkout.loaded', {'transaction_id': 'txn_1'}),
      );

      state = state.apply(
        _event('checkout.error', {'code': 'invalid_field', 'detail': 'Bad'}),
      );
      expect(state.error?.code, 'invalid_field');
      expect(state.data?.transactionId, 'txn_1');

      state = state.apply(
        _event('checkout.items.updated', {'transaction_id': 'txn_1'}),
      );
      expect(state.error, isNull);
    });
  });

  testWidgets('PaddleCheckoutBuilder rebuilds from events', (tester) async {
    final events = StreamController<CheckoutEvent>.broadcast(sync: true);
    final seen = <CheckoutEvent>[];
    addTearDown(events.close);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PaddleCheckoutBuilder(
          events: events.stream,
          onEvent: seen.add,
          builder: (context, state) => Text(state.phase.name),
        ),
      ),
    );
    expect(find.text('idle'), findsOneWidget);

    events.add(_event('checkout.loaded'));
    await tester.pump();
    expect(find.text('ready'), findsOneWidget);
    expect(seen, hasLength(1));
  });
}
