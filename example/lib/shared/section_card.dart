import 'package:flutter/material.dart';

/// A rounded, outlined card with an optional title. Used across the demos
/// so every page shares the same spacing and surface colour.
class SectionCard extends StatelessWidget {
  /// Creates a card around [child].
  const SectionCard({required this.child, this.title, super.key});

  /// Optional heading shown above [child].
  final String? title;

  /// The card contents.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
