import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/material.dart';

// Eyebrow = chip pequeno uppercase usado antes de cada h2/hero h1.
// Espelha o <Eyebrow> do Primitives.jsx (mood corporate).
class Eyebrow extends StatelessWidget {
  const Eyebrow({
    super.key,
    required this.text,
    this.isDesktop = true,
  });

  final String text;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final style = isDesktop
        ? WebRootTokens.eyebrowDesktop
        : WebRootTokens.eyebrowMobile;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WebRootTokens.lineSoft, // rgba(15,45,58,0.08)
        borderRadius: BorderRadius.circular(WebRootTokens.radiusPill),
      ),
      child: Text(text.toUpperCase(), style: style),
    );
  }
}
