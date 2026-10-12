import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../../json.dart';
import '../../paddle_environment.dart';
import '../../paddle_exception.dart';
import '../js_value_converter.dart';
import '../paddle_platform.dart';
import 'paddle_js_bindings.dart';

/// Creates the platform implementation used on Flutter web.
PaddlePlatform createPaddlePlatform() => WebPaddlePlatform();

/// [PaddlePlatform] backed by the real Paddle.js v2 runtime on the page.
class WebPaddlePlatform implements PaddlePlatform {
  /// Creates the web platform. Paddle.js is only touched once [load] runs.
  WebPaddlePlatform();

  /// In-flight script load, shared by concurrent callers of [load].
  Future<void>? _pendingLoad;

  @override
  bool get isSupported => true;

  @override
  bool get isLoaded => paddleJs != null;

  @override
  String? get libraryVersion {
    try {
      return paddleJs?.status.libraryVersion;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> load(Uri scriptUrl, {required Duration timeout}) async {
    if (isLoaded) return;
    final inFlight = _pendingLoad;
    if (inFlight != null) return inFlight;

    final pending = _injectScript(scriptUrl);
    _pendingLoad = pending;
    try {
      await pending.timeout(
        timeout,
        onTimeout: () => throw PaddleScriptLoadException(
          'Timed out after ${timeout.inMilliseconds}ms loading Paddle.js '
          'from $scriptUrl.',
        ),
      );
    } catch (_) {
      // Clear the cache so a later call can retry the load.
      _pendingLoad = null;
      rethrow;
    }
  }

  @override
  void setEnvironment(PaddleEnvironment environment) {
    // Paddle.js defaults to production, so only sandbox needs a call.
    if (!environment.isSandbox) return;
    _guard(() => _requirePaddle().environment.setEnvironment('sandbox'));
  }

  @override
  void initialize(JsonMap options, PaddleEventHandler onEvent) {
    _guard(() {
      final paddle = _requirePaddle();
      final jsOptions = _toJs(options) as JSObject;
      void eventCallback(JSAny? event) {
        try {
          onEvent(toJsonMap(event?.dartify()));
        } catch (error, stackTrace) {
          // A Dart failure must never break Paddle.js itself.
          Zone.current.handleUncaughtError(error, stackTrace);
        }
      }

      jsOptions.setProperty('eventCallback'.toJS, eventCallback.toJS);
      paddle.initialize(jsOptions);
    });
  }

  @override
  void update(JsonMap options) =>
      _guard(() => _requirePaddle().update(_toJs(options)));

  @override
  void openCheckout(JsonMap options) =>
      _guard(() => _requirePaddle().checkout.open(_toJs(options)));

  @override
  void updateCheckout(JsonMap options) =>
      _guard(() => _requirePaddle().checkout.updateCheckout(_toJs(options)));

  @override
  void updateCheckoutItems(List<JsonMap> items) =>
      _guard(() => _requirePaddle().checkout.updateItems(_toJs(items)));

  @override
  void closeCheckout() => _guard(() => _requirePaddle().checkout.close());

  @override
  Future<JsonMap> pricePreview(JsonMap request) =>
      _promise(() => _requirePaddle().pricePreview(_toJs(request)));

  @override
  Future<JsonMap> transactionPreview(JsonMap request) =>
      _promise(() => _requirePaddle().transactionPreview(_toJs(request)));

  @override
  Future<JsonMap> initCancellationFlow(JsonMap request) => _promise(
    () => _requirePaddle().retain.initCancellationFlow(_toJs(request)),
  );

  @override
  void retainDemo(JsonMap options) =>
      _guard(() => _requirePaddle().retain.demo(_toJs(options)));

  @override
  void prepareFrameTarget(Object element, {required String className}) {
    final target = element as web.HTMLElement;
    target.className = className;
    target.style
      ..width = '100%'
      ..height = '100%'
      ..overflow = 'auto';
  }

  @override
  Future<void> whenFrameTargetReady(
    String className, {
    required Duration timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (!_isFrameTargetReady(className)) {
      if (stopwatch.elapsed >= timeout) {
        throw PaddleConfigurationException(
          'Inline checkout container ".$className" was not found in the page. '
          'Render PaddleCheckoutFrame first.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Returns the live `window.Paddle` or throws when it is not loaded.
  PaddleJs _requirePaddle() {
    final paddle = paddleJs;
    if (paddle == null) throw const PaddleNotInitializedException();
    return paddle;
  }

  /// Runs [body], converting unexpected JS errors into [PaddleJsException].
  /// Package exceptions pass through unchanged.
  T _guard<T>(T Function() body) {
    try {
      return body();
    } on PaddleException {
      rethrow;
    } catch (error) {
      throw PaddleJsException(error.toString(), raw: error);
    }
  }

  /// Awaits a Paddle promise and converts its result to a [JsonMap].
  Future<JsonMap> _promise(JSPromise<JSAny?> Function() call) async {
    final JSPromise<JSAny?> promise;
    try {
      promise = call();
    } on PaddleException {
      rethrow;
    } catch (error) {
      throw PaddleJsException(error.toString(), raw: error);
    }

    final JSAny? result;
    try {
      result = await promise.toDart;
    } catch (error) {
      throw _rejectionToException(error);
    }
    return toJsonMap(result?.dartify());
  }

  /// Builds a [PaddleJsException] from a rejected Paddle promise. Paddle
  /// errors look like `{error: {type, code, detail}}` or `{type, code, detail}`.
  PaddleJsException _rejectionToException(Object error) {
    final value = error.isA<JSAny>() ? (error as JSAny).dartify() : error;
    if (value is! Map) {
      return PaddleJsException(value.toString(), raw: error);
    }

    final json = toJsonMap(value);
    final nested = json['error'] is Map ? toJsonMap(json['error']) : json;
    final type = nested.stringOrNull('type');
    final code = nested.stringOrNull('code');
    final detail = nested.stringOrNull('detail');
    return PaddleJsException(
      detail ?? code ?? 'Paddle.js request failed',
      type: type,
      code: code,
      detail: detail,
      raw: value,
    );
  }

  /// Injects the Paddle.js `<script>` (or waits for an existing one) and
  /// completes once `window.Paddle` is defined.
  Future<void> _injectScript(Uri scriptUrl) {
    final src = scriptUrl.toString();
    final existing = _findScript(src);
    final completer = Completer<void>();

    void onLoad(web.Event event) {
      if (completer.isCompleted) return;
      if (isLoaded) {
        completer.complete();
      } else {
        completer.completeError(
          PaddleScriptLoadException('Failed to load Paddle.js from $src'),
        );
      }
    }

    void onError(web.Event event) {
      if (completer.isCompleted) return;
      completer.completeError(
        PaddleScriptLoadException('Failed to load Paddle.js from $src'),
      );
    }

    if (existing != null) {
      existing
        ..addEventListener('load', onLoad.toJS)
        ..addEventListener('error', onError.toJS);
      if (isLoaded) completer.complete();
    } else {
      final script =
          (web.document.createElement('script') as web.HTMLScriptElement)
            ..src = src
            ..async = true
            ..addEventListener('load', onLoad.toJS)
            ..addEventListener('error', onError.toJS);
      final parent = web.document.head ?? web.document.body;
      parent?.appendChild(script);
    }
    return completer.future;
  }

  /// Returns the `<script>` element already pointing at [src], if any.
  web.HTMLScriptElement? _findScript(String src) {
    final scripts = web.document.getElementsByTagName('script');
    for (var i = 0; i < scripts.length; i++) {
      // getElementsByTagName('script') only ever yields script elements.
      final script = scripts.item(i) as web.HTMLScriptElement?;
      if (script != null && script.src == src) return script;
    }
    return null;
  }

  /// Whether an element with [className] is attached to the document.
  bool _isFrameTargetReady(String className) {
    final matches = web.document.getElementsByClassName(className);
    if (matches.length == 0) return false;
    return matches.item(0)?.isConnected ?? false;
  }

  /// Converts a Dart value into a JS value for Paddle.js.
  JSAny _toJs(Object value) => value.jsify()!;
}
