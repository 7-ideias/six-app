import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

abstract final class _SixMobileThemeToggleTokens {
  const _SixMobileThemeToggleTokens._();

  static const Color celestialAccent = Color(0xFFF5A12C);
  static const double trackWidth = 56;
  static const double trackHeight = 30;
  static const double thumbSize = 24;
  static const double trackPadding = 3;
  static const Duration animationDuration = Duration(milliseconds: 260);
}

/// Seletor mobile de tema claro/escuro com transição visual entre sol e lua.
///
/// A área de toque permanece maior que a cápsula visual para preservar
/// ergonomia, enquanto o estado também é comunicado por semântica e ícone.
class SixMobileThemeToggle extends StatelessWidget {
  const SixMobileThemeToggle({
    super.key,
    required this.isDark,
    required this.onChanged,
    required this.semanticsLabel,
    this.enabled = true,
  });

  final bool isDark;
  final ValueChanged<bool> onChanged;
  final String semanticsLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    final bool reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    final Duration duration =
        reduceMotion
            ? Duration.zero
            : _SixMobileThemeToggleTokens.animationDuration;
    final Color trackColor =
        isDark
            ? Color.alphaBlend(
              colors.accent.withValues(alpha: 0.10),
              colors.primary,
            )
            : Color.alphaBlend(
              colors.mutedText.withValues(alpha: 0.12),
              colors.softSurface,
            );
    final Color thumbColor =
        isDark
            ? _SixMobileThemeToggleTokens.celestialAccent
            : colors.surfaceElevated;
    final Color activeIconColor =
        isDark
            ? SixMobilePalette.brandNavyDeep
            : _SixMobileThemeToggleTokens.celestialAccent;
    final Color inactiveIconColor = colors.mutedText.withValues(alpha: 0.55);
    final double thumbLeft =
        isDark
            ? _SixMobileThemeToggleTokens.trackWidth -
                _SixMobileThemeToggleTokens.thumbSize -
                _SixMobileThemeToggleTokens.trackPadding
            : _SixMobileThemeToggleTokens.trackPadding;

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: isDark,
      label: semanticsLabel,
      onTap: enabled ? () => _changeTheme(!isDark) : null,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => _changeTheme(!isDark) : null,
            child: SizedBox(
              width: 64,
              height: 44,
              child: Center(
                child: AnimatedContainer(
                  key: const ValueKey<String>(
                    'six-mobile-theme-toggle-track',
                  ),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  width: _SixMobileThemeToggleTokens.trackWidth,
                  height: _SixMobileThemeToggleTokens.trackHeight,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.border.withValues(
                        alpha: isDark ? 0.30 : 0.55,
                      ),
                      width: 0.7,
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 7,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: duration,
                            opacity: isDark ? 0.72 : 0,
                            child: Icon(
                              Icons.wb_sunny_rounded,
                              size: 13,
                              color: inactiveIconColor,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 7,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: duration,
                            opacity: isDark ? 0 : 0.62,
                            child: Icon(
                              Icons.nightlight_round,
                              size: 13,
                              color: inactiveIconColor,
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        key: const ValueKey<String>(
                          'six-mobile-theme-toggle-thumb-position',
                        ),
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        left: thumbLeft,
                        top: _SixMobileThemeToggleTokens.trackPadding,
                        child: AnimatedContainer(
                          key: const ValueKey<String>(
                            'six-mobile-theme-toggle-thumb',
                          ),
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          width: _SixMobileThemeToggleTokens.thumbSize,
                          height: _SixMobileThemeToggleTokens.thumbSize,
                          decoration: BoxDecoration(
                            color: thumbColor,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: colors.navigationShadow.withValues(
                                  alpha: isDark ? 0.58 : 0.36,
                                ),
                                blurRadius: 6,
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
                              final Animation<double> rotation = Tween<double>(
                                begin: isDark ? -0.10 : 0.10,
                                end: 0,
                              ).animate(animation);
                              final Animation<double> scale = Tween<double>(
                                begin: 0.72,
                                end: 1,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: scale,
                                  child: RotationTransition(
                                    turns: rotation,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Icon(
                              isDark
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded,
                              key: ValueKey<String>(
                                isDark
                                    ? 'six-mobile-theme-toggle-moon'
                                    : 'six-mobile-theme-toggle-sun',
                              ),
                              size: 14,
                              color: activeIconColor,
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

  void _changeTheme(bool nextValue) {
    HapticFeedback.selectionClick();
    onChanged(nextValue);
  }
}
