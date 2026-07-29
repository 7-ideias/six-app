import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<T?> showAppModalSideSheet<T>({
  required BuildContext context,
  required Widget child,
  String barrierLabel = 'Fechar painel',
}) {
  final bool reduceMotion =
      !kIsWeb && (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  return Navigator.of(context).push<T>(
    _AppModalSideSheetRoute<T>(
      barrierLabelText: barrierLabel,
      reduceMotion: reduceMotion,
      child: child,
    ),
  );
}

class _AppModalSideSheetRoute<T> extends PageRoute<T> {
  _AppModalSideSheetRoute({
    required this.child,
    required this.barrierLabelText,
    required this.reduceMotion,
  });

  final Widget child;
  final String barrierLabelText;
  final bool reduceMotion;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String get barrierLabel => barrierLabelText;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      kIsWeb
          ? const Duration(milliseconds: 340)
          : reduceMotion
          ? const Duration(milliseconds: 180)
          : const Duration(milliseconds: 500);

  @override
  Duration get reverseTransitionDuration =>
      kIsWeb
          ? const Duration(milliseconds: 260)
          : reduceMotion
          ? const Duration(milliseconds: 140)
          : const Duration(milliseconds: 360);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _AppModalSideSheetPage(
      routeAnimation: animation,
      barrierLabel: barrierLabelText,
      child: child,
    );
  }
}

class _AppModalSideSheetPage extends StatefulWidget {
  const _AppModalSideSheetPage({
    required this.routeAnimation,
    required this.barrierLabel,
    required this.child,
  });

  final Animation<double> routeAnimation;
  final String barrierLabel;
  final Widget child;

  @override
  State<_AppModalSideSheetPage> createState() => _AppModalSideSheetPageState();
}

