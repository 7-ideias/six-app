import 'package:flutter/material.dart';

@immutable
class WebThemeTokens extends ThemeExtension<WebThemeTokens> {
  const WebThemeTokens({
    required this.workspaceBackground,
    required this.sidebarBackground,
    required this.sidebarBorder,
    required this.headerBackground,
    required this.headerBorder,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.cardBackground,
    required this.cardBorder,
    required this.inputBackground,
    required this.menuBackground,
    required this.divider,
    required this.hoverBackground,
    required this.selectedBackground,
    required this.selectedBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.disabledBackground,
    required this.disabledForeground,
    required this.financialPositive,
    required this.financialNegative,
    required this.stockCritical,
    required this.stockWarning,
    required this.statusNeutral,
  });

  static const Duration transitionDuration = Duration(milliseconds: 220);
  static const Curve transitionCurve = Curves.easeOutCubic;

  final Color workspaceBackground;
  final Color sidebarBackground;
  final Color sidebarBorder;
  final Color headerBackground;
  final Color headerBorder;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color cardBackground;
  final Color cardBorder;
  final Color inputBackground;
  final Color menuBackground;
  final Color divider;
  final Color hoverBackground;
  final Color selectedBackground;
  final Color selectedBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color disabledBackground;
  final Color disabledForeground;
  final Color financialPositive;
  final Color financialNegative;
  final Color stockCritical;
  final Color stockWarning;
  final Color statusNeutral;

