import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/material.dart';

// Card de feature da seção "Recursos".
// Desktop: hover eleva (-3px) + shadow stronger; mobile: estático.
class FeatureCard extends StatefulWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.isDesktop = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isDesktop;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.isDesktop
        ? WebRootTokens.radiusBig - 4 // 16 nos cards (radiusBig=20)
        : WebRootTokens.radiusCard;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
      decoration: BoxDecoration(
        color: WebRootTokens.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: WebRootTokens.lineSoft),
        boxShadow:
            _hover ? WebRootTokens.cardHoverShadow : WebRootTokens.cardShadow,
      ),
      padding: EdgeInsets.all(widget.isDesktop ? 24 : 18),
      child: widget.isDesktop ? _verticalLayout() : _horizontalLayout(),
    );

    if (!widget.isDesktop) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: card,
    );
  }

  Widget _iconBox(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          // 1f = 12% opacity (rgba ./12)
          color: widget.iconColor.withValues(alpha: 0.12),
          borderRadius:
              BorderRadius.circular(widget.isDesktop ? 14 : 12),
        ),
        child: Icon(widget.icon, color: widget.iconColor, size: size * 0.5),
      );

  Widget _verticalLayout() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(48),
          const SizedBox(height: 18),
          Text(widget.title, style: WebRootTokens.featureTitle),
          const SizedBox(height: 8),
          Text(widget.description, style: WebRootTokens.featureBody),
        ],
      );

  Widget _horizontalLayout() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: WebRootTokens.featureTitleMobile),
                const SizedBox(height: 4),
                Text(widget.description, style: WebRootTokens.featureBody),
              ],
            ),
          ),
        ],
      );
}
