import '../../../core/json.dart';
import '../../../core/paddle_exception.dart';
import '../../../core/platform/paddle_platform.dart';
import '../domain/entities/cancellation_flow_result.dart';
import '../domain/entities/retain_demo_feature.dart';
import '../domain/retain_service.dart';

/// [RetainService] backed by `Paddle.Retain`.
class PaddleRetainService implements RetainService {
  /// Creates the service on top of [_platform].
  const PaddleRetainService(this._platform);

  final PaddlePlatform _platform;

  @override
  Future<CancellationFlowResult> initCancellationFlow({
    String? subscriptionId,
  }) async {
    if (subscriptionId != null && !subscriptionId.startsWith('sub_')) {
      throw const PaddleValidationException(
        'subscriptionId must be a Paddle subscription ID (sub_...).',
      );
    }
    final request = compactJson({'subscriptionId': subscriptionId});
    final json = await _platform.initCancellationFlow(request);
    return CancellationFlowResult.fromJson(json);
  }

  @override
  void demo(RetainDemoFeature feature) =>
      _platform.retainDemo({'feature': feature.value});
}
