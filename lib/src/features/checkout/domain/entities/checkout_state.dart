import 'checkout_data.dart';
import 'checkout_error.dart';
import 'checkout_event.dart';

/// Coarse lifecycle of a checkout, derived from its events.
enum CheckoutPhase {
  /// No checkout event received yet.
  idle,

  /// The checkout is loaded and the customer can interact with it.
  ready,

  /// A payment was submitted and is being processed.
  processingPayment,

  /// Payment succeeded (`checkout.completed`). Confirm fulfilment on your
  /// backend before granting access.
  completed,

  /// The checkout was closed.
  closed,
}

/// Snapshot of a checkout built from its event stream.
///
/// Use it to render your own order summary next to an inline checkout:
/// items, totals and discounts always reflect what Paddle will charge.
class CheckoutState {
  /// Creates a state.
  const CheckoutState({
    this.phase = CheckoutPhase.idle,
    this.data,
    this.lastEvent,
    this.error,
  });

  /// Current lifecycle phase.
  final CheckoutPhase phase;

  /// Latest checkout data (items, totals, customer, ...), if any.
  final CheckoutData? data;

  /// The most recent event.
  final CheckoutEvent? lastEvent;

  /// The latest error or warning, cleared by the next non-error event.
  final CheckoutError? error;

  /// Whether the checkout is loaded and not yet finished.
  bool get isReady => phase == CheckoutPhase.ready;

  /// Whether a payment is being processed.
  bool get isProcessingPayment => phase == CheckoutPhase.processingPayment;

  /// Whether the payment completed.
  bool get isCompleted => phase == CheckoutPhase.completed;

  /// Returns the state after [event].
  CheckoutState apply(CheckoutEvent event) {
    final error = event.error;
    return CheckoutState(
      phase: _phaseAfter(event),
      // Error and warning payloads are not checkout data; keep the last one.
      data: error == null ? (event.data ?? data) : data,
      lastEvent: event,
      error: error,
    );
  }

  CheckoutPhase _phaseAfter(CheckoutEvent event) => switch (event.name) {
    CheckoutEventName.loaded => CheckoutPhase.ready,
    CheckoutEventName.paymentInitiated => CheckoutPhase.processingPayment,
    CheckoutEventName.paymentFailed ||
    CheckoutEventName.paymentError => CheckoutPhase.ready,
    CheckoutEventName.completed => CheckoutPhase.completed,
    CheckoutEventName.closed => CheckoutPhase.closed,
    _ => phase == CheckoutPhase.idle ? CheckoutPhase.ready : phase,
  };
}
