import '../../../../core/json.dart';
import '../../../../core/paddle_exception.dart';

/// Postal address of a customer, either a saved Paddle address or details.
class CheckoutAddress {
  const CheckoutAddress._({
    this.id,
    this.countryCode,
    this.postalCode,
    this.region,
    this.city,
    this.firstLine,
  });

  /// Uses a saved Paddle address (`add_...`).
  factory CheckoutAddress.id(String id) => CheckoutAddress._(id: id);

  /// Uses address details. [countryCode] is an ISO 3166-1 alpha-2 code.
  factory CheckoutAddress.details({
    required String countryCode,
    String? postalCode,
    String? region,
    String? city,
    String? firstLine,
  }) => CheckoutAddress._(
    countryCode: countryCode,
    postalCode: postalCode,
    region: region,
    city: city,
    firstLine: firstLine,
  );

  /// Saved Paddle address ID (`add_...`), when set.
  final String? id;

  /// ISO 3166-1 alpha-2 country code, when using details.
  final String? countryCode;

  /// Postal or ZIP code.
  final String? postalCode;

  /// State, province or region.
  final String? region;

  /// City.
  final String? city;

  /// First line of the street address.
  final String? firstLine;

  /// Throws [PaddleValidationException] when the address is incomplete.
  void validate() {
    if (id == null && (countryCode ?? '').trim().isEmpty) {
      throw const PaddleValidationException(
        'CheckoutAddress.details requires a countryCode.',
      );
    }
  }

  /// The Paddle.js address shape.
  JsonMap toJson() {
    final addressId = id;
    if (addressId != null) return {'id': addressId};
    return compactJson({
      'countryCode': countryCode,
      'postalCode': postalCode,
      'region': region,
      'city': city,
      'firstLine': firstLine,
    });
  }
}

/// Business the customer buys for.
class CheckoutBusiness {
  const CheckoutBusiness._({this.id, this.name, this.taxIdentifier});

  /// Uses a saved Paddle business (`biz_...`).
  factory CheckoutBusiness.id(String id) => CheckoutBusiness._(id: id);

  /// Uses business details. Paddle requires an address when a business is
  /// given.
  factory CheckoutBusiness.details({
    required String name,
    String? taxIdentifier,
  }) => CheckoutBusiness._(name: name, taxIdentifier: taxIdentifier);

  /// Saved Paddle business ID (`biz_...`), when set.
  final String? id;

  /// Business name, when using details.
  final String? name;

  /// Tax identifier (for example a VAT number).
  final String? taxIdentifier;

  /// Throws [PaddleValidationException] when the business is incomplete.
  void validate() {
    if (id == null && (name ?? '').trim().isEmpty) {
      throw const PaddleValidationException(
        'CheckoutBusiness.details requires a name.',
      );
    }
  }

  /// The Paddle.js business shape.
  JsonMap toJson() {
    final businessId = id;
    if (businessId != null) return {'id': businessId};
    return compactJson({'name': name, 'taxIdentifier': taxIdentifier});
  }
}

/// The customer taking part in a checkout.
class CheckoutCustomer {
  const CheckoutCustomer._({this.id, this.email, this.address, this.business});

  /// An existing Paddle customer (`ctm_...`).
  factory CheckoutCustomer.id(
    String id, {
    CheckoutAddress? address,
    CheckoutBusiness? business,
  }) => CheckoutCustomer._(id: id, address: address, business: business);

  /// A customer identified by email address.
  factory CheckoutCustomer.email(
    String email, {
    CheckoutAddress? address,
    CheckoutBusiness? business,
  }) => CheckoutCustomer._(email: email, address: address, business: business);

  /// Paddle customer ID (`ctm_...`), when identified by ID.
  final String? id;

  /// Customer email address, when identified by email.
  final String? email;

  /// Customer address.
  final CheckoutAddress? address;

  /// Business the customer buys for.
  final CheckoutBusiness? business;

  /// Throws [PaddleValidationException] when the customer is invalid.
  /// A business requires an address.
  void validate() {
    if (business != null && address == null) {
      throw const PaddleValidationException(
        'A customer business requires an address.',
      );
    }
    address?.validate();
    business?.validate();
  }

  /// The Paddle.js customer shape.
  JsonMap toJson() => compactJson({
    'id': id,
    'email': email,
    'address': address?.toJson(),
    'business': business?.toJson(),
  });
}
