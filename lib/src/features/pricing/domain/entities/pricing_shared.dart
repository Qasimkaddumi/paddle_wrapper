import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';

final RegExp _currencyCodePattern = RegExp(r'^[A-Z]{3}$');

/// Unwraps the `data` envelope Paddle.js may add to preview results.
///
/// Returns [json] itself when it has no `data` object.
JsonMap unwrapPreviewData(JsonMap json) => json.mapOrNull('data') ?? json;

/// Reads a list of strings under [key], ignoring non-string entries.
List<String> stringListOf(JsonMap json, String key) {
  final value = json[key];
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String) item,
  ];
}

/// Validates the fields shared by price and transaction preview requests.
///
/// Throws a [PaddleValidationException] when [currencyCode] is not an upper case
/// ISO 4217 code (e.g. `USD`) or when [address] has an empty country code.
void validatePreviewCommon({String? currencyCode, PreviewAddress? address}) {
  if (currencyCode != null && !_currencyCodePattern.hasMatch(currencyCode)) {
    throw PaddleValidationException(
      'currencyCode: Must be an upper case ISO 4217 code such as "USD".',
    );
  }
  if (address != null && address.countryCode.isEmpty) {
    throw PaddleValidationException(
      'address.countryCode: Is required when an address is given.',
    );
  }
}

/// A location used to localize prices and tax.
class PreviewAddress {
  /// Creates an address. [countryCode] is an ISO 3166-1 alpha-2 code.
  const PreviewAddress({required this.countryCode, this.postalCode});

  /// Parses an address object returned by Paddle.js.
  factory PreviewAddress.fromJson(JsonMap json) => PreviewAddress(
    countryCode: json.stringOrNull('countryCode') ?? '',
    postalCode: json.stringOrNull('postalCode'),
  );

  /// ISO 3166-1 alpha-2 country code, e.g. `US`.
  final String countryCode;

  /// Postal or ZIP code, when known.
  final String? postalCode;

  /// The Paddle.js wire shape, with null fields omitted.
  JsonMap toJson() =>
      compactJson({'countryCode': countryCode, 'postalCode': postalCode});
}

/// Monetary totals in the lowest denomination of the currency (e.g. cents),
/// as strings, exactly as Paddle returns them.
class PreviewTotals {
  /// Creates totals.
  const PreviewTotals({
    this.subtotal,
    this.discount,
    this.tax,
    this.total,
    this.credit,
    this.balance,
    this.grandTotal,
    this.fee,
    this.earnings,
    this.currencyCode,
  });

  /// Parses a totals object returned by Paddle.js.
  factory PreviewTotals.fromJson(JsonMap json) => PreviewTotals(
    subtotal: json.stringOrNull('subtotal'),
    discount: json.stringOrNull('discount'),
    tax: json.stringOrNull('tax'),
    total: json.stringOrNull('total'),
    credit: json.stringOrNull('credit'),
    balance: json.stringOrNull('balance'),
    grandTotal: json.stringOrNull('grandTotal'),
    fee: json.stringOrNull('fee'),
    earnings: json.stringOrNull('earnings'),
    currencyCode: json.stringOrNull('currencyCode'),
  );

  /// Amount before discounts and tax.
  final String? subtotal;

  /// Discount amount.
  final String? discount;

  /// Tax amount.
  final String? tax;

  /// Amount due, including tax.
  final String? total;

  /// Credit applied to the transaction.
  final String? credit;

  /// Balance remaining after credit.
  final String? balance;

  /// Grand total, when Paddle reports one.
  final String? grandTotal;

  /// Paddle fee, when reported.
  final String? fee;

  /// Earnings after fees, when reported.
  final String? earnings;

  /// ISO 4217 currency code of the amounts, when reported.
  final String? currencyCode;
}

/// Display-ready totals such as `$10.00`, as formatted by Paddle.
class FormattedTotals {
  /// Creates formatted totals.
  const FormattedTotals({this.subtotal, this.discount, this.tax, this.total});

