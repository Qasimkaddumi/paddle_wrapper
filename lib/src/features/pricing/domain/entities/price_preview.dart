import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';
import 'pricing_shared.dart';

/// One price to localize in a [PricePreviewRequest].
class PricePreviewItem {
  /// Creates an item for [priceId] (`pri_...`) and [quantity].
  const PricePreviewItem(this.priceId, {this.quantity = 1});

  /// Paddle price ID (`pri_...`).
  final String priceId;

  /// Number of units. Must be at least 1.
  final int quantity;

  /// The Paddle.js wire shape.
  JsonMap toJson() => {'priceId': priceId, 'quantity': quantity};
}

/// Request body for `Paddle.PricePreview`.
///
/// When no [address] or [customerIpAddress] is given, Paddle.js localizes
/// prices using the visitor's IP address.
class PricePreviewRequest {
  /// Creates a request. [items] must not be empty.
  const PricePreviewRequest({
    required this.items,
    this.customerId,
    this.addressId,
    this.businessId,
    this.currencyCode,
    this.discountId,
    this.address,
    this.customerIpAddress,
  });

  /// Prices to preview. Must not be empty.
  final List<PricePreviewItem> items;

  /// Paddle customer ID (`ctm_...`).
  final String? customerId;

  /// Paddle address ID (`add_...`).
  final String? addressId;

  /// Paddle business ID (`biz_...`).
  final String? businessId;

  /// Upper case ISO 4217 currency code, e.g. `USD`.
  final String? currencyCode;

  /// Paddle discount ID (`dsc_...`).
  final String? discountId;

  /// Location used for localization, when not using [addressId].
  final PreviewAddress? address;

  /// IP address used for localization.
  final String? customerIpAddress;

  /// Throws a [PaddleValidationException] when the request is invalid.
  void validate() {
    if (items.isEmpty) {
      throw PaddleValidationException('items: At least one item is required.');
    }
    for (final item in items) {
      if (item.priceId.isEmpty) {
        throw PaddleValidationException('items.priceId: Must not be empty.');
      }
      if (item.quantity < 1) {
        throw PaddleValidationException('items.quantity: Must be at least 1.');
      }
    }
    validatePreviewCommon(currencyCode: currencyCode, address: address);
  }

  /// The Paddle.js wire shape, with null fields omitted.
  JsonMap toJson() => compactJson({
    'items': [for (final item in items) item.toJson()],
    'customerId': customerId,
    'addressId': addressId,
    'businessId': businessId,
    'currencyCode': currencyCode,
    'discountId': discountId,
    'address': address?.toJson(),
    'customerIpAddress': customerIpAddress,
  });
}

/// Localized prices returned by `Paddle.PricePreview`.
class PricePreviewResult {
  /// Creates a result.
  const PricePreviewResult({
    this.currencyCode,
    this.customerId,
    this.addressId,
    this.businessId,
    this.discountId,
    this.address,
    this.customerIpAddress,
    this.lineItems = const [],
    this.availablePaymentMethods = const [],
    this.raw = const <String, dynamic>{},
  });

  /// Parses a response. Accepts both `{data: {...}}` and unwrapped payloads.
  factory PricePreviewResult.fromJson(JsonMap json) {
    final data = unwrapPreviewData(json);
    final details = data.mapOrNull('details') ?? const <String, dynamic>{};
    final addressJson = data.mapOrNull('address');
    return PricePreviewResult(
      currencyCode: data.stringOrNull('currencyCode'),
      customerId: data.stringOrNull('customerId'),
      addressId: data.stringOrNull('addressId'),
      businessId: data.stringOrNull('businessId'),
      discountId: data.stringOrNull('discountId'),
      address: addressJson == null
          ? null
          : PreviewAddress.fromJson(addressJson),
      customerIpAddress: data.stringOrNull('customerIpAddress'),
      lineItems: details.listOf('lineItems', PricePreviewLineItem.fromJson),
      availablePaymentMethods: stringListOf(data, 'availablePaymentMethods'),
      raw: data,
    );
  }

  /// ISO 4217 currency code of the prices.
  final String? currencyCode;

  /// Paddle customer ID (`ctm_...`), when known.
  final String? customerId;

  /// Paddle address ID (`add_...`), when known.
  final String? addressId;

  /// Paddle business ID (`biz_...`), when known.
  final String? businessId;

  /// Paddle discount ID (`dsc_...`), when known.
  final String? discountId;

  /// Location Paddle used for localization.
  final PreviewAddress? address;

  /// IP address Paddle used for localization.
  final String? customerIpAddress;

  /// One entry per requested price.
  final List<PricePreviewLineItem> lineItems;

  /// Payment method types available for these prices, e.g. `card`.
  final List<String> availablePaymentMethods;

  /// The response payload as returned by Paddle.js.
  final JsonMap raw;

  /// Returns the line item for [priceId], or `null` when not present.
  PricePreviewLineItem? lineItemFor(String priceId) {
    for (final item in lineItems) {
      if (item.priceId == priceId) return item;
    }
    return null;
  }
}

/// A localized price for one requested item.
class PricePreviewLineItem {
  /// Creates a line item.
  const PricePreviewLineItem({
    this.price,
    this.priceId,
    this.quantity,
    this.taxRate,
    this.unitTotals,
    this.formattedUnitTotals,
    this.totals,
    this.formattedTotals,
    this.product,
    this.raw = const <String, dynamic>{},
  });

  /// Parses a line item returned by Paddle.js.
  factory PricePreviewLineItem.fromJson(JsonMap json) {
    final priceJson = json.mapOrNull('price');
    final unitTotalsJson = json.mapOrNull('unitTotals');
    final formattedUnitTotalsJson = json.mapOrNull('formattedUnitTotals');
    final totalsJson = json.mapOrNull('totals');
    final formattedTotalsJson = json.mapOrNull('formattedTotals');
    final productJson = json.mapOrNull('product');
    final price = priceJson == null ? null : PreviewPrice.fromJson(priceJson);
    return PricePreviewLineItem(
      price: price,
      priceId: price?.id ?? json.stringOrNull('priceId'),
      quantity: json.intOrNull('quantity'),
      taxRate: json.stringOrNull('taxRate'),
      unitTotals: unitTotalsJson == null
          ? null
          : PreviewTotals.fromJson(unitTotalsJson),
      formattedUnitTotals: formattedUnitTotalsJson == null
          ? null
          : FormattedTotals.fromJson(formattedUnitTotalsJson),
      totals: totalsJson == null ? null : PreviewTotals.fromJson(totalsJson),
      formattedTotals: formattedTotalsJson == null
          ? null
          : FormattedTotals.fromJson(formattedTotalsJson),
      product: productJson == null
          ? null
          : PreviewProduct.fromJson(productJson),
      raw: json,
    );
  }

  /// The price this line refers to.
  final PreviewPrice? price;

  /// Paddle price ID (`pri_...`), taken from [price] when present.
  final String? priceId;

  /// Number of units.
  final int? quantity;

  /// Tax rate as a decimal string, e.g. `0.08875`.
  final String? taxRate;

  /// Per-unit totals in the lowest denomination.
  final PreviewTotals? unitTotals;

  /// Per-unit totals formatted for display.
  final FormattedTotals? formattedUnitTotals;

  /// Totals for the whole line, in the lowest denomination.
  final PreviewTotals? totals;

  /// Totals for the whole line, formatted for display.
  final FormattedTotals? formattedTotals;

  /// The product this price belongs to.
  final PreviewProduct? product;

  /// The line item object as returned by Paddle.js.
  final JsonMap raw;
}
