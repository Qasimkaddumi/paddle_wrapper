import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';

/// An upsell offered after the transaction [transactionId] was paid.
///
/// Upsells are only supported on inline one-page checkouts.
class CheckoutUpsell {
  /// Creates an upsell for the transaction [transactionId] (`txn_...`).
  const CheckoutUpsell(this.transactionId, {this.showSkipButton});

  /// The transaction ID (`txn_...`) the upsell is attached to.
  final String transactionId;

  /// Whether to show a button that lets the buyer skip the upsell.
  final bool? showSkipButton;

  /// Throws [PaddleValidationException] when the upsell is invalid.
  void validate() {
    if (transactionId.trim().isEmpty) {
      throw const PaddleValidationException(
        'Upsell transactionId must not be empty.',
      );
    }
  }

  /// The Paddle.js upsell shape.
  JsonMap toJson() => compactJson({
    'transactionId': transactionId,
    'settings': showSkipButton == null
        ? null
        : {'showSkipButton': showSkipButton},
  });
}
