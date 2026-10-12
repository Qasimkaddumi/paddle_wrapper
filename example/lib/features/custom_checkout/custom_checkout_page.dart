import 'package:flutter/material.dart';
import 'package:paddle_wrapper/paddle_wrapper.dart';

import '../../config/app_config.dart';
import '../confirmation/confirmation_page.dart';
import '../confirmation/order_backend.dart';
import 'order_summary.dart';

/// Inline checkout demo: your own order summary, Paddle's payment form.
///
/// Paddle requires that an inline checkout shows the items and totals
/// somewhere on your page. Here they are drawn by [OrderSummary] from the
/// live checkout data. The card form itself is always rendered by Paddle
/// (PCI compliance), inside the [PaddleCheckoutFrame] on the right.
class CustomCheckoutPage extends StatefulWidget {
  /// Creates the page. [backend] is used by the confirmation page.
  const CustomCheckoutPage({required this.backend, super.key});

  /// Your backend, used to confirm the order after payment.
  final OrderBackend backend;

  @override
  State<CustomCheckoutPage> createState() => _CustomCheckoutPageState();
}

class _CustomCheckoutPageState extends State<CustomCheckoutPage> {
  static const int _maxQuantity = 10;

  /// Options of the inline checkout. Kept constant on purpose: quantity and
  /// discount changes are sent through the service, not by rebuilding the
  /// frame, so the frame never sends a second, duplicate update.
  static const CheckoutOptions _options = CheckoutOptions(
    items: [CheckoutItem(priceId: AppConfig.priceId)],
    settings: CheckoutSettings(
      variant: CheckoutVariant.onePage,
      showAddDiscounts: true,
    ),
  );

  final TextEditingController _discountController = TextEditingController();
  int _quantity = 1;
  String? _actionError;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  CheckoutItem get _item =>
      CheckoutItem(priceId: AppConfig.priceId, quantity: _quantity);

  void _changeQuantity(int delta) {
    final next = _quantity + delta;
    if (next < 1 || next > _maxQuantity) return;
    _run(() {
      Paddle.instance.checkout.updateItems([
        CheckoutItem(priceId: AppConfig.priceId, quantity: next),
      ]);
      setState(() => _quantity = next);
    });
  }

  void _applyDiscount() {
    final code = _discountController.text.trim();
    if (code.isEmpty) return;
    _run(() {
      Paddle.instance.checkout.update(
        CheckoutUpdate(items: [_item], discount: CheckoutDiscount.code(code)),
      );
    });
  }

  /// Runs a Paddle call, showing validation errors thrown by the package.
  /// Errors reported by Paddle.js arrive later as `checkout.error` events
  /// and appear in the summary through `CheckoutState.error`.
  void _run(VoidCallback action) {
    setState(() => _actionError = null);
    try {
      action();
    } on PaddleException catch (error) {
      setState(() => _actionError = error.message);
    }
  }

  void _onEvent(CheckoutEvent event) {
    if (!mounted || !event.isCompleted) return;
    final transactionId = event.data?.transactionId;
    if (transactionId == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmationPage(
          backend: widget.backend,
          transactionId: transactionId,
        ),
      ),
    );
  }

  void _onFrameError(Object error) {
    if (!mounted) return;
    setState(() => _actionError = '$error');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inline checkout')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              final summary = PaddleCheckoutBuilder(
                onEvent: _onEvent,
                builder: (context, state) => OrderSummary(
                  state: state,
                  quantity: _quantity,
                  maxQuantity: _maxQuantity,
                  discountController: _discountController,
                  actionError: _actionError,
                  onQuantityChanged: _changeQuantity,
                  onApplyDiscount: _applyDiscount,
                ),
              );

              final checkout = Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 650,
                  child: PaddleCheckoutFrame(
                    options: _options,
                    onError: _onFrameError,
                  ),
                ),
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: summary),
                    const SizedBox(width: 24),
                    Expanded(flex: 6, child: checkout),
                  ],
                );
              }
              return Column(
                children: [summary, const SizedBox(height: 24), checkout],
              );
            },
          ),
        ),
      ),
    ),
  );
}
