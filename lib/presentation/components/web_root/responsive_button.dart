import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_scheme.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum WebButtonSize { sm, md, lg }
enum WebButtonVariant { primary, secondary, ghost }

// Botão unificado para a landing — equivale a WebPrimaryButton +
// WebSecondaryButton + GhostButton do Primitives.jsx. Mantém a mesma
// hierarquia (height 40/50/56 para sm/md/lg, raio 14, gap 8).
class ResponsiveButton extends StatefulWidget {
  const ResponsiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.size = WebButtonSize.md,
    this.variant = WebButtonVariant.primary,
    this.trailing,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final WebButtonSize size;
  final WebButtonVariant variant;
  final Widget? trailing;
  final bool expand;

  @override
  State<ResponsiveButton> createState() => _ResponsiveButtonState();
}

class _ResponsiveButtonState extends State<ResponsiveButton> {
  bool _hover = false;

  ({double height, EdgeInsets padding, TextStyle style}) _sizing() {
    switch (widget.size) {
      case WebButtonSize.sm:
        return (
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          style: WebRootTokens.buttonSm,
        );
      case WebButtonSize.md:
        return (
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          style: WebRootTokens.buttonMd,
        );
      case WebButtonSize.lg:
        return (
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          style: WebRootTokens.buttonLg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isDark = SixThemeResolver().isDark;
    final scheme = WebRootScheme(isDark: isDark);
    final s = _sizing();
    final ink = WebRootTokens.ink;
    final radius = BorderRadius.circular(WebRootTokens.radiusBtn);

    BoxDecoration decoration;
    Color textColor;
    switch (widget.variant) {
      case WebButtonVariant.primary:
        // Dark: accent (âmbar) com texto escuro — visível sobre qualquer fundo dark.
        // Light: ink escuro com texto branco — comportamento original.
        decoration = BoxDecoration(
          color: isDark
              ? (_hover ? const Color(0xFFE69423) : WebRootTokens.accent)
              : (_hover ? const Color(0xFF0A212C) : ink),
          borderRadius: radius,
        );
        textColor = isDark ? ink : Colors.white;
        break;
      case WebButtonVariant.secondary:
        decoration = BoxDecoration(
          color: _hover ? scheme.hoverBg : scheme.cardBg,
          borderRadius: radius,
          border: Border.all(color: scheme.border),
        );
        textColor = scheme.textPrimary;
        break;
      case WebButtonVariant.ghost:
        decoration = BoxDecoration(
          color: _hover ? scheme.hoverBg : Colors.transparent,
          borderRadius: radius,
        );
        textColor = scheme.textPrimary;
        break;
    }

    final content = SizedBox(
      height: s.height,
      child: Padding(
        padding: s.padding,
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                widget.label,
                style: s.style.copyWith(color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(color: textColor, size: 18),
                child: widget.trailing!,
              ),
            ],
          ],
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}
