import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SixWebSplashScene extends StatefulWidget {
  const SixWebSplashScene({
    super.key,
    this.title,
    this.subtitle,
    this.semanticLabel = 'Six',
  });

  final String? title;
  final String? subtitle;
  final String semanticLabel;

  @override
  State<SixWebSplashScene> createState() => _SixWebSplashSceneState();
}

class _SixWebSplashSceneState extends State<SixWebSplashScene>
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final bool isCompact = width < 640;
        final double horizontalPadding = isCompact ? 20.0 : 40.0;
        final double brandSize = _clampDouble(
          isCompact ? width * 0.42 : 210,
          118,
          isCompact ? 168 : 220,
        );
        final double panelPadding = isCompact ? 28.0 : 44.0;
        final double panelMaxWidth = isCompact ? 400.0 : 520.0;
        final double backgroundMarkSize = _clampDouble(
          isCompact ? width * 0.84 : width * 0.26,
          isCompact ? 210 : 260,
          isCompact ? 360 : 460,
        );

        return AnimatedBuilder(
          animation: _backgroundController,
          builder: (BuildContext context, Widget? child) {
            final double progress = _backgroundController.value;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + progress * 0.42, -1),
                  end: Alignment(1, 1 - progress * 0.34),
                  colors: <Color>[
                    Color.lerp(
                      _SixWebSplashPalette.navy950,
                      _SixWebSplashPalette.navy900,
                      progress,
                    )!,
                    Color.lerp(
                      _SixWebSplashPalette.navy900,
                      _SixWebSplashPalette.blue900,
                      progress,
                    )!,
                    Color.lerp(
                      _SixWebSplashPalette.blue800,
                      _SixWebSplashPalette.navy950,
                      progress,
                    )!,
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SixSplashBackgroundPainter(
                        progress: progress,
                        compact: isCompact,
                      ),
                    ),
                  ),
                  _SplashBackgroundWatermark(
                    size: backgroundMarkSize,
                    progress: progress,
                    opacity: 0.08,
                  ),
                  _GlowOrb(
                    diameter: isCompact ? 210 : 360,
                    left: -60 + progress * 28,
                    top: isCompact ? 48 : 86,
                    opacity: 0.22,
                  ),
                  _GlowOrb(
                    diameter: isCompact ? 180 : 300,
                    right: -72 + progress * 34,
                    bottom: isCompact ? 70 : 86,
                    opacity: 0.16,
                  ),
                  Positioned(
                    right: isCompact ? -46 : -34,
                    bottom: isCompact ? 20 : -70,
                    child: IgnorePointer(
                      child: Text(
                        '6',
                        style: TextStyle(
                          color: Colors.white.withOpacity(
                            isCompact ? 0.045 : 0.055,
                          ),
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
                          horizontal: horizontalPadding,
                          vertical: 28,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: panelMaxWidth),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.085),
                              borderRadius: BorderRadius.circular(
                                isCompact ? 28 : 36,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 1,
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x30000000),
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
                                  _SixLogoConstellation(
                                    size: brandSize,
                                    progress: progress,
                                    semanticLabel: widget.semanticLabel,
                                  ),
                                  if (_hasText(widget.title)) ...<Widget>[
                                    SizedBox(height: isCompact ? 24 : 30),
                                    Text(
                                      widget.title!.trim(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isCompact ? 19 : 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                  if (_hasText(widget.subtitle)) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.subtitle!.trim(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.76),
                                        fontSize: isCompact ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: isCompact ? 30 : 38),
                                  _SixProgressDots(compact: isCompact),
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

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  double _clampDouble(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}

class _SplashBackgroundWatermark extends StatelessWidget {
  const _SplashBackgroundWatermark({
    required this.size,
    required this.progress,
    required this.opacity,
  });

  final double size;
  final double progress;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0.05, -0.02),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: 1.9,
              child: _SixWordmark(
                size: size,
                compact: false,
                watermark: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SixLogoConstellation extends StatelessWidget {
  const _SixLogoConstellation({
    required this.size,
    required this.progress,
    required this.semanticLabel,
  });

  final double size;
  final double progress;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final double orbitRadius = size * 0.56;
    final double dotSize = _clamp(size * 0.048, 5.5, 9);

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size * 1.72,
        height: size * 1.40,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: size * 1.42,
              height: size * 0.92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.34),
                gradient: RadialGradient(
                  colors: <Color>[
                    Colors.white.withOpacity(0.22),
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.00),
                  ],
                ),
              ),
            ),
            for (int index = 0; index < 6; index++)
              Transform.translate(
                offset: Offset.fromDirection(
                  (math.pi * 2 * index / 6) + (progress * math.pi * 0.22),
                  orbitRadius,
                ),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(index.isEven ? 0.82 : 0.48),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withOpacity(0.28),
                        blurRadius: 16,
                        spreadRadius: 1.4,
                      ),
                    ],
                  ),
                )
                    .animate(
                      onPlay: (AnimationController controller) =>
                          controller.repeat(reverse: true),
                      delay: (index * 90).ms,
                    )
                    .scale(
                      begin: const Offset(0.74, 0.74),
                      end: const Offset(1.16, 1.16),
                      duration: 860.ms,
                      curve: Curves.easeInOut,
                    ),
              ),
            _SixWordmark(size: size, compact: size < 150)
                .animate()
                .fadeIn(duration: 620.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1, 1),
                  duration: 820.ms,
                  curve: Curves.easeOutBack,
                ),
          ],
        ),
      ),
    );
  }

  double _clamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}

