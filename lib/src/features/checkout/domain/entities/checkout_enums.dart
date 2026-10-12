import '../../../../core/json.dart';

/// How a checkout is presented to the buyer.
enum CheckoutDisplayMode with PaddleEnum {
  /// Rendered inside a container element on the page (`frameTarget`).
  inline('inline'),

  /// Rendered by Paddle.js as an overlay on top of the page.
  overlay('overlay');

  const CheckoutDisplayMode(this.value);

  @override
  final String value;
}

/// Colour theme of the checkout.
enum CheckoutTheme with PaddleEnum {
  /// Light theme.
  light('light'),

  /// Dark theme.
  dark('dark');

  const CheckoutTheme(this.value);

  @override
  final String value;
}

/// Layout variant of the checkout.
enum CheckoutVariant with PaddleEnum {
  /// Single page with every step visible. Required for upsells.
  onePage('one-page'),

  /// Multiple steps, one at a time.
  multiPage('multi-page'),

  /// Express checkout. Requires `displayMode` inline.
  express('express');

  const CheckoutVariant(this.value);

  @override
  final String value;
}

/// Languages Paddle.js can render the checkout in.
enum CheckoutLocale with PaddleEnum {
  /// Arabic.
  ar('ar'),

  /// Chinese (simplified).
  zhHans('zh-Hans'),

  /// Chinese (traditional).
  zhTW('zh-TW'),

  /// Danish.
  da('da'),

  /// Dutch.
  nl('nl'),

  /// English.
  en('en'),

  /// French.
  fr('fr'),

  /// German.
  de('de'),

  /// Italian.
  it('it'),

  /// Japanese.
  ja('ja'),

  /// Korean.
  ko('ko'),

  /// Norwegian.
  norwegian('no'),

  /// Polish.
  pl('pl'),

  /// Portuguese.
  pt('pt'),

  /// Portuguese (Brazil).
  ptBR('pt-BR'),

  /// Turkish.
  tr('tr'),

  /// Russian.
  ru('ru'),

  /// Spanish.
  es('es'),

  /// Swedish.
  sv('sv');

  const CheckoutLocale(this.value);

  @override
  final String value;
}

/// Payment methods that can be allowed in a checkout.
enum PaymentMethod with PaddleEnum {
  /// Alipay.
  alipay('alipay'),

  /// Apple Pay.
  applePay('apple_pay'),

  /// Bancontact.
  bancontact('bancontact'),

  /// BLIK.
  blik('blik'),

  /// Cards.
  card('card'),

  /// Google Pay.
  googlePay('google_pay'),

  /// iDEAL.
  ideal('ideal'),

  /// KakaoPay.
  kakaoPay('kakao_pay'),

  /// MB WAY.
  mbWay('mb_way'),

  /// NaverPay.
  naverPay('naver_pay'),

  /// PAYCO.
  payco('payco'),

  /// PayPal.
  paypal('paypal'),

  /// Pix.
  pix('pix'),

  /// Samsung Pay.
  samsungPay('samsung_pay'),

  /// Payment methods the buyer saved earlier.
  savedPaymentMethods('saved_payment_methods'),

  /// South Korean local cards.
  southKoreaLocalCard('south_korea_local_card'),

  /// UPI.
  upi('upi'),

  /// A payment method this package does not know yet. Not allowed in
  /// [CheckoutSettings.allowedPaymentMethods].
  unknown('unknown');

  const PaymentMethod(this.value);

  @override
  final String value;
}

/// Status of a checkout transaction, as reported in checkout events.
enum TransactionStatus with PaddleEnum {
  /// Draft transaction.
  draft('draft'),

  /// Ready to be billed.
  ready('ready'),

  /// Billed, awaiting payment.
  billed('billed'),

  /// Paid.
  paid('paid'),

  /// Completed.
  completed('completed'),

  /// Canceled.
  canceled('canceled'),

  /// Payment is overdue.
  pastDue('past_due'),

  /// A status this package does not know yet.
  unknown('unknown');

  const TransactionStatus(this.value);

  @override
  final String value;
}