  /// Parses a formatted totals object returned by Paddle.js.
  factory FormattedTotals.fromJson(JsonMap json) => FormattedTotals(
    subtotal: json.stringOrNull('subtotal'),
    discount: json.stringOrNull('discount'),
    tax: json.stringOrNull('tax'),
    total: json.stringOrNull('total'),
  );

  /// Formatted subtotal.
  final String? subtotal;

  /// Formatted discount.
  final String? discount;

  /// Formatted tax.
  final String? tax;

  /// Formatted total.
  final String? total;
}

/// Billing or trial period, e.g. `month` x 1.
class PreviewBillingCycle {
  /// Creates a billing cycle.
  const PreviewBillingCycle({this.interval, this.frequency});

  /// Parses a billing cycle object returned by Paddle.js.
  factory PreviewBillingCycle.fromJson(JsonMap json) => PreviewBillingCycle(
    interval: json.stringOrNull('interval'),
    frequency: json.intOrNull('frequency'),
  );

  /// Unit of time: `day`, `week`, `month` or `year`.
  final String? interval;

  /// Number of [interval]s per cycle.
  final int? frequency;
}

/// The price a line item refers to.
class PreviewPrice {
  /// Creates a price.
  const PreviewPrice({
    this.id,
    this.productId,
    this.name,
    this.description,
    this.billingCycle,
    this.trialPeriod,
    this.unitPriceAmount,
    this.unitPriceCurrencyCode,
    this.raw = const <String, dynamic>{},
  });

  /// Parses a price object returned by Paddle.js.
  factory PreviewPrice.fromJson(JsonMap json) {
    final billingCycleJson = json.mapOrNull('billingCycle');
    final trialPeriodJson = json.mapOrNull('trialPeriod');
    final unitPrice = json.mapOrNull('unitPrice');
    return PreviewPrice(
      id: json.stringOrNull('id'),
      productId: json.stringOrNull('productId'),
      name: json.stringOrNull('name'),
      description: json.stringOrNull('description'),
      billingCycle: billingCycleJson == null
          ? null
          : PreviewBillingCycle.fromJson(billingCycleJson),
      trialPeriod: trialPeriodJson == null
          ? null
          : PreviewBillingCycle.fromJson(trialPeriodJson),
      unitPriceAmount: unitPrice?.stringOrNull('amount'),
      unitPriceCurrencyCode: unitPrice?.stringOrNull('currencyCode'),
      raw: json,
    );
  }

  /// Paddle price ID (`pri_...`).
  final String? id;

  /// Paddle product ID (`pro_...`).
  final String? productId;

  /// Name of the price.
  final String? name;

  /// Description of the price.
  final String? description;

  /// Billing cycle, or `null` for one-time prices.
  final PreviewBillingCycle? billingCycle;

  /// Trial period, or `null` when the price has no trial.
  final PreviewBillingCycle? trialPeriod;

  /// Unit price amount in the lowest denomination, as a string.
  final String? unitPriceAmount;

  /// ISO 4217 currency code of [unitPriceAmount].
  final String? unitPriceCurrencyCode;

  /// The full price object as returned by Paddle.js.
  final JsonMap raw;
}

/// The product a price belongs to.
class PreviewProduct {
  /// Creates a product.
  const PreviewProduct({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.raw = const <String, dynamic>{},
  });

  /// Parses a product object returned by Paddle.js.
  factory PreviewProduct.fromJson(JsonMap json) => PreviewProduct(
    id: json.stringOrNull('id'),
    name: json.stringOrNull('name'),
    description: json.stringOrNull('description'),
    imageUrl: json.stringOrNull('imageUrl'),
    raw: json,
  );

  /// Paddle product ID (`pro_...`).
  final String? id;

  /// Name of the product.
  final String? name;

  /// Description of the product.
  final String? description;

  /// Image URL of the product.
  final String? imageUrl;

  /// The full product object as returned by Paddle.js.
  final JsonMap raw;
}
