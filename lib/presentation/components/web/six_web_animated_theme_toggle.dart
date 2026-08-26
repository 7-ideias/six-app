import 'package:flutter/material.dart';

/// Átomo Web reutilizável para alternância visual entre tema claro e escuro.
///
/// A cápsula preserva o movimento do seletor original do SixoApp e respeita
/// as preferências de redução de movimento do navegador.
class SixWebAnimatedThemeToggle extends StatefulWidget {
  const SixWebAnimatedThemeToggle({
    super.key,
    required this.isDark,
    required this.onChanged,
    required this.semanticsLabel,
    required this.trackColor,
    required this.thumbColor,
    required this.activeIconColor,
    required this.inactiveIconColor,
    required this.hoverShadowColor,
  });

  final bool isDark;
  final ValueChanged<bool> onChanged;
  final String semanticsLabel;
  final Color trackColor;
  final Color thumbColor;
  final Color activeIconColor;
  final Color inactiveIconColor;
  final Color hoverShadowColor;

  @override
  State<SixWebAnimatedThemeToggle> createState() =>
      _SixWebAnimatedThemeToggleState();
}

class _SixWebAnimatedThemeToggleState
    extends State<SixWebAnimatedThemeToggle> {
  static const double _trackWidth = 52;
  static const double _trackHeight = 28;
  static const double _thumbSize = 22;
  static const double _trackPadding = 3;
  static const Duration _duration = Duration(milliseconds: 250);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    final bool reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    final Duration duration = reduceMotion ? Duration.zero : _duration;
    final double thumbLeft =
        widget.isDark
            ? _trackWidth - _thumbSize - _trackPadding
            : _trackPadding;

    return Semantics(
      button: true,
      toggled: widget.isDark,
      label: widget.semanticsLabel,
      onTap: () => widget.onChanged(!widget.isDark),
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onChanged(!widget.isDark),
            child: SizedBox(
              width: _trackWidth,
              height: _trackHeight,
              child: Center(
                child: AnimatedContainer(
                  key: const ValueKey<String>('six-web-theme-toggle-track'),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  width: _trackWidth,
                  height: _trackHeight,
                  decoration: BoxDecoration(
                    color: widget.trackColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow:
                        _hovered
                            ? <BoxShadow>[
                              BoxShadow(
                                color: widget.hoverShadowColor.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                            : const <BoxShadow>[],
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: _trackPadding + 2,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: duration,
                            opacity: widget.isDark ? 0.46 : 0,
                            child: Icon(
                              Icons.wb_sunny_rounded,
                              size: 14,
                              color: widget.inactiveIconColor,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: _trackPadding + 2,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: duration,
                            opacity: widget.isDark ? 0 : 0.46,
                            child: Icon(
                              Icons.nightlight_round,
                              size: 13,
                              color: widget.inactiveIconColor,
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        key: const ValueKey<String>(
                          'six-web-theme-toggle-thumb-position',
                        ),
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        left: thumbLeft,
                        top: _trackPadding,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: BoxDecoration(
                            color: widget.thumbColor,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: duration,
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (
                              Widget child,
                              Animation<double> animation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.74,
                                    end: 1,
                                  ).animate(animation),
                                  child: RotationTransition(
                                    turns: Tween<double>(
                                      begin: widget.isDark ? -0.10 : 0.10,
                                      end: 0,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Icon(
                              widget.isDark
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded,
                              key: ValueKey<String>(
                                widget.isDark
                                    ? 'six-web-theme-toggle-moon'
                                    : 'six-web-theme-toggle-sun',
                              ),
                              size: 13,
                              color: widget.activeIconColor,
                            ),
                          ),
                        ),
                      ),
                    ],
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