class _AppModalSideSheetPageState extends State<_AppModalSideSheetPage> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'AppModalSideSheet');
  double _dragExtent = 0;
  bool _closing = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double _resolvePanelWidth(double screenWidth) {
    if (screenWidth < 360) return screenWidth * 0.92;
    if (screenWidth < 600) return (screenWidth * 0.9).clamp(0, 420);
    return (screenWidth * 0.42).clamp(400, 460);
  }

  double _curvedWebRouteValue(AnimationStatus status, double value) {
    final Curve curve =
        status == AnimationStatus.reverse
            ? Curves.easeInCubic
            : Curves.easeOutCubic;
    return curve.transform(value.clamp(0.0, 1.0));
  }

  double _openingProgress(double value, bool reduceMotion) {
    final double t = value.clamp(0.0, 1.0);
    if (reduceMotion) return Curves.easeOutCubic.transform(t);

    return Curves.easeOutCubic.transform(t);
  }

  double _closingProgress(double value, bool reduceMotion) {
    final double t = value.clamp(0.0, 1.0);
    if (reduceMotion) return Curves.easeInCubic.transform(t);

    return Curves.easeInQuart.transform(t);
  }

  double _panelProgress({
    required AnimationStatus status,
    required double value,
    required bool reduceMotion,
  }) {
    if (status == AnimationStatus.reverse) {
      return _closingProgress(value, reduceMotion);
    }

    return _openingProgress(value, reduceMotion);
  }

  double _panelOpacity(double progress, bool reduceMotion) {
    if (reduceMotion) return progress;
    return _transformClamped(Curves.easeOutCubic, progress / 0.58);
  }

  double _transformClamped(Curve curve, double value) {
    return curve.transform(value.clamp(0.0, 1.0));
  }

  double _panelScale(double progress, bool reduceMotion) {
    if (reduceMotion) return lerpDouble(0.985, 1, progress)!;

    if (progress < 0.84) {
      final double eased = _transformClamped(
        Curves.easeOutCubic,
        progress / 0.84,
      );
      return lerpDouble(0.92, 1.006, eased)!;
    }

    final double settle = _transformClamped(
      Curves.easeOutCubic,
      (progress - 0.84) / 0.16,
    );
    return lerpDouble(1.006, 1, settle)!;
  }

  double _panelRotationZ(double progress, bool reduceMotion) {
    if (reduceMotion) return 0;

    final double t = _transformClamped(Curves.easeOutCubic, progress / 0.86);
    return lerpDouble(-0.022, 0, t)!;
  }

  double _panelRotationY(double progress, bool reduceMotion) {
    if (reduceMotion) return 0;

    final double t = _transformClamped(Curves.easeOutCubic, progress / 0.86);
    return lerpDouble(0.045, 0, t)!;
  }

  List<BoxShadow> _panelShadow(
    BuildContext context,
    double progress,
    bool reduceMotion,
  ) {
    final Color shadowColor = Theme.of(context).colorScheme.shadow;
    final double lift =
        reduceMotion ? progress : Curves.easeOutCubic.transform(progress);

    return <BoxShadow>[
      BoxShadow(
        color: shadowColor.withValues(alpha: lerpDouble(0.08, 0.24, lift)!),
        blurRadius: lerpDouble(16, 38, lift)!,
        spreadRadius: lerpDouble(0, 2, lift)!,
        offset: Offset(lerpDouble(-4, -16, lift)!, lerpDouble(8, 24, lift)!),
      ),
    ];
  }

  Matrix4 _panelTransform({
    required double progress,
    required bool reduceMotion,
  }) {
    final double x = lerpDouble(reduceMotion ? 28 : 96, 0, progress)!;
    final double y = lerpDouble(reduceMotion ? -8 : -34, 0, progress)!;
    final double scale = _panelScale(progress, reduceMotion);

    final Matrix4 matrix = Matrix4.identity();
    if (!reduceMotion) {
      matrix.setEntry(3, 2, 0.0008);
    }

    return matrix
      ..translateByDouble(x, y, 0, 1)
      ..rotateY(_panelRotationY(progress, reduceMotion))
      ..rotateZ(_panelRotationZ(progress, reduceMotion))
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _close(BuildContext context) {
    if (_closing) return;

    _closing = true;
    Navigator.of(context).maybePop().whenComplete(() {
      if (mounted) {
        _closing = false;
      }
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, double panelWidth) {
    if (details.primaryDelta == null) return;

    setState(() {
      _dragExtent = (_dragExtent + details.primaryDelta!).clamp(0, panelWidth);
    });
  }

  void _handleDragEnd(DragEndDetails details, double panelWidth) {
    final double velocity = details.primaryVelocity ?? 0;
    final bool shouldClose = _dragExtent > panelWidth * 0.28 || velocity > 620;

    if (shouldClose) {
      _close(context);
      return;
    }

    setState(() => _dragExtent = 0);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _close(context);
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Size screenSize = MediaQuery.sizeOf(context);
              final double panelWidth = _resolvePanelWidth(screenSize.width);

              return AnimatedBuilder(
                animation: widget.routeAnimation,
                builder: (BuildContext context, Widget? child) {
                  final AnimationStatus status = widget.routeAnimation.status;
                  final double routeAnimationValue =
                      widget.routeAnimation.value;
                  final double routeValue =
                      kIsWeb
                          ? _curvedWebRouteValue(status, routeAnimationValue)
                          : _panelProgress(
                            status: status,
                            value: routeAnimationValue,
                            reduceMotion: reduceMotion,
                          );
                  final double dragProgress = (_dragExtent / panelWidth).clamp(
                    0.0,
                    1.0,
                  );
                  final double visibility = (routeValue * (1 - dragProgress))
                      .clamp(0.0, 1.0);
                  final double panelOffset =
                      kIsWeb ? panelWidth * (1 - visibility) : 0;

                  return Material(
                    type: MaterialType.transparency,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Semantics(
                          label: widget.barrierLabel,
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _close(context),
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX:
                                      kIsWeb
                                          ? 4 * visibility
                                          : (reduceMotion ? 0 : 3 * visibility),
                                  sigmaY:
                                      kIsWeb
                                          ? 4 * visibility
                                          : (reduceMotion ? 0 : 3 * visibility),
                                ),
                                child: ColoredBox(
                                  color: colorScheme.scrim.withValues(
                                    alpha:
                                        kIsWeb
                                            ? 0.38 * visibility
                                            : 0.30 * visibility,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: -panelOffset,
                          bottom: 0,
                          width: panelWidth,
                          child: _buildPanelTransition(
                            context: context,
                            child: child!,
                            visibility: visibility,
                            reduceMotion: reduceMotion,
                            panelWidth: panelWidth,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: widget.child,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPanelTransition({
    required BuildContext context,
    required Widget child,
    required double visibility,
    required bool reduceMotion,
    required double panelWidth,
  }) {
    if (kIsWeb) {
      return FadeTransition(
        opacity: widget.routeAnimation.drive(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        child: GestureDetector(
          onHorizontalDragUpdate:
              (DragUpdateDetails details) =>
                  _handleDragUpdate(details, panelWidth),
          onHorizontalDragEnd:
              (DragEndDetails details) => _handleDragEnd(details, panelWidth),
          child: child,
        ),
      );
    }

    return Opacity(
      opacity: _panelOpacity(visibility, reduceMotion),
      child: Transform(
        alignment: Alignment.topRight,
        transform: _panelTransform(
          progress: visibility,
          reduceMotion: reduceMotion,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(24),
            ),
            boxShadow: _panelShadow(context, visibility, reduceMotion),
          ),
          child: GestureDetector(
            onHorizontalDragUpdate:
                (DragUpdateDetails details) =>
                    _handleDragUpdate(details, panelWidth),
            onHorizontalDragEnd:
                (DragEndDetails details) => _handleDragEnd(details, panelWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
