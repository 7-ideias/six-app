import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_button.dart';
import 'package:flutter/material.dart';

class PlanData {
  const PlanData({
    required this.name,
    required this.price,
    required this.cadence,
    required this.pitch,
    required this.features,
    required this.cta,
    this.featured = false,
  });

  final String name;
  final String price;
  final String cadence;
  final String pitch;
  final List<String> features;
  final String cta;
  final bool featured;
}

// Card de plano da seção "Planos". O featured fica elevado (translateY -8 no
// desktop) e tem fundo ink + CTA accent. Os demais são brancos com borda.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.isDesktop,
    this.onChoose,
  });

  final PlanData plan;
  final bool isDesktop;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final featured = plan.featured;
    final bg = featured ? WebRootTokens.ink : WebRootTokens.surface;
    final radius = isDesktop
        ? WebRootTokens.radiusBig
        : 20.0; // mobile usa 20 no plan (CSS)

    return Transform.translate(
      offset: featured && isDesktop ? const Offset(0, -8) : Offset.zero,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: featured
              ? null
              : Border.all(color: WebRootTokens.line),
          boxShadow: featured
              ? WebRootTokens.featuredPlanShadow
              : WebRootTokens.cardShadow,
        ),
        padding: EdgeInsets.all(isDesktop ? 28 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(featured),
            const SizedBox(height: 16),
            _price(featured),
            const SizedBox(height: 12),
            Text(
              plan.pitch,
              style: WebRootTokens.featureBody.copyWith(
                color: featured
                    ? const Color(0xBFFFFFFF) // 0.75
                    : WebRootTokens.fgSoft,
                fontSize: isDesktop ? 14 : 13,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: featured ? const Color(0x1AFFFFFF) : WebRootTokens.line,
            ),
            const SizedBox(height: 20),
            ...plan.features.map((f) => _featureRow(f, featured)),
            const SizedBox(height: 20),
            _cta(featured),
          ],
        ),
      ),
    );
  }

  Widget _header(bool featured) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            plan.name,
            style: WebRootTokens.planName.copyWith(
              color: featured ? WebRootTokens.accent : WebRootTokens.ink,
            ),
          ),
        ),
        if (featured)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: WebRootTokens.accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'MAIS ESCOLHIDO',
              style: TextStyle(
                fontFamily: WebRootTokens.fontFamily,
                fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: WebRootTokens.ink,
              ),
            ),
          ),
      ],
    );
  }

  Widget _price(bool featured) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          plan.price,
          style: (isDesktop
                  ? WebRootTokens.planPriceDesktop
                  : WebRootTokens.planPriceMobile)
              .copyWith(color: featured ? Colors.white : WebRootTokens.ink),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            plan.cadence,
            style: TextStyle(
              fontFamily: WebRootTokens.fontFamily,
              fontFamilyFallback: WebRootTokens.fontFamilyFallback,
              fontSize: 13,
              color: featured
                  ? const Color(0xA6FFFFFF)
                  : WebRootTokens.fgMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureRow(String text, bool featured) {
    final checkColor =
        featured ? WebRootTokens.accent : WebRootTokens.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check, size: 16, color: checkColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: WebRootTokens.fontFamily,
                fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                fontSize: isDesktop ? 14 : 13,
                height: 1.45,
                color: featured
                    ? const Color(0xEBFFFFFF) // 0.92
                    : WebRootTokens.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cta(bool featured) {
    if (featured) {
      // Accent solid CTA
      return _AccentCta(label: plan.cta, onPressed: onChoose);
    }
    return ResponsiveButton(
      label: plan.cta,
      onPressed: onChoose,
      variant: WebButtonVariant.secondary,
      size: WebButtonSize.md,
      expand: true,
      trailing: const Icon(Icons.arrow_forward, size: 16),
    );
  }
}

class _AccentCta extends StatefulWidget {
  const _AccentCta({required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  State<_AccentCta> createState() => _AccentCtaState();
}

class _AccentCtaState extends State<_AccentCta> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 52,
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0xFFE69423)
                : WebRootTokens.accent,
            borderRadius: BorderRadius.circular(WebRootTokens.radiusBtn),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: WebRootTokens.buttonMd
                    .copyWith(color: WebRootTokens.ink),
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
}
