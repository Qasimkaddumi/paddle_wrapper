import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../paddle.dart';
import '../domain/entities/checkout_event.dart';
import '../domain/entities/checkout_state.dart';

/// Builds UI from the live state of the Paddle checkout.
///
/// Pair it with `PaddleCheckoutFrame` to design your own checkout page:
/// Paddle renders the payment form, you render everything else.
///
/// ```dart
/// PaddleCheckoutBuilder(
///   builder: (context, state) => OrderSummary(
///     items: state.data?.items ?? const [],
///     total: state.data?.totals?.total,
///   ),
/// )
/// ```
class PaddleCheckoutBuilder extends StatefulWidget {
  /// Creates the builder.
  const PaddleCheckoutBuilder({
    required this.builder,
    this.events,
    this.onEvent,
    super.key,
  });

  /// Called with the latest [CheckoutState] whenever it changes.
  final Widget Function(BuildContext context, CheckoutState state) builder;

  /// Event source. Defaults to `Paddle.instance.events`.
  final Stream<CheckoutEvent>? events;

  /// Optional side-effect hook for every event, e.g. navigation on
  /// completion.
  final ValueChanged<CheckoutEvent>? onEvent;

  @override
  State<PaddleCheckoutBuilder> createState() => _PaddleCheckoutBuilderState();
}

class _PaddleCheckoutBuilderState extends State<PaddleCheckoutBuilder> {
  CheckoutState _state = const CheckoutState();
  StreamSubscription<CheckoutEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(PaddleCheckoutBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      unawaited(_subscription?.cancel());
      _subscribe();
    }
  }

  void _subscribe() {
    final events = widget.events ?? Paddle.instance.events;
    _subscription = events.listen((event) {
      widget.onEvent?.call(event);
      if (mounted) setState(() => _state = _state.apply(event));
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}
