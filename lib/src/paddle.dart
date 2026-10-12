import 'dart:async';

import 'package:flutter/foundation.dart';

import 'core/json.dart';
import 'core/paddle_exception.dart';
import 'core/platform/paddle_platform.dart';
import 'features/checkout/data/paddle_checkout_service.dart';
import 'features/checkout/domain/checkout_service.dart';
import 'features/checkout/domain/entities/checkout_event.dart';
import 'features/checkout/domain/entities/checkout_settings.dart';
import 'features/pricing/data/paddle_pricing_service.dart';
import 'features/pricing/domain/pricing_service.dart';
import 'features/retain/data/paddle_retain_service.dart';
import 'features/retain/domain/retain_service.dart';
import 'paddle_config.dart';

/// Entry point of the package: a facade over Paddle.js.
///
/// Paddle.js is a page-wide singleton, so this class is too:
///
/// ```dart
/// await Paddle.initialize(const PaddleConfig(clientToken: 'test_...'));
/// await Paddle.instance.checkout.open(
///   CheckoutOptions(items: [CheckoutItem(priceId: 'pri_...')]),
/// );
/// ```
class Paddle {
  Paddle._({
    required this.config,
    required PaddlePlatform platform,
    required StreamController<JsonMap> rawEvents,
  }) : _platform = platform,
       _rawEvents = rawEvents,
       checkout = PaddleCheckoutService(
         platform: platform,
         rawEvents: rawEvents.stream,
       ),
       pricing = PaddlePricingService(platform),
       retain = PaddleRetainService(platform);

  static Paddle? _instance;
  static Future<Paddle>? _initializing;

  /// The configuration Paddle was initialized with.
  final PaddleConfig config;

  /// Overlay and inline checkout.
  final CheckoutService checkout;

  /// Localized price and transaction previews.
  final PricingService pricing;

  /// Paddle Retain.
  final RetainService retain;

  final PaddlePlatform _platform;
  final StreamController<JsonMap> _rawEvents;

  /// The initialized instance.
  ///
  /// Throws [PaddleNotInitializedException] before [initialize] completes.
  static Paddle get instance =>
      _instance ?? (throw const PaddleNotInitializedException());

  /// Whether [initialize] has completed.
  static bool get isInitialized => _instance != null;

  /// Loads and initializes Paddle.js. Safe to call more than once: later
  /// calls with the same token return the existing instance; a different
  /// token or environment throws [PaddleConfigurationException].
  ///
  /// [platform] lets tests (or future platforms) swap the Paddle.js bridge.
  static Future<Paddle> initialize(
    PaddleConfig config, {
    PaddlePlatform? platform,
  }) {
    final existing = _instance;
    if (existing != null) {
      if (existing.config.clientToken != config.clientToken ||
          existing.config.environment != config.environment) {
        // Paddle.js cannot be re-initialized with another account.
        return Future.error(
          const PaddleConfigurationException(
            'Paddle is already initialized with a different client token or '
            'environment. Reload the page to switch accounts.',
          ),
        );
      }
      return Future.value(existing);
    }
    return _initializing ??= _create(
      config,
      platform ?? PaddlePlatform(),
    ).whenComplete(() => _initializing = null);
  }

  static Future<Paddle> _create(
    PaddleConfig config,
    PaddlePlatform platform,
  ) async {
    config.validate();
    if (!platform.isSupported) throw const PaddleUnsupportedPlatformException();

    await platform.load(config.resolvedScriptUrl, timeout: config.loadTimeout);
    platform.setEnvironment(config.environment);

    final rawEvents = StreamController<JsonMap>.broadcast();
    platform.initialize(config.toInitializeJson(), rawEvents.add);

    return _instance = Paddle._(
      config: config,
      platform: platform,
      rawEvents: rawEvents,
    );
  }

  /// Every checkout event. Shortcut for `checkout.events`.
  ///
  /// This is a broadcast stream without replay: events emitted while nobody
  /// listens are dropped. Subscribe before opening a checkout, ideally once
  /// at app level, so `checkout.completed` is never missed.
  Stream<CheckoutEvent> get events => checkout.events;

  /// Version of the loaded Paddle.js library.
  String? get libraryVersion => _platform.libraryVersion;

  /// Sets (or clears, with `null`) the logged-in customer used by Retain.
  void updateRetainCustomer(String? customerId) {
    if (customerId != null && !customerId.startsWith('ctm_')) {
      throw const PaddleConfigurationException(
        'customerId must be a Paddle customer ID (ctm_...).',
      );
    }
    _platform.update({
      'pwCustomer': PaddleConfig.retainCustomerJson(customerId),
    });
  }

  /// Replaces the default settings applied to every checkout.
  void updateCheckoutSettings(CheckoutSettings settings) => _platform.update({
    'checkout': {'settings': settings.toJson()},
  });

  /// Drops the singleton so [initialize] can run again. Tests only.
  @visibleForTesting
  static Future<void> reset() async {
    final instance = _instance;
    _instance = null;
    _initializing = null;
    await instance?._rawEvents.close();
  }
}
