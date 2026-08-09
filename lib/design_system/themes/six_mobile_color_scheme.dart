import 'package:flutter/material.dart';

import 'six_mobile_palette.dart';

class SixMobileColorScheme {
  const SixMobileColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.softSurface,
    required this.softAccentSurface,
    required this.iconSurface,
    required this.border,
    required this.strongBorder,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.onAccent,
    required this.titleText,
    required this.mutedText,
    required this.onPrimary,
    required this.heroSupportingText,
    required this.heroLabelText,
    required this.navigationShadow,
    required this.heroShadow,
    required this.error,
    required this.errorBorder,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color softSurface;
  final Color softAccentSurface;
  final Color iconSurface;
  final Color border;
  final Color strongBorder;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color onAccent;
  final Color titleText;
  final Color mutedText;
  final Color onPrimary;
  final Color heroSupportingText;
  final Color heroLabelText;
  final Color navigationShadow;
  final Color heroShadow;
  final Color error;
  final Color errorBorder;

  static const SixMobileColorScheme light = SixMobileColorScheme(
    background: SixMobilePalette.backgroundLight,
    surface: SixMobilePalette.surfaceLight,
    surfaceElevated: SixMobilePalette.surfaceElevatedLight,
    softSurface: SixMobilePalette.softNeutralSurfaceLight,
    softAccentSurface: SixMobilePalette.softAccentSurfaceLight,
    iconSurface: SixMobilePalette.iconSurfaceLight,
    border: SixMobilePalette.borderLight,
    strongBorder: SixMobilePalette.activeBorderLight,
    primary: SixMobilePalette.primaryLight,
    secondary: SixMobilePalette.secondaryLight,
    accent: SixMobilePalette.accentLight,
    onAccent: SixMobilePalette.onAccentLight,
    titleText: SixMobilePalette.titleTextLight,
    mutedText: SixMobilePalette.mutedTextLight,
    onPrimary: SixMobilePalette.onPrimary,
    heroSupportingText: SixMobilePalette.heroSupportingTextLight,
    heroLabelText: SixMobilePalette.heroLabelTextLight,
    navigationShadow: SixMobilePalette.navigationShadowLight,
    heroShadow: SixMobilePalette.heroShadowLight,
    error: SixMobilePalette.errorLight,
    errorBorder: SixMobilePalette.errorBorderLight,
  );

  static const SixMobileColorScheme dark = SixMobileColorScheme(
    background: Color(0xFF101214),
    surface: Color(0xFF181B20),
    surfaceElevated: Color(0xFF1E2229),
    softSurface: Color(0xFF20252D),
    softAccentSurface: Color(0xFF172A45),
    iconSurface: Color(0xFF222833),
    border: Color(0xFF303640),
    strongBorder: Color(0xFF46505C),
    primary: Color(0xFF12171D),
    secondary: Color(0xFF29313A),
    accent: Color(0xFF60A5FA),
    onAccent: Color(0xFF07111E),
    titleText: Color(0xFFEFF4FA),
    mutedText: Color(0xFFAAB4C2),
    onPrimary: Colors.white,
    heroSupportingText: Color(0xFFD6DEE8),
    heroLabelText: Color(0xFFB6C1CE),
    navigationShadow: Color(0x66000000),
    heroShadow: Color(0x80000000),
    error: Color(0xFFF87171),
    errorBorder: Color(0xFF7F1D1D),
  );

  static SixMobileColorScheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

extension SixMobileColorSchemeContext on BuildContext {
  SixMobileColorScheme get sixMobileColors => SixMobileColorScheme.of(this);
}
