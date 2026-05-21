import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/material.dart';

// Topbar mobile sticky com logo + CTA pill "Baixar app".
// Equivalente a .topbar do mobile/index.html.
class MobileHeader extends StatelessWidget {
  const MobileHeader({super.key, this.onCta});

  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEBFFFFFF), // 0.92
        border: const Border(
          bottom: BorderSide(color: WebRootTokens.line),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: WebRootTokens.gutterMobile,
        vertical: 12,
      ),
      child: Row(
        children: [
          _logo(),
          const Spacer(),
          GestureDetector(
            onTap: onCta,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: WebRootTokens.ink,
                  borderRadius:
                      BorderRadius.circular(WebRootTokens.radiusPill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Baixar app',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: WebRootTokens.fontFamily,
                        fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_downward, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    // Asset oficial: o PNG tem aspect 1668x2388 com folga grande em volta.
    // Usamos OverflowBox + altura grande pra "puxar" o logo pra cima da topbar
    // sem aumentar a altura real do header (mantemos 56px).
    // Logo mobile um pouco maior — antes height: 60 / box 110x32.
    // Agora 130x36 com asset em 80px (ainda contido no header de 56px via
    // OverflowBox).
    return SizedBox(
      width: 130,
      height: 36,
      child: OverflowBox(
        maxWidth: 170,
        maxHeight: 100,
        alignment: Alignment.centerLeft,
        child: Image.asset(
          'assets/images/six-logo-flecha.png',
          height: 80,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
