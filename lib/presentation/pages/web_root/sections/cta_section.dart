import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_container.dart';
import 'package:appplanilha/presentation/components/web_root/store_badge.dart';
import 'package:flutter/material.dart';

// Banner final "Está em dúvida?" (desktop) ou "Baixe o Six e comece hoje"
// (mobile, com store badges).
class CtaSection extends StatelessWidget {
  const CtaSection({
    super.key,
    required this.isDesktop,
    this.onTalk,
  });

  final bool isDesktop;
  final VoidCallback? onTalk;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) return _desktop();
    return _mobile();
  }

  Widget _desktop() {
    return Container(
      color: WebRootTokens.bgCanvas,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: ResponsiveContainer(
        isDesktop: true,
        child: Container(
          decoration: BoxDecoration(
            color: WebRootTokens.ink,
            borderRadius: BorderRadius.circular(WebRootTokens.radiusBig),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Está em dúvida? Faça um teste.',
                      style: WebRootTokens.sectionTitleDesktop.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '14 dias grátis, sem cartão. Um especialista te ajuda a configurar.',
                      style: WebRootTokens.leadDesktop.copyWith(
                        color: const Color(0xBFFFFFFF),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _whiteCta(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whiteCta() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTalk,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(WebRootTokens.radiusBtn),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fale com um especialista',
                style: WebRootTokens.buttonMd.copyWith(color: WebRootTokens.ink),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward,
                  size: 16, color: WebRootTokens.ink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WebRootTokens.gutterMobile,
        32,
        WebRootTokens.gutterMobile,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: WebRootTokens.ink,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      WebRootTokens.accent.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Baixe o Six e comece hoje.',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '14 dias grátis, sem cartão. Disponível para iPhone e Android.',
                  style: TextStyle(
                    color: Color(0xC7FFFFFF),
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: StoreBadge(
                        store: AppStore.apple,
                        dark: false,
                        onTap: onTalk,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StoreBadge(
                        store: AppStore.google,
                        dark: false,
                        onTap: onTalk,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
