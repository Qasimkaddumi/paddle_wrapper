import '../../../../core/json.dart';
import 'checkout_enums.dart';

T? _objectOrNull<T>(JsonMap json, String key, T Function(JsonMap) fromJson) {
  final value = json.mapOrNull(key);
  return value == null ? null : fromJson(value);
}

/// Monetary totals of a checkout, in the smallest currency unit.
class CheckoutTotals {
  /// Creates totals.
  const CheckoutTotals({
    this.subtotal,
    this.discount,
    this.tax,
    this.total,
    this.credit,
    this.balance,
  });

  /// Parses a totals object. Never throws.
  factory CheckoutTotals.fromJson(JsonMap json) => CheckoutTotals(
    subtotal: json.numOrNull('subtotal'),
    discount: json.numOrNull('discount'),
    tax: json.numOrNull('tax'),
    total: json.numOrNull('total'),
    credit: json.numOrNull('credit'),
    balance: json.numOrNull('balance'),
  );

  /// Subtotal before discounts and tax.
  final num? subtotal;

  /// Total discount.
  final num? discount;

  /// Total tax.
  final num? tax;

  /// Amount due, including tax.
  final num? total;

  /// Credit applied.
  final num? credit;

  /// Balance after credit.
  final num? balance;
}

/// A billing interval, such as one month.
class CheckoutInterval {
  /// Creates an interval.
  const CheckoutInterval({this.interval, this.frequency});

  /// Parses an interval object. Never throws.
  factory CheckoutInterval.fromJson(JsonMap json) => CheckoutInterval(
    interval: json.stringOrNull('interval'),
    frequency: json.intOrNull('frequency'),
  );

  /// Unit of the interval: `day`, `week`, `month` or `year`.
  final String? interval;

  /// Number of [interval] units.
  final int? frequency;
}

/// Product a checkout item refers to.
class CheckoutProduct {
  /// Creates a product.
  const CheckoutProduct({this.id, this.name, this.description, this.imageUrl});

  /// Parses a product object. Never throws.
  factory CheckoutProduct.fromJson(JsonMap json) => CheckoutProduct(
    id: json.stringOrNull('id'),
    name: json.stringOrNull('name'),
    description: json.stringOrNull('description'),
    imageUrl: json.stringOrNull('image_url'),
  );

  /// Paddle product ID (`pro_...`).
  final String? id;

  /// Product name.
  final String? name;

  /// Product description.
  final String? description;

  /// Product image URL.
  final String? imageUrl;
}

/// A line item of a checkout as reported by Paddle.
class CheckoutDataItem {
  /// Creates an item.
  const CheckoutDataItem({
    this.priceId,
    this.priceName,
    this.quantity,
    this.product,
    this.billingCycle,
    this.trialPeriod,
    this.totals,
    this.recurringTotals,
  });

  /// Parses an item object. Never throws.
  factory CheckoutDataItem.fromJson(JsonMap json) => CheckoutDataItem(
    priceId: json.stringOrNull('price_id'),
    priceName: json.stringOrNull('price_name'),
    quantity: json.intOrNull('quantity'),
    product: _objectOrNull(json, 'product', CheckoutProduct.fromJson),
    billingCycle: _objectOrNull(
      json,
      'billing_cycle',
      CheckoutInterval.fromJson,
    ),
    trialPeriod: _objectOrNull(json, 'trial_period', CheckoutInterval.fromJson),
    totals: _objectOrNull(json, 'totals', CheckoutTotals.fromJson),
    recurringTotals: _objectOrNull(
      json,
      'recurring_totals',
      CheckoutTotals.fromJson,
    ),
  );

  /// Price ID (`pri_...`).
  final String? priceId;

  /// Price name.
  final String? priceName;

  /// Quantity purchased.
  final int? quantity;

  /// Product of this item.
  final CheckoutProduct? product;

  /// Billing cycle, for recurring prices.
  final CheckoutInterval? billingCycle;

  /// Trial period, when the price has one.
  final CheckoutInterval? trialPeriod;

  /// Totals for this item.
  final CheckoutTotals? totals;

  /// Recurring totals for this item.
  final CheckoutTotals? recurringTotals;
}

/// Address of a customer as reported by Paddle.
class CheckoutDataAddress {
  /// Creates an address.
  const CheckoutDataAddress({
    this.id,
    this.countryCode,
    this.postalCode,
    this.firstLine,
    this.city,
    this.region,
  });

