import 'package:appplanilha/design_system/helpers/six_theme_resolver.dart';
import 'package:appplanilha/design_system/tokens/web_root_scheme.dart';
import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/mobile_bottom_dock.dart';
import 'package:appplanilha/presentation/components/web_root/mobile_footer.dart';
import 'package:appplanilha/presentation/components/web_root/mobile_header.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/cta_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/features_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/hero_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/pricing_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/segments_section.dart';
import 'package:appplanilha/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Layout para viewports < 1024px (mobile + tablet).
// Ordem do design oficial (mobile/index.html):
//   topbar → hero → features → segments → pricing → cta → footer
// + sticky bottom dock (.dock) que aparece depois que o usuário scrolla
// além da área #baixar.
class MobileLayout extends StatefulWidget {
  const MobileLayout({
    super.key,
    this.onSignup,
    this.onChoosePlan,
  });

  final VoidCallback? onSignup;
  final ValueChanged<String>? onChoosePlan;

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  final ScrollController _ctrl = ScrollController();
  // Aproximação do offset onde os store badges do hero saem da viewport.
  // O design real usa IntersectionObserver, aqui usamos um threshold simples.
  static const double _dockThreshold = 600;
  bool _dockVisible = false;

  // Keys de scroll — usadas para smooth scroll a partir do header/CTAs.
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final next = _ctrl.offset > _dockThreshold;
    if (next != _dockVisible && mounted) {
      setState(() => _dockVisible = next);
    }
  }

  void _scrollToPricing() => _scrollTo(_pricingKey);
  void _scrollToCta() => _scrollTo(_ctaKey);

  void _scrollTo(GlobalKey k) {
    final ctx = k.currentContext;
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
      backgroundColor: scheme.surfacePage,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WebRootTokens.mobileContentMaxWidth,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: scheme.border),
                right: BorderSide(color: scheme.border),
              ),
              color: scheme.surfacePage,
            ),
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _ctrl,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedHeaderDelegate(
                        child: MobileHeader(onCta: _scrollToPricing),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        HeroSection(
                          isDesktop: false,
                          onStart: _scrollToPricing,
                        ),
                        const RepaintBoundary(
                          child: FeaturesSection(isDesktop: false),
                        ),
                        const SegmentsSection(),
                        RepaintBoundary(
                          child: KeyedSubtree(
                            key: _pricingKey,
                            child: PricingSection(
                              isDesktop: false,
                              onChoose: widget.onChoosePlan,
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _ctaKey,
                          child: CtaSection(
                            isDesktop: false,
                            onTalk: _scrollToCta,
                          ),
                        ),
                        const MobileFooter(),
                        // Padding extra pra deixar espaço pra dock fixo sem
                        // cobrir conteúdo final
                        SizedBox(height: _dockVisible ? 80 : 0),
                      ]),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MobileBottomDock(
                    visible: _dockVisible,
                    onTap: widget.onSignup,
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

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      child;

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate old) => old.child != child;
}
