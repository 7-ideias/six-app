import 'package:flutter/material.dart';

import '../../domain/models/aparencia_models.dart';
import '../helpers/six_theme_resolver.dart';

/// Fonte única das cores da experiência mobile do Six.
///
/// A base visual é neutra para que ícones, bordas e estados de interação
/// tenham mais destaque. O tema e as telas web permanecem independentes.
abstract final class SixMobilePalette {
  const SixMobilePalette._();

  static bool get _isDark {
    final SixThemeResolver resolver = SixThemeResolver();
    if (resolver.tema == TemaSistema.automatico) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }

    return resolver.isDark;
  }

  // Identidade principal
  static const Color primaryLight = Color(0xFF252A31);
  static const Color primaryDark = Color(0xFF12171D);
  static const Color secondaryLight = Color(0xFF4B5563);
  static const Color secondaryDark = Color(0xFF29313A);
  static const Color accentLight = Color(0xFF2563EB);
  static const Color accentDark = Color(0xFF60A5FA);

  static Color get primary => _isDark ? primaryDark : primaryLight;
  static Color get secondary => _isDark ? secondaryDark : secondaryLight;
  static Color get accent => _isDark ? accentDark : accentLight;

  // Assinatura visual do SixoApp em experiências de marca mobile.
  // Estes tokens mantêm splash e área não autenticada conectadas sem alterar
  // as superfícies funcionais do restante do aplicativo.
  static const Color brandNavyDeep = Color(0xFF00163A);
  static const Color brandNavy = Color(0xFF021D48);
  static const Color brandNavyBright = Color(0xFF063071);
  static const Color brandCyan = Color(0xFF10D9F0);
  static const Color brandBlue = Color(0xFF145BFF);
  static const Color brandSupportingText = Color(0xFFA8C6EE);

  // Estrutura
  static const Color backgroundLight = Color(0xFFF3F4F6);
  static const Color backgroundDark = Color(0xFF101214);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF181B20);
  static const Color surfaceElevatedLight = Colors.white;
  static const Color surfaceElevatedDark = Color(0xFF1E2229);
  static const Color borderLight = Color(0xFFD1D5DB);
  static const Color borderDark = Color(0xFF303640);
  static const Color strongBorderLight = Color(0xFFCBD5E1);
  static const Color strongBorderDark = Color(0xFF46505C);
  static const Color softAccentSurfaceLight = Color(0xFFF4F6F8);
  static const Color softAccentSurfaceDark = Color(0xFF172A45);
  static const Color softNeutralSurfaceLight = Color(0xFFF8FAFC);
  static const Color softNeutralSurfaceDark = Color(0xFF20252D);
  static const Color iconSurfaceLight = Color(0xFFF8FAFC);
  static const Color iconSurfaceDark = Color(0xFF222833);

  static Color get background => _isDark ? backgroundDark : backgroundLight;
  static Color get surface => _isDark ? surfaceDark : surfaceLight;
  static Color get surfaceElevated =>
      _isDark ? surfaceElevatedDark : surfaceElevatedLight;
  static Color get border => _isDark ? borderDark : borderLight;
  static Color get strongBorder =>
      _isDark ? strongBorderDark : strongBorderLight;
  static Color get softAccentSurface =>
      _isDark ? softAccentSurfaceDark : softAccentSurfaceLight;
  static Color get softNeutralSurface =>
      _isDark ? softNeutralSurfaceDark : softNeutralSurfaceLight;
  static Color get iconSurface => _isDark ? iconSurfaceDark : iconSurfaceLight;

  // Tipografia
  static const Color titleTextLight = Color(0xFF111827);
  static const Color titleTextDark = Color(0xFFEFF4FA);
  static const Color mutedTextLight = Color(0xFF6B7280);
  static const Color mutedTextDark = Color(0xFFAAB4C2);
  static const Color onPrimary = Colors.white;
  static const Color onAccentLight = Colors.white;
  static const Color onAccentDark = Color(0xFF07111E);
  static const Color heroSupportingTextLight = Color(0xFFE5E7EB);
  static const Color heroSupportingTextDark = Color(0xFFD6DEE8);
  static const Color heroLabelTextLight = Color(0xFFD1D5DB);
  static const Color heroLabelTextDark = Color(0xFFB6C1CE);

  static Color get titleText => _isDark ? titleTextDark : titleTextLight;
  static Color get mutedText => _isDark ? mutedTextDark : mutedTextLight;
  static Color get onAccent => _isDark ? onAccentDark : onAccentLight;
  static Color get heroSupportingText =>
      _isDark ? heroSupportingTextDark : heroSupportingTextLight;
  static Color get heroLabelText =>
      _isDark ? heroLabelTextDark : heroLabelTextLight;

  // Estados e detalhes
  static const Color notificationBadge = Color(0xFFDC2626);
  static const Color activeBorderLight = Color(0xFFCBD5E1);
  static const Color activeBorderDark = Color(0xFF46505C);
  static const Color highlightedBorderLight = Color(0xFF93C5FD);
  static const Color highlightedBorderDark = Color(0xFF60A5FA);
  static const Color errorLight = Color(0xFFB91C1C);
  static const Color errorDark = Color(0xFFF87171);
  static const Color errorBorderLight = Color(0xFFFCA5A5);
  static const Color errorBorderDark = Color(0xFF7F1D1D);

  static Color get activeBorder =>
      _isDark ? activeBorderDark : activeBorderLight;
  static Color get highlightedBorder =>
      _isDark ? highlightedBorderDark : highlightedBorderLight;
  static Color get error => _isDark ? errorDark : errorLight;
  static Color get errorBorder => _isDark ? errorBorderDark : errorBorderLight;

  // Sombras relacionadas à identidade visual
  static const Color heroShadowLight = Color(0x1F111827);
  static const Color heroShadowDark = Color(0x80000000);
  static const Color navigationShadowLight = Color(0x14111827);
  static const Color navigationShadowDark = Color(0x66000000);

  static Color get heroShadow => _isDark ? heroShadowDark : heroShadowLight;
  static Color get navigationShadow =>
      _isDark ? navigationShadowDark : navigationShadowLight;
}
