import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/core/paddle_exception.dart';
import 'package:paddle_wrapper/src/features/pricing/data/paddle_pricing_service.dart';
import 'package:paddle_wrapper/src/features/pricing/domain/entities/price_preview.dart';
import 'package:paddle_wrapper/src/features/pricing/domain/entities/pricing_shared.dart';
import 'package:paddle_wrapper/src/features/pricing/domain/entities/transaction_preview.dart';

import '../../support/fake_paddle_platform.dart';

void main() {
  late FakePaddlePlatform fake;
  late PaddlePricingService service;

  setUp(() {
    fake = FakePaddlePlatform();
    service = PaddlePricingService(fake);
  });

  group('previewPrices', () {
    test('sends the exact camelCase body to Paddle.PricePreview', () async {
      fake.results['pricePreview'] = {
        'data': {
          'currencyCode': 'USD',
          'details': {
            'lineItems': [
              {
                'price': {'id': 'pri_01'},
                'quantity': 1,
              },
            ],
          },
        },
      };

      final result = await service.previewPrices(
        const PricePreviewRequest(
          items: [PricePreviewItem('pri_01')],
          currencyCode: 'USD',
          address: PreviewAddress(countryCode: 'US', postalCode: '10001'),
        ),
      );

      expect(fake.argsOf('pricePreview').single, {
        'items': [
          {'priceId': 'pri_01', 'quantity': 1},
        ],
        'currencyCode': 'USD',
        'address': {'countryCode': 'US', 'postalCode': '10001'},
      });
      expect(result.currencyCode, 'USD');
      expect(result.lineItemFor('pri_01')?.quantity, 1);
    });

    test('does not call the platform when validation fails', () async {
      await expectLater(
        service.previewPrices(const PricePreviewRequest(items: [])),
        throwsA(isA<PaddleValidationException>()),
      );
      expect(fake.argsOf('pricePreview'), isEmpty);
    });

    test('propagates platform errors', () async {
      fake.errors['pricePreview'] = const PaddleJsException(
        'Invalid price',
        type: 'request_error',
        code: 'invalid_field',
      );

      await expectLater(
        service.previewPrices(
          const PricePreviewRequest(items: [PricePreviewItem('pri_bad')]),
        ),
        throwsA(
          isA<PaddleJsException>().having(
            (e) => e.code,
            'code',
            'invalid_field',
          ),
        ),
      );
    });
  });

  group('previewTransaction', () {
    test(
      'sends the exact camelCase body to Paddle.TransactionPreview',
      () async {
        fake.results['transactionPreview'] = {
          'currencyCode': 'EUR',
          'details': {
            'totals': {'total': '1080', 'currencyCode': 'EUR'},
            'lineItems': <Object?>[],
          },
        };

        final result = await service.previewTransaction(
          const TransactionPreviewRequest(
            items: [
              TransactionPreviewItem(
                'pri_01',
                quantity: 3,
                includeInTotals: true,
              ),
            ],
            customerId: 'ctm_01',
            ignoreTrials: true,
          ),
        );

        expect(fake.argsOf('transactionPreview').single, {
          'items': [
            {'priceId': 'pri_01', 'quantity': 3, 'includeInTotals': true},
          ],
          'customerId': 'ctm_01',
          'ignoreTrials': true,
        });
        expect(result.totals?.total, '1080');
      },
    );

    test('does not call the platform when validation fails', () async {
      await expectLater(
        service.previewTransaction(
          const TransactionPreviewRequest(
            items: [TransactionPreviewItem('pri_01', quantity: 0)],
          ),
        ),
        throwsA(isA<PaddleValidationException>()),
      );
      expect(fake.argsOf('transactionPreview'), isEmpty);
    });

    test('propagates platform errors', () async {
      fake.errors['transactionPreview'] = const PaddleJsException('Boom');

      await expectLater(
        service.previewTransaction(
          const TransactionPreviewRequest(
            items: [TransactionPreviewItem('pri_01')],
          ),
        ),
        throwsA(isA<PaddleJsException>()),
      );
    });
  });
}
