import '../json.dart';
import '../paddle_environment.dart';
import 'paddle_platform_factory.dart';

/// Callback receiving a raw Paddle.js event (`{name: ..., data: {...}}`).
typedef PaddleEventHandler = void Function(JsonMap event);

/// Low-level bridge to the Paddle.js runtime.
///
/// It speaks plain JSON maps using the exact camelCase shapes Paddle.js
/// expects, so feature services own all mapping between typed models and
/// Paddle's wire format. New platforms (mobile, desktop) are added by
/// implementing this interface; nothing else in the package changes.
abstract interface class PaddlePlatform {
  /// The implementation for the current platform. On web this drives the
  /// real Paddle.js; elsewhere every call throws
  /// `PaddleUnsupportedPlatformException`.
  factory PaddlePlatform() => createPaddlePlatform();

  /// Whether Paddle.js can run on this platform.
  bool get isSupported;

  /// Whether the Paddle.js script is present on the page.
  bool get isLoaded;

  /// Version reported by `Paddle.Status.libraryVersion`, if loaded.
  String? get libraryVersion;

  /// Injects the Paddle.js script from [scriptUrl] unless already loaded and
  /// completes once `window.Paddle` is available.
  Future<void> load(Uri scriptUrl, {required Duration timeout});

  /// Calls `Paddle.Environment.set()`. Must run before [initialize].
  void setEnvironment(PaddleEnvironment environment);

  /// Calls `Paddle.Initialize()` with [options] and routes every checkout
  /// event to [onEvent].
  void initialize(JsonMap options, PaddleEventHandler onEvent);

  /// Calls `Paddle.Update()` with [options].
  void update(JsonMap options);

  /// Calls `Paddle.Checkout.open()`.
  void openCheckout(JsonMap options);

  /// Calls `Paddle.Checkout.updateCheckout()`.
  void updateCheckout(JsonMap options);

  /// Calls `Paddle.Checkout.updateItems()`.
  void updateCheckoutItems(List<JsonMap> items);

  /// Calls `Paddle.Checkout.close()`.
  void closeCheckout();

  /// Calls `Paddle.PricePreview()` and resolves with its result.
  Future<JsonMap> pricePreview(JsonMap request);

  /// Calls `Paddle.TransactionPreview()` and resolves with its result.
  Future<JsonMap> transactionPreview(JsonMap request);

  /// Calls `Paddle.Retain.initCancellationFlow()` and resolves with its result.
  Future<JsonMap> initCancellationFlow(JsonMap request);

  /// Calls `Paddle.Retain.demo()`.
  void retainDemo(JsonMap options);

  /// Prepares an element created by an `HtmlElementView` so it can host an
  /// inline checkout: assigns [className] and sizing styles.
  void prepareFrameTarget(Object element, {required String className});

  /// Completes once an element with [className] is attached to the document,
  /// so Paddle.js can find it as an inline `frameTarget`.
  Future<void> whenFrameTargetReady(
    String className, {
    required Duration timeout,
  });
}
