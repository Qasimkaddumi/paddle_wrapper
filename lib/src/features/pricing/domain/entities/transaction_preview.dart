import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';
import 'pricing_shared.dart';

/// One price to include in a [TransactionPreviewRequest].
class TransactionPreviewItem {
  /// Creates an item for [priceId] (`pri_...`).
  const TransactionPreviewItem(
    this.priceId, {
    this.quantity = 1,
    this.includeInTotals,
  });

  /// Paddle price ID (`pri_...`).
  final String priceId;

  /// Number of units. Must be at least 1.
  final int quantity;

  /// Whether the item counts towards the transaction totals. Paddle default
  /// applies when `null`.
  final bool? includeInTotals;

  /// The Paddle.js wire shape, with null fields omitted.
  JsonMap toJson() => compactJson({
    'priceId': priceId,
    'quantity': quantity,
    'includeInTotals': includeInTotals,
  });
}

/// Request body for `Paddle.TransactionPreview`.
class TransactionPreviewRequest {
  /// Creates a request. [items] must not be empty.
  const TransactionPreviewRequest({
    required this.items,
    this.customerId,
    this.addressId,
    this.businessId,
    this.currencyCode,
    this.discountId,
    this.address,
    this.customerIpAddress,
    this.ignoreTrials,
  });

  /// Prices to include. Must not be empty.
  final List<TransactionPreviewItem> items;

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

  /// Location used for tax calculation.
  final PreviewAddress? address;

  /// IP address used for localization.
  final String? customerIpAddress;

  /// Whether to ignore trial periods when calculating totals.
  final bool? ignoreTrials;

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
    'ignoreTrials': ignoreTrials,
  });
}

/// Transaction preview returned by `Paddle.TransactionPreview`.
class TransactionPreviewResult {
  /// Creates a result.
  const TransactionPreviewResult({
    this.currencyCode,
    this.customerId,
    this.addressId,
    this.businessId,
    this.discountId,
    this.totals,
    this.lineItems = const [],
    this.availablePaymentMethods = const [],
    this.raw = const <String, dynamic>{},
  });

  /// Parses a response. Accepts both `{data: {...}}` and unwrapped payloads.
  factory TransactionPreviewResult.fromJson(JsonMap json) {
    final data = unwrapPreviewData(json);
    final details = data.mapOrNull('details') ?? const <String, dynamic>{};
    final totalsJson = details.mapOrNull('totals');
    return TransactionPreviewResult(
      currencyCode: data.stringOrNull('currencyCode'),
      customerId: data.stringOrNull('customerId'),
      addressId: data.stringOrNull('addressId'),
      businessId: data.stringOrNull('businessId'),
      discountId: data.stringOrNull('discountId'),
      totals: totalsJson == null ? null : PreviewTotals.fromJson(totalsJson),
      lineItems: details.listOf(
        'lineItems',
        TransactionPreviewLineItem.fromJson,
      ),
      availablePaymentMethods: stringListOf(data, 'availablePaymentMethods'),
      raw: data,
    );
  }

  /// ISO 4217 currency code of the amounts.
  final String? currencyCode;

  /// Paddle customer ID (`ctm_...`), when known.
  final String? customerId;

  /// Paddle address ID (`add_...`), when known.
  final String? addressId;

  /// Paddle business ID (`biz_...`), when known.
  final String? businessId;

  /// Paddle discount ID (`dsc_...`), when known.
  final String? discountId;

  /// Totals for the whole transaction.
  final PreviewTotals? totals;

  /// One entry per priced item.
  final List<TransactionPreviewLineItem> lineItems;

  /// Payment method types available for this transaction.
  final List<String> availablePaymentMethods;

  /// The response payload as returned by Paddle.js.
  final JsonMap raw;
}

/// A priced item within a [TransactionPreviewResult].
class TransactionPreviewLineItem {
  /// Creates a line item.
  const TransactionPreviewLineItem({
    this.priceId,
    this.quantity,
    this.taxRate,
    this.unitTotals,
    this.totals,
    this.formattedUnitTotals,
    this.formattedTotals,
    this.product,
    this.raw = const <String, dynamic>{},
  });

  /// Parses a line item returned by Paddle.js.
  factory TransactionPreviewLineItem.fromJson(JsonMap json) {
    final unitTotalsJson = json.mapOrNull('unitTotals');
    final totalsJson = json.mapOrNull('totals');
    final formattedUnitTotalsJson = json.mapOrNull('formattedUnitTotals');
    final formattedTotalsJson = json.mapOrNull('formattedTotals');
    final productJson = json.mapOrNull('product');
    return TransactionPreviewLineItem(
      priceId: json.stringOrNull('priceId'),
      quantity: json.intOrNull('quantity'),
      taxRate: json.stringOrNull('taxRate'),
      unitTotals: unitTotalsJson == null
          ? null
          : PreviewTotals.fromJson(unitTotalsJson),
      totals: totalsJson == null ? null : PreviewTotals.fromJson(totalsJson),
      formattedUnitTotals: formattedUnitTotalsJson == null
          ? null
          : FormattedTotals.fromJson(formattedUnitTotalsJson),
      formattedTotals: formattedTotalsJson == null
          ? null
          : FormattedTotals.fromJson(formattedTotalsJson),
      product: productJson == null
          ? null
          : PreviewProduct.fromJson(productJson),
      raw: json,
    );
  }

  /// Paddle price ID (`pri_...`).
  final String? priceId;

  /// Number of units.
  final int? quantity;

  /// Tax rate as a decimal string, e.g. `0.08875`.
  final String? taxRate;

  /// Per-unit totals in the lowest denomination.
  final PreviewTotals? unitTotals;

  /// Totals for the whole line, in the lowest denomination.
  final PreviewTotals? totals;

  /// Per-unit totals formatted for display.
  final FormattedTotals? formattedUnitTotals;

  /// Totals for the whole line, formatted for display.
  final FormattedTotals? formattedTotals;

  /// The product this price belongs to.
  final PreviewProduct? product;

  /// The line item object as returned by Paddle.js.
  final JsonMap raw;
}
