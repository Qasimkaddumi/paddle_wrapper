import 'package:paddle_wrapper/src/core/json.dart';
import 'package:paddle_wrapper/src/core/paddle_environment.dart';
import 'package:paddle_wrapper/src/core/platform/paddle_platform.dart';

/// In-memory [PaddlePlatform] that records calls, for unit tests.
class FakePaddlePlatform implements PaddlePlatform {
  /// Every call as `(methodName, argument)`, in order.
  final List<(String, Object?)> calls = [];

  /// Result returned by the promise based methods, keyed by method name.
  final Map<String, JsonMap> results = {};

  /// Error thrown by the promise based methods, keyed by method name.
  final Map<String, Object> errors = {};

  PaddleEventHandler? _onEvent;

  @override
  bool isSupported = true;

  @override
  bool isLoaded = false;

  @override
  String? libraryVersion = '2.0.0-test';

  /// Simulates Paddle.js emitting [event].
  void emit(JsonMap event) => _onEvent?.call(event);

  /// Arguments of every call to [method].
  List<Object?> argsOf(String method) => [
    for (final call in calls)
      if (call.$1 == method) call.$2,
  ];

  Future<JsonMap> _promise(String method, JsonMap request) async {
    calls.add((method, request));
    final error = errors[method];
    if (error != null) throw error;
    return results[method] ?? <String, dynamic>{};
  }

  @override
  Future<void> load(Uri scriptUrl, {required Duration timeout}) async {
    calls.add(('load', scriptUrl));
    isLoaded = true;
  }

  @override
  void setEnvironment(PaddleEnvironment environment) =>
      calls.add(('setEnvironment', environment));

  @override
  void initialize(JsonMap options, PaddleEventHandler onEvent) {
    calls.add(('initialize', options));
    _onEvent = onEvent;
  }

  @override
  void update(JsonMap options) => calls.add(('update', options));

  @override
  void openCheckout(JsonMap options) => calls.add(('openCheckout', options));

  @override
  void updateCheckout(JsonMap options) =>
      calls.add(('updateCheckout', options));

  @override
  void updateCheckoutItems(List<JsonMap> items) =>
      calls.add(('updateCheckoutItems', items));

  @override
  void closeCheckout() => calls.add(('closeCheckout', null));

  @override
  Future<JsonMap> pricePreview(JsonMap request) =>
      _promise('pricePreview', request);

  @override
  Future<JsonMap> transactionPreview(JsonMap request) =>
      _promise('transactionPreview', request);

  @override
  Future<JsonMap> initCancellationFlow(JsonMap request) =>
      _promise('initCancellationFlow', request);

  @override
  void retainDemo(JsonMap options) => calls.add(('retainDemo', options));

  @override
  void prepareFrameTarget(Object element, {required String className}) =>
      calls.add(('prepareFrameTarget', className));

  @override
  Future<void> whenFrameTargetReady(
    String className, {
    required Duration timeout,
  }) async => calls.add(('whenFrameTargetReady', className));
}
