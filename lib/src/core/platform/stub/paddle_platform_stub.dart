import '../../json.dart';
import '../../paddle_environment.dart';
import '../../paddle_exception.dart';
import '../paddle_platform.dart';

/// Creates the platform implementation used on non-web targets.
PaddlePlatform createPaddlePlatform() => const StubPaddlePlatform();

/// [PaddlePlatform] for platforms without Paddle.js. Every call throws
/// [PaddleUnsupportedPlatformException].
class StubPaddlePlatform implements PaddlePlatform {
  /// Creates the stub platform.
  const StubPaddlePlatform();

  @override
  bool get isSupported => false;

  @override
  bool get isLoaded => false;

  @override
  String? get libraryVersion => null;

  @override
  Future<void> load(Uri scriptUrl, {required Duration timeout}) async {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void setEnvironment(PaddleEnvironment environment) {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void initialize(JsonMap options, PaddleEventHandler onEvent) {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void update(JsonMap options) {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void openCheckout(JsonMap options) {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void updateCheckout(JsonMap options) {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void updateCheckoutItems(List<JsonMap> items) {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void closeCheckout() {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  Future<JsonMap> pricePreview(JsonMap request) async {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  Future<JsonMap> transactionPreview(JsonMap request) async {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  Future<JsonMap> initCancellationFlow(JsonMap request) async {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void retainDemo(JsonMap options) {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  void prepareFrameTarget(Object element, {required String className}) {
    throw const PaddleUnsupportedPlatformException();
  }

  @override
  Future<void> whenFrameTargetReady(
    String className, {
    required Duration timeout,
  }) async {
    throw const PaddleUnsupportedPlatformException();
  }
}
