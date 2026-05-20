import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/mobile_bottom_dock.dart';
import 'package:appplanilha/presentation/components/web_root/mobile_footer.dart';
import 'package:appplanilha/presentation/components/web_root/mobile_header.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/cta_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/features_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/hero_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/pricing_section.dart';
import 'package:appplanilha/presentation/pages/web_root/sections/segments_section.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebRootTokens.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WebRootTokens.mobileContentMaxWidth,
          ),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: WebRootTokens.line),
                right: BorderSide(color: WebRootTokens.line),
              ),
              color: WebRootTokens.surface,
            ),
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _ctrl,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedHeaderDelegate(
                        child: MobileHeader(onCta: widget.onSignup),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        HeroSection(
                          isDesktop: false,
                          onStart: widget.onSignup,
                        ),
                        const RepaintBoundary(
                          child: FeaturesSection(isDesktop: false),
                        ),
                        const SegmentsSection(),
                        RepaintBoundary(
                          child: PricingSection(
                            isDesktop: false,
                            onChoose: widget.onChoosePlan,
                          ),
                        ),
                        CtaSection(
                          isDesktop: false,
                          onTalk: widget.onSignup,
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
