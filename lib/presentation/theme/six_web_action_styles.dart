import 'package:flutter/material.dart';

import '../../design_system/themes/app_theme.dart';

/// Uses the same appearance palette and state rules as the application theme.
/// Page-local themes must not turn informational/status colors into CTA colors.
abstract final class SixWebActionStyles {
  static ThemeData _canonical(ThemeData theme) => AppTheme.getThemeWithScheme(
    theme.colorScheme,
    isDark: theme.brightness == Brightness.dark,
    visualDensity: theme.visualDensity,
  );

  static ButtonStyle primary(BuildContext context) =>
      _canonical(Theme.of(context)).filledButtonTheme.style!;

  static ButtonStyle secondary(BuildContext context) =>
      _canonical(Theme.of(context)).outlinedButtonTheme.style!;

  static ButtonStyle text(BuildContext context) =>
      _canonical(Theme.of(context)).textButtonTheme.style!;

  static ButtonStyle icon(BuildContext context) =>
      _canonical(Theme.of(context)).iconButtonTheme.style!;

  static ButtonStyle danger(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = primary(context);
    return base.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled)
                ? base.backgroundColor?.resolve(states)
                : scheme.errorContainer,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled)
                ? base.foregroundColor?.resolve(states)
                : scheme.onErrorContainer,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled)
                ? null
                : scheme.onErrorContainer.withValues(alpha: 0.12),
      ),
    );
  }

  static ButtonStyle dangerText(BuildContext context) {
    final base = text(context);
    final color = Theme.of(context).colorScheme.error;
    return base.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled)
                ? base.foregroundColor?.resolve(states)
                : color,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled)
                ? null
                : color.withValues(alpha: 0.12),
      ),
    );
  }

  static ThemeData apply(ThemeData theme) {
    final canonical = _canonical(theme);
    return theme.copyWith(
      filledButtonTheme: canonical.filledButtonTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: canonical.filledButtonTheme.style,
      ),
      outlinedButtonTheme: canonical.outlinedButtonTheme,
      textButtonTheme: canonical.textButtonTheme,
      iconButtonTheme: canonical.iconButtonTheme,
      segmentedButtonTheme: canonical.segmentedButtonTheme,
    );
  }
}
