import 'package:appplanilha/design_system/tokens/auth_tokens.dart';
import 'package:flutter/material.dart';

/// Título + subtítulo de uma tela de autenticação.
///
/// Título: Inter Medium 24px black (Figma).
/// Subtítulo: 14px Regular muted (#555555).
class SixAuthTitle extends StatelessWidget {
  const SixAuthTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: SixAuthTokens.fontSizeTitle,
            fontWeight: SixAuthTokens.fontWeightTitle,
            color: SixAuthTokens.colorTextPrimary,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: SixAuthTokens.fontSizeSubtitle,
              fontWeight: SixAuthTokens.fontWeightSubtitle,
              color: SixAuthTokens.colorTextMuted,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
