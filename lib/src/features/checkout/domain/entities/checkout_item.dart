import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';

/// A price and quantity to purchase in a checkout.
class CheckoutItem {
  /// Creates an item for the Paddle price [priceId] (`pri_...`).
  const CheckoutItem({required this.priceId, this.quantity = 1});

  /// The Paddle price ID (`pri_...`).
  final String priceId;

  /// How many units to purchase. Must be at least 1.
  final int quantity;

  /// Throws [PaddleValidationException] when the item is invalid.
  void validate() {
    if (priceId.trim().isEmpty) {
      throw const PaddleValidationException(
        'CheckoutItem.priceId must not be empty.',
      );
    }
    if (quantity < 1) {
      throw const PaddleValidationException(
        'CheckoutItem.quantity must be at least 1.',
      );
    }
  }

  /// The Paddle.js item shape: `{priceId, quantity}`.
  JsonMap toJson() => {'priceId': priceId, 'quantity': quantity};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutItem &&
          other.priceId == priceId &&
          other.quantity == quantity;

  @override
  int get hashCode => Object.hash(priceId, quantity);

  @override
  String toString() => 'CheckoutItem(priceId: $priceId, quantity: $quantity)';
}
