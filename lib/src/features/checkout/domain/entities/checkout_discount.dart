import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';

/// A discount applied to a checkout, by code or by Paddle discount ID.
sealed class CheckoutDiscount {
  const CheckoutDiscount();

  /// A discount code entered by the buyer or known to your app.
  const factory CheckoutDiscount.code(String code) = CheckoutDiscountCode;

  /// A Paddle discount ID (`dsc_...`).
  const factory CheckoutDiscount.id(String id) = CheckoutDiscountId;

  /// Throws [PaddleValidationException] when the discount is invalid.
  void validate();

  /// The Paddle.js fields this discount contributes.
  JsonMap toJson();
}

/// A discount identified by its code.
final class CheckoutDiscountCode extends CheckoutDiscount {
  /// Creates a discount from [code].
  const CheckoutDiscountCode(this.code);

  /// The discount code.
  final String code;

  @override
  void validate() {
    if (code.trim().isEmpty) {
      throw const PaddleValidationException('Discount code must not be empty.');
    }
  }

  @override
  JsonMap toJson() => {'discountCode': code};
}

/// A discount identified by its Paddle ID.
final class CheckoutDiscountId extends CheckoutDiscount {
  /// Creates a discount from the Paddle discount [id] (`dsc_...`).
  const CheckoutDiscountId(this.id);

  /// The Paddle discount ID (`dsc_...`).
  final String id;

  @override
  void validate() {
    if (id.trim().isEmpty) {
      throw const PaddleValidationException('Discount ID must not be empty.');
    }
  }

  @override
  JsonMap toJson() => {'discountId': id};
}
