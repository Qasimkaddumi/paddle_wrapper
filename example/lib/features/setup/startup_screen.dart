import 'package:flutter/material.dart';

/// Shown instead of the app when configuration is missing or Paddle.js
/// could not start. Kept independent of Paddle so it always renders.
class StartupScreen extends StatelessWidget {
  /// Creates a startup screen.
  const StartupScreen({
    required this.title,
    required this.message,
    this.details = const [],
    super.key,
  });

  /// Heading of the screen.
  final String title;

  /// Explanation shown under the heading.
  final String message;

  /// Optional extra lines, such as the names of missing variables.
  final List<String> details;

  static const String _runCommand =
      'flutter run -d chrome --web-port 5000 '
      '--dart-define=PADDLE_CLIENT_TOKEN=test_xxx '
      '--dart-define=PADDLE_PRICE_ID=pri_xxx';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(message, style: theme.textTheme.bodyLarge),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final detail in details)
                    Text(
                      '- $detail',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Run the example with:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _runCommand,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
