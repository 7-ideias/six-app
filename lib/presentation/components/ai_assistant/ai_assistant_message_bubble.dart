import 'package:flutter/material.dart';

class AiAssistantMessageBubble extends StatelessWidget {
  const AiAssistantMessageBubble({
    super.key,
    required this.text,
    this.isUser = false,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor =
        isUser
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest;
    final Color textColor =
        isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: textColor, height: 1.35)),
      ),
    );
  }
}
