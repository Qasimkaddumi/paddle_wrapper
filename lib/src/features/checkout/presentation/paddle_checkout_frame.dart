import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/platform/paddle_platform.dart';
import '../../../paddle.dart';
import '../domain/checkout_service.dart';
import '../domain/entities/checkout_enums.dart';
import '../domain/entities/checkout_options.dart';
import '../domain/entities/checkout_settings.dart';
import '../domain/entities/checkout_update.dart';

/// Renders an inline Paddle checkout.
///
/// The widget creates a container `<div>` with the class name
/// [frameTarget] and opens the checkout inside it once the frame is
/// attached. Give it a bounded height, for example
/// `SizedBox(height: 700, child: PaddleCheckoutFrame(...))`.
///
/// Changing [options] updates the items of the open checkout. Other
/// changes (customer, discount, custom data) are sent along with the items.
/// Re-opening with different settings is not supported; use a new widget
/// key for that.
class PaddleCheckoutFrame extends StatefulWidget {
  /// Creates an inline checkout frame for [options].
  const PaddleCheckoutFrame({
    required this.options,
    this.frameTarget = 'paddle-checkout-frame',
    this.frameInitialHeight,
    this.frameStyle,
    this.checkoutService,
    this.platform,
    this.closeOnDispose = true,
    this.onError,
    super.key,
  });

  /// The checkout to open. Its `settings` are merged with the frame values
  /// below, and the frame values win.
  final CheckoutOptions options;

  /// Class name of the container element Paddle.js renders into. Must be
  /// unique on the page.
  final String frameTarget;

  /// Initial height of the frame, in pixels. Falls back to
  /// `options.settings.frameInitialHeight`, then to Paddle's recommended 450.
  final int? frameInitialHeight;

  /// CSS applied to the frame. When `null`, the value from [options] or
  /// the Paddle.js default is used.
  final String? frameStyle;

  /// Service used to open and update the checkout. Defaults to
  /// `Paddle.instance.checkout`.
  final CheckoutService? checkoutService;

  /// Platform used to prepare the container element. Defaults to
  /// `PaddlePlatform()`.
  final PaddlePlatform? platform;

  /// Whether to close the checkout when the widget is disposed.
  final bool closeOnDispose;

  /// Called with errors from opening or updating the checkout. When `null`,
  /// errors are reported with [FlutterError.reportError].
  final ValueChanged<Object>? onError;

  @override
  State<PaddleCheckoutFrame> createState() => _PaddleCheckoutFrameState();
}

class _PaddleCheckoutFrameState extends State<PaddleCheckoutFrame> {
  late final PaddlePlatform _platform;
  bool _opened = false;

  CheckoutService get _service =>
      widget.checkoutService ?? Paddle.instance.checkout;

  @override
  void initState() {
    super.initState();
    _platform = widget.platform ?? PaddlePlatform();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didUpdateWidget(PaddleCheckoutFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_opened || identical(oldWidget.options, widget.options)) return;
    final before = oldWidget.options.items;
    final after = widget.options.items;
    if (listEquals(before, after)) return;
    _guard(() {
      _service.update(
        CheckoutUpdate(
          items: after,
          customer: widget.options.customer,
          discount: widget.options.discount,
          customData: widget.options.customData,
        ),
      );
    });
  }

  @override
  void dispose() {
    if (widget.closeOnDispose && _opened) {
      _guard(() => _service.close());
    }
    super.dispose();
  }

  Future<void> _open() async {
    if (!mounted) return;
    final options = widget.options;
    final settings = (options.settings ?? const CheckoutSettings()).copyWith(
      displayMode: CheckoutDisplayMode.inline,
      frameTarget: widget.frameTarget,
      frameInitialHeight:
          widget.frameInitialHeight ??
          options.settings?.frameInitialHeight ??
          450,
      frameStyle:
          widget.frameStyle ??
          options.settings?.frameStyle ??
          CheckoutSettings.defaultFrameStyle,
    );
    try {
      await _service.open(options.copyWith(settings: settings));
      if (mounted) {
        _opened = true;
      } else if (widget.closeOnDispose) {
        // Disposed while waiting for the frame: don't leave it open.
        _service.close();
      }
    } on Object catch (error, stack) {
      _report(error, stack);
    }
  }

  void _guard(void Function() action) {
    try {
      action();
    } on Object catch (error, stack) {
      _report(error, stack);
    }
  }

  void _report(Object error, StackTrace stack) {
    final onError = widget.onError;
    if (onError != null) {
      onError(error);
    } else {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'paddle_wrapper',
          context: ErrorDescription('while handling a Paddle checkout frame'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'div',
    onElementCreated: (element) =>
        _platform.prepareFrameTarget(element, className: widget.frameTarget),
  );
}
