import 'package:flutter/material.dart';

class AiAssistantButton extends StatelessWidget {
  const AiAssistantButton({
    super.key,
    required this.onTap,
    required this.label,
    this.extended = false,
  });

  final VoidCallback onTap;
  final String label;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (extended) {
      return FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.auto_awesome_outlined),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    return FloatingActionButton.small(
      onPressed: onTap,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      tooltip: label,
      child: const Icon(Icons.auto_awesome_outlined),
    );
  }
}
