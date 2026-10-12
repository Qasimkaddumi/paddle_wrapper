import 'entities/checkout_event.dart';
import 'entities/checkout_item.dart';
import 'entities/checkout_options.dart';
import 'entities/checkout_update.dart';

/// Opens, updates and closes Paddle checkouts and exposes their events.
abstract interface class CheckoutService {
  /// Every event emitted by Paddle.js checkouts (broadcast stream).
  Stream<CheckoutEvent> get events;

  /// Opens a checkout. For inline checkouts this waits until the
  /// `frameTarget` element is attached to the page.
  Future<void> open(CheckoutOptions options);

  /// Updates items, customer, discount or custom data of the open checkout.
  void update(CheckoutUpdate update);

  /// Replaces the full list of items on the open checkout.
  void updateItems(List<CheckoutItem> items);

  /// Closes the open checkout.
  void close();
}
