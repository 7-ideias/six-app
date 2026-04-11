import 'package:flutter/material.dart';

import '../../models/aparencia_models.dart';
import '../../models/pdv_visual_theme.dart';

class PdvVisualThemeResolver {
  static PdvVisualTheme resolve(PaletaSistema paleta, {TemaSistema? tema}) {
    final bool darkMode = tema == TemaSistema.escuro;
    final Color pageBackground = darkMode ? const Color(0xFF101214) : paleta.fundo;
    final Color surfaceBackground = darkMode ? const Color(0xFF181B1F) : paleta.superficie;
    final Color primaryText = darkMode ? Colors.white : paleta.textoPrimario;
    final Color secondaryText = darkMode ? Colors.white70 : paleta.textoSecundario;

    return PdvVisualTheme(
      backgroundPage: pageBackground,
      backgroundSurface: surfaceBackground,
      backgroundSidebar: paleta.primaria,
      cardBackground: surfaceBackground,
      cardBorder: darkMode
          ? Colors.white.withOpacity(0.14)
          : paleta.secundaria.withOpacity(0.2),
      cardShadow: Colors.black.withOpacity(darkMode ? 0.20 : 0.05),
      primaryText: primaryText,
      secondaryText: secondaryText,
      badgeBackground: paleta.secundaria,
      badgeText: _estimateContrast(paleta.secundaria),
      iconColor: paleta.primaria,
      highlightColor: paleta.destaque,
      successColor: paleta.destaque,
      warningColor: paleta.alerta,
      eventCardBackground: pageBackground.withOpacity(0.72),
      eventCardBorder: darkMode
          ? Colors.white.withOpacity(0.10)
          : paleta.secundaria.withOpacity(0.1),
      actionButtonBackground: paleta.primaria,
      actionButtonForeground: _estimateContrast(paleta.primaria),
    );
  }

  static Color _estimateContrast(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
