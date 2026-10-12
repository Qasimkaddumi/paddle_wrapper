import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/core/paddle_exception.dart';
import 'package:paddle_wrapper/src/core/json.dart';
import 'package:paddle_wrapper/src/features/pricing/domain/entities/price_preview.dart';
import 'package:paddle_wrapper/src/features/pricing/domain/entities/pricing_shared.dart';
import 'package:paddle_wrapper/src/features/pricing/domain/entities/transaction_preview.dart';

const JsonMap pricePreviewPayload = {
  'customerId': null,
  'addressId': null,
  'businessId': null,
  'currencyCode': 'USD',
  'discountId': null,
  'address': {'countryCode': 'US', 'postalCode': '10001'},
  'customerIpAddress': '203.0.113.7',
  'details': {
    'lineItems': [
      {
        'price': {
          'id': 'pri_01',
          'productId': 'pro_01',
          'name': 'Pro monthly',
          'description': 'Monthly',
          'billingCycle': {'interval': 'month', 'frequency': 1},
          'trialPeriod': null,
          'unitPrice': {'amount': '1000', 'currencyCode': 'USD'},
        },
        'quantity': 2,
        'taxRate': '0.08875',
        'unitTotals': {
          'subtotal': '1000',
          'discount': '0',
          'tax': '89',
          'total': '1089',
        },
        'formattedUnitTotals': {
          'subtotal': r'$10.00',
          'discount': r'$0.00',
          'tax': r'$0.89',
          'total': r'$10.89',
        },
        'totals': {
          'subtotal': '2000',
          'discount': '0',
          'tax': '178',
          'total': '2178',
        },
        'formattedTotals': {
          'subtotal': r'$20.00',
          'discount': r'$0.00',
          'tax': r'$1.78',
          'total': r'$21.78',
        },
        'product': {
          'id': 'pro_01',
          'name': 'Pro',
          'description': null,
          'imageUrl': null,
        },
        'discounts': <Object?>[],
      },
      {
        'price': {
          'id': 'pri_02',
          'name': 'Pro yearly',
          'trialPeriod': {'interval': 'day', 'frequency': 14},
        },
        'quantity': 1,
        'taxRate': '0',
      },
    ],
  },
  'availablePaymentMethods': ['card', 'paypal', 42],
};

const JsonMap transactionPreviewPayload = {
  'customerId': 'ctm_01',
  'addressId': null,
  'businessId': null,
  'currencyCode': 'EUR',
  'discountId': 'dsc_01',
  'ignoreTrials': false,
  'items': <Object?>[],
  'details': {
    'taxRatesUsed': [
      {
        'taxRate': '0.2',
        'totals': {'tax': '200'},
      },
    ],
    'totals': {
      'subtotal': '1000',
      'discount': '100',
      'tax': '180',
      'total': '1080',
      'credit': '0',
      'balance': '1080',
      'grandTotal': '1080',
      'fee': null,
      'earnings': null,
      'currencyCode': 'EUR',
    },
    'lineItems': [
      {
        'priceId': 'pri_03',
        'quantity': '3',
        'taxRate': '0.2',
        'unitTotals': {
          'subtotal': '1000',
          'discount': '100',
          'tax': '180',
          'total': '1080',
        },
        'totals': {
          'subtotal': '1000',
          'discount': '100',
          'tax': '180',
          'total': '1080',
        },
        'formattedUnitTotals': {'subtotal': '€10.00', 'total': '€10.80'},
        'product': {'id': 'pro_03', 'name': 'Seats'},
      },
    ],
  },
  'availablePaymentMethods': ['card'],
};

