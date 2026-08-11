import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  group('WebThemeTokens', () {
    test('define hierarquia clara de superficies em Light e Dark', () {
      final WebThemeTokens light = WebThemeTokens.resolve(
        ThemeData.light(useMaterial3: true),
      );
      final WebThemeTokens dark = WebThemeTokens.resolve(
        ThemeData.dark(useMaterial3: true),
      );

      expect(light.workspaceBackground, isNot(light.cardBackground));
      expect(dark.workspaceBackground, isNot(dark.sidebarBackground));
      expect(dark.sidebarBackground, isNot(dark.surface));
      expect(dark.surface, isNot(dark.cardBorder));
      expect(dark.surface, isNot(dark.surfaceElevated));
      expect(dark.hoverBackground, isNot(dark.selectedBackground));
      expect(
        dark.workspaceBackground.computeLuminance(),
        lessThan(dark.surface.computeLuminance()),
      );
      expect(
        dark.surface.computeLuminance(),
        lessThan(dark.surfaceElevated.computeLuminance()),
      );
    });

    test('mantem texto principal com contraste adequado no Dark', () {
      final WebThemeTokens dark = WebThemeTokens.resolve(
        ThemeData.dark(useMaterial3: true),
      );

      expect(
        _contrastRatio(dark.primaryText, dark.workspaceBackground),
        greaterThan(7),
      );
      expect(
        _contrastRatio(dark.secondaryText, dark.sidebarBackground),
        greaterThan(4.5),
      );
    });

    test('define selected e cores semanticas distintas', () {
      final WebThemeTokens dark = WebThemeTokens.resolve(
        ThemeData.dark(useMaterial3: true),
      );

      expect(dark.selectedBackground, isNot(dark.hoverBackground));
      expect(dark.selectedBorder, isNot(dark.selectedBackground));
      expect(<Color>{
        dark.success,
        dark.warning,
        dark.danger,
        dark.info,
      }, hasLength(4));
      expect(<Color>{
        dark.financialPositive,
        dark.financialNegative,
      }, hasLength(2));
      expect(<Color>{dark.stockCritical, dark.stockWarning}, hasLength(2));
    });

    test('instala ThemeExtension sem substituir extensoes externas', () {
      final ThemeData baseTheme = ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        extensions: const <ThemeExtension<dynamic>>[_ProbeExtension('keep')],
      );

      final ThemeData webTheme = WebThemeTokens.applyTo(baseTheme);

      expect(webTheme.extension<WebThemeTokens>(), isNotNull);
      expect(webTheme.extension<_ProbeExtension>()?.value, 'keep');
      expect(
        webTheme.popupMenuTheme.color,
        webTheme.extension<WebThemeTokens>()!.menuBackground,
      );
    });

    test('nao e referenciado por arquivos Mobile', () {
      final List<String> forbiddenReferences =
          Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((File file) => file.path.endsWith('.dart'))
              .where(
                (File file) =>
                    file.readAsStringSync().contains('WebThemeTokens'),
              )
              .map((File file) => file.path.replaceAll('\\', '/'))
              .where(_isForbiddenMobilePath)
              .toList();

      expect(forbiddenReferences, isEmpty);
    });
  });
}

double _contrastRatio(Color a, Color b) {
  final double lighter =
      a.computeLuminance() > b.computeLuminance()
          ? a.computeLuminance()
          : b.computeLuminance();
  final double darker =
      a.computeLuminance() > b.computeLuminance()
          ? b.computeLuminance()
          : a.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

bool _isForbiddenMobilePath(String path) {
  final String normalized = path.toLowerCase();
  return normalized.endsWith('_mobile_screen.dart') ||
      normalized.contains('/mobile/') ||
      normalized.contains('mobile_main_shell') ||
      normalized.contains('navbar_mobile') ||
      normalized.contains('mobile_navigation_controller') ||
      normalized.contains('six_mobile_');
}

@immutable
class _ProbeExtension extends ThemeExtension<_ProbeExtension> {
  const _ProbeExtension(this.value);

  final String value;

  @override
  _ProbeExtension copyWith({String? value}) {
    return _ProbeExtension(value ?? this.value);
  }

  @override
  _ProbeExtension lerp(ThemeExtension<_ProbeExtension>? other, double t) {
    return this;
  }
}
