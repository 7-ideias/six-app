import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

Future<void> showSixWebSettingsDialog({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _SixWebSettingsDialogRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        semanticsLabel: routeContext.t(
          'web.navigation.settings',
          fallback: 'Configurações',
        ),
        child: Builder(builder: builder),
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => child,
  );
}

class _DismissDialogIntent extends Intent {
  const _DismissDialogIntent();
}

class _SixWebSettingsDialogRouteSurface extends StatelessWidget {
  const _SixWebSettingsDialogRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.semanticsLabel,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final String semanticsLabel;
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
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): _DismissDialogIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _DismissDialogIntent: CallbackAction<_DismissDialogIntent>(
              onInvoke: (_DismissDialogIntent intent) {
                Navigator.of(context).maybePop();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: AnimatedBuilder(
              animation: curvedAnimation,
              child: child,
              builder: (BuildContext context, Widget? dialogChild) {
                final double progress = curvedAnimation.value;
                final double overlayAlpha =
                    Theme.of(context).brightness == Brightness.dark
                        ? 0.78
                        : 0.68;
                final Color overlayColor =
                    Color.lerp(
                      Colors.transparent,
                      const Color(0xFF0B1324).withValues(alpha: overlayAlpha),
                      progress,
                    )!;

                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).maybePop(),
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(
                              sigmaX: 12 * progress,
                              sigmaY: 12 * progress,
                            ),
                            child: ColoredBox(color: overlayColor),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Opacity(
                            opacity: progress,
                            child: Transform.translate(
                              offset: Offset(0, (1 - progress) * 28),
                              child: Transform.scale(
                                scale:
                                    reduceMotion ? 1 : 0.96 + (0.04 * progress),
                                child: Semantics(
                                  namesRoute: true,
                                  label: semanticsLabel,
                                  child: _SixWebSettingsDialogShell(
                                    reduceMotion: reduceMotion,
                                    child:
                                        dialogChild ?? const SizedBox.shrink(),
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }
}

class _SixWebSettingsDialogShell extends StatefulWidget {
  const _SixWebSettingsDialogShell({
    required this.child,
    required this.reduceMotion,
  });

  final Widget child;
  final bool reduceMotion;

  @override
  State<_SixWebSettingsDialogShell> createState() =>
      _SixWebSettingsDialogShellState();
}

class _SixWebSettingsDialogShellState extends State<_SixWebSettingsDialogShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _badgeController;

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.reduceMotion) {
        _badgeController.value = 1;
      } else {
        _badgeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final double maxWidth = size.width >= 1800 ? 1760 : size.width * 0.94;
    final double maxHeight = size.height >= 1080 ? 980 : size.height * 0.92;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            minWidth: size.width >= 1120 ? 960 : 0,
          ),
          child: DecoratedBox(
            key: const ValueKey<String>('six-settings-dialog-surface'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: tokens.cardBorder.withValues(alpha: 0.88),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF020617).withValues(alpha: 0.36),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: tokens.surfaceElevated.withValues(alpha: 0.98),
                surfaceTintColor: Colors.transparent,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        color: tokens.info.withValues(alpha: 0.92),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              tokens.info.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: maxWidth,
                      height: maxHeight,
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -18,
          left: 28,
          child: _SettingsBadge(
            animation: _badgeController,
            reduceMotion: widget.reduceMotion,
          ),
        ),
      ],
    );
  }
}

class _SettingsBadge extends StatelessWidget {
  const _SettingsBadge({required this.animation, required this.reduceMotion});

  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double progress = reduceMotion ? 1 : animation.value;
        final double scale = 0.92 + (0.08 * progress);
        final double glowAlpha = 0.16 + (0.10 * progress);

        return Transform.scale(
          scale: scale,
          child: Container(
            key: const ValueKey<String>('six-settings-dialog-badge'),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: tokens.info.withValues(alpha: glowAlpha),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.surfaceElevated,
                border: Border.all(
                  color: tokens.info.withValues(
                    alpha: 0.28 + (0.28 * progress),
                  ),
                  width: 1.4,
                ),
              ),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.info.withValues(alpha: 0.12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.tune_rounded,
                      color: tokens.info,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
