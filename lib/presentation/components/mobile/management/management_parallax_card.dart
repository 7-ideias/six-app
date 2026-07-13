import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/management/management_parallax_card_data.dart';

class ManagementParallaxCard extends StatelessWidget {
  const ManagementParallaxCard({
    super.key,
    required this.data,
    required this.delta,
    required this.isActive,
    required this.parallaxIntensity,
    required this.imageOverflowFraction,
    required this.reduceMotion,
  });

  final ManagementParallaxCardData data;
  final double delta;
  final bool isActive;
  final double parallaxIntensity;
  final double imageOverflowFraction;
  final bool reduceMotion;

  static const double _cardBorderRadius = 26;
  static const double _cardContentPadding = 18;
  static const double _iconContainerSize = 46;
  static const double _iconBorderRadius = 17;
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(_cardBorderRadius);
    final BorderSide borderSide = BorderSide(
      color: isActive ? const Color(0x33FFFFFF) : const Color(0x2AFFFFFF),
    );
    final Color shadowColor =
        isActive ? const Color(0x16111827) : const Color(0x0D111827);

    Widget cardContent = Container(
      key: ValueKey<String>('management-parallax-card-${data.id}'),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.fromBorderSide(borderSide),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            spreadRadius: -1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildParallaxBackground(),
            _buildOverlay(),
            _buildContent(),
          ],
        ),
      ),
    );

    if (data.onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: data.onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  Widget _buildParallaxBackground() {
    final double clampedDelta = delta.clamp(-1.2, 1.2).toDouble();
    final double effectiveDelta = reduceMotion ? 0 : clampedDelta;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth = constraints.maxWidth;
        final double parallaxExtent =
            (cardWidth * imageOverflowFraction / 2)
                .clamp(24.0, 120.0)
                .toDouble();
        final double parallaxOffset =
            -effectiveDelta * cardWidth * parallaxIntensity;
        final double safeOffset =
            parallaxOffset.clamp(-parallaxExtent, parallaxExtent).toDouble();

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              left: -parallaxExtent,
              right: -parallaxExtent,
              top: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(safeOffset, 0),
                child: Image.asset(
                  data.imageAssetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) {
                    return DecoratedBox(
                      key: ValueKey<String>(
                        'management-parallax-fallback-${data.id}',
                      ),
                      decoration: BoxDecoration(
                        gradient: data.fallbackGradient,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverlay() {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0x16000000),
              Color(0x2E000000),
              Color(0x9E000000),
            ],
            stops: <double>[0, 0.45, 1],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final double iconDelta =
        reduceMotion ? 0 : delta.clamp(-1.0, 1.0).toDouble() * -4;

    return Padding(
      padding: const EdgeInsets.all(_cardContentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Transform.translate(
            offset: Offset(iconDelta, 0),
            child: Container(
              width: _iconContainerSize,
              height: _iconContainerSize,
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(_iconBorderRadius),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Icon(
                data.icon,
                color: SixMobilePalette.onPrimary,
                size: _iconSize,
              ),
            ),
          ),
          const Spacer(),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.heroSupportingText,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
