import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Configuracoes Dark Web', () {
    late String source;

    setUpAll(() {
      source =
          File(
            'lib/presentation/screens/configuracoes_six_web_page.dart',
          ).readAsStringSync();
    });

    test('usa WebThemeTokens nas superficies, controles e feedback', () {
      expect(source, contains('web_theme_tokens.dart'));
      expect(source, contains('tokens.workspaceBackground'));
      expect(source, contains('tokens.surface'));
      expect(source, contains('tokens.cardBackground'));
      expect(source, contains('tokens.cardBorder'));
      expect(source, contains('tokens.inputBackground'));
      expect(source, contains('tokens.surfaceElevated'));
      expect(source, contains('tokens.selectedBackground'));
      expect(source, contains('tokens.selectedBorder'));
      expect(source, contains('tokens.disabledBackground'));
      expect(source, contains('tokens.disabledForeground'));
      expect(source, contains('backgroundColor: tokens.success'));
      expect(source, contains('backgroundColor: tokens.danger'));

      expect(source, isNot(contains('Colors.green')));
      expect(source, isNot(contains('Colors.red')));
      expect(source, isNot(contains('withOpacity')));
      expect(source, isNot(contains('surfaceContainer')));
      expect(source, isNot(contains('outlineVariant')));
    });

    test('Aparencia tem opcoes de tema com selected state explicito', () {
      expect(source, contains('Widget _buildThemeOptionCard'));
      expect(source, contains('Widget _buildThemeOptions'));
      expect(source, contains('_selecionarTemaVisual(label)'));
      expect(source, contains("label: 'Claro'"));
      expect(source, contains("label: 'Escuro'"));
      expect(source, contains("label: 'Automático'"));
      expect(source, contains('Semantics('));
      expect(source, contains('selected: selected'));
      expect(source, contains('Icons.check_circle_rounded'));
      expect(source, isNot(contains("label: 'Tema do sistema'")));
    });

    test('layout compacto leva o usuario para a secao selecionada', () {
      expect(
        source,
        contains('final ScrollController _conteudoScrollController'),
      );
      expect(source, contains('final GlobalKey _conteudoSecaoKey'));
      expect(source, contains('bool _ultimoLayoutEmpilhado'));
      expect(source, contains('void _selecionarSecao'));
      expect(source, contains('void _garantirConteudoSelecionadoVisivel'));
      expect(source, contains('Scrollable.ensureVisible'));
      expect(source, contains('WebThemeTokens.transitionDuration'));
      expect(source, contains('WebThemeTokens.transitionCurve'));
      expect(source, contains('key: _conteudoSecaoKey'));
      expect(source, contains('constraints.maxWidth < 1180'));
      expect(source, contains('constraints.maxWidth < 1040'));
    });

    test(
      'troca de tema nao usa key por tema nem altera infraestrutura global',
      () {
        expect(source, contains('SixThemeResolver().atualizarConfiguracao'));
        expect(source, contains('_aplicarAparenciaPreview'));
        expect(source, isNot(contains('Key(_temaSelecionado)')));
        expect(source, isNot(contains('Key(themeMode)')));
        expect(source, isNot(contains('ThemeProvider')));
        expect(source, isNot(contains('SharedPreferences')));
      },
    );
  });
}
