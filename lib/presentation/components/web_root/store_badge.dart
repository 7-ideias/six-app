import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/material.dart';

enum AppStore { apple, google }

// "Baixar na App Store" / "Disponível no Google Play".
// Equivalente ao .store-btn da mobile/index.html — usa as próprias artworks
// inline (não os PNGs antigos, que são as badges oficiais) para ficar fiel
// ao mood do design (botão ink rounded com glyph + 2 linhas).
class StoreBadge extends StatefulWidget {
  const StoreBadge({
    super.key,
    required this.store,
    this.onTap,
    this.dark = true,
  });

  final AppStore store;
  final VoidCallback? onTap;
  // dark=true: variante ink (hero); dark=false: variante branca (cta banner).
  final bool dark;

  @override
  State<StoreBadge> createState() => _StoreBadgeState();
}

class _StoreBadgeState extends State<StoreBadge> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.dark
        ? (_pressed ? const Color(0xFF0A212C) : WebRootTokens.ink)
        : (_pressed ? const Color(0xFFF2F2F2) : Colors.white);
    final fg = widget.dark ? Colors.white : WebRootTokens.ink;
    final smallColor = widget.dark
        ? const Color(0xB8FFFFFF) // rgba(255,255,255,0.72)
        : WebRootTokens.fgMuted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(WebRootTokens.radiusBtn),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: Center(child: _glyph(fg)),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store == AppStore.apple
                        ? 'Baixar na'
                        : 'Disponível no',
                    style: TextStyle(
                      fontFamily: WebRootTokens.fontFamily,
                      fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: smallColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.store == AppStore.apple
                        ? 'App Store'
                        : 'Google Play',
                    style: TextStyle(
                      fontFamily: WebRootTokens.fontFamily,
                      fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: fg,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glyph(Color color) {
    return widget.store == AppStore.apple
        ? Icon(Icons.apple, size: 24, color: color)
        : Icon(Icons.shop, size: 22, color: color);
  }
}
