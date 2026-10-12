import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paddle_wrapper/paddle_wrapper.dart';

import '../../config/app_config.dart';
import '../../shared/section_card.dart';
import '../confirmation/confirmation_page.dart';
import '../confirmation/order_backend.dart';

/// Overlay checkout demo.
///
/// Prices are localized by Paddle (currency, tax, country) with
/// `Paddle.instance.pricing.previewPrices`. "Buy" opens Paddle's own overlay
/// checkout, so the payment UI is entirely rendered by Paddle.
class PricingPage extends StatefulWidget {
  /// Creates the page. [backend] is used by the confirmation page.
  const PricingPage({required this.backend, super.key});

  /// Your backend, used to confirm the order after payment.
  final OrderBackend backend;

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  late Future<PricePreviewResult> _previews;
  StreamSubscription<CheckoutEvent>? _events;

  @override
  void initState() {
    super.initState();
    _previews = _loadPrices();
    _events = Paddle.instance.events.listen(_onCheckoutEvent);
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    super.dispose();
  }

  Future<PricePreviewResult> _loadPrices() =>
      Paddle.instance.pricing.previewPrices(
        PricePreviewRequest(
          items: [
            for (final priceId in AppConfig.priceIds) PricePreviewItem(priceId),
          ],
        ),
      );

  void _onCheckoutEvent(CheckoutEvent event) {
    if (!mounted) return;
    if (event.isCompleted) {
      final transactionId = event.data?.transactionId;
      if (transactionId == null) return;
      // The payment is done, but only the backend can confirm the order.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConfirmationPage(
            backend: widget.backend,
            transactionId: transactionId,
          ),
        ),
      );
    } else if (event.isError) {
      _showMessage(event.error?.detail ?? 'Checkout error: ${event.rawName}');
    }
  }

  Future<void> _buy(String priceId) async {
    try {
      await Paddle.instance.checkout.open(
        CheckoutOptions(
          items: [CheckoutItem(priceId: priceId)],
          settings: const CheckoutSettings.overlay(
            theme: CheckoutTheme.light,
            locale: CheckoutLocale.en,
            showAddDiscounts: true,
          ),
        ),
      );
    } on PaddleException catch (error) {
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _retry() => setState(() => _previews = _loadPrices());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Overlay checkout')),
    body: FutureBuilder<PricePreviewResult>(
      future: _previews,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorView(message: '${snapshot.error}', onRetry: _retry);
        }
        final result = snapshot.requireData;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionCard(
                    title: 'Localized for you',
                    child: Text(
                      'Paddle previews these prices for your location and '
                      'currency. The checkout opens as a Paddle overlay, so '
                      'the payment form is rendered by Paddle.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final priceId in AppConfig.priceIds) ...[
                    _PlanCard(
                      priceId: priceId,
                      line: result.lineItemFor(priceId),
                      onBuy: () => unawaited(_buy(priceId)),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.priceId,
    required this.line,
    required this.onBuy,
  });

  final String priceId;
  final PricePreviewLineItem? line;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = this.line;
    final unitPrice = line?.formattedUnitTotals?.total ?? '-';
    final tax = line?.formattedTotals?.tax;
    final cycle = _billingLabel(line?.price?.billingCycle);
    final priceName = line?.price?.name;

    return SectionCard(
      title: line?.product?.name ?? 'Price $priceId',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (priceName != null)
            Text(
              priceName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                unitPrice,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(cycle, style: theme.textTheme.bodyMedium),
            ],
          ),
          if (tax != null) ...[
            const SizedBox(height: 4),
            Text(
              'Includes $tax tax at checkout',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (line == null) ...[
            const SizedBox(height: 8),
            Text(
              'Paddle did not return a price for $priceId.',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: line == null ? null : onBuy,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Buy'),
            ),
          ),
        ],
      ),
    );
  }

  static String _billingLabel(PreviewBillingCycle? cycle) {
    final interval = cycle?.interval;
    if (cycle == null || interval == null) return 'one-time';
    final frequency = cycle.frequency ?? 1;
    return frequency == 1 ? 'per $interval' : 'every $frequency ${interval}s';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
