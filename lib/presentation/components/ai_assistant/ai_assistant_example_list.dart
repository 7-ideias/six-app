import 'package:flutter/material.dart';

class AiAssistantExampleList extends StatelessWidget {
  const AiAssistantExampleList({
    super.key,
    required this.title,
    required this.examples,
  });

  final String title;
  final List<String> examples;

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...examples.map(
          (String item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 7),
                ),
                Expanded(child: Text(item, style: textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
