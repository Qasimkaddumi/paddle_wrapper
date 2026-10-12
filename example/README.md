# paddle_wrapper example

A small Flutter web app that demonstrates the `paddle_wrapper` package:

| Demo | What it shows |
| --- | --- |
| Overlay checkout | Localized prices from `Paddle.instance.pricing.previewPrices`, Paddle's default overlay checkout, and navigation on `checkout.completed`. |
| Inline checkout | Your own order summary built with `PaddleCheckoutBuilder`, the Paddle payment form rendered by `PaddleCheckoutFrame`, quantity changes and discount codes. |
| Confirmation | Waiting for your backend to confirm the order with `PaymentConfirmation`. The backend here is a fake. |

## Run it

You need a Paddle sandbox client-side token and a sandbox price ID.

```sh
flutter run -d chrome --web-port 5000 --dart-define=PADDLE_CLIENT_TOKEN=test_xxx --dart-define=PADDLE_PRICE_ID=pri_xxx
```

Optional: a second price for the pricing page.

```sh
--dart-define=PADDLE_PRICE_ID_2=pri_yyy
```

If a required value is missing, the app shows a setup screen that lists what to pass.

## Paddle setup

1. In Paddle, go to **Developer tools > Authentication** and copy a client-side token. Sandbox tokens start with `test_`. Never use an API key (`pdl_...`) in an app.
2. Go to **Checkout > Checkout settings** and add the local origin, for example `http://localhost:5000`, as an approved domain for payment links. Paddle.js refuses to open checkouts from unapproved origins.
3. Make sure the price you use has a default payment link.

The fixed `--web-port 5000` keeps the origin stable, so the approved domain keeps working between runs.

## Where to look

```text
lib/
  main.dart                       Paddle.initialize, startup errors
  app.dart                        MaterialApp (Material 3) and theme
  config/app_config.dart          --dart-define values
  features/
    home/home_page.dart           demo list
    pricing/pricing_page.dart     overlay checkout demo
    custom_checkout/              inline checkout demo
    confirmation/                 backend polling and the fake backend
    setup/startup_screen.dart     shown when configuration is missing
  shared/section_card.dart        shared card widget
```

`features/confirmation/order_backend.dart` contains the comment that explains how the fake should be replaced with a real backend call. Read it before you copy this example into a product.
