import 'dart:math' as math;

import 'package:flutter/material.dart';

class SixMobileAnimatedGradientBackground extends StatefulWidget {
  const SixMobileAnimatedGradientBackground({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor = const Color(0xFFF4F7FB),
    this.primaryColor = const Color(0xFF0B1F3A),
    this.secondaryColor = const Color(0xFF123B69),
    this.accentColor = const Color(0xFF2563EB),
  });

  final Widget child;
  final bool enabled;
  final Color baseColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  @override
  State<SixMobileAnimatedGradientBackground> createState() =>
      _SixMobileAnimatedGradientBackgroundState();
}

class _SixMobileAnimatedGradientBackgroundState
    extends State<SixMobileAnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  @override
  void didUpdateWidget(
    covariant SixMobileAnimatedGradientBackground oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    _syncAnimationState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimationState() {
    if (widget.enabled && !_reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: widget.baseColor),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (widget.enabled && !_reduceMotion)
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: _SixAmbientGradientPainter(
                    progress: _controller.value,
                    baseColor: widget.baseColor,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                    accentColor: widget.accentColor,
                  ),
                );
              },
            )
          else
            CustomPaint(
              painter: _SixAmbientGradientPainter(
                progress: 0,
                baseColor: widget.baseColor,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
                accentColor: widget.accentColor,
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _SixAmbientGradientPainter extends CustomPainter {
  const _SixAmbientGradientPainter({
    required this.progress,
    required this.baseColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  final double progress;
  final Color baseColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Color midBlue = Color.lerp(primaryColor, secondaryColor, 0.55)!;
    final Color softBlue = Color.lerp(secondaryColor, baseColor, 0.74)!;

    final Paint basePaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              primaryColor,
              midBlue.withOpacity(0.86),
              softBlue,
              baseColor,
              Colors.white,
            ],
            stops: const <double>[0, 0.18, 0.48, 0.78, 1],
          ).createShader(rect);

    canvas.drawRect(rect, basePaint);

    _paintMovingBlob(
      canvas,
      size,
      color: secondaryColor.withOpacity(0.30),
      radiusFactor: 0.72,
      x: 0.20 + 0.18 * math.sin(progress * math.pi * 2),
      y: 0.18 + 0.08 * math.cos(progress * math.pi * 2 + 0.7),
    );

    _paintMovingBlob(
      canvas,
      size,
      color: accentColor.withOpacity(0.16),
      radiusFactor: 0.78,
      x: 0.88 + 0.16 * math.sin(progress * math.pi * 2 + 1.9),
      y: 0.34 + 0.10 * math.cos(progress * math.pi * 2 + 1.3),
    );

    _paintMovingBlob(
      canvas,
      size,
      color: Colors.white.withOpacity(0.30),
      radiusFactor: 0.88,
      x: 0.48 + 0.14 * math.sin(progress * math.pi * 2 + 3.2),
      y: 0.66 + 0.08 * math.cos(progress * math.pi * 2 + 2.4),
    );

    _paintMovingBlob(
      canvas,
      size,
      color: primaryColor.withOpacity(0.12),
      radiusFactor: 0.58,
      x: 0.74 + 0.10 * math.sin(progress * math.pi * 2 + 4.1),
      y: 0.10 + 0.06 * math.cos(progress * math.pi * 2 + 3.8),
    );
  }

  void _paintMovingBlob(
    Canvas canvas,
    Size size, {
    required Color color,
    required double radiusFactor,
    required double x,
    required double y,
  }) {
    final double shortestSide = math.min(size.width, size.height);
    final double radius = shortestSide * radiusFactor;
    final Offset center = Offset(size.width * x, size.height * y);

    final Paint paint =
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              color,
              color.withOpacity(color.opacity * 0.42),
              color.withOpacity(0),
            ],
            stops: const <double>[0, 0.46, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SixAmbientGradientPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        baseColor != oldDelegate.baseColor ||
        primaryColor != oldDelegate.primaryColor ||
        secondaryColor != oldDelegate.secondaryColor ||
        accentColor != oldDelegate.accentColor;
  }
}
