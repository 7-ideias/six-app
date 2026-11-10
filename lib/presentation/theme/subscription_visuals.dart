import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens from web/site-assets/css/home-impact.css, scoped to billing.
/// No app-wide theme changes: billing is the continuation of the public offer.
abstract final class SubscriptionVisuals {
  static const background = Color(0xFF071125);
  static const surface = Color(0xFF152035);
  static const highlightedSurface = Color(0xFF143044);
  static const blue = Color(0xFF4C6FFF);
  static const cyan = Color(0xFF25D9EE);
  static const foreground = Color(0xFFF7FBFF);
  static const muted = Color(0xFFB6C6DA);
  static const border = Color(0xFF35465C);

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.dark,
      primary: cyan,
      onPrimary: background,
      surface: surface,
      onSurface: foreground,
      error: const Color(0xFFFF9AA8),
    );
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(bodyColor: foreground, displayColor: foreground),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: background,
          disabledBackgroundColor: border,
          disabledForegroundColor: muted,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          disabledForegroundColor: muted,
          side: const BorderSide(color: border),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: cyan,
        checkmarkColor: background,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(color: foreground, fontFamily: 'Inter'),
        secondaryLabelStyle: const TextStyle(
          color: background,
          fontFamily: 'Inter',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
