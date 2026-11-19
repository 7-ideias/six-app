import 'package:flutter/material.dart';

import '../../domain/models/pdv_visual_theme.dart';
import 'web_theme_tokens.dart';

class WebPdvTheme extends ThemeExtension<WebPdvTheme> {
  const WebPdvTheme._(this.colors);

  final PdvVisualTheme colors;

  static PdvVisualTheme resolve(ThemeData theme) {
    return theme.extension<WebPdvTheme>()?.colors ??
        WebPdvTheme.fromTheme(
          theme,
          theme.extension<WebThemeTokens>() ?? WebThemeTokens.resolve(theme),
        ).colors;
  }

  factory WebPdvTheme.fromTheme(ThemeData theme, WebThemeTokens tokens) {
    final ColorScheme colorScheme = theme.colorScheme;
    final bool dark = colorScheme.brightness == Brightness.dark;
    final Color accent = dark ? tokens.info : colorScheme.primary;
    final Color selected = dark ? tokens.selectedBackground : accent;

    return WebPdvTheme._(
      PdvVisualTheme(
        backgroundPage: tokens.workspaceBackground,
        backgroundSurface: tokens.surface,
        backgroundSidebar: tokens.sidebarBackground,
        cardBackground: tokens.cardBackground,
        cardBorder: tokens.cardBorder,
        cardShadow: dark ? Colors.transparent : accent.withValues(alpha: 0.12),
        primaryText: tokens.primaryText,
        secondaryText: tokens.secondaryText,
        badgeBackground: selected,
        badgeText: dark ? tokens.primaryText : colorScheme.onPrimary,
        iconColor: accent,
        highlightColor: accent,
        successColor: tokens.success,
        warningColor: tokens.warning,
        eventCardBackground: dark ? tokens.surfaceMuted : tokens.cardBackground,
        eventCardBorder: tokens.cardBorder,
        actionButtonBackground: accent,
        actionButtonForeground:
            dark ? tokens.workspaceBackground : colorScheme.onPrimary,
      ),
    );
  }

  @override
  WebPdvTheme copyWith({PdvVisualTheme? colors}) =>
      WebPdvTheme._(colors ?? this.colors);

  @override
  WebPdvTheme lerp(WebPdvTheme? other, double t) {
    if (other == null) return this;
    final end = other.colors;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;

    return WebPdvTheme._(
      PdvVisualTheme(
        backgroundPage: blend(colors.backgroundPage, end.backgroundPage),
        backgroundSurface: blend(colors.backgroundSurface, end.backgroundSurface),
        backgroundSidebar: blend(colors.backgroundSidebar, end.backgroundSidebar),
        cardBackground: blend(colors.cardBackground, end.cardBackground),
        cardBorder: blend(colors.cardBorder, end.cardBorder),
        cardShadow: blend(colors.cardShadow, end.cardShadow),
        primaryText: blend(colors.primaryText, end.primaryText),
        secondaryText: blend(colors.secondaryText, end.secondaryText),
        badgeBackground: blend(colors.badgeBackground, end.badgeBackground),
        badgeText: blend(colors.badgeText, end.badgeText),
        iconColor: blend(colors.iconColor, end.iconColor),
        highlightColor: blend(colors.highlightColor, end.highlightColor),
        successColor: blend(colors.successColor, end.successColor),
        warningColor: blend(colors.warningColor, end.warningColor),
        eventCardBackground: blend(colors.eventCardBackground, end.eventCardBackground),
        eventCardBorder: blend(colors.eventCardBorder, end.eventCardBorder),
        actionButtonBackground: blend(colors.actionButtonBackground, end.actionButtonBackground),
        actionButtonForeground: blend(colors.actionButtonForeground, end.actionButtonForeground),
      ),
    );
  }
}
