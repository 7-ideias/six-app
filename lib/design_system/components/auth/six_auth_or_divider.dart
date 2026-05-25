import 'package:appplanilha/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

/// Divisor "ou continue com" entre o formulário e o botão Google.
class SixAuthOrDivider extends StatelessWidget {
  const SixAuthOrDivider({super.key, this.text = 'ou continue com'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: SixAuthTokens.colorDivider,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              color: SixAuthTokens.colorDividerText,
              fontSize: 13,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: SixAuthTokens.colorDivider,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
