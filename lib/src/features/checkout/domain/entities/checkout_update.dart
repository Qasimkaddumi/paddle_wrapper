import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';
import 'checkout_customer.dart';
import 'checkout_discount.dart';
import 'checkout_item.dart';

/// Changes to apply to an open checkout (`Paddle.Checkout.updateCheckout`).
class CheckoutUpdate {
  /// Creates an update. [items] is the full list of items and is required.
  const CheckoutUpdate({
    required this.items,
    this.customer,
    this.discount,
    this.customData,
  });

  /// The full list of items. Must not be empty.
  final List<CheckoutItem> items;

  /// Customer to set on the checkout.
  final CheckoutCustomer? customer;

  /// Discount to apply to the checkout.
  final CheckoutDiscount? discount;

  /// Custom data to attach to the transaction. Must not be empty when set.
  final JsonMap? customData;

  /// Throws [PaddleValidationException] when the update is invalid.
  void validate() {
    if (items.isEmpty) {
      throw const PaddleValidationException(
        'A checkout update requires at least one item.',
      );
    }
    for (final item in items) {
      item.validate();
    }
    customer?.validate();
    discount?.validate();
    final data = customData;
    if (data != null && data.isEmpty) {
      throw const PaddleValidationException(
        'customData must contain at least one key when provided.',
      );
    }
  }

  /// The Paddle.js `updateCheckout` payload. Null fields are omitted.
  JsonMap toJson() => compactJson({
    'items': [for (final item in items) item.toJson()],
    'customer': customer?.toJson(),
    ...?discount?.toJson(),
    'customData': customData,
  });
}
