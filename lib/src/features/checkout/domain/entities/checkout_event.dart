import '../../../../core/json.dart';
import 'checkout_data.dart';
import 'checkout_error.dart';

/// Every checkout event name Paddle.js emits.
enum CheckoutEventName with PaddleEnum {
  /// The checkout was closed.
  closed('checkout.closed'),

  /// The payment completed.
  completed('checkout.completed'),

  /// A customer was created during checkout.
  customerCreated('checkout.customer.created'),

  /// A customer was removed from the checkout.
  customerRemoved('checkout.customer.removed'),

  /// The customer was updated.
  customerUpdated('checkout.customer.updated'),

  /// A discount was applied.
  discountApplied('checkout.discount.applied'),

  /// A discount was removed.
  discountRemoved('checkout.discount.removed'),

  /// An error occurred.
  error('checkout.error'),

  /// Items were removed.
  itemsRemoved('checkout.items.removed'),

  /// Items were updated.
  itemsUpdated('checkout.items.updated'),

  /// The checkout finished loading.
  loaded('checkout.loaded'),

  /// A payment error occurred.
  paymentError('checkout.payment.error'),

  /// A payment failed.
  paymentFailed('checkout.payment.failed'),

  /// A payment was initiated.
  paymentInitiated('checkout.payment.initiated'),

  /// A payment method was selected.
  paymentSelected('checkout.payment.selected'),

  /// The checkout was updated.
  updated('checkout.updated'),

  /// An upsell was canceled.
  upsellCanceled('checkout.upsell.canceled'),

  /// A warning was emitted.
  warning('checkout.warning'),

  /// An event this package does not know yet. The original name is kept in
  /// [CheckoutEvent.rawName].
  unknown('unknown');

  const CheckoutEventName(this.value);

  @override
  final String value;
}

/// An event emitted by a Paddle.js checkout.
class CheckoutEvent {
  /// Creates an event.
  const CheckoutEvent({
    required this.name,
    required this.rawName,
    required this.raw,
    this.data,
    this.error,
  });

  /// Parses a raw Paddle.js event (`{name, data}`). Never throws: unknown
  /// names become [CheckoutEventName.unknown] and malformed data is dropped.
  factory CheckoutEvent.fromJson(JsonMap json) {
    final rawName = json.stringOrNull('name') ?? '';
    final name = parsePaddleEnum(
      CheckoutEventName.values,
      rawName,
      fallback: CheckoutEventName.unknown,
    );
    final rawData = json.mapOrNull('data');
    final isErrorEvent =
        name == CheckoutEventName.error ||
        name == CheckoutEventName.warning ||
        name == CheckoutEventName.paymentError;
    return CheckoutEvent(
      name: name,
      rawName: rawName,
      raw: json,
      data: rawData == null ? null : CheckoutData.fromJson(rawData),
      error: isErrorEvent
          ? CheckoutError.fromJson(rawData ?? const <String, dynamic>{})
          : null,
    );
  }

  /// The parsed event name.
  final CheckoutEventName name;

  /// The event name exactly as Paddle.js sent it.
  final String rawName;

  /// The event as received from Paddle.js.
  final JsonMap raw;

  /// The checkout data carried by the event, when present.
  final CheckoutData? data;

  /// The error for `checkout.error`, `checkout.warning` and
  /// `checkout.payment.error` events. Always set for those events, even when
  /// Paddle sent no data (all fields are then `null`).
  final CheckoutError? error;

  /// Whether the payment completed.
  bool get isCompleted => name == CheckoutEventName.completed;

  /// Whether the checkout was closed.
  bool get isClosed => name == CheckoutEventName.closed;

  /// Whether the checkout finished loading.
  bool get isLoaded => name == CheckoutEventName.loaded;

  /// Whether this is an error event (`checkout.error` or
  /// `checkout.payment.error`).
  bool get isError =>
      name == CheckoutEventName.error || name == CheckoutEventName.paymentError;

  @override
  String toString() => 'CheckoutEvent($rawName)';
}
