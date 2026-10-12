import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/paddle_wrapper.dart';

import 'support/fake_paddle_platform.dart';

void main() {
  late FakePaddlePlatform platform;

  setUp(() => platform = FakePaddlePlatform());
  tearDown(Paddle.reset);

  group('PaddleConfig', () {
    test('infers the environment from the token prefix', () {
      expect(
        const PaddleConfig(clientToken: 'test_abc').environment,
        PaddleEnvironment.sandbox,
      );
      expect(
        const PaddleConfig(clientToken: 'live_abc').environment,
        PaddleEnvironment.production,
      );
    });

    test('rejects empty tokens, API keys and mismatched environments', () {
      for (final config in [
        const PaddleConfig(clientToken: ' '),
        const PaddleConfig(clientToken: 'pdl_sdbx_apikey_123'),
        const PaddleConfig(
          clientToken: 'test_abc',
          environment: PaddleEnvironment.production,
        ),
        const PaddleConfig(clientToken: 'test_abc', retainCustomerId: 'sub_1'),
      ]) {
        expect(config.validate, throwsA(isA<PaddleConfigurationException>()));
      }
    });

    test('builds Initialize options', () {
      const config = PaddleConfig(
        clientToken: 'live_abc',
        retainCustomerId: 'ctm_1',
        checkoutSettings: CheckoutSettings(theme: CheckoutTheme.dark),
      );
      expect(config.toInitializeJson(), {
        'token': 'live_abc',
        'pwCustomer': {'id': 'ctm_1'},
        'checkout': {
          'settings': {'theme': 'dark'},
        },
      });
    });
  });

  group('Paddle', () {
    test('instance throws before initialize', () {
      expect(
        () => Paddle.instance,
        throwsA(isA<PaddleNotInitializedException>()),
      );
      expect(Paddle.isInitialized, isFalse);
    });

    test('loads, sets the environment, then initializes', () async {
      final paddle = await Paddle.initialize(
        const PaddleConfig(clientToken: 'test_abc'),
        platform: platform,
      );

      expect(Paddle.instance, same(paddle));
      expect(platform.calls.map((c) => c.$1), [
        'load',
        'setEnvironment',
        'initialize',
      ]);
      expect(platform.argsOf('setEnvironment'), [PaddleEnvironment.sandbox]);
      expect(paddle.libraryVersion, '2.0.0-test');
    });

    test(
      'concurrent and repeated initialize calls share one instance',
      () async {
        const config = PaddleConfig(clientToken: 'test_abc');
        final results = await Future.wait([
          Paddle.initialize(config, platform: platform),
          Paddle.initialize(config, platform: platform),
        ]);
        final again = await Paddle.initialize(config, platform: platform);

        expect(results.first, same(results.last));
        expect(again, same(results.first));
        expect(platform.argsOf('initialize'), hasLength(1));
      },
    );

    test('rejects re-initialization with another account', () async {
      await Paddle.initialize(
        const PaddleConfig(clientToken: 'test_abc'),
        platform: platform,
      );
      await expectLater(
        Paddle.initialize(
          const PaddleConfig(clientToken: 'test_other'),
          platform: platform,
        ),
        throwsA(isA<PaddleConfigurationException>()),
      );
    });

    test('fails on unsupported platforms', () async {
      platform.isSupported = false;
      await expectLater(
        Paddle.initialize(
          const PaddleConfig(clientToken: 'test_abc'),
          platform: platform,
        ),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(Paddle.isInitialized, isFalse);
    });

    test('forwards Paddle.js events as typed checkout events', () async {
      final paddle = await Paddle.initialize(
        const PaddleConfig(clientToken: 'test_abc'),
        platform: platform,
      );
      final next = paddle.events.first;

      platform.emit({
        'name': 'checkout.completed',
        'data': {'transaction_id': 'txn_1'},
      });

      final event = await next;
      expect(event.name, CheckoutEventName.completed);
      expect(event.data?.transactionId, 'txn_1');
    });

    test('updates the Retain customer and default checkout settings', () async {
      final paddle = await Paddle.initialize(
        const PaddleConfig(clientToken: 'test_abc'),
        platform: platform,
      );

      paddle
        ..updateRetainCustomer('ctm_1')
        ..updateRetainCustomer(null)
        ..updateCheckoutSettings(
          const CheckoutSettings(locale: CheckoutLocale.fr),
        );

      expect(platform.argsOf('update'), [
        {
          'pwCustomer': {'id': 'ctm_1'},
        },
        {'pwCustomer': <String, dynamic>{}},
        {
          'checkout': {
            'settings': {'locale': 'fr'},
          },
        },
      ]);
      expect(
        () => paddle.updateRetainCustomer('user_42'),
        throwsA(isA<PaddleConfigurationException>()),
      );
    });
  });
}
