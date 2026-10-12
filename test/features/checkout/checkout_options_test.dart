import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/core/paddle_exception.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_customer.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_discount.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_enums.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_item.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_options.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_settings.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_update.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_upsell.dart';

const _item = CheckoutItem(priceId: 'pri_1');

void main() {
  group('CheckoutOptions.toJson', () {
    test('serializes items with quantity', () {
      final options = CheckoutOptions(
        items: const [CheckoutItem(priceId: 'pri_1', quantity: 3)],
      );

      expect(options.toJson(), {
        'items': [
          {'priceId': 'pri_1', 'quantity': 3},
        ],
      });
    });

    test('defaults quantity to 1 and omits empty optional fields', () {
      final json = CheckoutOptions(items: const [_item]).toJson();

      expect(json, {
        'items': [
          {'priceId': 'pri_1', 'quantity': 1},
        ],
      });
    });

    test('uses transactionId instead of items', () {
      final json = CheckoutOptions.transaction('txn_1').toJson();

      expect(json, {'transactionId': 'txn_1'});
      expect(json.containsKey('items'), isFalse);
    });

    test('serializes customer by email with address and business', () {
      final options = CheckoutOptions(
        items: const [_item],
        customer: CheckoutCustomer.email(
          'buyer@example.com',
          address: CheckoutAddress.details(
            countryCode: 'GB',
            postalCode: 'SW1A 1AA',
            region: 'London',
            city: 'London',
            firstLine: '10 Downing St',
          ),
          business: CheckoutBusiness.details(
            name: 'Acme Ltd',
            taxIdentifier: 'GB123',
          ),
        ),
      );

      expect(options.toJson()['customer'], {
        'email': 'buyer@example.com',
        'address': {
          'countryCode': 'GB',
          'postalCode': 'SW1A 1AA',
          'region': 'London',
          'city': 'London',
          'firstLine': '10 Downing St',
        },
        'business': {'name': 'Acme Ltd', 'taxIdentifier': 'GB123'},
      });
    });

    test('serializes customer and address by Paddle id', () {
      final options = CheckoutOptions(
        items: const [_item],
        customer: CheckoutCustomer.id(
          'ctm_1',
          address: CheckoutAddress.id('add_1'),
          business: CheckoutBusiness.id('biz_1'),
        ),
      );

      expect(options.toJson()['customer'], {
        'id': 'ctm_1',
        'address': {'id': 'add_1'},
        'business': {'id': 'biz_1'},
      });
    });

    test('serializes a discount code', () {
      final json = CheckoutOptions(
        items: const [_item],
        discount: const CheckoutDiscount.code('SAVE10'),
      ).toJson();

      expect(json['discountCode'], 'SAVE10');
      expect(json.containsKey('discountId'), isFalse);
    });

    test('serializes a discount id', () {
      final json = CheckoutOptions(
        items: const [_item],
        discount: const CheckoutDiscount.id('dsc_1'),
      ).toJson();

      expect(json['discountId'], 'dsc_1');
      expect(json.containsKey('discountCode'), isFalse);
    });

    test('serializes upsell with and without skip button', () {
      final withSkip = CheckoutOptions(
        items: const [_item],
        settings: const CheckoutSettings.inline(frameTarget: 'frame'),
        upsell: const CheckoutUpsell('txn_2', showSkipButton: true),
      ).toJson();
      final withoutSkip = CheckoutUpsell('txn_2').toJson();

      expect(withSkip['upsell'], {
        'transactionId': 'txn_2',
        'settings': {'showSkipButton': true},
      });
      expect(withoutSkip, {'transactionId': 'txn_2'});
    });

    test('passes customData, customerAuthToken and savedPaymentMethodId', () {
      final json = CheckoutOptions(
        items: const [_item],
        customData: const {'orderRef': 'abc'},
        customerAuthToken: 'token',
        savedPaymentMethodId: 'paymtd_1',
      ).toJson();

      expect(json['customData'], {'orderRef': 'abc'});
      expect(json['customerAuthToken'], 'token');
      expect(json['savedPaymentMethodId'], 'paymtd_1');
    });

    test('serializes inline settings with wire values', () {
      final options = CheckoutOptions(
        items: const [_item],
        settings: CheckoutSettings.inline(
          frameTarget: 'paddle-frame',
          allowedPaymentMethods: const [
            PaymentMethod.applePay,
            PaymentMethod.card,
          ],
          locale: CheckoutLocale.ptBR,
          theme: CheckoutTheme.dark,
          variant: CheckoutVariant.onePage,
          successUrl: Uri(scheme: 'https', host: 'example.com', path: '/ok'),
        ),
      );

      expect(options.toJson()['settings'], {
        'displayMode': 'inline',
        'frameTarget': 'paddle-frame',
        'frameInitialHeight': '450',
        'frameStyle': CheckoutSettings.defaultFrameStyle,
        'allowedPaymentMethods': ['apple_pay', 'card'],
        'locale': 'pt-BR',
        'theme': 'dark',
        'variant': 'one-page',
        'successUrl': 'https://example.com/ok',
      });
    });

    test('serializes overlay settings without frame fields', () {
      final settings = const CheckoutSettings.overlay(
        variant: CheckoutVariant.multiPage,
        locale: CheckoutLocale.norwegian,
      ).toJson();

      expect(settings, {
        'displayMode': 'overlay',
        'variant': 'multi-page',
        'locale': 'no',
      });
    });

    test('copyWith replaces only the given settings fields', () {
      const base = CheckoutSettings(theme: CheckoutTheme.light);
      final copy = base.copyWith(
        displayMode: CheckoutDisplayMode.inline,
        frameTarget: 'frame',
        frameInitialHeight: 600,
      );

      expect(copy.theme, CheckoutTheme.light);
      expect(copy.displayMode, CheckoutDisplayMode.inline);
      expect(copy.frameTarget, 'frame');
      expect(copy.toJson()['frameInitialHeight'], '600');
    });

    test('copyWith on options keeps the transaction id', () {
      final options = CheckoutOptions.transaction('txn_9');
      final copy = options.copyWith(settings: const CheckoutSettings.overlay());

      expect(copy.transactionId, 'txn_9');
      expect(copy.items, isEmpty);
      expect(copy.toJson()['transactionId'], 'txn_9');
    });
  });

  group('validation', () {
    void expectInvalid(void Function() action) {
      expect(action, throwsA(isA<PaddleValidationException>()));
    }

    test('requires items or a transaction id', () {
      expectInvalid(() => const CheckoutOptions(items: []).validate());
    });

    test('rejects items together with a transaction id', () {
      expectInvalid(
        () =>
            CheckoutOptions.transaction('txn_1')
                .copyWith(items: const [_item])
                .validate(),
      );
    });

    test('accepts a transaction id without items', () {
      CheckoutOptions.transaction('txn_1').validate();
    });

    test('rejects empty customData', () {
      expectInvalid(
        () => CheckoutOptions(
          items: const [_item],
          customData: const {},
        ).validate(),
      );
    });

    test('requires customerAuthToken for savedPaymentMethodId', () {
      expectInvalid(
        () => CheckoutOptions(
          items: const [_item],
          savedPaymentMethodId: 'paymtd_1',
        ).validate(),
      );
      CheckoutOptions(
        items: const [_item],
        savedPaymentMethodId: 'paymtd_1',
        customerAuthToken: 'token',
      ).validate();
    });

    test('rejects savedPaymentMethodId with the express variant', () {
      expectInvalid(
        () => CheckoutOptions(
          items: const [_item],
          settings: const CheckoutSettings.inline(
            frameTarget: 'frame',
            variant: CheckoutVariant.express,
          ),
          savedPaymentMethodId: 'paymtd_1',
          customerAuthToken: 'token',
        ).validate(),
      );
    });

    test('rejects upsell unless inline one-page', () {
      final upsell = const CheckoutUpsell('txn_2');
      expectInvalid(
        () => CheckoutOptions(
          items: const [_item],
          settings: const CheckoutSettings.overlay(),
          upsell: upsell,
        ).validate(),
      );
      expectInvalid(
        () => CheckoutOptions(
          items: const [_item],
          settings: const CheckoutSettings.inline(
            frameTarget: 'frame',
            variant: CheckoutVariant.multiPage,
          ),
          upsell: upsell,
        ).validate(),
      );
      CheckoutOptions(
        items: const [_item],
        settings: const CheckoutSettings.inline(
          frameTarget: 'frame',
          variant: CheckoutVariant.onePage,
        ),
        upsell: upsell,
      ).validate();
      // Without settings the upsell rule is skipped.
      CheckoutOptions(items: const [_item], upsell: upsell).validate();
    });

    test('rejects a business without an address', () {
      expectInvalid(
        () => CheckoutOptions(
          items: const [_item],
          customer: CheckoutCustomer.email(
            'a@example.com',
            business: CheckoutBusiness.details(name: 'Acme'),
          ),
        ).validate(),
      );
    });

    test('rejects an item with quantity below 1', () {
      expectInvalid(
        () => CheckoutOptions(
          items: const [CheckoutItem(priceId: 'pri_1', quantity: 0)],
        ).validate(),
      );
    });

    test('rejects an empty discount code', () {
      expectInvalid(
        () => CheckoutOptions(
          items: const [_item],
          discount: const CheckoutDiscount.code(' '),
        ).validate(),
      );
    });

    test('inline settings require a frameTarget', () {
      expectInvalid(
        () =>
            const CheckoutSettings(displayMode: CheckoutDisplayMode.inline)
                .validate(),
      );
    });

    test('express requires inline display mode', () {
      expectInvalid(
        () =>
            const CheckoutSettings(variant: CheckoutVariant.express).validate(),
      );
      expectInvalid(
        () =>
            const CheckoutSettings.overlay(variant: CheckoutVariant.express)
                .validate(),
      );
      const CheckoutSettings.inline(
        frameTarget: 'frame',
        variant: CheckoutVariant.express,
      ).validate();
    });

    test('successUrl must be http or https', () {
      expectInvalid(
        () =>
            CheckoutSettings(successUrl: Uri.parse('ftp://example.com/ok'))
                .validate(),
      );
      expectInvalid(
        () =>
            CheckoutSettings(successUrl: Uri.parse('example.com/ok'))
                .validate(),
      );
      CheckoutSettings(successUrl: Uri.parse('http://example.com/ok'))
          .validate();
    });

    test('rejects the unknown payment method', () {
      expectInvalid(
        () => const CheckoutSettings(
          allowedPaymentMethods: [PaymentMethod.unknown],
        ).validate(),
      );
    });

    test('CheckoutUpdate requires items and a non-empty customData', () {
      expectInvalid(() => const CheckoutUpdate(items: []).validate());
      expectInvalid(
        () => const CheckoutUpdate(items: [_item], customData: {}).validate(),
      );
      const CheckoutUpdate(items: [_item]).validate();
    });

    test('CheckoutUpdate.toJson includes items and discount id', () {
      final json = CheckoutUpdate(
        items: const [_item],
        discount: const CheckoutDiscount.id('dsc_1'),
      ).toJson();

      expect(json, {
        'items': [
          {'priceId': 'pri_1', 'quantity': 1},
        ],
        'discountId': 'dsc_1',
      });
    });
  });
}
