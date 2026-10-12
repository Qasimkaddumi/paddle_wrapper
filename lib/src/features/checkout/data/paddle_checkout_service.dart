import '../../../core/json.dart';
import '../../../core/paddle_exception.dart';
import '../../../core/platform/paddle_platform.dart';
import '../domain/checkout_service.dart';
import '../domain/entities/checkout_enums.dart';
import '../domain/entities/checkout_event.dart';
import '../domain/entities/checkout_item.dart';
import '../domain/entities/checkout_options.dart';
import '../domain/entities/checkout_update.dart';

/// [CheckoutService] backed by Paddle.js through a [PaddlePlatform].
class PaddleCheckoutService implements CheckoutService {
  /// Creates the service. [rawEvents] is the stream of raw Paddle.js events
  /// (`{name, data}` maps) routed by the Paddle facade.
  PaddleCheckoutService({
    required PaddlePlatform platform,
    required Stream<JsonMap> rawEvents,
    // The private field cannot be an initializing formal (its parameter is
    // named `platform`, which callers pass by name).
    // ignore: prefer_initializing_formals
  }) : _platform = platform,
       events = rawEvents.map(CheckoutEvent.fromJson).asBroadcastStream();

  /// How long an inline checkout waits for its `frameTarget` to be attached.
  static const Duration frameTargetTimeout = Duration(seconds: 10);

  final PaddlePlatform _platform;

  @override
  final Stream<CheckoutEvent> events;

  /// Opens a checkout.
  ///
  /// Inline checkouts (`settings.displayMode` is inline) first wait until the
  /// `frameTarget` element is attached to the page. Inline checkouts must be
  /// passed their settings here; the global defaults from `PaddleConfig` are
  /// not used to decide this. Throws [PaddleValidationException] before
  /// calling Paddle.js when the options are invalid.
  @override
  Future<void> open(CheckoutOptions options) async {
    options.validate();
    final settings = options.settings;
    final target = settings?.frameTarget;
    if (settings?.displayMode == CheckoutDisplayMode.inline && target != null) {
      await _platform.whenFrameTargetReady(target, timeout: frameTargetTimeout);
    }
    _platform.openCheckout(options.toJson());
  }

  /// Updates the open checkout. Throws [PaddleValidationException] before
  /// calling Paddle.js when the update is invalid.
  @override
  void update(CheckoutUpdate update) {
    update.validate();
    _platform.updateCheckout(update.toJson());
  }

  /// Replaces the full item list of the open checkout. Throws
  /// [PaddleValidationException] when [items] is empty.
  @override
  void updateItems(List<CheckoutItem> items) {
    if (items.isEmpty) {
      throw const PaddleValidationException(
        'updateItems requires at least one item.',
      );
    }
    for (final item in items) {
      item.validate();
    }
    _platform.updateCheckoutItems([for (final item in items) item.toJson()]);
  }

  /// Closes the open checkout.
  @override
  void close() => _platform.closeCheckout();
}
