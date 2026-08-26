import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web/six_web_animated_theme_toggle.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/theme_provider.dart';

/// Entrada interativa de tema para menus Web autenticados.
///
/// Diferentemente de um [PopupMenuItem], esta entrada preserva o menu durante
/// a animação e o fecha ao final. Isso permite perceber a transição sem manter
/// uma superfície capturada no tema anterior sobre a página já atualizada.
class SixWebThemeMenuEntry<T> extends PopupMenuEntry<T> {
  const SixWebThemeMenuEntry({super.key});

  @override
  double get height => 54;

  @override
  bool represents(T? value) => false;

  @override
  State<SixWebThemeMenuEntry<T>> createState() =>
      _SixWebThemeMenuEntryState<T>();
}

class _SixWebThemeMenuEntryState<T>
    extends State<SixWebThemeMenuEntry<T>> {
  bool _switchingTheme = false;

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final ThemeData theme =
        isDark ? themeProvider.darkTheme : themeProvider.lightTheme;
    final WebThemeTokens tokens = WebThemeTokens.resolve(theme);
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final Duration iconDuration =
        reduceMotion ? Duration.zero : WebThemeTokens.transitionDuration;
    final Color accent =
        theme.brightness == Brightness.dark
            ? tokens.info
            : theme.colorScheme.primary;
    final String title = context.t(
      'web.header.theme.dark',
      fallback: 'Tema escuro',
    );
    final String semanticsLabel = context.t(
      isDark
          ? 'web.header.theme.dark.disable'
          : 'web.header.theme.dark.enable',
      fallback: isDark ? 'Desativar tema escuro' : 'Ativar tema escuro',
    );
    final Color trackColor =
        isDark ? tokens.surfaceElevated : tokens.divider;
    final Color thumbColor = isDark ? tokens.warning : tokens.surfaceElevated;
    final Color activeIconColor =
        isDark ? tokens.workspaceBackground : tokens.warning;

    return Semantics(
      container: true,
      button: true,
      toggled: isDark,
      label: semanticsLabel,
      onTap:
          _switchingTheme
              ? null
              : () => _toggleTheme(themeProvider, !isDark, reduceMotion),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey<String>('web-user-menu-theme-entry'),
              borderRadius: BorderRadius.circular(10),
              hoverColor: tokens.hoverBackground,
              focusColor: tokens.hoverBackground,
              splashColor: tokens.selectedBackground,
              onTap:
                  _switchingTheme
                      ? null
                      : () => _toggleTheme(
                        themeProvider,
                        !isDark,
                        reduceMotion,
                      ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: iconDuration,
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      child: Icon(
                        isDark
                            ? Icons.nightlight_round
                            : Icons.wb_sunny_rounded,
                        key: ValueKey<IconData>(
                          isDark
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                        ),
                        size: 18,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IgnorePointer(
                      child: SixWebAnimatedThemeToggle(
                        isDark: isDark,
                        semanticsLabel: semanticsLabel,
                        trackColor: trackColor,
                        thumbColor: thumbColor,
                        activeIconColor: activeIconColor,
                        inactiveIconColor: tokens.mutedText,
                        hoverShadowColor: accent,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleTheme(
    ThemeProvider themeProvider,
    bool isDark,
    bool reduceMotion,
  ) {
    if (_switchingTheme) return;
    setState(() => _switchingTheme = true);
    unawaited(themeProvider.toggleTheme(isDark));
    unawaited(_closeMenuAfterTransition(reduceMotion));
  }

  Future<void> _closeMenuAfterTransition(bool reduceMotion) async {
    if (!reduceMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
