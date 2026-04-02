import 'package:flutter/material.dart';

import '../../models/aparencia_models.dart';
import '../../models/pdv_visual_theme.dart';

class PdvVisualThemeResolver {
  static PdvVisualTheme resolve(PaletaSistema paleta) {
    return PdvVisualTheme(
      backgroundPage: paleta.fundo,
      backgroundSurface: paleta.superficie,
      backgroundSidebar: paleta.primaria,
      cardBackground: paleta.superficie,
      cardBorder: paleta.secundaria.withOpacity(0.2),
      cardShadow: Colors.black.withOpacity(0.05),
      primaryText: paleta.textoPrimario,
      secondaryText: paleta.textoSecundario,
      badgeBackground: paleta.secundaria,
      badgeText: _estimateContrast(paleta.secundaria),
      iconColor: paleta.primaria,
      highlightColor: paleta.destaque,
      successColor: paleta.destaque,
      warningColor: paleta.alerta,
      eventCardBackground: paleta.fundo.withOpacity(0.5),
      eventCardBorder: paleta.secundaria.withOpacity(0.1),
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
