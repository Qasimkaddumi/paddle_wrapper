import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../confirmation/order_backend.dart';
import '../custom_checkout/custom_checkout_page.dart';
import '../pricing/pricing_page.dart';
import '../../shared/section_card.dart';

/// Lists the checkout demos. Each demo opens a Paddle checkout for the
/// price IDs passed through `--dart-define`.
class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({required this.backend, super.key});

  /// Your backend, passed on to the demos that confirm payments.
  final OrderBackend backend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('paddle_wrapper examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Configured prices',
            child: Text(
              AppConfig.priceIds.join('\n'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DemoTile(
            icon: Icons.open_in_new,
            title: 'Overlay checkout',
            subtitle:
                'Paddle renders the whole checkout. Localized prices come '
                'from the pricing service.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PricingPage(backend: backend),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DemoTile(
            icon: Icons.dashboard_customize_outlined,
            title: 'Inline checkout (your own design)',
            subtitle:
                'Your order summary, Paddle-rendered payment form. Driven by '
                'PaddleCheckoutBuilder and PaddleCheckoutFrame.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CustomCheckoutPage(backend: backend),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