  /// Parses an address object. Never throws.
  factory CheckoutDataAddress.fromJson(JsonMap json) => CheckoutDataAddress(
    id: json.stringOrNull('id'),
    countryCode: json.stringOrNull('country_code'),
    postalCode: json.stringOrNull('postal_code'),
    firstLine: json.stringOrNull('first_line'),
    city: json.stringOrNull('city'),
    region: json.stringOrNull('region'),
  );

  /// Paddle address ID (`add_...`).
  final String? id;

  /// ISO country code.
  final String? countryCode;

  /// Postal code.
  final String? postalCode;

  /// First line of the street address.
  final String? firstLine;

  /// City.
  final String? city;

  /// State or region.
  final String? region;
}

/// Business as reported by Paddle.
class CheckoutDataBusiness {
  /// Creates a business.
  const CheckoutDataBusiness({this.id, this.name, this.taxIdentifier});

  /// Parses a business object. Never throws.
  factory CheckoutDataBusiness.fromJson(JsonMap json) => CheckoutDataBusiness(
    id: json.stringOrNull('id'),
    name: json.stringOrNull('name'),
    taxIdentifier: json.stringOrNull('tax_identifier'),
  );

  /// Paddle business ID (`biz_...`).
  final String? id;

  /// Business name.
  final String? name;

  /// Tax identifier.
  final String? taxIdentifier;
}

/// Customer as reported by Paddle.
class CheckoutDataCustomer {
  /// Creates a customer.
  const CheckoutDataCustomer({
    this.id,
    this.email,
    this.address,
    this.business,
  });

  /// Parses a customer object. Never throws.
  factory CheckoutDataCustomer.fromJson(JsonMap json) => CheckoutDataCustomer(
    id: json.stringOrNull('id'),
    email: json.stringOrNull('email'),
    address: _objectOrNull(json, 'address', CheckoutDataAddress.fromJson),
    business: _objectOrNull(json, 'business', CheckoutDataBusiness.fromJson),
  );

  /// Paddle customer ID (`ctm_...`).
  final String? id;

  /// Customer email address.
  final String? email;

  /// Customer address.
  final CheckoutDataAddress? address;

  /// Business the customer buys for.
  final CheckoutDataBusiness? business;
}

/// Discount applied to a checkout.
class CheckoutDataDiscount {
  /// Creates a discount.
  const CheckoutDataDiscount({this.id, this.code});

  /// Parses a discount object. Never throws.
  factory CheckoutDataDiscount.fromJson(JsonMap json) => CheckoutDataDiscount(
    id: json.stringOrNull('id'),
    code: json.stringOrNull('code'),
  );

  /// Paddle discount ID (`dsc_...`).
  final String? id;

  /// Discount code.
  final String? code;
}

/// Settings Paddle.js is currently using for the checkout.
///
/// Values are kept as the raw strings Paddle sends.
class CheckoutDataSettings {
  /// Creates the settings snapshot.
  const CheckoutDataSettings({this.displayMode, this.theme, this.variant});

  /// Parses a settings object. Never throws.
  factory CheckoutDataSettings.fromJson(JsonMap json) => CheckoutDataSettings(
    displayMode: json.stringOrNull('display_mode'),
    theme: json.stringOrNull('theme'),
    variant: json.stringOrNull('variant'),
  );

  /// `inline` or `overlay`.
  final String? displayMode;

  /// `light` or `dark`.
  final String? theme;

  /// `one-page`, `multi-page` or `express`.
  final String? variant;
}

/// Upsell state of a checkout.
class CheckoutDataUpsell {
  /// Creates the upsell snapshot.
  const CheckoutDataUpsell({
    this.transactionId,
    this.showSkipButton,
    this.sameSession,
  });

  /// Parses an upsell object. Never throws.
  factory CheckoutDataUpsell.fromJson(JsonMap json) => CheckoutDataUpsell(
    transactionId: json.stringOrNull('transaction_id'),
    showSkipButton: json.boolOrNull('show_skip_button'),
    sameSession: json.boolOrNull('same_session'),
  );

  /// Transaction ID (`txn_...`) the upsell belongs to.
  final String? transactionId;

  /// Whether the skip button is shown.
  final bool? showSkipButton;

