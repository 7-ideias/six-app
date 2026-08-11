import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/theme/web_pdv_theme.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

void main() {
  group('WebPdvTheme', () {
    test('alinha superficies e textos Dark aos WebThemeTokens', () {
      final ThemeData theme = ThemeData.dark(useMaterial3: true);
      final WebThemeTokens tokens = WebThemeTokens.resolve(theme);
      final pdvTheme = WebPdvTheme.resolve(theme);

      expect(pdvTheme.backgroundPage, tokens.workspaceBackground);
      expect(pdvTheme.backgroundSurface, tokens.surface);
      expect(pdvTheme.cardBackground, tokens.cardBackground);
      expect(pdvTheme.cardBorder, tokens.cardBorder);
      expect(pdvTheme.primaryText, tokens.primaryText);
      expect(pdvTheme.secondaryText, tokens.secondaryText);
      expect(pdvTheme.iconColor, tokens.info);
      expect(pdvTheme.successColor, tokens.success);
      expect(pdvTheme.warningColor, tokens.warning);
      expect(pdvTheme.eventCardBackground, tokens.surfaceMuted);
    });

    test('mantem Light Mode proximo ao ColorScheme e tokens Web', () {
      final ThemeData theme = ThemeData.light(useMaterial3: true);
      final WebThemeTokens tokens = WebThemeTokens.resolve(theme);
      final pdvTheme = WebPdvTheme.resolve(theme);

      expect(pdvTheme.backgroundPage, tokens.workspaceBackground);
      expect(pdvTheme.backgroundSurface, tokens.surface);
      expect(pdvTheme.cardBackground, tokens.cardBackground);
      expect(pdvTheme.iconColor, theme.colorScheme.primary);
      expect(pdvTheme.actionButtonBackground, theme.colorScheme.primary);
      expect(pdvTheme.actionButtonForeground, theme.colorScheme.onPrimary);
    });

    test(
      'PaginaPrincipalWeb resolve PDV pela ponte Web sem remount por key',
      () {
        final String source =
            File('lib/pagina_principal_web.dart').readAsStringSync();

        expect(source, contains('WebPdvTheme.resolve(theme)'));
        expect(source, isNot(contains('Key(_themeResolver.tema)')));
        expect(source, isNot(contains('Key(themeMode)')));
      },
    );

    test('modal Selecionar itens usa superficies Web tokenizadas', () {
      final String paginaSource =
          File('lib/pagina_principal_web.dart').readAsStringSync();
      final String selectorSource =
          File(
            'lib/presentation/screens/produto_lista_sub_painel_web.dart',
          ).readAsStringSync();

      expect(paginaSource, contains('dialogTokens.surfaceElevated'));
      expect(
        paginaSource,
        contains('barrierColor: tokens.workspaceBackground'),
      );
      expect(selectorSource, contains('_usarTokensSelecaoWeb'));
      expect(selectorSource, contains('tokens.surfaceElevated'));
      expect(selectorSource, contains('tokens.selectedBackground'));
      expect(selectorSource, contains('tokens.selectedBorder'));
    });
  });
}
