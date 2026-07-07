import 'dart:math' as math;

import 'package:flutter/material.dart';

class SixMobileAnimatedGradientBackground extends StatefulWidget {
  const SixMobileAnimatedGradientBackground({
    super.key,
    required this.child,
    this.enabled = true,
    this.intensity = 0.45,
    this.baseColor = const Color(0xFFF4F7FB),
    this.primaryColor = const Color(0xFF0B1F3A),
    this.secondaryColor = const Color(0xFF123B69),
    this.accentColor = const Color(0xFF2563EB),
  });

  final Widget child;
  final bool enabled;

  /// Escala de percepção visual: 0.0 = imperceptível, 1.0 = exagerado.
  final double intensity;
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
      duration: const Duration(seconds: 9),
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
                    intensity: widget.intensity,
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
                intensity: widget.intensity,
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
    required this.intensity,
  });

  final double progress;
  final Color baseColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final double i = intensity.clamp(0.0, 1.0);
    final double t = progress * math.pi * 2;

    final Color midBlue = Color.lerp(primaryColor, secondaryColor, 0.50)!;
    final Color softBlue = Color.lerp(secondaryColor, baseColor, 0.70)!;

    final Paint basePaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              primaryColor,
              midBlue.withOpacity(0.90),
              softBlue,
              baseColor,
              Colors.white,
            ],
            stops: const <double>[0, 0.16, 0.42, 0.72, 1],
          ).createShader(rect);

    canvas.drawRect(rect, basePaint);

    // Área 1: topo, próximo ao hero.
    _paintAura(
      canvas,
      size,
      color: accentColor.withOpacity(0.12 + (0.30 * i)),
      radiusFactor: 0.44 + (0.08 * math.sin(t).abs()),
      x: 0.12 + 0.22 * math.sin(t),
      y: 0.15 + 0.05 * math.cos(t * 1.2),
    );

    _paintAura(
      canvas,
      size,
      color: secondaryColor.withOpacity(0.14 + (0.34 * i)),
      radiusFactor: 0.50 + (0.10 * math.sin(t + 1.7).abs()),
      x: 0.82 + 0.18 * math.sin(t + 1.8),
      y: 0.20 + 0.05 * math.cos(t + 0.7),
    );

    // Área 2: entre hero e primeiros cards.
    _paintAura(
      canvas,
      size,
      color: Colors.white.withOpacity(0.18 + (0.50 * i)),
      radiusFactor: 0.64 + (0.12 * math.sin(t + 2.3).abs()),
      x: 0.52 + 0.20 * math.sin(t + 2.3),
      y: 0.34 + 0.05 * math.cos(t * 1.1 + 1.4),
    );

    _paintAura(
      canvas,
      size,
      color: accentColor.withOpacity(0.08 + (0.26 * i)),
      radiusFactor: 0.48 + (0.10 * math.sin(t + 3.1).abs()),
      x: 0.92 + 0.18 * math.sin(t + 3.1),
      y: 0.39 + 0.06 * math.cos(t + 2.4),
    );

    // Área 3: entre blocos de acompanhamento.
    _paintAura(
      canvas,
      size,
      color: Colors.white.withOpacity(0.20 + (0.55 * i)),
      radiusFactor: 0.72 + (0.14 * math.sin(t + 4.2).abs()),
      x: 0.34 + 0.24 * math.sin(t + 4.2),
      y: 0.58 + 0.06 * math.cos(t + 3.5),
    );

    _paintAura(
      canvas,
      size,
      color: secondaryColor.withOpacity(0.06 + (0.18 * i)),
      radiusFactor: 0.54 + (0.10 * math.sin(t + 5.0).abs()),
      x: 0.82 + 0.16 * math.sin(t + 5.0),
      y: 0.62 + 0.05 * math.cos(t + 4.6),
    );
  }

  void _paintAura(
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
              color.withOpacity(color.opacity * 0.72),
              color.withOpacity(color.opacity * 0.28),
              color.withOpacity(0),
            ],
            stops: const <double>[0, 0.32, 0.66, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SixAmbientGradientPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        intensity != oldDelegate.intensity ||
        baseColor != oldDelegate.baseColor ||
        primaryColor != oldDelegate.primaryColor ||
        secondaryColor != oldDelegate.secondaryColor ||
        accentColor != oldDelegate.accentColor;
  }
}
