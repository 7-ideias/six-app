import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia exclusiva da experiência mobile do Six.
///
/// Mantém a versão web independente e concentra aqui os ajustes de família,
/// peso, espaçamento e altura de linha usados no Android e iOS.
abstract final class SixMobileTypography {
  const SixMobileTypography._();

  static const List<String> _fallbackFonts = <String>[
    'SF Pro Display',
    'SF Pro Text',
    'Segoe UI',
    'Roboto',
    'Arial',
  ];

  static ThemeData apply(ThemeData theme) {
    final TextTheme manropeTextTheme = GoogleFonts.manropeTextTheme(
      theme.textTheme,
    );
    final TextTheme manropePrimaryTextTheme = GoogleFonts.manropeTextTheme(
      theme.primaryTextTheme,
    );

    final TextTheme textTheme = manropeTextTheme.copyWith(
      displayLarge: _style(
        manropeTextTheme.displayLarge,
        weight: FontWeight.w700,
        letterSpacing: -1,
        height: 1.05,
      ),
      displayMedium: _style(
        manropeTextTheme.displayMedium,
        weight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.08,
      ),
      displaySmall: _style(
        manropeTextTheme.displaySmall,
        weight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.1,
      ),
      headlineLarge: _style(
        manropeTextTheme.headlineLarge,
        weight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.12,
      ),
      headlineMedium: _style(
        manropeTextTheme.headlineMedium,
        weight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.15,
      ),
      headlineSmall: _style(
        manropeTextTheme.headlineSmall,
        weight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.18,
      ),
      titleLarge: _style(
        manropeTextTheme.titleLarge,
        weight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      titleMedium: _style(
        manropeTextTheme.titleMedium,
        weight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.25,
      ),
      titleSmall: _style(
        manropeTextTheme.titleSmall,
        weight: FontWeight.w600,
        letterSpacing: -0.05,
        height: 1.25,
      ),
      bodyLarge: _style(
        manropeTextTheme.bodyLarge,
        weight: FontWeight.w400,
        letterSpacing: -0.05,
        height: 1.45,
      ),
      bodyMedium: _style(
        manropeTextTheme.bodyMedium,
        weight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.42,
      ),
      bodySmall: _style(
        manropeTextTheme.bodySmall,
        weight: FontWeight.w400,
        letterSpacing: 0.05,
        height: 1.38,
      ),
      labelLarge: _style(
        manropeTextTheme.labelLarge,
        weight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.2,
      ),
      labelMedium: _style(
        manropeTextTheme.labelMedium,
        weight: FontWeight.w600,
        letterSpacing: 0.05,
        height: 1.2,
      ),
      labelSmall: _style(
        manropeTextTheme.labelSmall,
        weight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.2,
      ),
    );

    final TextStyle appBarTitleStyle = GoogleFonts.manrope(
      textStyle: theme.appBarTheme.titleTextStyle ?? textTheme.titleLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.15,
    ).copyWith(fontFamilyFallback: _fallbackFonts);

    return theme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: manropePrimaryTextTheme,
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: appBarTitleStyle,
        toolbarTextStyle: _style(
          GoogleFonts.manrope(
            textStyle:
                theme.appBarTheme.toolbarTextStyle ?? textTheme.bodyMedium,
          ),
          weight: FontWeight.w500,
          letterSpacing: 0,
          height: 1.2,
        ),
      ),
    );
  }

  static TextStyle? _style(
    TextStyle? style, {
    required FontWeight weight,
    required double letterSpacing,
    required double height,
  }) {
    return style?.copyWith(
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      fontFamilyFallback: _fallbackFonts,
    );
  }
}