class _SixWordmark extends StatelessWidget {
  const _SixWordmark({
    required this.size,
    required this.compact,
    this.watermark = false,
  });

  final double size;
  final bool compact;
  final bool watermark;

  @override
  Widget build(BuildContext context) {
    final double width = watermark ? size * 1.72 : size * 1.10;
    final double height = watermark ? size * 0.62 : size * 0.62;
    final double radius = watermark ? size * 0.20 : size * 0.18;
    final double sixFontSize = watermark ? size * 0.28 : size * 0.24;
    final double posFontSize = watermark ? size * 0.10 : size * 0.078;

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: watermark ? size * 0.16 : size * 0.11,
        vertical: watermark ? size * 0.07 : size * 0.075,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withOpacity(watermark ? 0.14 : 0.18),
            Colors.white.withOpacity(watermark ? 0.04 : 0.07),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(watermark ? 0.14 : 0.34),
          width: watermark ? 0.8 : 1.2,
        ),
        boxShadow: watermark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.10),
                  blurRadius: 22,
                  offset: const Offset(0, -8),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: watermark ? size * 0.16 : size * 0.145,
            height: watermark ? size * 0.16 : size * 0.145,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(watermark ? 0.10 : 0.15),
              border: Border.all(
                color: Colors.white.withOpacity(watermark ? 0.12 : 0.38),
              ),
            ),
            child: Text(
              '6',
              style: TextStyle(
                color: Colors.white.withOpacity(watermark ? 0.42 : 0.92),
                fontSize: watermark ? size * 0.09 : size * 0.082,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: watermark ? size * 0.04 : size * 0.035),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Six',
                style: TextStyle(
                  color: Colors.white.withOpacity(watermark ? 0.38 : 0.94),
                  fontSize: sixFontSize,
                  fontWeight: FontWeight.w900,
                  height: 0.90,
                  letterSpacing: -1.8,
                ),
              ),
              SizedBox(height: watermark ? size * 0.018 : size * 0.012),
              Text(
                'POS',
                style: TextStyle(
                  color: Colors.white.withOpacity(watermark ? 0.25 : 0.68),
                  fontSize: posFontSize,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: watermark ? 4.6 : 3.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SixProgressDots extends StatelessWidget {
  const _SixProgressDots({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double dotSize = compact ? 7.0 : 8.0;

    return Semantics(
      label: 'Carregando',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: compact ? 8 : 10,
        runSpacing: 8,
        children: List<Widget>.generate(6, (int index) {
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
                onPlay: (AnimationController controller) =>
                    controller.repeat(reverse: true),
                delay: (index * 110).ms,
              )
              .scale(
                begin: const Offset(0.74, 1),
                end: Offset(index == 5 ? 2.2 : 1.45, 1),
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
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
                _SixWebSplashPalette.blue600.withOpacity(opacity * 0.44),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SixSplashBackgroundPainter extends CustomPainter {
  const _SixSplashBackgroundPainter({
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
      final double radius =
          (compact ? 36.0 : 58.0) + index * (compact ? 8 : 12);
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
  bool shouldRepaint(covariant _SixSplashBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.compact != compact;
  }
}

class _SixWebSplashPalette {
  const _SixWebSplashPalette._();

  static const Color navy950 = Color(0xFF03111F);
  static const Color navy900 = Color(0xFF06243A);
  static const Color blue900 = Color(0xFF0A3555);
  static const Color blue800 = Color(0xFF0F4C75);
  static const Color blue600 = Color(0xFF2B8FDB);
}
