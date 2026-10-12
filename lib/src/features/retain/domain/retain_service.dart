import 'entities/cancellation_flow_result.dart';
import 'entities/retain_demo_feature.dart';

/// Paddle Retain: cancellation flows and demos. Retain only loads for live
/// accounts initialised with a `retainCustomerId`.
abstract interface class RetainService {
  /// Starts a Retain cancellation flow (`Paddle.Retain.initCancellationFlow`).
  ///
  /// [subscriptionId] is required when the customer has several
  /// subscriptions.
  Future<CancellationFlowResult> initCancellationFlow({String? subscriptionId});

  /// Shows a Retain demo (`Paddle.Retain.demo`).
  void demo(RetainDemoFeature feature);
}
