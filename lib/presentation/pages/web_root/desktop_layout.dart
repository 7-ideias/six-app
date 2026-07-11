import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_scheme.dart';
import 'package:sixpos/presentation/components/web_root/desktop_footer.dart';
import 'package:sixpos/presentation/components/web_root/desktop_header.dart';
import 'package:sixpos/presentation/pages/web_root/sections/cta_section.dart';
import 'package:sixpos/presentation/pages/web_root/sections/features_section.dart';
import 'package:sixpos/presentation/pages/web_root/sections/hero_section.dart';
import 'package:sixpos/presentation/pages/web_root/sections/pricing_section.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Layout para viewports >= 1024px.
// Header sticky + scroll vertical com hero / features / pricing / cta / footer.
// A estrutura visual segue o padrão do dashboard /admin: fundo claro,
// cards grandes, bordas sutis e bastante respiro sem remover seções atuais.
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
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);
    return Scaffold(
      backgroundColor: scheme.isDark ? const Color(0xFF081422) : const Color(0xFFF4F7FB),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _HomeDashboardBackground(scheme: scheme),
          Column(
            children: [
              DesktopHeader(
                onLogin: widget.onLogin,
                onSignup: () => _scrollTo('pricing'),
                onNavTap: _scrollTo,
                activeId: _activeNav,
              ),
              Expanded(
                // SingleChildScrollView + Column (em vez de ListView lazy) garante
                // que TODAS as sections estejam renderizadas e seus GlobalKeys
                // tenham currentContext válido — sem isso, Scrollable.ensureVisible
                // falha em pulos não-lineares (ex.: home → about direto).
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HomeSectionPanel(
                            key: _heroKey,
                            scheme: scheme,
                            priorityDelay: Duration.zero,
                            child: HeroSection(
                              isDesktop: true,
                              onStart: () => _scrollTo('pricing'),
                              onWatch: () => _scrollTo('about'),
                            ),
                          ),
                          _HomeSectionPanel(
                            key: _featuresKey,
                            scheme: scheme,
                            priorityDelay: const Duration(milliseconds: 80),
                            child: const RepaintBoundary(
                              child: FeaturesSection(isDesktop: true),
                            ),
                          ),
                          _HomeSectionPanel(
                            key: _pricingKey,
                            scheme: scheme,
                            priorityDelay: const Duration(milliseconds: 140),
                            child: RepaintBoundary(
                              child: PricingSection(
                                isDesktop: true,
                                onChoose: widget.onChoosePlan,
                              ),
                            ),
                          ),
                          _HomeSectionPanel(
                            key: _ctaKey,
                            scheme: scheme,
                            priorityDelay: const Duration(milliseconds: 200),
                            child: CtaSection(
                              isDesktop: true,
                              onTalk: widget.onSignup,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const DesktopFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeSectionPanel extends StatefulWidget {
  const _HomeSectionPanel({
    super.key,
    required this.child,
    required this.scheme,
    required this.priorityDelay,
  });

  final Widget child;
  final WebRootScheme scheme;
  final Duration priorityDelay;

  @override
  State<_HomeSectionPanel> createState() => _HomeSectionPanelState();
}

class _HomeSectionPanelState extends State<_HomeSectionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.018),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future<void>.delayed(widget.priorityDelay, () {
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.scheme.isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xE61B2F47)
                    : Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.78),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0B1F3A).withOpacity(isDark ? 0.18 : 0.08),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDashboardBackground extends StatelessWidget {
  const _HomeDashboardBackground({required this.scheme});

  final WebRootScheme scheme;

  @override
  Widget build(BuildContext context) {
    final bool isDark = scheme.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[Color(0xFF07111E), Color(0xFF0B1B2E), Color(0xFF081422)]
              : const <Color>[Color(0xFFF4F7FB), Color(0xFFE7F0FA), Color(0xFFF8FAFC)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -170,
            right: -120,
            child: _HomeOrb(
              size: 390,
              color: const Color(0xFF2563EB).withOpacity(isDark ? 0.16 : 0.12),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -130,
            child: _HomeOrb(
              size: 430,
              color: const Color(0xFF0B1F3A).withOpacity(isDark ? 0.30 : 0.08),
            ),
          ),
          Positioned(
            top: 180,
            left: 80,
            child: _HomeOrb(
              size: 180,
              color: const Color(0xFF16A34A).withOpacity(isDark ? 0.08 : 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeOrb extends StatelessWidget {
  const _HomeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
