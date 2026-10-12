/// Build-time configuration read from `--dart-define` flags.
///
/// ```text
/// flutter run -d chrome \
///   --dart-define=PADDLE_CLIENT_TOKEN=test_xxx \
///   --dart-define=PADDLE_PRICE_ID=pri_xxx
/// ```
///
/// Only client-side tokens (`test_...` or `live_...`) belong here. Never put
/// a Paddle API key (`pdl_...`) in an app: it would ship to every browser.
abstract final class AppConfig {
  /// Paddle client-side token (Paddle > Developer tools > Authentication).
  static const String clientToken = String.fromEnvironment(
    'PADDLE_CLIENT_TOKEN',
  );

  /// Primary price ID (`pri_...`) shown in the demos.
  static const String priceId = String.fromEnvironment('PADDLE_PRICE_ID');

  /// Optional second price ID (`pri_...`) shown on the pricing page.
  static const String secondPriceId = String.fromEnvironment(
    'PADDLE_PRICE_ID_2',
  );

  /// Names of the required variables that were not provided.
  static List<String> get missing => [
    if (clientToken.isEmpty) 'PADDLE_CLIENT_TOKEN',
    if (priceId.isEmpty) 'PADDLE_PRICE_ID',
  ];

  /// Whether every required variable was provided.
  static bool get isConfigured => missing.isEmpty;

  /// All price IDs to show, primary first.
  static List<String> get priceIds => [
    priceId,
    if (secondPriceId.isNotEmpty) secondPriceId,
  ];
}
