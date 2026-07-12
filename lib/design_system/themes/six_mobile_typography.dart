import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tipografia exclusiva da experiência mobile do Six.
///
/// Mantém a versão web independente e concentra aqui pesos, espaçamentos e
/// alturas de linha usados no Android e iOS, sem depender de fontes externas.
abstract final class SixMobileTypography {
  const SixMobileTypography._();

  static const List<String> _fallbackFonts = <String>[
    'SF Pro Text',
    'SF Pro Display',
    'Noto Sans',
    'Segoe UI',
    'Arial',
  ];

  static String? get _titleFontFamily {
    return defaultTargetPlatform == TargetPlatform.android
        ? 'sans-serif-medium'
        : null;
  }

  static String? get _bodyFontFamily {
    return defaultTargetPlatform == TargetPlatform.android
        ? 'sans-serif'
        : null;
  }

  static ThemeData apply(ThemeData theme) {
    final TextTheme textTheme = _buildTextTheme(theme.textTheme);
    final TextTheme primaryTextTheme = _buildTextTheme(
      theme.primaryTextTheme,
    );

    final TextStyle? appBarTitleStyle = _style(
      theme.appBarTheme.titleTextStyle ?? textTheme.titleLarge,
      family: _titleFontFamily,
      weight: FontWeight.w600,
      letterSpacing: -0.25,
      height: 1.15,
    );

    return theme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: appBarTitleStyle,
        toolbarTextStyle: _style(
          theme.appBarTheme.toolbarTextStyle ?? textTheme.bodyMedium,
          family: _bodyFontFamily,
          weight: FontWeight.w500,
          letterSpacing: 0,
          height: 1.2,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: _style(
        base.displayLarge,
        family: _titleFontFamily,
        weight: FontWeight.w600,
        letterSpacing: -0.9,
        height: 1.06,
      ),
      displayMedium: _style(
        base.displayMedium,
        family: _titleFontFamily,
        weight: FontWeight.w600,
        letterSpacing: -0.7,
        height: 1.08,
      ),
      displaySmall: _style(
        base.displaySmall,
        family: _titleFontFamily,
        weight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      headlineLarge: _style(
        base.headlineLarge,
        family: _titleFontFamily,
        weight: FontWeight.w600,
        letterSpacing: -0.45,
        height: 1.12,
      ),
      headlineMedium: _style(
        base.headlineMedium,
        family: _titleFontFamily,
        weight: FontWeight.w600,
        letterSpacing: -0.35,
        height: 1.14,
      ),
      headlineSmall: _style(
        base.headlineSmall,
        family: _titleFontFamily,
        weight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.17,
      ),
      titleLarge: _style(
        base.titleLarge,
        family: _titleFontFamily,
        weight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.2,
      ),
      titleMedium: _style(
        base.titleMedium,
        family: _titleFontFamily,
        weight: FontWeight.w500,
        letterSpacing: -0.1,
        height: 1.24,
      ),
      titleSmall: _style(
        base.titleSmall,
        family: _titleFontFamily,
        weight: FontWeight.w500,
        letterSpacing: -0.05,
        height: 1.24,
      ),
      bodyLarge: _style(
        base.bodyLarge,
        family: _bodyFontFamily,
        weight: FontWeight.w400,
        letterSpacing: -0.02,
        height: 1.46,
      ),
      bodyMedium: _style(
        base.bodyMedium,
        family: _bodyFontFamily,
        weight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.43,
      ),
      bodySmall: _style(
        base.bodySmall,
        family: _bodyFontFamily,
        weight: FontWeight.w400,
        letterSpacing: 0.02,
        height: 1.4,
      ),
      labelLarge: _style(
        base.labelLarge,
        family: _titleFontFamily,
        weight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.2,
      ),
      labelMedium: _style(
        base.labelMedium,
        family: _titleFontFamily,
        weight: FontWeight.w500,
        letterSpacing: 0.02,
        height: 1.2,
      ),
      labelSmall: _style(
        base.labelSmall,
        family: _titleFontFamily,
        weight: FontWeight.w500,
        letterSpacing: 0.05,
        height: 1.2,
      ),
    );
  }

  static TextStyle? _style(
    TextStyle? style, {
    required String? family,
    required FontWeight weight,
    required double letterSpacing,
    required double height,
  }) {
    return style?.copyWith(
      fontFamily: family,
      fontFamilyFallback: _fallbackFonts,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
