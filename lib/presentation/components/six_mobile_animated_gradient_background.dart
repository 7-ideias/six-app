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
    final Paint basePaint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, basePaint);

    _paintSoftOrb(
      canvas,
      size,
      color: primaryColor.withOpacity(0.032),
      radiusFactor: 0.72,
      x: 0.20 + 0.10 * math.sin(progress * math.pi * 2),
      y: 0.08 + 0.05 * math.cos(progress * math.pi * 2),
    );

    _paintSoftOrb(
      canvas,
      size,
      color: secondaryColor.withOpacity(0.028),
      radiusFactor: 0.86,
      x: 0.84 + 0.08 * math.sin(progress * math.pi * 2 + 1.4),
      y: 0.34 + 0.07 * math.cos(progress * math.pi * 2 + 1.1),
    );

    _paintSoftOrb(
      canvas,
      size,
      color: accentColor.withOpacity(0.024),
      radiusFactor: 0.64,
      x: 0.42 + 0.12 * math.sin(progress * math.pi * 2 + 2.6),
      y: 0.96 + 0.05 * math.cos(progress * math.pi * 2 + 2.2),
    );
  }

  void _paintSoftOrb(
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
            colors: <Color>[color, color.withOpacity(0)],
            stops: const <double>[0, 1],
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
