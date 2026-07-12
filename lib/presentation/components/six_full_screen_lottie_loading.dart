import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Exibe um asset Lottie sobre toda a rota enquanto uma operação está ativa.
///
/// O componente não conhece a origem do carregamento. A tela consumidora deve
/// apenas fornecer [isLoading], mantendo o estado assíncrono fora da camada
/// visual.
class SixFullScreenLottieLoading extends StatelessWidget {
  const SixFullScreenLottieLoading({
    super.key,
    required this.isLoading,
    required this.animationAsset,
    required this.semanticsLabel,
    required this.child,
    this.backgroundColor = const Color(0xFFF4F7FB),
  });

  final bool isLoading;
  final String animationAsset;
  final String semanticsLabel;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: isLoading,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              reverseDuration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isLoading
                  ? _buildLoading()
                  : const SizedBox.shrink(
                      key: ValueKey<String>('full-screen-lottie-hidden'),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Semantics(
      key: const ValueKey<String>('full-screen-lottie-visible'),
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
              Color(0xFFF4F7FB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RepaintBoundary(
          child: Lottie.asset(
            animationAsset,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            repeat: true,
          ),
        ),
      ),
    );
  }
}
