import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

/// Divisor "ou continue com" entre o formulário e o botão Google.
class SixAuthOrDivider extends StatelessWidget {
  const SixAuthOrDivider({super.key, this.text = 'ou continue com'});

  final String text;

  @override
  Widget build(BuildContext context) {
    final Color dividerColor = SixAuthTokens.divider(context);
    final Color textColor = SixAuthTokens.dividerText(context);

    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: TextStyle(color: textColor, fontSize: 13)),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
      ],
    );
  }
}
