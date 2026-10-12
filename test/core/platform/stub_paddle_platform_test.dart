import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/core/paddle_environment.dart';
import 'package:paddle_wrapper/src/core/paddle_exception.dart';
import 'package:paddle_wrapper/src/core/platform/paddle_platform.dart';
import 'package:paddle_wrapper/src/core/platform/stub/paddle_platform_stub.dart';

void main() {
  const stub = StubPaddlePlatform();
  const unsupported = PaddleUnsupportedPlatformException();

  group('StubPaddlePlatform', () {
    test('the default factory returns the stub on the VM', () {
      expect(PaddlePlatform(), isA<StubPaddlePlatform>());
    });

    test('reports unsupported and not loaded', () {
      expect(stub.isSupported, isFalse);
      expect(stub.isLoaded, isFalse);
      expect(stub.libraryVersion, isNull);
    });

    test('synchronous methods throw PaddleUnsupportedPlatformException', () {
      expect(
        () => stub.setEnvironment(PaddleEnvironment.sandbox),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(
        () => stub.initialize({}, (_) {}),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(
        () => stub.update({}),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(
        () => stub.openCheckout({}),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(
        () => stub.updateCheckout({}),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(
        () => stub.updateCheckoutItems([]),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(
        () => stub.closeCheckout(),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(
        () => stub.retainDemo({}),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
      expect(
        () => stub.prepareFrameTarget(Object(), className: 'frame'),
        throwsA(isA<PaddleUnsupportedPlatformException>()),
      );
    });

    test(
      'asynchronous methods fail with PaddleUnsupportedPlatformException',
      () async {
        await expectLater(
          stub.load(
            Uri.parse('https://example.com/paddle.js'),
            timeout: const Duration(seconds: 1),
          ),
          throwsA(isA<PaddleUnsupportedPlatformException>()),
        );
        await expectLater(
          stub.pricePreview({}),
          throwsA(isA<PaddleUnsupportedPlatformException>()),
        );
        await expectLater(
          stub.transactionPreview({}),
          throwsA(isA<PaddleUnsupportedPlatformException>()),
        );
        await expectLater(
          stub.initCancellationFlow({}),
          throwsA(isA<PaddleUnsupportedPlatformException>()),
        );
        await expectLater(
          stub.whenFrameTargetReady(
            'frame',
            timeout: const Duration(seconds: 1),
          ),
          throwsA(isA<PaddleUnsupportedPlatformException>()),
        );
      },
    );

    test('the thrown exception is the shared unsupported exception', () {
      expect(
        unsupported.message,
        'Paddle.js is only available on Flutter web.',
      );
    });
  });
}
