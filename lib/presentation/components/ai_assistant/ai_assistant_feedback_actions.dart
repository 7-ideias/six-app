import 'package:flutter/material.dart';

class AiAssistantFeedbackActions extends StatelessWidget {
  const AiAssistantFeedbackActions({
    super.key,
    required this.title,
    required this.helpedLabel,
    required this.notHelpedLabel,
    required this.onFeedback,
    this.loading = false,
    this.sent = false,
  });

  final String title;
  final String helpedLabel;
  final String notHelpedLabel;
  final Future<void> Function(bool helped) onFeedback;
  final bool loading;
  final bool sent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: loading || sent ? null : () => onFeedback(true),
              icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
              label: Text(helpedLabel),
            ),
            OutlinedButton.icon(
              onPressed: loading || sent ? null : () => onFeedback(false),
              icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
              label: Text(notHelpedLabel),
            ),
          ],
        ),
      ],
    );
  }
}
