import 'package:flutter/material.dart';

import '../../domain/models/pdv_visual_theme.dart';
import 'web_theme_tokens.dart';

class WebPdvTheme {
  const WebPdvTheme._();

  static PdvVisualTheme resolve(ThemeData theme) {
    final WebThemeTokens tokens = WebThemeTokens.resolve(theme);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool dark = colorScheme.brightness == Brightness.dark;
    final Color accent = dark ? tokens.info : colorScheme.primary;
    final Color selected = dark ? tokens.selectedBackground : accent;

    return PdvVisualTheme(
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
    );
  }
}
