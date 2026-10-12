import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paddle_wrapper/paddle_wrapper.dart';

import '../../shared/section_card.dart';
import 'order_backend.dart';

/// Waits for your backend to confirm a payment.
///
/// Paddle tells YOUR server about the payment through a webhook. The browser
/// only learns that the checkout closed successfully, which is not enough to
/// grant access. This page polls your backend until the order is final.
class ConfirmationPage extends StatefulWidget {
  /// Creates the page for the Paddle transaction [transactionId] (`txn_...`).
  const ConfirmationPage({
    required this.backend,
    required this.transactionId,
    super.key,
  });

  /// Your backend. Replace [FakeOrderBackend] with a real implementation.
  final OrderBackend backend;

  /// Transaction from the `checkout.completed` event.
  final String transactionId;

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  late final PaymentConfirmation<OrderStatus> _confirmation;
  late Stream<OrderStatus> _statuses;

  @override
  void initState() {
    super.initState();
    _confirmation = PaymentConfirmation<OrderStatus>(
      fetchStatus: widget.backend.fetchOrderStatus,
      isFinal: (status) => status.isFinal,
      policy: const PollingPolicy(
        initialInterval: Duration(seconds: 1),
        maxInterval: Duration(seconds: 3),
        timeout: Duration(minutes: 1),
      ),
    );
    _statuses = _confirmation.watch(widget.transactionId);
  }

  void _retry() =>
      setState(() => _statuses = _confirmation.watch(widget.transactionId));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order confirmation')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<OrderStatus>(
            stream: _statuses,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final error = snapshot.error;
                if (error is PaymentConfirmationTimeoutException) {
                  return _ResultCard(
                    icon: Icons.schedule,
                    color: Theme.of(context).colorScheme.tertiary,
                    title: 'Still processing',
                    message:
                        'Your payment was received by Paddle, but your server '
                        'has not confirmed it yet. Check back in a few '
                        'minutes. Transaction ${widget.transactionId}.',
                    actionLabel: 'Check again',
                    onAction: _retry,
                  );
                }
                return _ResultCard(
                  icon: Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  title: 'Could not confirm the order',
                  message: '$error',
                  actionLabel: 'Try again',
                  onAction: _retry,
                );
              }

              final status = snapshot.data;
              if (status == null) {
                return const _ResultCard(
                  icon: Icons.hourglass_top,
                  title: 'Confirming your payment',
                  message: 'Asking your server for the order status...',
                  showProgress: true,
                );
              }

              return switch (status.state) {
                OrderState.paid => _ResultCard(
                  icon: Icons.check_circle_outline,
                  color: Colors.green.shade700,
                  title: 'Thank you, your order is paid',
                  message:
                      'Transaction ${status.transactionId} is confirmed by '
                      'your backend. Access can be granted now.',
                ),
                OrderState.failed => _ResultCard(
                  icon: Icons.cancel_outlined,
                  color: Theme.of(context).colorScheme.error,
                  title: 'Payment failed',
                  message: 'Your server reports the order as failed.',
                  actionLabel: 'Back to examples',
                  onAction: () => Navigator.of(context).pop(),
                ),
                OrderState.pending => const _ResultCard(
                  icon: Icons.hourglass_top,
                  title: 'Confirming your payment',
                  message:
                      'Paddle is sending the webhook to your server. This '
                      'usually takes a few seconds.',
                  showProgress: true,
                ),
              };
            },
          ),
        ),
      ),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.message,
    this.color,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? color;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return SectionCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showProgress)
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(),
            )
          else
            Icon(icon, size: 56, color: accent),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
