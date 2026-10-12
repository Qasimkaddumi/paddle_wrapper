import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/core/json.dart';
import 'package:paddle_wrapper/src/core/paddle_exception.dart';
import 'package:paddle_wrapper/src/features/checkout/data/paddle_checkout_service.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_enums.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_event.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_item.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_options.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_settings.dart';
import 'package:paddle_wrapper/src/features/checkout/domain/entities/checkout_update.dart';

import '../../support/fake_paddle_platform.dart';

const _items = [CheckoutItem(priceId: 'pri_1', quantity: 2)];

void main() {
  late FakePaddlePlatform platform;
  late StreamController<JsonMap> rawEvents;
  late PaddleCheckoutService service;

  setUp(() {
    platform = FakePaddlePlatform();
    rawEvents = StreamController<JsonMap>.broadcast();
    service = PaddleCheckoutService(
      platform: platform,
      rawEvents: rawEvents.stream,
    );
  });

  tearDown(() async {
    await rawEvents.close();
  });

  List<String> callNames() => [for (final call in platform.calls) call.$1];

  group('open', () {
    test('opens an overlay checkout with the JSON options', () async {
      final options = CheckoutOptions(
        items: _items,
        settings: const CheckoutSettings.overlay(theme: CheckoutTheme.dark),
      );

      await service.open(options);

      expect(platform.argsOf('openCheckout').single, options.toJson());
      expect(platform.argsOf('whenFrameTargetReady'), isEmpty);
    });

    test(
      'waits for the frame target before opening an inline checkout',
      () async {
        await service.open(
          CheckoutOptions(
            items: _items,
            settings: const CheckoutSettings.inline(frameTarget: 'frame-a'),
          ),
        );

        expect(callNames(), ['whenFrameTargetReady', 'openCheckout']);
        expect(platform.argsOf('whenFrameTargetReady').single, 'frame-a');
      },
    );

    test('does not call the platform when validation fails', () async {
      final invalid = CheckoutOptions(
        items: _items,
        settings: const CheckoutSettings(
          displayMode: CheckoutDisplayMode.inline,
        ),
      );

      await expectLater(
        service.open(invalid),
        throwsA(isA<PaddleValidationException>()),
      );
      expect(platform.calls, isEmpty);
    });

    test('rejects a checkout with no items and no transaction', () async {
      await expectLater(
        service.open(const CheckoutOptions(items: [])),
        throwsA(isA<PaddleValidationException>()),
      );
      expect(platform.calls, isEmpty);
    });
  });

  group('events', () {
    test('maps raw Paddle.js events to CheckoutEvent', () async {
      final next = service.events.first;

      rawEvents.add({
        'name': 'checkout.loaded',
        'data': {'id': 'che_1'},
      });

      final event = await next;
      expect(event, isA<CheckoutEvent>());
      expect(event.name, CheckoutEventName.loaded);
      expect(event.isLoaded, isTrue);
      expect(event.data!.id, 'che_1');
    });

    test('emits every event to several listeners', () async {
      final first = service.events.toList();
      final second = service.events.first;

      rawEvents.add({'name': 'checkout.closed'});
      await Future<void>.delayed(Duration.zero);
      await rawEvents.close();

      expect((await second).name, CheckoutEventName.closed);
      expect((await first).single.name, CheckoutEventName.closed);
    });
  });

  group('update', () {
    test('sends the update payload to updateCheckout', () {
      final update = CheckoutUpdate(items: _items, customData: const {'a': 1});

      service.update(update);

      expect(platform.argsOf('updateCheckout').single, update.toJson());
    });

    test('does not call the platform when the update is invalid', () {
      expect(
        () => service.update(const CheckoutUpdate(items: [])),
        throwsA(isA<PaddleValidationException>()),
      );
      expect(platform.calls, isEmpty);
    });
  });

  group('updateItems', () {
    test('replaces the items through the platform', () {
      service.updateItems(_items);

      expect(platform.argsOf('updateCheckoutItems').single, [
        {'priceId': 'pri_1', 'quantity': 2},
      ]);
    });

    test('rejects an empty list without calling the platform', () {
      expect(
        () => service.updateItems(const []),
        throwsA(isA<PaddleValidationException>()),
      );
      expect(platform.calls, isEmpty);
    });
  });

  test('close delegates to the platform', () {
    service.close();

    expect(callNames(), ['closeCheckout']);
  });
}
