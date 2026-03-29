import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppColorSchemes {
  static ColorScheme getLightScheme(AppPalette palette) {
    switch (palette) {
      case AppPalette.corporate:
        return const ColorScheme.light(
          primary: AppColors.corporatePrimary,
          onPrimary: Colors.white,
          secondary: AppColors.corporateSecondary,
          onSecondary: Colors.white,
          tertiary: AppColors.corporateAccent,
          onTertiary: Colors.white,
          surface: AppColors.corporateSurface,
          onSurface: AppColors.corporatePrimary,
          error: AppColors.corporateError,
          onError: Colors.white,
        );
      case AppPalette.modernPremium:
        return const ColorScheme.light(
          primary: AppColors.premiumPrimary,
          onPrimary: Colors.white,
          secondary: AppColors.premiumSecondary,
          onSecondary: Colors.white,
          tertiary: AppColors.premiumAccent,
          onTertiary: Colors.white,
          surface: AppColors.premiumSurface,
          onSurface: AppColors.premiumPrimary,
          error: AppColors.premiumError,
          onError: Colors.white,
        );
      case AppPalette.lightContemporary:
        return const ColorScheme.light(
          primary: AppColors.contemporaryPrimary,
          onPrimary: Colors.white,
          secondary: AppColors.contemporarySecondary,
          onSecondary: Colors.white,
          tertiary: AppColors.contemporaryAccent,
          onTertiary: Colors.white,
          surface: AppColors.contemporarySurface,
          onSurface: AppColors.contemporaryPrimary,
          error: AppColors.contemporaryError,
          onError: Colors.white,
        );
    }
  }

  static ColorScheme getDarkScheme(AppPalette palette) {
    // Para o Dark Mode, podemos ter variações baseadas na paleta ou uma base dark consistente.
    // Vamos usar as cores primárias de cada paleta suavizadas para o dark, ou manter uma base dark sólida.
    
    Color primary;
    Color secondary;

    switch (palette) {
      case AppPalette.corporate:
        primary = const Color(0xFF90CAF9);
        secondary = AppColors.corporateSecondary;
        break;
      case AppPalette.modernPremium:
        primary = AppColors.premiumSecondary;
        secondary = AppColors.premiumAccent;
        break;
      case AppPalette.lightContemporary:
        primary = const Color(0xFF55E6C1);
        secondary = AppColors.contemporarySecondary;
        break;
    }

    return ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.black,
      secondary: secondary,
      onSecondary: Colors.black,
      surface: AppColors.darkSurface,
      onSurface: Colors.white70,
      error: const Color(0xFFCF6679),
      onError: Colors.black,
    );
  }
}
