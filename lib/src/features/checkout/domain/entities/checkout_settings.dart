import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';
import 'checkout_enums.dart';

/// Settings applied to a checkout. Maps to the Paddle.js `settings` object.
///
/// Every field is optional: omitted fields keep the Paddle.js default, or
/// the account default set through `PaddleConfig.checkoutSettings`.
class CheckoutSettings {
  /// Creates settings with any combination of fields.
  ///
  /// Prefer [CheckoutSettings.overlay] or [CheckoutSettings.inline] for
  /// the common cases.
  const CheckoutSettings({
    this.allowLogout,
    this.allowDiscountRemoval,
    this.allowedPaymentMethods,
    this.displayMode,
    this.frameInitialHeight,
    this.frameStyle,
    this.frameTarget,
    this.locale,
    this.showAddDiscounts,
    this.showAddTaxId,
    this.showNonExpressPaymentMethods,
    this.successUrl,
    this.theme,
    this.variant,
  });

  /// Settings for an overlay checkout.
  const CheckoutSettings.overlay({
    bool? allowLogout,
    bool? allowDiscountRemoval,
    List<PaymentMethod>? allowedPaymentMethods,
    CheckoutLocale? locale,
    bool? showAddDiscounts,
    bool? showAddTaxId,
    Uri? successUrl,
    CheckoutTheme? theme,
    CheckoutVariant? variant,
  }) : this(
         allowLogout: allowLogout,
         allowDiscountRemoval: allowDiscountRemoval,
         allowedPaymentMethods: allowedPaymentMethods,
         displayMode: CheckoutDisplayMode.overlay,
         locale: locale,
         showAddDiscounts: showAddDiscounts,
         showAddTaxId: showAddTaxId,
         successUrl: successUrl,
         theme: theme,
         variant: variant,
       );

  /// Settings for an inline checkout rendered into the element whose class
  /// name is [frameTarget].
  const CheckoutSettings.inline({
    required String frameTarget,
    int frameInitialHeight = 450,
    String frameStyle = defaultFrameStyle,
    bool? allowLogout,
    bool? allowDiscountRemoval,
    List<PaymentMethod>? allowedPaymentMethods,
    CheckoutLocale? locale,
    bool? showAddDiscounts,
    bool? showAddTaxId,
    Uri? successUrl,
    CheckoutTheme? theme,
    CheckoutVariant? variant,
  }) : this(
         allowLogout: allowLogout,
         allowDiscountRemoval: allowDiscountRemoval,
         allowedPaymentMethods: allowedPaymentMethods,
         displayMode: CheckoutDisplayMode.inline,
         frameInitialHeight: frameInitialHeight,
         frameStyle: frameStyle,
         frameTarget: frameTarget,
         locale: locale,
         showAddDiscounts: showAddDiscounts,
         showAddTaxId: showAddTaxId,
         successUrl: successUrl,
         theme: theme,
         variant: variant,
       );

  /// Default CSS applied to an inline checkout frame.
  static const String defaultFrameStyle =
      'width: 100%; min-width: 312px; background-color: transparent; '
      'border: none;';

  /// Whether the buyer can log out of the checkout.
  final bool? allowLogout;

  /// Whether the buyer can remove a discount from the checkout.
  final bool? allowDiscountRemoval;

  /// Payment methods to offer. When `null`, Paddle offers all enabled ones.
  final List<PaymentMethod>? allowedPaymentMethods;

  /// Overlay or inline presentation. Inline requires [frameTarget].
  final CheckoutDisplayMode? displayMode;

  /// Initial height of an inline frame, in pixels.
  final int? frameInitialHeight;

  /// CSS applied to an inline frame.
  final String? frameStyle;

  /// Class name of the container element that hosts an inline checkout.
  final String? frameTarget;

  /// Language of the checkout.
  final CheckoutLocale? locale;

  /// Whether the buyer can add discount codes.
  final bool? showAddDiscounts;

  /// Whether the buyer can add a tax identifier.
  final bool? showAddTaxId;

