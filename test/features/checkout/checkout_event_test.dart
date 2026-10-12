import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_enums.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_event.dart';

Map<String, dynamic> _completedPayload() => {
  'name': 'checkout.completed',
  'data': {
    'id': 'che_1',
    'transaction_id': 'txn_1',
    'status': 'completed',
    'custom_data': {'userId': 'u1'},
    'currency_code': 'USD',
    'customer': {
      'id': 'ctm_1',
      'email': 'buyer@example.com',
      'address': {
        'id': 'add_1',
        'country_code': 'US',
        'postal_code': '10001',
        'first_line': '1 Main St',
        'city': 'New York',
        'region': 'NY',
      },
      'business': {'id': 'biz_1', 'name': 'Acme', 'tax_identifier': '123'},
    },
    'items': [
      {
        'price_id': 'pri_1',
        'price_name': 'Monthly',
        'quantity': 2,
        'product': {
          'id': 'pro_1',
          'name': 'Pro',
          'description': 'The pro plan',
          'image_url': 'https://example.com/a.png',
        },
        'billing_cycle': {'interval': 'month', 'frequency': 1},
        'trial_period': null,
        'totals': {
          'subtotal': 2000,
          'discount': 0,
          'tax': 0,
          'total': 2000,
          'credit': 0,
          'balance': 2000,
        },
        'recurring_totals': null,
      },
    ],
    'totals': {
      'subtotal': 2000,
      'discount': 200,
      'tax': 0,
      'total': 1800,
      'credit': 0,
      'balance': 1800,
    },
    'recurring_totals': null,
    'settings': {
      'display_mode': 'overlay',
      'theme': 'light',
      'variant': 'one-page',
    },
    'discount': {'id': 'dsc_1', 'code': 'SAVE'},
    'upsell': {
      'transaction_id': 'txn_2',
      'show_skip_button': true,
      'same_session': false,
    },
    'payment': {
      'method_details': {
        'type': 'card',
        'card': {
          'type': 'visa',
          'last4': '4242',
          'expiry_month': 12,
          'expiry_year': 2030,
        },
      },
    },
  },
};

