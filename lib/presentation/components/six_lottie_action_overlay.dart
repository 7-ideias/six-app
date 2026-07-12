import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/six_animation_assets.dart';

/// Overlay reutilizável para bloquear a tela durante uma ação assíncrona.
///
/// O asset, os textos, as dimensões e o efeito de fundo podem ser substituídos
/// sem alterar a tela que dispara a operação.
class SixLottieActionOverlay extends StatelessWidget {
  const SixLottieActionOverlay({
    super.key,
    required this.isLoading,
    required this.title,
    required this.child,
    this.subtitle,
    this.animationAsset = SixAnimationAssets.saleProcessing,
    this.animationSize = 156,
    this.backgroundBlurSigma = 8,
    this.barrierColor = const Color(0x66000000),
  }) : assert(backgroundBlurSigma >= 0);

  final bool isLoading;
  final String title;
  final String? subtitle;
  final Widget child;
  final String animationAsset;
  final double animationSize;

  /// Intensidade do desfoque aplicado em todo o conteúdo abaixo do overlay.
  final double backgroundBlurSigma;

  /// Cor aplicada sobre o conteúdo desfocado para reforçar o foco na ação.
  final Color barrierColor;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          child,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !isLoading,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                reverseDuration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isLoading
                    ? _buildOverlay(context)
                    : const SizedBox.shrink(
                        key: ValueKey<String>('six-action-overlay-hidden'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String normalizedSubtitle = subtitle?.trim() ?? '';
    final String semanticsLabel = normalizedSubtitle.isEmpty
        ? title
        : '$title. $normalizedSubtitle';

    return ClipRect(
      key: const ValueKey<String>('six-action-overlay-visible'),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: backgroundBlurSigma,
          sigmaY: backgroundBlurSigma,
        ),
        child: ColoredBox(
          color: barrierColor,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Material(
                    color: theme.colorScheme.surface,
                    elevation: 18,
                    shadowColor: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(28),
                    clipBehavior: Clip.antiAlias,
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      label: semanticsLabel,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Lottie.asset(
                              animationAsset,
                              width: animationSize,
                              height: animationSize,
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (normalizedSubtitle.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                normalizedSubtitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
