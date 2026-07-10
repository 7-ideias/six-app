import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_scheme.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/components/web_root/responsive_container.dart';
import 'package:sixpos/presentation/components/web_root/store_badge.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Banner final CTA — desktop: "Está em dúvida?" | mobile: "Baixe o Six".
// Suporta dark mode e l10n.
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
    context.watch<ThemeProvider>();
    final l10n = WebRootL10n.of(context);
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);
    return isDesktop ? _desktop(l10n, scheme) : _mobile(l10n, scheme);
  }

  Widget _desktop(WebRootL10n l10n, WebRootScheme scheme) {
    return Container(
      color: scheme.bgCanvas,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: ResponsiveContainer(
        isDesktop: true,
        child: SixWebEntry(
          order: 0,
          duration: const Duration(milliseconds: 640),
          child: Container(
          decoration: BoxDecoration(
            color: scheme.ctaBannerBg,
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
                      l10n.ctaDesktopTitle,
                      style: WebRootTokens.sectionTitleDesktop.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.ctaDesktopSub,
                      style: WebRootTokens.leadDesktop.copyWith(
                        color: const Color(0xBFFFFFFF),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _whiteCta(l10n),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _whiteCta(WebRootL10n l10n) {
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
                l10n.ctaDesktopButton,
                style: WebRootTokens.buttonMd.copyWith(color: WebRootTokens.ink),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: WebRootTokens.ink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobile(WebRootL10n l10n, WebRootScheme scheme) {
    return SixWebEntry(
      order: 0,
      duration: const Duration(milliseconds: 640),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(
        WebRootTokens.gutterMobile,
        32,
        WebRootTokens.gutterMobile,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.ctaBannerBg,
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
                Text(
                  l10n.ctaMobileTitle,
                  style: const TextStyle(
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
                Text(
                  l10n.ctaMobileSub,
                  style: const TextStyle(
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
      ),
    );
  }
}
