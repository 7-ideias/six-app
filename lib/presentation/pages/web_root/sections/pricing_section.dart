import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_scheme.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';
import 'package:sixpos/presentation/components/web_root/eyebrow.dart';
import 'package:sixpos/presentation/components/web_root/plan_card.dart';
import 'package:sixpos/presentation/components/web_root/responsive_container.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PricingSection extends StatefulWidget {
  const PricingSection({super.key, required this.isDesktop, this.onChoose});

  final bool isDesktop;
  final ValueChanged<String>? onChoose;

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  static const double _centerScale = 1.08;
  static const double _sideScale = 0.88;
  static const double _sideTranslateY = 6;
  static const double _sideOpacity = 0.92;
  static const double _viewportFraction = 0.74;

  late final PageController _page = PageController(
    initialPage: 1,
    viewportFraction: _viewportFraction,
  );

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final l10n = WebRootL10n.of(context);
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);

    // Build PlanData list from l10n (locale-aware)
    final planDataList = l10n.plans
        .map(
          (p) => PlanData(
            name: p.name,
            price: p.price,
            cadence: p.cadence,
            pitch: p.pitch,
            features: p.features,
            cta: p.cta,
            featured: p.featured,
          ),
        )
        .toList();

    return Container(
      color: scheme.surfacePage,
      padding: EdgeInsets.symmetric(vertical: widget.isDesktop ? 96 : 48),
      child: ResponsiveContainer(
        isDesktop: widget.isDesktop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _head(l10n: l10n, scheme: scheme),
            SizedBox(height: widget.isDesktop ? 56 : 28),
            if (widget.isDesktop)
              _gridDesktop(planDataList)
            else
              _perspectiveMobile(planDataList),
          ],
        ),
      ),
    );
  }

  Widget _head({required WebRootL10n l10n, required WebRootScheme scheme}) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: widget.isDesktop ? 720 : double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(text: l10n.pricingEyebrow, isDesktop: widget.isDesktop),
            SizedBox(height: widget.isDesktop ? 16 : 14),
            Text(
              l10n.pricingSectionTitle,
              style: widget.isDesktop
                  ? WebRootTokens.sectionTitleDesktop
                      .copyWith(color: scheme.textPrimary)
                  : WebRootTokens.sectionTitleMobile
                      .copyWith(color: scheme.textPrimary),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 12),
            Text(
              widget.isDesktop
                  ? l10n.pricingSectionLeadDesktop
                  : l10n.pricingSectionLeadMobile,
              style: widget.isDesktop
                  ? WebRootTokens.leadDesktop
                      .copyWith(fontSize: 16, color: scheme.textSoft)
                  : WebRootTokens.leadMobile
                      .copyWith(fontSize: 15, color: scheme.textSoft),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridDesktop(List<PlanData> plans) {
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 3;
        const gap = 20.0;
        final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
        return IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < plans.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: cardW,
                child: PlanCard(
                  plan: plans[i],
                  isDesktop: true,
                  emphasizeFeatured: true,
                  onChoose: () => widget.onChoose?.call(plans[i].name),
                ),
              ),
            ],
          ],
        ),
        );
      },
    );
  }

  Widget _perspectiveMobile(List<PlanData> plans) {
    return Column(
      children: [
        SizedBox(
          height: 560,
          child: PageView.builder(
            controller: _page,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: plans.length,
            onPageChanged: (_) => setState(() {}),
            itemBuilder: (context, i) {
              return AnimatedBuilder(
                animation: _page,
                builder: (context, child) {
                  final page = _page.hasClients && _page.page != null
                      ? _page.page!
                      : _page.initialPage.toDouble();
                  final delta = (page - i).abs().clamp(0.0, 1.0);
                  final scale = _lerp(_centerScale, _sideScale, delta);
                  final ty = _lerp(0, _sideTranslateY, delta);
                  final op = _lerp(1.0, _sideOpacity, delta);
                  return Center(
                    child: Opacity(
                      opacity: op,
                      child: Transform.translate(
                        offset: Offset(0, ty),
                        child: Transform.scale(scale: scale, child: child),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      _page.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: PlanCard(
                      plan: plans[i],
                      isDesktop: false,
                      emphasizeFeatured: false,
                      onChoose: () => widget.onChoose?.call(plans[i].name),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _dotsIndicator(plans.length),
      ],
    );
  }

  Widget _dotsIndicator(int count) {
    return AnimatedBuilder(
      animation: _page,
      builder: (context, _) {
        final page = _page.hasClients && _page.page != null
            ? _page.page!
            : _page.initialPage.toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              _dot(distance: (page - i).abs().clamp(0.0, 1.0)),
          ],
        );
      },
    );
  }

  Widget _dot({required double distance}) {
    final width = _lerp(22, 6, distance);
    final color = Color.lerp(
      WebRootTokens.accent,
      WebRootTokens.line,
      distance,
    )!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
