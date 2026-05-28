import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Toggle animado claro/escuro para os headers web.
//
// Design: pill larga com dois ícones (sol à esq / lua à dir). O thumb circula
// translada suavemente entre eles ao trocar de modo. Inspirado no Figma
// "Light - Dark mode toggle switcher | Button 29":
//   https://www.figma.com/design/2VZgSo8Nbwf3HC6s9Wpys9/...
//
// Layout:    [☀ ●] (claro)   →   [● ☾] (escuro)
// Pill: 52×28  Thumb: 22×22  Padding: 3
class WebDarkToggle extends StatefulWidget {
  const WebDarkToggle({super.key});

  @override
  State<WebDarkToggle> createState() => _WebDarkToggleState();
}

class _WebDarkToggleState extends State<WebDarkToggle>
    with SingleTickerProviderStateMixin {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    // Lê o ThemeProvider para reconstruir ao mudar.
    context.watch<ThemeProvider>();
    final isDark = SixThemeResolver().isDark;

    // Cores adaptadas: em dark mode o pill fica no tom do ink.
    const pillDark = Color(0xFF1E3040);   // ink levemente iluminado
    const pillLight = Color(0xFFE3E6E5);  // line token
    const thumbDark = Color(0xFFF5A12C);  // accent — destaca a lua
    const thumbLight = Color(0xFFFFFFFF); // branco no modo claro

    const pillW = 52.0;
    const pillH = 28.0;
    const thumbD = 22.0;
    const pad = 3.0;

    final pillColor = isDark ? pillDark : pillLight;
    final thumbColor = isDark ? thumbDark : thumbLight;

    return Semantics(
      label: isDark ? 'Mudar para modo claro' : 'Mudar para modo escuro',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => SixThemeResolver().toggleDarkLight(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: pillW,
            height: pillH,
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: _hover
                  ? [
                      BoxShadow(
                        color: (isDark ? thumbDark : WebRootTokens.ink)
                            .withValues(alpha: 0.18),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // Ícone sol (esquerda)
                Positioned(
                  left: pad + 2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isDark ? 0.4 : 0.0, // visível no dark como hint
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        size: 14,
                        color: Color(0xFF8A8F8D),
                      ),
                    ),
                  ),
                ),
                // Ícone lua (direita)
                Positioned(
                  right: pad + 2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isDark ? 0.0 : 0.45, // visível no light como hint
                      child: const Icon(
                        Icons.nightlight_round,
                        size: 13,
                        color: Color(0xFF8A8F8D),
                      ),
                    ),
                  ),
                ),
                // Thumb animado
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: isDark ? (pillW - thumbD - pad) : pad,
                  top: pad,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: thumbD,
                    height: thumbD,
                    decoration: BoxDecoration(
                      color: thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isDark
                            ? Icons.nightlight_round
                            : Icons.wb_sunny_rounded,
                        size: 13,
                        color: isDark
                            ? WebRootTokens.ink
                            : const Color(0xFFF5A12C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
