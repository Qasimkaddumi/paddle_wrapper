import '../../../../core/json.dart';

/// A single field problem reported by Paddle.
class CheckoutFieldError {
  /// Creates a field error.
  const CheckoutFieldError({required this.field, required this.message});

  /// Parses a field error object. Never throws.
  factory CheckoutFieldError.fromJson(JsonMap json) => CheckoutFieldError(
    field: json.stringOrNull('field') ?? '',
    message: json.stringOrNull('message') ?? '',
  );

  /// The field that is invalid, such as `customer.email`.
  final String field;

  /// Human readable description of the problem.
  final String message;

  @override
  String toString() => 'CheckoutFieldError($field: $message)';
}

/// An error or warning reported by a checkout event.
///
/// Mirrors the Paddle API error shape. Every field is optional because the
/// event may carry no data at all.
class CheckoutError {
  /// Creates an error.
  const CheckoutError({
    this.type,
    this.code,
    this.detail,
    this.documentationUrl,
    this.fieldErrors = const [],
  });

  /// Parses an error payload. Accepts both the flat shape and one wrapped in
  /// an `error` object. Never throws.
  factory CheckoutError.fromJson(JsonMap json) {
    final source = json.mapOrNull('error') ?? json;
    return CheckoutError(
      type: source.stringOrNull('type'),
      code: source.stringOrNull('code'),
      detail: source.stringOrNull('detail'),
      documentationUrl: source.stringOrNull('documentation_url'),
      fieldErrors: source.listOf('errors', CheckoutFieldError.fromJson),
    );
  }

  /// Error type, such as `request_error`.
  final String? type;

  /// Error code, such as `invalid_field`.
  final String? code;

  /// Human readable detail.
  final String? detail;

  /// Link to the Paddle documentation for this error.
  final String? documentationUrl;

  /// Per-field problems, when Paddle reports them.
  final List<CheckoutFieldError> fieldErrors;

  @override
  String toString() =>
      'CheckoutError(type: $type, code: $code, detail: $detail)';
}
