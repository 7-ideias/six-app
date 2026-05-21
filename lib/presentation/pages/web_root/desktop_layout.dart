import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/desktop_footer.dart';
import 'package:appplanilha/presentation/components/web_root/desktop_header.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/cta_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/features_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/hero_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/pricing_section.dart';
import 'package:flutter/material.dart';

// Layout para viewports >= 1024px.
// Header sticky + scroll vertical com hero / features / pricing / cta / footer.
// Mantém GlobalKeys nas sections de destino para smooth-scroll do nav.
class DesktopLayout extends StatefulWidget {
  const DesktopLayout({
    super.key,
    this.onLogin,
    this.onSignup,
    this.onChoosePlan,
  });

  final VoidCallback? onLogin;
  final VoidCallback? onSignup;
  final ValueChanged<String>? onChoosePlan;

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();
  String _activeNav = 'home';

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Roteamento:
  //   home     → topo (offset 0)
  //   features → features section
  //   pricing  → pricing section
  //   about    → CTA section
  void _scrollTo(String id) {
    setState(() => _activeNav = id);
    // 'home' rola explicitamente para o topo (offset 0) em vez de só
    // garantir visibilidade — mais previsível pra usuário que clica "Início".
    if (id == 'home') {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
      return;
    }

    GlobalKey? target;
    switch (id) {
      case 'features':
        target = _featuresKey;
        break;
      case 'pricing':
        target = _pricingKey;
        break;
      case 'about':
        target = _ctaKey;
        break;
    }
    final ctx = target?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0.04, // pequeno padding no topo
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebRootTokens.surface,
      body: Column(
        children: [
          DesktopHeader(
            onLogin: widget.onLogin,
            onSignup: () => _scrollTo('pricing'), // "Começar agora" → planos
            onNavTap: _scrollTo,
            activeId: _activeNav,
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.zero,
              children: [
                KeyedSubtree(
                  key: _heroKey,
                  child: HeroSection(
                    isDesktop: true,
                    onStart: () => _scrollTo('pricing'),
                    onWatch: () => _scrollTo('about'),
                  ),
                ),
                RepaintBoundary(
                  child: KeyedSubtree(
                    key: _featuresKey,
                    child: const FeaturesSection(isDesktop: true),
                  ),
                ),
                RepaintBoundary(
                  child: KeyedSubtree(
                    key: _pricingKey,
                    child: PricingSection(
                      isDesktop: true,
                      onChoose: widget.onChoosePlan,
                    ),
                  ),
                ),
                KeyedSubtree(
                  key: _ctaKey,
                  child: CtaSection(
                    isDesktop: true,
                    onTalk: widget.onSignup,
                  ),
                ),
                const DesktopFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
