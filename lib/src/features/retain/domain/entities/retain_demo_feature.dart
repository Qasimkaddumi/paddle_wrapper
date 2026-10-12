import '../../../../core/json.dart';

/// Retain demos that `Paddle.Retain.demo` can show.
enum RetainDemoFeature with PaddleEnum {
  /// Payment recovery demo.
  paymentRecovery('paymentRecovery'),

  /// Cancellation flow demo.
  cancellationFlow('cancellationFlow'),

  /// Terms acceptance demo.
  termsAcceptance('termsAcceptance');

  const RetainDemoFeature(this.value);

  @override
  final String value;
}
