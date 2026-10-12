import 'core/json.dart';
import 'core/paddle_environment.dart';
import 'core/paddle_exception.dart';
import 'features/checkout/domain/entities/checkout_settings.dart';

/// Configuration passed to `Paddle.initialize`.
class PaddleConfig {
  /// Creates a configuration.
  ///
  /// [environment] defaults to the one implied by the [clientToken] prefix
  /// (`test_` for sandbox, `live_` for production).
  const PaddleConfig({
    required this.clientToken,
    PaddleEnvironment? environment,
    this.checkoutSettings,
    this.retainCustomerId,
    this.scriptUrl,
    this.loadTimeout = const Duration(seconds: 20),
  }) // A public named parameter cannot initialize a private field directly.
    // ignore: prefer_initializing_formals
    : _environment = environment;

  /// Default Paddle.js v2 script location.
  static final Uri defaultScriptUrl = Uri.parse(
    'https://cdn.paddle.com/paddle/v2/paddle.js',
  );

  /// Client-side token from Paddle > Developer tools > Authentication.
  /// Never use an API key here.
  final String clientToken;

  final PaddleEnvironment? _environment;

  /// Default settings applied to every checkout opened on the page.
  final CheckoutSettings? checkoutSettings;

  /// Paddle customer ID (`ctm_...`) of the logged-in user, for Retain.
  final String? retainCustomerId;

  /// Overrides where Paddle.js is loaded from.
  final Uri? scriptUrl;

  /// How long to wait for Paddle.js to load.
  final Duration loadTimeout;

  /// The resolved environment.
  PaddleEnvironment get environment =>
      _environment ??
      PaddleEnvironment.fromClientToken(clientToken) ??
      PaddleEnvironment.production;

  /// The resolved script URL.
  Uri get resolvedScriptUrl => scriptUrl ?? defaultScriptUrl;

  /// Throws [PaddleConfigurationException] when the config cannot work.
  void validate() {
    if (clientToken.trim().isEmpty) {
      throw const PaddleConfigurationException(
        'clientToken must not be empty.',
      );
    }
    if (clientToken.startsWith('pdl_')) {
      throw const PaddleConfigurationException(
        'clientToken looks like a secret API key. Use a client-side token '
        '(test_... or live_...) and never ship API keys to the browser.',
      );
    }
    final implied = PaddleEnvironment.fromClientToken(clientToken);
    if (implied != null && implied != environment) {
      throw PaddleConfigurationException(
        'A ${implied.tokenPrefix} token cannot be used with the '
        '${environment.name} environment.',
      );
    }
    if (retainCustomerId != null && !retainCustomerId!.startsWith('ctm_')) {
      throw const PaddleConfigurationException(
        'retainCustomerId must be a Paddle customer ID (ctm_...).',
      );
    }
  }

  /// Options for `Paddle.Initialize()`.
  JsonMap toInitializeJson() => compactJson({
    'token': clientToken,
    'pwCustomer': retainCustomerJson(retainCustomerId),
    if (checkoutSettings != null)
      'checkout': {'settings': checkoutSettings!.toJson()},
  });

  /// `pwCustomer` payload: an empty object when nobody is logged in.
  static JsonMap retainCustomerJson(String? customerId) =>
      customerId == null ? <String, dynamic>{} : {'id': customerId};
}
