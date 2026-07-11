import 'package:flutter/material.dart';

import '../../models/aparencia_models.dart';
import '../../models/pdv_visual_theme.dart';

class PdvVisualThemeResolver {
  static PdvVisualTheme resolve(PaletaSistema paleta, {TemaSistema? tema}) {
    final bool darkMode = tema == TemaSistema.escuro;
    final Color pageBackground = darkMode ? const Color(0xFF07111E) : const Color(0xFFF4F7FB);
    final Color surfaceBackground = darkMode ? const Color(0xFF0B1B2E) : Colors.white;
    final Color cardBackground = darkMode ? const Color(0xFF10243A) : Colors.white;
    final Color primaryText = darkMode ? Colors.white : const Color(0xFF0F172A);
    final Color secondaryText = darkMode ? Colors.white70 : const Color(0xFF475569);
    final Color primary = darkMode ? const Color(0xFF93C5FD) : paleta.primaria;
    final Color accent = darkMode ? const Color(0xFF60A5FA) : paleta.secundaria;

    return PdvVisualTheme(
      backgroundPage: pageBackground,
      backgroundSurface: surfaceBackground,
      backgroundSidebar: darkMode ? const Color(0xFF07111E) : const Color(0xFF0B1F3A),
      cardBackground: cardBackground,
      cardBorder: darkMode
          ? Colors.white.withOpacity(0.10)
          : const Color(0xFFE2E8F0),
      cardShadow: const Color(0xFF0B1F3A).withOpacity(darkMode ? 0.22 : 0.08),
      primaryText: primaryText,
      secondaryText: secondaryText,
      badgeBackground: accent,
      badgeText: _estimateContrast(accent),
      iconColor: primary,
      highlightColor: paleta.destaque,
      successColor: const Color(0xFF16A34A),
      warningColor: paleta.alerta,
      eventCardBackground: darkMode
          ? Colors.white.withOpacity(0.04)
          : const Color(0xFFF8FAFC),
      eventCardBorder: darkMode
          ? Colors.white.withOpacity(0.08)
          : const Color(0xFFE2E8F0),
      actionButtonBackground: darkMode ? const Color(0xFF2563EB) : paleta.primaria,
      actionButtonForeground: _estimateContrast(darkMode ? const Color(0xFF2563EB) : paleta.primaria),
    );
  }

  static Color _estimateContrast(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
