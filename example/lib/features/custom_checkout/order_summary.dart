import 'package:flutter/material.dart';
import 'package:paddle_wrapper/paddle_wrapper.dart';

import '../../shared/section_card.dart';

/// Your own order summary, drawn from the live state of an inline checkout.
///
/// Every number comes from [state], which mirrors what Paddle will charge.
/// Quantity and discount changes are reported to the page, which forwards
/// them to Paddle.
class OrderSummary extends StatelessWidget {
  /// Creates the summary.
  const OrderSummary({
    required this.state,
    required this.quantity,
    required this.maxQuantity,
    required this.discountController,
    required this.onQuantityChanged,
    required this.onApplyDiscount,
    this.actionError,
    super.key,
  });

  /// Live checkout state from `PaddleCheckoutBuilder`.
  final CheckoutState state;

  /// Quantity the page last sent to Paddle.
  final int quantity;

  /// Largest quantity the buyer may choose.
  final int maxQuantity;

  /// Controller of the discount code field.
  final TextEditingController discountController;

  /// Called with `+1` or `-1`.
  final ValueChanged<int> onQuantityChanged;

  /// Called when the buyer applies the discount code.
  final VoidCallback onApplyDiscount;

  /// Error from a call made by this page, if any.
  final String? actionError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = state.data;
    final items = data?.items ?? const <CheckoutDataItem>[];
    final totals = data?.totals;
    final currency = data?.currencyCode;
    final ready = data != null && !state.isProcessingPayment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Order summary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PhaseChip(phase: state.phase),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text('Loading your order from Paddle...')
              else
                for (final item in items)
                  _LineItemRow(
                    name: item.product?.name ?? item.priceName ?? 'Item',
                    description: item.priceName,
                    amount: _money(item.totals?.total, currency),
                  ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Quantity', style: theme.textTheme.bodyLarge),
                  const Spacer(),
                  IconButton.outlined(
                    tooltip: 'Remove one',
                    onPressed: ready && quantity > 1
                        ? () => onQuantityChanged(-1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Add one',
                    onPressed: ready && quantity < maxQuantity
                        ? () => onQuantityChanged(1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Discount',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: discountController,
                  enabled: ready,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onApplyDiscount(),
                  decoration: const InputDecoration(
                    labelText: 'Discount code',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: ready ? onApplyDiscount : null,
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Totals',
          child: Column(
            children: [
              _TotalRow(
                label: 'Subtotal',
                value: _money(totals?.subtotal, currency),
              ),
              if ((totals?.discount ?? 0) > 0)
                _TotalRow(
                  label: 'Discount${_discountLabel(data)}',
                  value: '-${_money(totals?.discount, currency)}',
                ),
              _TotalRow(label: 'Tax', value: _money(totals?.tax, currency)),
              const Divider(height: 24),
              _TotalRow(
                label: 'Total due',
                value: _money(totals?.total, currency),
                emphasize: true,
              ),
            ],
          ),
        ),
        if (state.error != null || actionError != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: _errorText(state.error) ?? actionError!),
        ],
        const SizedBox(height: 16),
        Text(
          'Paddle renders the payment form on the right, so card details '
          'never touch this app.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  static String _discountLabel(CheckoutData? data) {
    final code = data?.discount?.code;
    return code == null ? '' : ' ($code)';
  }

  /// Formats a minor-unit amount such as `1999` as `USD 19.99`.
  ///
  /// Paddle sends totals in the smallest currency unit. This assumes two
  /// decimal places. For exact, localized strings use the formatted values
  /// from `Paddle.instance.pricing.previewPrices`.
  static String _money(num? minorUnits, String? currency) {
    if (minorUnits == null) return '-';
    final amount = (minorUnits / 100).toStringAsFixed(2);
    return currency == null ? amount : '$currency $amount';
  }

  static String? _errorText(CheckoutError? error) {
    if (error == null) return null;
    final fields = [for (final field in error.fieldErrors) field.message];
    final parts = [if (error.detail != null) error.detail!, ...fields];
    if (parts.isNotEmpty) return parts.join(' ');
    return error.code ?? 'Paddle reported a problem with this checkout.';
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.phase});

  final CheckoutPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (phase) {
      CheckoutPhase.idle => ('Loading checkout', Icons.hourglass_empty),
      CheckoutPhase.ready => ('Ready to pay', Icons.shopping_bag_outlined),
      CheckoutPhase.processingPayment => ('Processing payment', Icons.sync),
      CheckoutPhase.completed => ('Payment received', Icons.check_circle),
      CheckoutPhase.closed => ('Checkout closed', Icons.close),
    };
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.name,
    required this.description,
    required this.amount,
  });

  final String name;
  final String? description;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall),
                if (description != null)
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(amount, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
