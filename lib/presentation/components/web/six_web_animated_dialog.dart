import 'dart:ui';

import 'package:flutter/material.dart';

Future<T?> showSixWebAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String barrierLabel = 'Fechar diálogo',
  Color overlayColor = const Color(0x8A0B1324),
  double overlayBlurSigma = 12,
  Duration transitionDuration = const Duration(milliseconds: 320),
  EdgeInsets padding = const EdgeInsets.all(24),
}) {
  assert(overlayBlurSigma >= 0);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: Colors.transparent,
    transitionDuration: transitionDuration,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _SixWebAnimatedDialogFrame(
        animation: animation,
        overlayColor: overlayColor,
        overlayBlurSigma: overlayBlurSigma,
        padding: padding,
        barrierDismissible: barrierDismissible,
        onDismiss:
            barrierDismissible
                ? () => Navigator.of(dialogContext).maybePop()
                : null,
        child: Builder(builder: builder),
      );
    },
  );
}

class _SixWebAnimatedDialogFrame extends StatelessWidget {
  const _SixWebAnimatedDialogFrame({
    required this.animation,
    required this.overlayColor,
    required this.overlayBlurSigma,
    required this.padding,
    required this.barrierDismissible,
    required this.child,
    this.onDismiss,
  });

  final Animation<double> animation;
  final Color overlayColor;
  final double overlayBlurSigma;
  final EdgeInsets padding;
  final bool barrierDismissible;
  final VoidCallback? onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: curvedAnimation,
        child: child,
        builder: (context, dialogChild) {
          final progress = curvedAnimation.value;
          final tint = Color.lerp(Colors.transparent, overlayColor, progress)!;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: barrierDismissible ? onDismiss : null,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: overlayBlurSigma * progress,
                        sigmaY: overlayBlurSigma * progress,
                      ),
                      child: ColoredBox(color: tint),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: padding,
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, (1 - progress) * 26),
                        child: Transform.scale(
                          scale: 0.965 + (0.035 * progress),
                          child: dialogChild,
                        ),
                      ),
                    ),
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
