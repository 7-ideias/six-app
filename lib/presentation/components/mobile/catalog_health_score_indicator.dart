import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

class CatalogHealthScoreIndicator extends StatelessWidget {
  const CatalogHealthScoreIndicator({
    super.key,
    required this.percentage,
    required this.statusLabel,
    required this.semanticColorCode,
    required this.attentionLabel,
    required this.reduceMotion,
    this.animationKey,
  });

  final int percentage;
  final String statusLabel;
  final String semanticColorCode;
  final String attentionLabel;
  final bool reduceMotion;
  final Object? animationKey;

  @override
  Widget build(BuildContext context) {
    final int normalizedPercentage = percentage.clamp(0, 100);
    final Color accent = _semanticAccentColor(semanticColorCode);
    final Color statusBackground = Color.alphaBlend(
      accent.withValues(alpha: 0.09),
      SixMobilePalette.surface,
    );
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final double ringSize = textScaler.scale(128).clamp(112.0, 148.0);
    final Duration duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 760);

    return Semantics(
      container: true,
      label: '$normalizedPercentage% de saúde. $statusLabel. $attentionLabel.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            key: ValueKey<String>('$normalizedPercentage-$animationKey'),
            tween: Tween<double>(
              begin: reduceMotion ? normalizedPercentage / 100 : 0,
              end: normalizedPercentage / 100,
            ),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double progress, _) {
              return SizedBox.square(
                dimension: ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CustomPaint(
                      size: Size.square(ringSize),
                      painter: _CatalogHealthRingPainter(
                        progress: progress,
                        accent: accent,
                        track: SixMobilePalette.softAccentSurface,
                        divider: SixMobilePalette.border,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '${(progress * 100).round()}%',
                              maxLines: 1,
                              style: const TextStyle(
                                color: SixMobilePalette.titleText,
                                fontSize: 32,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 104),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusBackground,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.24),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: SixMobilePalette.softNeutralSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.priority_high_rounded,
                  color: accent,
                  size: 16,
                  semanticLabel: null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attentionLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SixMobilePalette.titleText,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogHealthRingPainter extends CustomPainter {
  const _CatalogHealthRingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.divider,
  });

  final double progress;
  final Color accent;
  final Color track;
  final Color divider;

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.shortestSide * 0.095;
    final double inset = strokeWidth / 2;
    final Rect rect =
        Offset(inset, inset) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final Paint trackPaint =
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final Paint progressPaint =
        Paint()
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: math.pi * 1.5,
            colors: <Color>[accent.withValues(alpha: 0.72), accent],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final Paint dividerPaint =
        Paint()
          ..color = divider
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    final double sweep = (math.pi * 2 * progress).clamp(0.0, math.pi * 2);
    if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
    }

    for (int index = 0; index < 4; index += 1) {
      final double angle = -math.pi / 2 + (index * math.pi / 2);
      final Offset center = rect.center;
      final double radius = rect.width / 2;
      final Offset start = Offset(
        center.dx + math.cos(angle) * (radius - strokeWidth * 0.3),
        center.dy + math.sin(angle) * (radius - strokeWidth * 0.3),
      );
      final Offset end = Offset(
        center.dx + math.cos(angle) * (radius + strokeWidth * 0.3),
        center.dy + math.sin(angle) * (radius + strokeWidth * 0.3),
      );
      canvas.drawLine(start, end, dividerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CatalogHealthRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.track != track ||
        oldDelegate.divider != divider;
  }
}

Color _semanticAccentColor(String code) {
  switch (code) {
    case 'VERMELHO':
    case 'CRITICO':
    case 'CRITICA':
      return SixMobilePalette.error;
    case 'AMARELO':
    case 'ALERTA':
    case 'ATENCAO':
      return const Color(0xFFB7791F);
    case 'VERDE':
    case 'SAUDAVEL':
      return const Color(0xFF0F766E);
    case 'AZUL':
      return SixMobilePalette.accent;
    default:
      return SixMobilePalette.primary;
  }
}
