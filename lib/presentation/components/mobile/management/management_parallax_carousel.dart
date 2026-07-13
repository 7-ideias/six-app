import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/mobile/management/management_parallax_card.dart';
import 'package:sixpos/presentation/components/mobile/management/management_parallax_card_data.dart';

class ManagementParallaxCarousel extends StatelessWidget {
  const ManagementParallaxCarousel({
    super.key,
    required this.controller,
    required this.cards,
    required this.selectedIndex,
    required this.onPageChanged,
    this.viewportFraction = 0.92,
    this.height = 282,
    this.sideCardScale = 0.95,
    this.sideCardOpacity = 1,
    this.parallaxIntensity = 0.26,
    this.imageOverflowFraction = 0.52,
    this.pageSpacing = 0,
    this.pageHorizontalPadding = 0,
    this.padEnds = false,
    this.clipBehavior = Clip.none,
    this.reduceMotion = false,
  });

  final PageController controller;
  final List<ManagementParallaxCardData> cards;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;
  final double viewportFraction;
  final double height;
  final double sideCardScale;
  final double sideCardOpacity;
  final double parallaxIntensity;
  final double imageOverflowFraction;
  final double pageSpacing;
  final double pageHorizontalPadding;
  final bool padEnds;
  final Clip clipBehavior;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    assert(
      controller.viewportFraction == viewportFraction,
      'O PageController precisa usar o mesmo viewportFraction do carousel.',
    );

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: controller,
        padEnds: padEnds,
        clipBehavior: clipBehavior,
        physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
        itemCount: cards.length,
        onPageChanged: onPageChanged,
        itemBuilder: (BuildContext context, int index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, Widget? child) {
              final double currentPage = _resolveCurrentPage();
              final double delta = currentPage - index;
              final double distance = delta.abs().clamp(0.0, 1.0).toDouble();
              final double easedDistance =
                  reduceMotion ? 0 : Curves.easeOutCubic.transform(distance);
              final double scale = lerpDouble(1, sideCardScale, easedDistance)!;
              final double opacity =
                  lerpDouble(1, sideCardOpacity, easedDistance)!;
              final bool applyOpacity = opacity < 0.999;

              Widget cardChild = Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: pageSpacing,
                ).add(EdgeInsets.symmetric(horizontal: pageHorizontalPadding)),
                child: RepaintBoundary(
                  child: ManagementParallaxCard(
                    data: cards[index],
                    delta: delta,
                    isActive: distance < 0.5,
                    parallaxIntensity: parallaxIntensity,
                    imageOverflowFraction: imageOverflowFraction,
                    reduceMotion: reduceMotion,
                  ),
                ),
              );

              if (applyOpacity) {
                cardChild = Opacity(opacity: opacity, child: cardChild);
              }

              return Transform.translate(
                offset: Offset(0, easedDistance * 4),
                child: Transform.scale(scale: scale, child: cardChild),
              );
            },
          );
        },
      ),
    );
  }

  double _resolveCurrentPage() {
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return selectedIndex.toDouble();
    }

    return controller.page ?? selectedIndex.toDouble();
  }
}