  /// Whether the upsell opens in the same checkout session.
  final bool? sameSession;
}

/// Card used for a payment.
class CheckoutCard {
  /// Creates a card.
  const CheckoutCard({
    this.type,
    this.last4,
    this.expiryMonth,
    this.expiryYear,
  });

  /// Parses a card object. Never throws.
  factory CheckoutCard.fromJson(JsonMap json) => CheckoutCard(
    type: json.stringOrNull('type'),
    last4: json.stringOrNull('last4'),
    expiryMonth: json.intOrNull('expiry_month'),
    expiryYear: json.intOrNull('expiry_year'),
  );

  /// Card brand, such as `visa`.
  final String? type;

  /// Last four digits.
  final String? last4;

  /// Expiry month (1-12).
  final int? expiryMonth;

  /// Expiry year.
  final int? expiryYear;
}

/// Payment information reported with a checkout event.
class CheckoutPayment {
  /// Creates the payment information.
  const CheckoutPayment({this.methodType, this.card});

  /// Parses a payment object. Never throws.
  factory CheckoutPayment.fromJson(JsonMap json) {
    final details = json.mapOrNull('method_details');
    return CheckoutPayment(
      methodType: details?.stringOrNull('type'),
      card: details == null
          ? null
          : _objectOrNull(details, 'card', CheckoutCard.fromJson),
    );
  }

  /// Payment method type, such as `card` or `paypal`.
  final String? methodType;

  /// Card details, when paid by card.
  final CheckoutCard? card;
}

/// The checkout data carried by a Paddle.js event (`event.data`).
///
/// Parsing is lenient: missing or malformed fields become `null` or empty.
class CheckoutData {
  /// Creates checkout data.
  const CheckoutData({
    this.id,
    this.transactionId,
    this.status,
    this.customData,
    this.currencyCode,
    this.customer,
    this.items = const [],
    this.totals,
    this.recurringTotals,
    this.settings,
    this.discount,
    this.upsell,
    this.payment,
  });

  /// Parses the `data` object of a Paddle.js event. Never throws.
  factory CheckoutData.fromJson(JsonMap json) => CheckoutData(
    id: json.stringOrNull('id'),
    transactionId: json.stringOrNull('transaction_id'),
    status: parsePaddleEnumOrNull(
      TransactionStatus.values,
      json['status'],
      fallback: TransactionStatus.unknown,
    ),
    customData: json.mapOrNull('custom_data'),
    currencyCode: json.stringOrNull('currency_code'),
    customer: _objectOrNull(json, 'customer', CheckoutDataCustomer.fromJson),
    items: json.listOf('items', CheckoutDataItem.fromJson),
    totals: _objectOrNull(json, 'totals', CheckoutTotals.fromJson),
    recurringTotals: _objectOrNull(
      json,
      'recurring_totals',
      CheckoutTotals.fromJson,
    ),
    settings: _objectOrNull(json, 'settings', CheckoutDataSettings.fromJson),
    discount: _objectOrNull(json, 'discount', CheckoutDataDiscount.fromJson),
    upsell: _objectOrNull(json, 'upsell', CheckoutDataUpsell.fromJson),
    payment: _objectOrNull(json, 'payment', CheckoutPayment.fromJson),
  );

  /// Checkout ID (`che_...`).
  final String? id;

  /// Transaction ID (`txn_...`).
  final String? transactionId;

  /// Transaction status. [TransactionStatus.unknown] for unrecognised values.
  final TransactionStatus? status;

  /// Custom data attached to the transaction.
  final JsonMap? customData;

  /// ISO currency code, such as `USD`.
  final String? currencyCode;

  /// Customer, when known.
  final CheckoutDataCustomer? customer;

  /// Line items. Empty when missing.
  final List<CheckoutDataItem> items;

  /// Totals of the checkout.
  final CheckoutTotals? totals;

  /// Recurring totals of the checkout, for subscriptions.
  final CheckoutTotals? recurringTotals;

  /// Settings Paddle.js is using.
  final CheckoutDataSettings? settings;

  /// Discount applied, if any.
  final CheckoutDataDiscount? discount;

  /// Upsell state, if any.
  final CheckoutDataUpsell? upsell;

  /// Payment information, once a payment was started.
  final CheckoutPayment? payment;
}
