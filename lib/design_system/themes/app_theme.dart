import 'package:flutter/material.dart';
import '../helpers/six_color_contrast.dart';
import 'app_colors.dart';
import 'app_color_schemes.dart';

class AppTheme {
  static ThemeData getThemeWithScheme(
    ColorScheme colorScheme, {
    required bool isDark,
    VisualDensity visualDensity = VisualDensity.standard,
  }) {
    final Color interactionSurface =
        isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest;
    final Color actionForeground = SixColorContrast.ensureForeground(
      colorScheme.primary,
      interactionSurface,
    );
    final Color componentBorder = SixColorContrast.ensureForeground(
      colorScheme.outline,
      interactionSurface,
      minimumRatio: SixColorContrast.minimumComponentRatio,
    );
    final Color primaryActionBackground = colorScheme.primaryContainer;
    final Color primaryActionForeground = SixColorContrast.onColor(
      primaryActionBackground,
    );
    final Color disabledBackground = colorScheme.onSurface.withValues(
      alpha: 0.12,
    );
    final Color disabledForeground = colorScheme.onSurface.withValues(
      alpha: 0.38,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor:
          isDark ? colorScheme.surfaceContainerLowest : colorScheme.surface,
      visualDensity: visualDensity,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
        foregroundColor: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(
          backgroundColor: primaryActionBackground,
          foregroundColor: primaryActionForeground,
          disabledBackground: disabledBackground,
          disabledForeground: disabledForeground,
          minimumSize: const Size.fromHeight(50),
          borderRadius: 30,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(
          backgroundColor: primaryActionBackground,
          foregroundColor: primaryActionForeground,
          disabledBackground: disabledBackground,
          disabledForeground: disabledForeground,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          borderRadius: 16,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(
          foregroundColor: actionForeground,
          disabledForeground: disabledForeground,
          borderColor: componentBorder,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          borderRadius: 16,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(
          foregroundColor: actionForeground,
          disabledForeground: disabledForeground,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: _iconButtonStyle(
          foregroundColor: colorScheme.onSurface,
          disabledForeground: disabledForeground,
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: _segmentedButtonStyle(
          selectedBackground: primaryActionBackground,
          selectedForeground: primaryActionForeground,
          foregroundColor: colorScheme.onSurface,
          disabledForeground: disabledForeground,
          borderColor: componentBorder,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        prefixIconColor: colorScheme.primary,
      ),

      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        labelStyle: TextStyle(color: colorScheme.primary),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withOpacity(0.1),
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
    );
  }

  static ThemeData getTheme(AppPalette palette, {required bool isDark}) {
    final colorScheme =
        isDark
            ? AppColorSchemes.getDarkScheme(palette)
            : AppColorSchemes.getLightScheme(palette);

    return getThemeWithScheme(colorScheme, isDark: isDark);
  }

  // Mantendo as referências antigas para não quebrar o código temporariamente durante a transição
  static ThemeData get lightTheme =>
      getTheme(AppPalette.corporate, isDark: false);
  static ThemeData get darkTheme =>
      getTheme(AppPalette.corporate, isDark: true);

  static ButtonStyle _filledButtonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color disabledBackground,
    required Color disabledForeground,
    required Size minimumSize,
    required double borderRadius,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        return states.contains(WidgetState.disabled)
            ? disabledBackground
            : backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        return states.contains(WidgetState.disabled)
            ? disabledForeground
            : foregroundColor;
      }),
      overlayColor: _overlayColor(foregroundColor),
      minimumSize: WidgetStatePropertyAll<Size>(minimumSize),
      padding:
          padding == null
              ? null
              : WidgetStatePropertyAll<EdgeInsetsGeometry>(padding),
      elevation: const WidgetStatePropertyAll<double>(0),
      shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      textStyle:
          textStyle == null
              ? null
              : WidgetStatePropertyAll<TextStyle>(textStyle),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static ButtonStyle _outlinedButtonStyle({
    required Color foregroundColor,
    required Color disabledForeground,
    required Color borderColor,
    required Size minimumSize,
    required EdgeInsetsGeometry padding,
    required TextStyle textStyle,
    required double borderRadius,
  }) {
    return ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll<Color>(
        Colors.transparent,
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        return states.contains(WidgetState.disabled)
            ? disabledForeground
            : foregroundColor;
      }),
      overlayColor: _overlayColor(foregroundColor),
      minimumSize: WidgetStatePropertyAll<Size>(minimumSize),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(padding),
      side: WidgetStateProperty.resolveWith<BorderSide>((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: disabledForeground.withValues(alpha: 0.45));
        }
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered)) {
          return BorderSide(color: foregroundColor, width: 1.2);
        }
        return BorderSide(color: borderColor, width: 1.1);
      }),
      textStyle: WidgetStatePropertyAll<TextStyle>(textStyle),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static ButtonStyle _textButtonStyle({
    required Color foregroundColor,
    required Color disabledForeground,
    required TextStyle textStyle,
  }) {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        return states.contains(WidgetState.disabled)
            ? disabledForeground
            : foregroundColor;
      }),
      overlayColor: _overlayColor(foregroundColor),
      textStyle: WidgetStatePropertyAll<TextStyle>(textStyle),
    );
  }

  static ButtonStyle _iconButtonStyle({
    required Color foregroundColor,
    required Color disabledForeground,
  }) {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        return states.contains(WidgetState.disabled)
            ? disabledForeground
            : foregroundColor;
      }),
      overlayColor: _overlayColor(foregroundColor),
    );
  }

  static ButtonStyle _segmentedButtonStyle({
    required Color selectedBackground,
    required Color selectedForeground,
    required Color foregroundColor,
    required Color disabledForeground,
    required Color borderColor,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        return states.contains(WidgetState.selected)
            ? selectedBackground
            : Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return disabledForeground;
        }
        return states.contains(WidgetState.selected)
            ? selectedForeground
            : foregroundColor;
      }),
      overlayColor: _overlayColor(foregroundColor),
      side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: borderColor)),
    );
  }

  static WidgetStateProperty<Color?> _overlayColor(Color foregroundColor) {
    return WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return foregroundColor.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.focused)) {
        return foregroundColor.withValues(alpha: 0.10);
      }
      if (states.contains(WidgetState.hovered)) {
        return foregroundColor.withValues(alpha: 0.08);
      }
      return null;
    });
  }
}

// Para manter compatibilidade com main.dart enquanto não refatoramos tudo
final ThemeData lightTheme = AppTheme.lightTheme;
final ThemeData darkTheme = AppTheme.darkTheme;