void main() {
  group('PreviewAddress', () {
    test('toJson omits a null postal code', () {
      expect(const PreviewAddress(countryCode: 'DE').toJson(), {
        'countryCode': 'DE',
      });
    });

    test('toJson keeps postal code', () {
      expect(
        const PreviewAddress(countryCode: 'US', postalCode: '10001').toJson(),
        {'countryCode': 'US', 'postalCode': '10001'},
      );
    });
  });

  group('PricePreviewRequest', () {
    test('serializes items, currency and address in camelCase', () {
      const request = PricePreviewRequest(
        items: [
          PricePreviewItem('pri_01', quantity: 2),
          PricePreviewItem('pri_02'),
        ],
        customerId: 'ctm_01',
        currencyCode: 'USD',
        address: PreviewAddress(countryCode: 'US', postalCode: '10001'),
      );

      expect(request.toJson(), {
        'items': [
          {'priceId': 'pri_01', 'quantity': 2},
          {'priceId': 'pri_02', 'quantity': 1},
        ],
        'customerId': 'ctm_01',
        'currencyCode': 'USD',
        'address': {'countryCode': 'US', 'postalCode': '10001'},
      });
    });

    test('omits every optional field when unset', () {
      const request = PricePreviewRequest(items: [PricePreviewItem('pri_01')]);

      expect(request.toJson(), {
        'items': [
          {'priceId': 'pri_01', 'quantity': 1},
        ],
      });
    });

    test('validate accepts a well formed request', () {
      const request = PricePreviewRequest(
        items: [PricePreviewItem('pri_01')],
        currencyCode: 'GBP',
        address: PreviewAddress(countryCode: 'GB'),
      );

      expect(request.validate, returnsNormally);
    });

    test('validate rejects an empty item list', () {
      const request = PricePreviewRequest(items: []);

      expect(request.validate, throwsA(isA<PaddleValidationException>()));
    });

    test('validate rejects a quantity below 1', () {
      const request = PricePreviewRequest(
        items: [PricePreviewItem('pri_01', quantity: 0)],
      );

      expect(request.validate, throwsA(isA<PaddleValidationException>()));
    });

    test('validate rejects a currency code that is not ISO 4217 shaped', () {
      for (final code in ['US', 'USDX', 'usd', '1234']) {
        final request = PricePreviewRequest(
          items: const [PricePreviewItem('pri_01')],
          currencyCode: code,
        );
        expect(
          request.validate,
          throwsA(isA<PaddleValidationException>()),
          reason: code,
        );
      }
    });

    test('validate rejects an address without a country code', () {
      const request = PricePreviewRequest(
        items: [PricePreviewItem('pri_01')],
        address: PreviewAddress(countryCode: ''),
      );

      expect(request.validate, throwsA(isA<PaddleValidationException>()));
    });
  });

  group('PricePreviewResult.fromJson', () {
    test('parses a wrapped {data: {...}} payload', () {
      final result = PricePreviewResult.fromJson({'data': pricePreviewPayload});

      expect(result.currencyCode, 'USD');
      expect(result.customerIpAddress, '203.0.113.7');
      expect(result.address?.countryCode, 'US');
      expect(result.address?.postalCode, '10001');
      expect(result.availablePaymentMethods, ['card', 'paypal']);
      expect(result.lineItems, hasLength(2));
      expect(result.raw['currencyCode'], 'USD');
    });

    test('parses an unwrapped payload identically', () {
      final wrapped = PricePreviewResult.fromJson({
        'data': pricePreviewPayload,
      });
      final unwrapped = PricePreviewResult.fromJson(pricePreviewPayload);

      expect(unwrapped.currencyCode, wrapped.currencyCode);
      expect(unwrapped.lineItems.length, wrapped.lineItems.length);
      expect(
        unwrapped.lineItemFor('pri_01')?.totals?.total,
        wrapped.lineItemFor('pri_01')?.totals?.total,
      );
    });

    test('parses nested line item details', () {
      final result = PricePreviewResult.fromJson(pricePreviewPayload);
      final item = result.lineItems.first;

      expect(item.priceId, 'pri_01');
      expect(item.quantity, 2);
      expect(item.taxRate, '0.08875');
      expect(item.price?.productId, 'pro_01');
      expect(item.price?.billingCycle?.interval, 'month');
      expect(item.price?.billingCycle?.frequency, 1);
      expect(item.price?.trialPeriod, isNull);
      expect(item.price?.unitPriceAmount, '1000');
      expect(item.price?.unitPriceCurrencyCode, 'USD');
      expect(item.unitTotals?.total, '1089');
      expect(item.totals?.tax, '178');
      expect(item.formattedUnitTotals?.total, r'$10.89');
      expect(item.formattedTotals?.total, r'$21.78');
      expect(item.product?.name, 'Pro');
      expect(item.raw['discounts'], isEmpty);
    });

    test('parses trial periods when present', () {
      final result = PricePreviewResult.fromJson(pricePreviewPayload);
      final trial = result.lineItemFor('pri_02')?.price?.trialPeriod;

      expect(trial?.interval, 'day');
      expect(trial?.frequency, 14);
    });

    test('never throws on an empty or partial payload', () {
      final result = PricePreviewResult.fromJson(const {});

      expect(result.currencyCode, isNull);
      expect(result.address, isNull);
      expect(result.lineItems, isEmpty);
      expect(result.availablePaymentMethods, isEmpty);
      expect(result.raw, isEmpty);
    });

    test('lineItemFor returns the matching item or null', () {
      final result = PricePreviewResult.fromJson(pricePreviewPayload);

      expect(result.lineItemFor('pri_02')?.quantity, 1);
      expect(result.lineItemFor('pri_missing'), isNull);
    });

    test('lineItemFor falls back to a top level priceId', () {
      final result = PricePreviewResult.fromJson({
        'details': {
          'lineItems': [
            {'priceId': 'pri_flat', 'quantity': 1},
          ],
        },
      });

      expect(result.lineItemFor('pri_flat')?.priceId, 'pri_flat');
    });
  });

  group('TransactionPreviewRequest', () {
    test('serializes items with includeInTotals and ignoreTrials', () {
      const request = TransactionPreviewRequest(
        items: [
          TransactionPreviewItem('pri_01', includeInTotals: true),
          TransactionPreviewItem('pri_02', quantity: 4),
        ],
        customerId: 'ctm_01',
        discountId: 'dsc_01',
        ignoreTrials: true,
      );

      expect(request.toJson(), {
        'items': [
          {'priceId': 'pri_01', 'quantity': 1, 'includeInTotals': true},
          {'priceId': 'pri_02', 'quantity': 4},
        ],
        'customerId': 'ctm_01',
        'discountId': 'dsc_01',
        'ignoreTrials': true,
      });
    });

    test('omits unset ignoreTrials and includeInTotals', () {
      const request = TransactionPreviewRequest(
        items: [TransactionPreviewItem('pri_01')],
      );

      expect(request.toJson(), {
        'items': [
          {'priceId': 'pri_01', 'quantity': 1},
        ],
      });
    });

    test('validate rejects empty items, bad quantity and bad currency', () {
      expect(
        const TransactionPreviewRequest(items: []).validate,
        throwsA(isA<PaddleValidationException>()),
      );
      expect(
        const TransactionPreviewRequest(
          items: [TransactionPreviewItem('pri_01', quantity: -1)],
        ).validate,
        throwsA(isA<PaddleValidationException>()),
      );
      expect(
        const TransactionPreviewRequest(
          items: [TransactionPreviewItem('pri_01')],
          currencyCode: 'eur',
        ).validate,
        throwsA(isA<PaddleValidationException>()),
      );
    });
  });

  group('TransactionPreviewResult.fromJson', () {
    test('parses a wrapped payload', () {
      final result = TransactionPreviewResult.fromJson({
        'data': transactionPreviewPayload,
      });

      expect(result.currencyCode, 'EUR');
      expect(result.customerId, 'ctm_01');
      expect(result.discountId, 'dsc_01');
      expect(result.availablePaymentMethods, ['card']);
      expect(result.totals?.total, '1080');
      expect(result.totals?.grandTotal, '1080');
      expect(result.totals?.currencyCode, 'EUR');
      expect(result.totals?.fee, isNull);
      expect(result.lineItems, hasLength(1));
    });

    test('parses an unwrapped payload and its line items', () {
      final result = TransactionPreviewResult.fromJson(
        transactionPreviewPayload,
      );
      final item = result.lineItems.single;

      expect(result.totals?.discount, '100');
      expect(item.priceId, 'pri_03');
      expect(item.quantity, 3);
      expect(item.taxRate, '0.2');
      expect(item.unitTotals?.subtotal, '1000');
      expect(item.totals?.total, '1080');
      expect(item.formattedUnitTotals?.total, '€10.80');
      expect(item.formattedTotals, isNull);
      expect(item.product?.name, 'Seats');
    });

    test('never throws on an empty payload', () {
      final result = TransactionPreviewResult.fromJson(const {});

      expect(result.totals, isNull);
      expect(result.lineItems, isEmpty);
      expect(result.availablePaymentMethods, isEmpty);
    });
  });
}
