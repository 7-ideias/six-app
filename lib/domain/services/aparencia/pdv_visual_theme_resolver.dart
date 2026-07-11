import 'package:flutter/material.dart';

import '../../models/aparencia_models.dart';
import '../../models/pdv_visual_theme.dart';

class PdvVisualThemeResolver {
  static PdvVisualTheme resolve(PaletaSistema paleta, {TemaSistema? tema}) {
    final bool darkMode = tema == TemaSistema.escuro;
    final Color pageBackground = darkMode
        ? const Color(0xFF07111E)
        : const Color(0xFFEAF2FF);
    final Color surfaceBackground = darkMode
        ? const Color(0xFF0B1B2E)
        : const Color(0xFFF8FBFF);
    final Color cardBackground = darkMode
        ? const Color(0xFF10243A)
        : Colors.white;
    final Color primaryText = darkMode ? Colors.white : const Color(0xFF0B1F3A);
    final Color secondaryText = darkMode ? Colors.white70 : const Color(0xFF475569);
    final Color primary = darkMode ? const Color(0xFF93C5FD) : const Color(0xFF0B1F3A);
    final Color accent = darkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return PdvVisualTheme(
      backgroundPage: pageBackground,
      backgroundSurface: surfaceBackground,
      backgroundSidebar: darkMode ? const Color(0xFF07111E) : const Color(0xFF0B1F3A),
      cardBackground: cardBackground,
      cardBorder: darkMode
          ? Colors.white.withOpacity(0.12)
          : const Color(0xFFBFDBFE),
      cardShadow: const Color(0xFF2563EB).withOpacity(darkMode ? 0.24 : 0.16),
      primaryText: primaryText,
      secondaryText: secondaryText,
      badgeBackground: accent,
      badgeText: _estimateContrast(accent),
      iconColor: primary,
      highlightColor: accent,
      successColor: const Color(0xFF16A34A),
      warningColor: paleta.alerta,
      eventCardBackground: darkMode
          ? Colors.white.withOpacity(0.05)
          : Colors.white,
      eventCardBorder: darkMode
          ? Colors.white.withOpacity(0.10)
          : const Color(0xFFBFDBFE),
      actionButtonBackground: accent,
      actionButtonForeground: _estimateContrast(accent),
    );
  }

  static Color _estimateContrast(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