  /// Whether to show payment methods outside express checkout. Only
  /// meaningful with [CheckoutVariant.express].
  final bool? showNonExpressPaymentMethods;

  /// Where the buyer is redirected after a successful payment. Must use
  /// `http` or `https`.
  final Uri? successUrl;

  /// Colour theme of the checkout.
  final CheckoutTheme? theme;

  /// Layout variant of the checkout.
  final CheckoutVariant? variant;

  /// Returns a copy with the given fields replaced. Fields that are `null`
  /// keep their current value.
  CheckoutSettings copyWith({
    bool? allowLogout,
    bool? allowDiscountRemoval,
    List<PaymentMethod>? allowedPaymentMethods,
    CheckoutDisplayMode? displayMode,
    int? frameInitialHeight,
    String? frameStyle,
    String? frameTarget,
    CheckoutLocale? locale,
    bool? showAddDiscounts,
    bool? showAddTaxId,
    bool? showNonExpressPaymentMethods,
    Uri? successUrl,
    CheckoutTheme? theme,
    CheckoutVariant? variant,
  }) => CheckoutSettings(
    allowLogout: allowLogout ?? this.allowLogout,
    allowDiscountRemoval: allowDiscountRemoval ?? this.allowDiscountRemoval,
    allowedPaymentMethods: allowedPaymentMethods ?? this.allowedPaymentMethods,
    displayMode: displayMode ?? this.displayMode,
    frameInitialHeight: frameInitialHeight ?? this.frameInitialHeight,
    frameStyle: frameStyle ?? this.frameStyle,
    frameTarget: frameTarget ?? this.frameTarget,
    locale: locale ?? this.locale,
    showAddDiscounts: showAddDiscounts ?? this.showAddDiscounts,
    showAddTaxId: showAddTaxId ?? this.showAddTaxId,
    showNonExpressPaymentMethods:
        showNonExpressPaymentMethods ?? this.showNonExpressPaymentMethods,
    successUrl: successUrl ?? this.successUrl,
    theme: theme ?? this.theme,
    variant: variant ?? this.variant,
  );

  /// Throws [PaddleValidationException] when the combination of settings
  /// cannot work with Paddle.js.
  void validate() {
    final target = frameTarget;
    if (displayMode == CheckoutDisplayMode.inline &&
        (target == null || target.trim().isEmpty)) {
      throw const PaddleValidationException(
        'Inline checkouts require a frameTarget.',
      );
    }
    if (variant == CheckoutVariant.express &&
        displayMode != CheckoutDisplayMode.inline) {
      throw const PaddleValidationException(
        'The express variant requires displayMode to be inline.',
      );
    }
    final url = successUrl;
    if (url != null && url.scheme != 'http' && url.scheme != 'https') {
      throw PaddleValidationException(
        'successUrl must start with http:// or https:// (got "$url").',
      );
    }
    final height = frameInitialHeight;
    if (height != null && height <= 0) {
      throw const PaddleValidationException(
        'frameInitialHeight must be greater than zero.',
      );
    }
    if (allowedPaymentMethods?.contains(PaymentMethod.unknown) ?? false) {
      throw const PaddleValidationException(
        'PaymentMethod.unknown cannot be used in allowedPaymentMethods.',
      );
    }
  }

  /// The Paddle.js `settings` object. Null fields are omitted.
  JsonMap toJson() => compactJson({
    'allowLogout': allowLogout,
    'allowDiscountRemoval': allowDiscountRemoval,
    'allowedPaymentMethods': allowedPaymentMethods
        ?.map((m) => m.value)
        .toList(),
    'displayMode': displayMode?.value,
    // Paddle.js expects the height as a string of pixels without "px".
    'frameInitialHeight': frameInitialHeight?.toString(),
    'frameStyle': frameStyle,
    'frameTarget': frameTarget,
    'locale': locale?.value,
    'showAddDiscounts': showAddDiscounts,
    'showAddTaxId': showAddTaxId,
    'showNonExpressPaymentMethods': showNonExpressPaymentMethods,
    'successUrl': successUrl?.toString(),
    'theme': theme?.value,
    'variant': variant?.value,
  });
}
