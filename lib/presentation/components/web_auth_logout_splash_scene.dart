import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WebAuthLogoutSplashScene extends StatefulWidget {
  const WebAuthLogoutSplashScene({super.key});

  @override
  State<WebAuthLogoutSplashScene> createState() => _WebAuthLogoutSplashSceneState();
}

class _WebAuthLogoutSplashSceneState extends State<WebAuthLogoutSplashScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bool isCompact = width < 640;
        final double logoSize = (isCompact ? width * 0.42 : 210)
            .clamp(118.0, isCompact ? 168.0 : 220.0)
            .toDouble();
        final double panelPadding = isCompact ? 28.0 : 44.0;
        final double panelMaxWidth = isCompact ? 400.0 : 520.0;
        final double backgroundMarkSize = (isCompact ? width * 0.84 : width * 0.26)
            .clamp(isCompact ? 210.0 : 260.0, isCompact ? 360.0 : 460.0)
            .toDouble();

        return AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, _) {
            final double progress = _backgroundController.value;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + progress * 0.38, -1),
                  end: Alignment(1, 1 - progress * 0.28),
                  colors: <Color>[
                    Color.lerp(_LogoutSplashPalette.navy950, _LogoutSplashPalette.navy900, progress)!,
                    Color.lerp(_LogoutSplashPalette.navy900, _LogoutSplashPalette.blue900, progress)!,
                    Color.lerp(_LogoutSplashPalette.blue800, _LogoutSplashPalette.navy950, progress)!,
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LogoutBackgroundPainter(
                        progress: progress,
                        compact: isCompact,
                      ),
                    ),
                  ),
                  _LogoutBackgroundWatermark(
                    size: backgroundMarkSize,
                    progress: progress,
                  ),
                  _LogoutGlowOrb(
                    diameter: isCompact ? 210 : 360,
                    left: -60 + progress * 28,
                    top: isCompact ? 48 : 86,
                    opacity: 0.24,
                  ),
                  _LogoutGlowOrb(
                    diameter: isCompact ? 180 : 300,
                    right: -72 + progress * 34,
                    bottom: isCompact ? 70 : 86,
                    opacity: 0.18,
                  ),
                  Positioned(
                    right: isCompact ? -46 : -34,
                    bottom: isCompact ? 20 : -70,
                    child: IgnorePointer(
                      child: Text(
                        '6',
                        style: TextStyle(
                          color: Colors.white.withOpacity(isCompact ? 0.05 : 0.06),
                          fontSize: isCompact ? 260 : 460,
                          fontWeight: FontWeight.w900,
                          height: 0.86,
                          letterSpacing: -28,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 20 : 40,
                          vertical: 28,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: panelMaxWidth),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(isCompact ? 28 : 36),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 1,
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 56,
                                  offset: Offset(0, 28),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(panelPadding),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _LogoutLogoConstellation(
                                    size: logoSize,
                                    progress: progress,
                                  ),
                                  SizedBox(height: isCompact ? 30 : 38),
                                  _LogoutProgressDots(compact: isCompact),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 520.ms, curve: Curves.easeOut)
                              .slideY(
                                begin: 0.045,
                                end: 0,
                                duration: 640.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LogoutBackgroundWatermark extends StatelessWidget {
  const _LogoutBackgroundWatermark({
    required this.size,
    required this.progress,
  });

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0.05, -0.02),
          child: Opacity(
            opacity: 0.10,
            child: Transform.scale(
              scale: 1.9,
              child: _LogoutLogoConstellation(size: size, progress: progress),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutLogoConstellation extends StatelessWidget {
  const _LogoutLogoConstellation({
    required this.size,
    required this.progress,
  });

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final double orbitRadius = size * 0.64;
    final double dotSize = (size * 0.055).clamp(6.0, 10.0).toDouble();

    return SizedBox(
      width: size * 1.72,
      height: size * 1.72,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size * 1.34,
            height: size * 1.34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  Colors.white.withOpacity(0.24),
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.00),
                ],
              ),
            ),
          ),
          for (int index = 0; index < 6; index++)
            Transform.translate(
              offset: Offset.fromDirection(
                (math.pi * 2 * index / 6) - (progress * math.pi * 0.22),
                orbitRadius,
              ),
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(index.isEven ? 0.82 : 0.52),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.white.withOpacity(0.34),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                    delay: (index * 90).ms,
                  )
                  .scale(
                    begin: const Offset(0.74, 0.74),
                    end: const Offset(1.16, 1.16),
                    duration: 860.ms,
                    curve: Curves.easeInOut,
                  ),
            ),
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.84),
                width: 1.2,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/six-logo-flecha.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          )
              .animate()
              .fadeIn(duration: 620.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.88, 0.88),
                end: const Offset(1, 1),
                duration: 820.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}

class _LogoutProgressDots extends StatelessWidget {
  const _LogoutProgressDots({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double dotSize = compact ? 7.0 : 8.0;

    return Semantics(
      label: 'Six',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: compact ? 8 : 10,
        runSpacing: 8,
        children: List.generate(6, (int index) {
          return Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(999),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.white.withOpacity(0.26),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
                delay: (index * 110).ms,
              )
              .scale(
                begin: const Offset(0.74, 1),
                end: Offset(index == 0 ? 2.2 : 1.45, 1),
                duration: 760.ms,
                curve: Curves.easeInOutCubic,
              )
              .fade(
                begin: 0.42,
                end: 1,
                duration: 760.ms,
                curve: Curves.easeInOut,
              );
        }),
      ),
    );
  }
}

class _LogoutGlowOrb extends StatelessWidget {
  const _LogoutGlowOrb({
    required this.diameter,
    required this.opacity,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  final double diameter;
  final double opacity;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                Colors.white.withOpacity(opacity),
                _LogoutSplashPalette.blue600.withOpacity(opacity * 0.44),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutBackgroundPainter extends CustomPainter {
  const _LogoutBackgroundPainter({
    required this.progress,
    required this.compact,
  });

  final double progress;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.8 : 1.1;

    for (int index = 0; index < 6; index++) {
      final double dx = size.width * (0.12 + index * 0.16) +
          math.sin(progress * math.pi + index) * 12;
      final double dy = size.height * (index.isEven ? 0.20 : 0.72) +
          math.cos(progress * math.pi + index) * 18;
      final double radius = (compact ? 36.0 : 58.0) + index * (compact ? 8 : 12);
      strokePaint.color = Colors.white.withOpacity(0.030 + index * 0.006);
      canvas.drawCircle(Offset(dx, dy), radius, strokePaint);
    }

    final Paint wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.1 : 1.4
      ..color = Colors.white.withOpacity(0.07);

    final Path wave = Path();
    final double baseY = size.height * (compact ? 0.66 : 0.58);
    for (double x = -20; x <= size.width + 20; x += 18) {
      final double y = baseY +
          math.sin((x / 96) + progress * math.pi * 2) * (compact ? 10 : 16);
      if (x == -20) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }
    canvas.drawPath(wave, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _LogoutBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.compact != compact;
  }
}

class _LogoutSplashPalette {
  const _LogoutSplashPalette._();

  static const Color navy950 = Color(0xFF03111F);
  static const Color navy900 = Color(0xFF06243A);
  static const Color blue900 = Color(0xFF0A3555);
  static const Color blue800 = Color(0xFF0F4C75);
  static const Color blue600 = Color(0xFF2B8FDB);
}
