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

    final Paint basePaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              primaryColor,
              Color.lerp(primaryColor, secondaryColor, 0.52)!.withOpacity(0.82),
              Color.lerp(secondaryColor, baseColor, 0.76)!,
              baseColor,
              Colors.white,
            ],
            stops: const <double>[0, 0.18, 0.46, 0.78, 1],
          ).createShader(rect);

    canvas.drawRect(rect, basePaint);

    _paintWave(
      canvas,
      size,
      color: Colors.white.withOpacity(0.16),
      amplitude: 18,
      yFactor: 0.22,
      speed: 1,
      thickness: 120,
    );

    _paintWave(
      canvas,
      size,
      color: accentColor.withOpacity(0.085),
      amplitude: 14,
      yFactor: 0.36,
      speed: -0.7,
      thickness: 150,
    );

    _paintWave(
      canvas,
      size,
      color: Colors.white.withOpacity(0.12),
      amplitude: 12,
      yFactor: 0.54,
      speed: 0.55,
      thickness: 180,
    );

    _paintSoftOrb(
      canvas,
      size,
      color: primaryColor.withOpacity(0.10),
      radiusFactor: 0.72,
      x: 0.16 + 0.06 * math.sin(progress * math.pi * 2),
      y: 0.12 + 0.03 * math.cos(progress * math.pi * 2),
    );

    _paintSoftOrb(
      canvas,
      size,
      color: secondaryColor.withOpacity(0.075),
      radiusFactor: 0.82,
      x: 0.88 + 0.05 * math.sin(progress * math.pi * 2 + 1.4),
      y: 0.34 + 0.04 * math.cos(progress * math.pi * 2 + 1.1),
    );
  }

  void _paintWave(
    Canvas canvas,
    Size size, {
    required Color color,
    required double amplitude,
    required double yFactor,
    required double speed,
    required double thickness,
  }) {
    final double phase = progress * math.pi * 2 * speed;
    final double baseY = size.height * yFactor;
    final Path path = Path()..moveTo(0, baseY);

    for (double x = 0; x <= size.width; x += 8) {
      final double normalizedX = x / size.width;
      final double y =
          baseY +
          math.sin((normalizedX * math.pi * 2.2) + phase) * amplitude +
          math.sin((normalizedX * math.pi * 4.1) - phase * 0.55) *
              amplitude *
              0.35;
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, baseY + thickness)
      ..lineTo(0, baseY + thickness * 0.72)
      ..close();

    final Paint paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[color, color.withOpacity(0)],
          ).createShader(
            Rect.fromLTWH(0, baseY - amplitude, size.width, thickness),
          );

    canvas.drawPath(path, paint);
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
