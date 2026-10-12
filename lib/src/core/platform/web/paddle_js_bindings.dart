// Minimal dart:js_interop bindings for the Paddle.js v2 global object.
//
// Only the members this package uses are declared. `window.Paddle` is
// undefined until the script has loaded, so [paddleJs] is nullable.
import 'dart:js_interop';

/// `window.Paddle`, or `null` when Paddle.js has not loaded.
@JS('Paddle')
external PaddleJs? get paddleJs;

/// The `Paddle` global namespace.
extension type PaddleJs._(JSObject _) implements JSObject {
  /// `Paddle.Environment`.
  @JS('Environment')
  external PaddleEnvironmentJs get environment;

  /// `Paddle.Status`.
  @JS('Status')
  external PaddleStatusJs get status;

  /// `Paddle.Checkout`.
  @JS('Checkout')
  external PaddleCheckoutJs get checkout;

  /// `Paddle.Retain`.
  @JS('Retain')
  external PaddleRetainJs get retain;

  /// `Paddle.Initialize(options)`.
  @JS('Initialize')
  external void initialize(JSAny options);

  /// `Paddle.Update(options)`.
  @JS('Update')
  external void update(JSAny options);

  /// `Paddle.PricePreview(request)`.
  @JS('PricePreview')
  external JSPromise<JSAny?> pricePreview(JSAny request);

  /// `Paddle.TransactionPreview(request)`.
  @JS('TransactionPreview')
  external JSPromise<JSAny?> transactionPreview(JSAny request);
}

/// `Paddle.Environment`.
extension type PaddleEnvironmentJs._(JSObject _) implements JSObject {
  /// `Paddle.Environment.set(name)`, e.g. `'sandbox'`.
  @JS('set')
  external void setEnvironment(String name);
}

/// `Paddle.Status`.
extension type PaddleStatusJs._(JSObject _) implements JSObject {
  /// `Paddle.Status.libraryVersion`.
  @JS('libraryVersion')
  external String? get libraryVersion;
}

/// `Paddle.Checkout`.
extension type PaddleCheckoutJs._(JSObject _) implements JSObject {
  /// `Paddle.Checkout.open(options)`.
  @JS('open')
  external void open(JSAny options);

  /// `Paddle.Checkout.updateCheckout(options)`.
  @JS('updateCheckout')
  external void updateCheckout(JSAny options);

  /// `Paddle.Checkout.updateItems(items)`.
  @JS('updateItems')
  external void updateItems(JSAny items);

  /// `Paddle.Checkout.close()`.
  @JS('close')
  external void close();
}

/// `Paddle.Retain`.
extension type PaddleRetainJs._(JSObject _) implements JSObject {
  /// `Paddle.Retain.initCancellationFlow(request)`.
  @JS('initCancellationFlow')
  external JSPromise<JSAny?> initCancellationFlow(JSAny request);

  /// `Paddle.Retain.demo(options)`.
  @JS('demo')
  external void demo(JSAny options);
}
