import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';

class SixWebSplashScene extends StatefulWidget {
  const SixWebSplashScene({
    super.key,
    this.title,
    this.subtitle,
    this.semanticLabel,
  });

  final String? title;
  final String? subtitle;
  final String? semanticLabel;

  @override
  State<SixWebSplashScene> createState() => _SixWebSplashSceneState();
}

class _SixWebSplashSceneState extends State<SixWebSplashScene>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _loopController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..forward();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    if (reduceMotion == _reduceMotion) return;

    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _entryController.value = 1;
      _loopController
        ..stop()
        ..value = 0.42;
    } else {
      if (!_entryController.isCompleted) {
        _entryController.forward();
      }
      if (!_loopController.isAnimating) {
        _loopController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String brandTitle = _resolveText(widget.title, 'SixoApp');
    final String message = _resolveText(
      widget.subtitle,
      context.t(
        'splash.preparingWorkspace',
        fallback: 'Preparando seu espaço...',
      ),
    );
    final String footer = context.t(
      'splash.connectedTagline',
      fallback: 'Tudo conectado. Tudo sob controle.',
    );

    return ColoredBox(
      color: _SixoAppWebSplashColors.navy950,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: widget.semanticLabel ?? '$brandTitle. $message',
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _entryController,
              _loopController,
            ]),
            builder: (BuildContext context, Widget? child) {
              final double entry = Curves.easeOutCubic.transform(
                _entryController.value,
              );
              final double progress = _loopController.value;

              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.08),
                        radius: 1.12,
                        colors: <Color>[
                          _SixoAppWebSplashColors.navy800,
                          _SixoAppWebSplashColors.navy920,
                          _SixoAppWebSplashColors.navy950,
                        ],
                        stops: <double>[0, 0.52, 1],
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _SixoAppWebBackgroundPainter(
                        progress: progress,
                        reduceMotion: _reduceMotion,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        final bool compact = constraints.maxWidth < 680;
                        final bool short = constraints.maxHeight < 650;
                        final double logoSize = math.min(
                          compact
                              ? constraints.maxWidth * 0.46
                              : constraints.maxHeight * 0.32,
                          compact ? 196.0 : 246.0,
                        );
                        final double titleSize = compact ? 42 : 54;

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 24 : 48,
                            vertical: short ? 18 : 30,
                          ),
                          child: Column(
                            children: <Widget>[
                              const Spacer(flex: 4),
                              Opacity(
                                opacity: entry,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - entry) * 18),
                                  child: Transform.scale(
                                    scale:
                                        (0.93 + (entry * 0.07)) *
                                        (_reduceMotion
                                            ? 1.0
                                            : 1.0 +
                                                (math.sin(
                                                      progress * math.pi * 2,
                                                    ) *
                                                    0.008)),
                                    child: _SixoAppWebAnimatedSymbol(
                                      size: logoSize,
                                      progress: progress,
                                      reduceMotion: _reduceMotion,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: short ? 8 : 14),
                              Opacity(
                                opacity: entry,
                                child: Text(
                                  brandTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleSize,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.7,
                                  ),
                                ),
                              ),
                              SizedBox(height: short ? 16 : 24),
                              Text(
                                message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      _SixoAppWebSplashColors.supportingText,
                                  fontSize: compact ? 15 : 17,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: short ? 16 : 22),
                              _SixoAppWebSweepProgress(
                                progress: progress,
                                reduceMotion: _reduceMotion,
                                width: compact ? 224 : 284,
                              ),
                              const Spacer(flex: 3),
                              Text(
                                footer,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _SixoAppWebSplashColors.footerText,
                                  fontSize: compact ? 12 : 14,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _resolveText(String? value, String fallback) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }
}

class _SixoAppWebAnimatedSymbol extends StatelessWidget {
  const _SixoAppWebAnimatedSymbol({
    required this.size,
    required this.progress,
    required this.reduceMotion,
  });

  final double size;
  final double progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  _SixoAppWebSplashColors.electricBlue.withValues(alpha: 0.24),
                  Colors.transparent,
                ],
                stops: const <double>[0, 0.72],
              ),
            ),
          ),
          Image.asset(
            'assets/images/sixoapp_splash_symbol.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          if (!reduceMotion)
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                final double center = -1.45 + (progress * 2.9);
                return LinearGradient(
                  begin: Alignment(center - 0.45, -1),
                  end: Alignment(center + 0.45, 1),
                  colors: const <Color>[
                    Colors.transparent,
                    Color(0xD9FFFFFF),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.36, 0.5, 0.64],
                ).createShader(bounds);
              },
              child: Image.asset(
                'assets/images/sixoapp_splash_symbol.png',
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

class _SixoAppWebSweepProgress extends StatelessWidget {
  const _SixoAppWebSweepProgress({
    required this.progress,
    required this.reduceMotion,
    required this.width,
  });

  final double progress;
  final bool reduceMotion;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 5,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double segmentWidth = constraints.maxWidth * 0.30;
          final double left =
              (reduceMotion ? 0.35 : progress) *
              (constraints.maxWidth - segmentWidth);
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _SixoAppWebSplashColors.progressTrack,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: left,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: <Color>[
                        _SixoAppWebSplashColors.cyan,
                        _SixoAppWebSplashColors.electricBlue,
                      ],
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: Color(0x8010D9F0), blurRadius: 9),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SixoAppWebBackgroundPainter extends CustomPainter {
  const _SixoAppWebBackgroundPainter({
    required this.progress,
    required this.reduceMotion,
  });

  final double progress;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final double phase = reduceMotion ? 0.32 : progress;
    final Paint arcPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _SixoAppWebSplashColors.electricBlue.withValues(
            alpha: 0.13,
          );

    final Path upperArc =
        Path()
          ..moveTo(-size.width * 0.08, size.height * 0.31)
          ..quadraticBezierTo(
            size.width * 0.38,
            -size.height * 0.12,
            size.width * 1.05,
            size.height * 0.18,
          );
    canvas.drawPath(upperArc, arcPaint);

    for (int index = 0; index < 5; index++) {
      final double y = size.height * (0.73 + (index * 0.028));
      final double amplitude = size.height * (0.035 + (index * 0.004));
      final double drift =
          math.sin((phase + index * 0.16) * math.pi * 2) * 8;
      final Path wave =
          Path()
            ..moveTo(-size.width * 0.08, y + drift)
            ..cubicTo(
              size.width * 0.18,
              y - amplitude,
              size.width * 0.31,
              y + amplitude,
              size.width * 0.50,
              y,
            )
            ..cubicTo(
              size.width * 0.70,
              y - amplitude,
              size.width * 0.82,
              y + amplitude,
              size.width * 1.08,
              y - (amplitude * 0.35),
            );
      canvas.drawPath(
        wave,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == 0 ? 1.2 : 0.7
          ..color = _SixoAppWebSplashColors.electricBlue.withValues(
            alpha: index == 0 ? 0.28 : 0.12,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SixoAppWebBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}

abstract final class _SixoAppWebSplashColors {
  const _SixoAppWebSplashColors._();

  static const Color navy950 = Color(0xFF00163A);
  static const Color navy920 = Color(0xFF021D48);
  static const Color navy800 = Color(0xFF063071);
  static const Color cyan = Color(0xFF10D9F0);
  static const Color electricBlue = Color(0xFF145BFF);
  static const Color supportingText = Color(0xFFA8C6EE);
  static const Color footerText = Color(0xFF8FB2E3);
  static const Color progressTrack = Color(0xFF082754);
}
