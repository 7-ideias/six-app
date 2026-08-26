import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_scheme.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';
import 'package:sixpos/presentation/components/web_root/web_dark_toggle.dart';
import 'package:sixpos/presentation/components/web_root/web_language_switcher.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Topbar mobile sticky com logo + CTA pill "Baixar app".
// Suporta dark mode e l10n.
class MobileHeader extends StatelessWidget {
  const MobileHeader({super.key, this.onCta});

  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final l10n = WebRootL10n.of(context);
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);

    return Container(
      decoration: BoxDecoration(
        color: scheme.headerBgMobile,
        border: Border(bottom: BorderSide(color: scheme.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: WebRootTokens.gutterMobile,
        vertical: 12,
      ),
      child: Row(
        children: [
          _logo(),
          const Spacer(),
          // Idioma
          const WebLanguageSwitcher(),
          const SizedBox(width: 6),
          // Dark mode toggle
          const WebDarkToggle(),
          const SizedBox(width: 10),
          // CTA "Baixar app"
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
                  borderRadius: BorderRadius.circular(WebRootTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.mobileDownloadCta,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: WebRootTokens.fontFamily,
                        fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: Colors.white,
                    ),
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
    final bool isDark = SixThemeResolver().isDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF00163A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x24145BFF),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/sixoapp_splash_symbol.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'SixoApp',
          style: TextStyle(
            color: isDark ? Colors.white : WebRootTokens.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
      ],
    );
  }
}
