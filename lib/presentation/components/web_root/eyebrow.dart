import 'package:appplanilha/design_system/helpers/six_theme_resolver.dart';
import 'package:appplanilha/design_system/tokens/web_root_scheme.dart';
import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Eyebrow = chip pequeno uppercase usado antes de cada h2/hero h1.
// Espelha o <Eyebrow> do Primitives.jsx (mood corporate).
// Suporta dark mode — pill fica com bg levemente escuro e texto claro.
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
    context.watch<ThemeProvider>();
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);
    final style = isDesktop
        ? WebRootTokens.eyebrowDesktop
        : WebRootTokens.eyebrowMobile;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.eyebrowBg,
        borderRadius: BorderRadius.circular(WebRootTokens.radiusPill),
      ),
      child: Text(
        text.toUpperCase(),
        style: style.copyWith(color: scheme.textPrimary),
      ),
    );
  }
}
