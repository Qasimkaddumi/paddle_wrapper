## 0.1.0

* Initial release for Flutter web.
* `Paddle.initialize` loads and initializes Paddle.js v2 with a client-side token (`PaddleConfig`).
* Overlay checkout with `Paddle.instance.checkout.open`, plus `update`, `updateItems` and `close`.
* Inline checkout with `PaddleCheckoutFrame` and `PaddleCheckoutBuilder`, which exposes live `CheckoutState` for custom order summaries.
* Typed checkout events (`CheckoutEvent`, `CheckoutEventName`) with lenient parsing of unknown events.
* Localized price previews (`previewPrices`) and transaction previews (`previewTransaction`).
* Paddle Retain: `initCancellationFlow`, `demo` and `updateRetainCustomer`.
* `PaymentConfirmation` and `PollingPolicy` for waiting on your backend to confirm a payment.
* Typed exception hierarchy rooted at `PaddleException`.
* `PaddlePlatform` bridge, so tests and future platforms can replace the Paddle.js implementation.
* Example app in `example/`.
