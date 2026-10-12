import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';
import 'checkout_customer.dart';
import 'checkout_discount.dart';
import 'checkout_enums.dart';
import 'checkout_item.dart';
import 'checkout_settings.dart';
import 'checkout_upsell.dart';

/// Everything needed to open a checkout (`Paddle.Checkout.open`).
///
/// A checkout is built either from [items] (a new purchase) or from an
/// existing [transactionId] (a draft transaction), never both.
class CheckoutOptions {
  const CheckoutOptions._({
    this.items = const [],
    this.transactionId,
    this.settings,
    this.customer,
    this.discount,
    this.upsell,
    this.customData,
    this.customerAuthToken,
    this.savedPaymentMethodId,
  });

  /// Opens a checkout for [items].
  const CheckoutOptions({
    required List<CheckoutItem> items,
    CheckoutSettings? settings,
    CheckoutCustomer? customer,
    CheckoutDiscount? discount,
    CheckoutUpsell? upsell,
    JsonMap? customData,
    String? customerAuthToken,
    String? savedPaymentMethodId,
  }) : this._(
         items: items,
         settings: settings,
         customer: customer,
         discount: discount,
         upsell: upsell,
         customData: customData,
         customerAuthToken: customerAuthToken,
         savedPaymentMethodId: savedPaymentMethodId,
       );

  /// Opens a checkout for an existing draft transaction [transactionId]
  /// (`txn_...`).
  const CheckoutOptions.transaction(
    String transactionId, {
    CheckoutSettings? settings,
    CheckoutCustomer? customer,
    CheckoutDiscount? discount,
    CheckoutUpsell? upsell,
    JsonMap? customData,
    String? customerAuthToken,
    String? savedPaymentMethodId,
  }) : this._(
         transactionId: transactionId,
         settings: settings,
         customer: customer,
         discount: discount,
         upsell: upsell,
         customData: customData,
         customerAuthToken: customerAuthToken,
         savedPaymentMethodId: savedPaymentMethodId,
       );

  /// Items to purchase. Empty when [transactionId] is used.
  final List<CheckoutItem> items;

  /// Existing transaction ID (`txn_...`). Null when [items] is used.
  final String? transactionId;

  /// Checkout settings. Null keeps the account and Paddle defaults.
  final CheckoutSettings? settings;

  /// Customer to pre-fill.
  final CheckoutCustomer? customer;

  /// Discount to apply.
  final CheckoutDiscount? discount;

  /// Upsell offered after payment. Inline one-page checkouts only.
  final CheckoutUpsell? upsell;

  /// Custom data attached to the transaction. Must not be empty when set.
  final JsonMap? customData;

  /// Auth token of a customer, required for [savedPaymentMethodId].
  final String? customerAuthToken;

  /// Saved payment method ID (`paymtd_...`). Requires [customerAuthToken]
  /// and cannot be used with the express variant.
  final String? savedPaymentMethodId;

  /// Returns a copy with the given fields replaced. Fields that are `null`
  /// keep their current value. The [transactionId] is kept as is.
  CheckoutOptions copyWith({
    List<CheckoutItem>? items,
    CheckoutSettings? settings,
    CheckoutCustomer? customer,
    CheckoutDiscount? discount,
    CheckoutUpsell? upsell,
    JsonMap? customData,
    String? customerAuthToken,
    String? savedPaymentMethodId,
  }) => CheckoutOptions._(
    items: items ?? this.items,
    transactionId: transactionId,
    settings: settings ?? this.settings,
    customer: customer ?? this.customer,
    discount: discount ?? this.discount,
    upsell: upsell ?? this.upsell,
    customData: customData ?? this.customData,
    customerAuthToken: customerAuthToken ?? this.customerAuthToken,
    savedPaymentMethodId: savedPaymentMethodId ?? this.savedPaymentMethodId,
  );

  /// Throws [PaddleValidationException] when the options cannot work
  /// with Paddle.js.
  void validate() {
    final txn = transactionId;
    if (txn != null) {
      if (items.isNotEmpty) {
        throw const PaddleValidationException(
          'Use either items or a transactionId, not both.',
        );
      }
      if (txn.trim().isEmpty) {
        throw const PaddleValidationException(
          'transactionId must not be empty.',
        );
      }
    } else if (items.isEmpty) {
      throw const PaddleValidationException(
        'A checkout requires at least one item or a transactionId.',
      );
    }
    for (final item in items) {
      item.validate();
    }
    settings?.validate();
    customer?.validate();
    discount?.validate();
    upsell?.validate();

    final data = customData;
    if (data != null && data.isEmpty) {
      throw const PaddleValidationException(
        'customData must contain at least one key when provided.',
      );
    }
    if (savedPaymentMethodId != null && customerAuthToken == null) {
      throw const PaddleValidationException(
        'savedPaymentMethodId requires a customerAuthToken.',
      );
    }
    if ((savedPaymentMethodId != null || customerAuthToken != null) &&
        settings?.variant == CheckoutVariant.express) {
      throw const PaddleValidationException(
        'Saved payment methods (customerAuthToken, savedPaymentMethodId) '
        'cannot be used with the express variant.',
      );
    }
    final current = settings;
    if (upsell != null &&
        current != null &&
        (current.displayMode != CheckoutDisplayMode.inline ||
            current.variant != CheckoutVariant.onePage)) {
      throw const PaddleValidationException(
        'Upsells require an inline, one-page checkout.',
      );
    }
  }

  /// The Paddle.js `Checkout.open` options. Null fields are omitted.
  JsonMap toJson() => compactJson({
    'settings': settings?.toJson(),
    'items': transactionId == null
        ? [for (final item in items) item.toJson()]
        : null,
    'transactionId': transactionId,
    'customer': customer?.toJson(),
    ...?discount?.toJson(),
    'upsell': upsell?.toJson(),
    'customData': customData,
    'customerAuthToken': customerAuthToken,
    'savedPaymentMethodId': savedPaymentMethodId,
  });
}