  static WebThemeTokens of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.extension<WebThemeTokens>() ?? resolve(theme);
  }

  static WebThemeTokens resolve(ThemeData theme) {
    final ColorScheme colorScheme = theme.colorScheme;
    return colorScheme.brightness == Brightness.dark
        ? dark(colorScheme)
        : light(colorScheme);
  }

  static ThemeData applyTo(ThemeData theme) {
    final WebThemeTokens tokens = resolve(theme);
    final Iterable<ThemeExtension<ThemeExtension<dynamic>>>
    inheritedExtensions = theme.extensions.values
        .where(
          (ThemeExtension<dynamic> extension) => extension is! WebThemeTokens,
        )
        .map(
          (ThemeExtension<dynamic> extension) =>
              extension as ThemeExtension<ThemeExtension<dynamic>>,
        );

    return theme.copyWith(
      extensions: <ThemeExtension<ThemeExtension<dynamic>>>[
        ...inheritedExtensions,
        tokens as ThemeExtension<ThemeExtension<dynamic>>,
      ],
      popupMenuTheme: theme.popupMenuTheme.copyWith(
        color: tokens.menuBackground,
        textStyle: theme.textTheme.bodyMedium?.copyWith(
          color: tokens.primaryText,
        ),
      ),
      dividerTheme: theme.dividerTheme.copyWith(color: tokens.divider),
      tooltipTheme: theme.tooltipTheme.copyWith(
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.cardBorder),
        ),
        textStyle: theme.textTheme.labelMedium?.copyWith(
          color: tokens.primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static WebThemeTokens light(ColorScheme colorScheme) {
    return WebThemeTokens(
      workspaceBackground: const Color(0xFFF8FAFC),
      sidebarBackground: const Color(0xFFFFFFFF),
      sidebarBorder: const Color(0xFFE2E8F0),
      headerBackground: const Color(0xFFFFFFFF),
      headerBorder: const Color(0xFFE2E8F0),
      surface: const Color(0xFFFFFFFF),
      surfaceElevated: const Color(0xFFFFFFFF),
      surfaceMuted: const Color(0xFFF1F5F9),
      cardBackground: const Color(0xFFFFFFFF),
      cardBorder: const Color(0xFFE2E8F0),
      inputBackground: const Color(0xFFF8FAFC),
      menuBackground: const Color(0xFFFFFFFF),
      divider: const Color(0xFFE2E8F0),
      hoverBackground: const Color(0xFFF1F5F9),
      selectedBackground: _blend(
        colorScheme.primary.withValues(alpha: 0.08),
        const Color(0xFFFFFFFF),
      ),
      selectedBorder: colorScheme.primary.withValues(alpha: 0.30),
      primaryText: const Color(0xFF0F172A),
      secondaryText: const Color(0xFF475569),
      mutedText: const Color(0xFF64748B),
      success: const Color(0xFF0F766E),
      warning: const Color(0xFFB45309),
      danger: const Color(0xFFDC2626),
      info: const Color(0xFF2563EB),
      disabledBackground: const Color(0xFFE2E8F0),
      disabledForeground: const Color(0xFF94A3B8),
      financialPositive: const Color(0xFF047857),
      financialNegative: const Color(0xFFB91C1C),
      stockCritical: const Color(0xFFB91C1C),
      stockWarning: const Color(0xFFB45309),
      statusNeutral: const Color(0xFF64748B),
    );
  }

  static WebThemeTokens dark(ColorScheme colorScheme) {
    const Color workspace = Color(0xFF08111F);
    const Color sidebar = Color(0xFF0B1524);
    const Color surface = Color(0xFF0F1B2D);
    const Color muted = Color(0xFF142238);
    const Color elevated = Color(0xFF1A2B44);
    final Color brandSelected = _blend(
      colorScheme.secondary.withValues(alpha: 0.16),
      muted,
    );

    return WebThemeTokens(
      workspaceBackground: workspace,
      sidebarBackground: sidebar,
      sidebarBorder: const Color(0xFF20344F),
      headerBackground: sidebar,
      headerBorder: const Color(0xFF20344F),
      surface: surface,
      surfaceElevated: elevated,
      surfaceMuted: muted,
      cardBackground: surface,
      cardBorder: const Color(0xFF263B5E),
      inputBackground: muted,
      menuBackground: surface,
      divider: const Color(0xFF20344F),
      hoverBackground: muted,
      selectedBackground: brandSelected,
      selectedBorder: colorScheme.secondary.withValues(alpha: 0.70),
      primaryText: const Color(0xFFEAF2FF),
      secondaryText: const Color(0xFFB9C7DA),
      mutedText: const Color(0xFF7F8EA3),
      success: const Color(0xFF34D399),
      warning: const Color(0xFFFBBF24),
      danger: const Color(0xFFF87171),
      info: const Color(0xFF60A5FA),
      disabledBackground: const Color(0xFF1A2433),
      disabledForeground: const Color(0xFF64748B),
      financialPositive: const Color(0xFF34D399),
      financialNegative: const Color(0xFFF87171),
      stockCritical: const Color(0xFFF87171),
      stockWarning: const Color(0xFFFBBF24),
      statusNeutral: const Color(0xFF94A3B8),
    );
  }

  static Color _blend(Color foreground, Color background) {
    return Color.alphaBlend(foreground, background);
  }

  @override
  WebThemeTokens copyWith({
    Color? workspaceBackground,
    Color? sidebarBackground,
    Color? sidebarBorder,
    Color? headerBackground,
    Color? headerBorder,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? cardBackground,
    Color? cardBorder,
    Color? inputBackground,
    Color? menuBackground,
    Color? divider,
    Color? hoverBackground,
    Color? selectedBackground,
    Color? selectedBorder,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? disabledBackground,
    Color? disabledForeground,
    Color? financialPositive,
    Color? financialNegative,
    Color? stockCritical,
    Color? stockWarning,
    Color? statusNeutral,
  }) {
    return WebThemeTokens(
      workspaceBackground: workspaceBackground ?? this.workspaceBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      headerBackground: headerBackground ?? this.headerBackground,
      headerBorder: headerBorder ?? this.headerBorder,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      inputBackground: inputBackground ?? this.inputBackground,
      menuBackground: menuBackground ?? this.menuBackground,
      divider: divider ?? this.divider,
      hoverBackground: hoverBackground ?? this.hoverBackground,
      selectedBackground: selectedBackground ?? this.selectedBackground,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      disabledBackground: disabledBackground ?? this.disabledBackground,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      financialPositive: financialPositive ?? this.financialPositive,
      financialNegative: financialNegative ?? this.financialNegative,
      stockCritical: stockCritical ?? this.stockCritical,
      stockWarning: stockWarning ?? this.stockWarning,
      statusNeutral: statusNeutral ?? this.statusNeutral,
    );
  }

  @override
  WebThemeTokens lerp(ThemeExtension<WebThemeTokens>? other, double t) {
    if (other is! WebThemeTokens) return this;

    return WebThemeTokens(
      workspaceBackground:
          Color.lerp(workspaceBackground, other.workspaceBackground, t)!,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      headerBackground:
          Color.lerp(headerBackground, other.headerBackground, t)!,
      headerBorder: Color.lerp(headerBorder, other.headerBorder, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      menuBackground: Color.lerp(menuBackground, other.menuBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      hoverBackground: Color.lerp(hoverBackground, other.hoverBackground, t)!,
      selectedBackground:
          Color.lerp(selectedBackground, other.selectedBackground, t)!,
      selectedBorder: Color.lerp(selectedBorder, other.selectedBorder, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      disabledBackground:
          Color.lerp(disabledBackground, other.disabledBackground, t)!,
      disabledForeground:
          Color.lerp(disabledForeground, other.disabledForeground, t)!,
      financialPositive:
          Color.lerp(financialPositive, other.financialPositive, t)!,
      financialNegative:
          Color.lerp(financialNegative, other.financialNegative, t)!,
      stockCritical: Color.lerp(stockCritical, other.stockCritical, t)!,
      stockWarning: Color.lerp(stockWarning, other.stockWarning, t)!,
      statusNeutral: Color.lerp(statusNeutral, other.statusNeutral, t)!,
    );
  }
}