void main() {
  group('CheckoutEvent.fromJson', () {
    test('parses a full checkout.completed payload', () {
      final event = CheckoutEvent.fromJson(_completedPayload());

      expect(event.name, CheckoutEventName.completed);
      expect(event.rawName, 'checkout.completed');
      expect(event.isCompleted, isTrue);
      expect(event.isClosed, isFalse);
      expect(event.isError, isFalse);
      expect(event.error, isNull);

      final data = event.data!;
      expect(data.id, 'che_1');
      expect(data.transactionId, 'txn_1');
      expect(data.status, TransactionStatus.completed);
      expect(data.customData, {'userId': 'u1'});
      expect(data.currencyCode, 'USD');

      expect(data.customer!.email, 'buyer@example.com');
      expect(data.customer!.address!.countryCode, 'US');
      expect(data.customer!.address!.firstLine, '1 Main St');
      expect(data.customer!.business!.taxIdentifier, '123');

      final item = data.items.single;
      expect(item.priceId, 'pri_1');
      expect(item.quantity, 2);
      expect(item.product!.name, 'Pro');
      expect(item.billingCycle!.interval, 'month');
      expect(item.billingCycle!.frequency, 1);
      expect(item.trialPeriod, isNull);
      expect(item.totals!.total, 2000);

      expect(data.totals!.discount, 200);
      expect(data.totals!.total, 1800);
      expect(data.recurringTotals, isNull);
      expect(data.settings!.displayMode, 'overlay');
      expect(data.settings!.variant, 'one-page');
      expect(data.discount!.code, 'SAVE');
      expect(data.upsell!.transactionId, 'txn_2');
      expect(data.upsell!.showSkipButton, isTrue);
      expect(data.upsell!.sameSession, isFalse);
      expect(data.payment!.methodType, 'card');
      expect(data.payment!.card!.last4, '4242');
      expect(data.payment!.card!.expiryMonth, 12);
      expect(data.payment!.card!.expiryYear, 2030);
    });

    test('keeps the raw map', () {
      final payload = _completedPayload();
      expect(CheckoutEvent.fromJson(payload).raw, payload);
    });

    test('maps an unknown event name to unknown and keeps the raw name', () {
      final event = CheckoutEvent.fromJson({
        'name': 'checkout.something.new',
        'data': null,
      });

      expect(event.name, CheckoutEventName.unknown);
      expect(event.rawName, 'checkout.something.new');
      expect(event.data, isNull);
      expect(event.error, isNull);
    });

    test('populates error for checkout.error', () {
      final event = CheckoutEvent.fromJson({
        'name': 'checkout.error',
        'data': {
          'type': 'request_error',
          'code': 'invalid_field',
          'detail': 'Invalid email',
          'documentation_url': 'https://developer.paddle.com/errors',
          'errors': [
            {'field': 'customer.email', 'message': 'must be an email'},
          ],
        },
      });

      expect(event.name, CheckoutEventName.error);
      expect(event.isError, isTrue);
      final error = event.error!;
      expect(error.type, 'request_error');
      expect(error.code, 'invalid_field');
      expect(error.detail, 'Invalid email');
      expect(error.documentationUrl, 'https://developer.paddle.com/errors');
      expect(error.fieldErrors.single.field, 'customer.email');
      expect(error.fieldErrors.single.message, 'must be an email');
    });

    test('unwraps an error object wrapped in error', () {
      final event = CheckoutEvent.fromJson({
        'name': 'checkout.payment.error',
        'data': {
          'error': {'type': 'payment', 'code': 'declined'},
        },
      });

      expect(event.name, CheckoutEventName.paymentError);
      expect(event.isError, isTrue);
      expect(event.error!.code, 'declined');
    });

    test('populates error for checkout.warning without making it an error', () {
      final event = CheckoutEvent.fromJson({
        'name': 'checkout.warning',
        'data': {'detail': 'Price changed'},
      });

      expect(event.error!.detail, 'Price changed');
      expect(event.isError, isFalse);
    });

    test('error is present with null fields when error data is missing', () {
      final event = CheckoutEvent.fromJson({'name': 'checkout.error'});

      expect(event.error, isNotNull);
      expect(event.error!.code, isNull);
      expect(event.error!.fieldErrors, isEmpty);
    });

    test('never throws on malformed data', () {
      final malformed = <Map<String, dynamic>>[
        {},
        {'name': 42, 'data': 'not a map'},
        {'name': 'checkout.completed', 'data': 'oops'},
        {
          'name': 'checkout.completed',
          'data': {
            'status': 'weird-status',
            'items': [1, 'x', null],
            'totals': 'nope',
            'customer': ['not', 'a', 'map'],
            'payment': {'method_details': 'bad'},
            'upsell': {'show_skip_button': 'yes'},
          },
        },
        {
          'name': 'checkout.error',
          'data': {'errors': 'bad', 'code': 7},
        },
      ];

      for (final payload in malformed) {
        expect(() => CheckoutEvent.fromJson(payload), returnsNormally);
      }

      final empty = CheckoutEvent.fromJson({});
      expect(empty.name, CheckoutEventName.unknown);
      expect(empty.rawName, '');
      expect(empty.data, isNull);

      final weird = CheckoutEvent.fromJson({
        'name': 'checkout.completed',
        'data': {
          'status': 'weird-status',
          'items': [1, 'x', null],
          'totals': 'nope',
          'upsell': {'show_skip_button': 'yes'},
        },
      });
      expect(weird.data!.status, TransactionStatus.unknown);
      expect(weird.data!.items, isEmpty);
      expect(weird.data!.totals, isNull);
      expect(weird.data!.upsell!.showSkipButton, isNull);
    });

    test('convenience getters match the event name', () {
      expect(
        CheckoutEvent.fromJson({'name': 'checkout.closed'}).isClosed,
        isTrue,
      );
      expect(
        CheckoutEvent.fromJson({'name': 'checkout.loaded'}).isLoaded,
        isTrue,
      );
    });
  });
}
