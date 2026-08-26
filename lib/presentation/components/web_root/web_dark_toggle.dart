import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web/six_web_animated_theme_toggle.dart';
import 'package:sixpos/providers/theme_provider.dart';

// Toggle animado claro/escuro para os headers web.
//
// Design: pill larga com dois ícones (sol à esq / lua à dir). O thumb circula
// translada suavemente entre eles ao trocar de modo. Inspirado no Figma
// "Light - Dark mode toggle switcher | Button 29":
//   https://www.figma.com/design/2VZgSo8Nbwf3HC6s9Wpys9/...
//
// Layout:    [☀ ●] (claro)   →   [● ☾] (escuro)
// Pill: 52×28  Thumb: 22×22  Padding: 3
class WebDarkToggle extends StatelessWidget {
  const WebDarkToggle({super.key});

  @override
  Widget build(BuildContext context) {
    // Lê o ThemeProvider para reconstruir ao mudar.
    context.watch<ThemeProvider>();
    final isDark = SixThemeResolver().isDark;

    // Cores adaptadas: em dark mode o pill fica no tom do ink.
    const pillDark = Color(0xFF1E3040); // ink levemente iluminado
    const pillLight = Color(0xFFE3E6E5); // line token
    const thumbDark = Color(0xFFF5A12C); // accent — destaca a lua
    const thumbLight = Color(0xFFFFFFFF); // branco no modo claro

    final pillColor = isDark ? pillDark : pillLight;
    final thumbColor = isDark ? thumbDark : thumbLight;
    final String semanticsLabel = context.t(
      isDark
          ? 'web.header.theme.dark.disable'
          : 'web.header.theme.dark.enable',
      fallback: isDark ? 'Desativar tema escuro' : 'Ativar tema escuro',
    );

    return SixWebAnimatedThemeToggle(
      isDark: isDark,
      semanticsLabel: semanticsLabel,
      trackColor: pillColor,
      thumbColor: thumbColor,
      activeIconColor:
          isDark ? WebRootTokens.ink : const Color(0xFFF5A12C),
      inactiveIconColor: const Color(0xFF8A8F8D),
      hoverShadowColor: isDark ? thumbDark : WebRootTokens.ink,
      onChanged: (bool value) {
        context.read<ThemeProvider>().toggleTheme(value);
      },
    );
  }
}
