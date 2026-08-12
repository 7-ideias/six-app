import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Financeiro Operacional Dark Web', () {
    late String caixaSource;
    late String agendaSource;
    late String agendaLancamentoSource;

    setUpAll(() {
      caixaSource =
          File(
            'lib/presentation/screens/operacoes_caixa_web_page.dart',
          ).readAsStringSync();
      agendaSource =
          File(
            'lib/presentation/screens/agenda_financeira_web.dart',
          ).readAsStringSync();
      agendaLancamentoSource =
          File(
            'lib/sub_painel_lancamento_agenda_financeira_web.dart',
          ).readAsStringSync();
    });

    test('Caixa usa WebThemeTokens em surfaces, inputs e modais', () {
      expect(caixaSource, contains('web_theme_tokens.dart'));
      expect(caixaSource, contains('tokens.workspaceBackground'));
      expect(caixaSource, contains('tokens.cardBackground'));
      expect(caixaSource, contains('tokens.surfaceMuted'));
      expect(caixaSource, contains('tokens.inputBackground'));
      expect(caixaSource, contains('tokens.surfaceElevated'));
      expect(caixaSource, contains('tokens.menuBackground'));
      expect(caixaSource, contains('tokens.selectedBackground'));
      expect(caixaSource, contains('tokens.selectedBorder'));
      expect(caixaSource, contains('barrierColor: tokens.workspaceBackground'));
    });

    test('Caixa usa semantica financeira sem hardcodes legados', () {
      expect(caixaSource, contains('tokens.financialPositive'));
      expect(caixaSource, contains('tokens.financialNegative'));
      expect(caixaSource, contains('tokens.success'));
      expect(caixaSource, contains('tokens.warning'));
      expect(caixaSource, contains('tokens.danger'));
      expect(caixaSource, contains('tokens.statusNeutral'));

      expect(caixaSource, isNot(contains('Color(0xff0f766e)')));
      expect(caixaSource, isNot(contains('Color(0xffb45309)')));
      expect(caixaSource, isNot(contains('Color(0xffbe123c)')));
      expect(caixaSource, isNot(contains('Color(0xff4338ca)')));
      expect(caixaSource, isNot(contains('Color(0xff047857)')));
      expect(caixaSource, isNot(contains('Color(0xff991b1b)')));
      expect(caixaSource, isNot(contains('highlight ? colorScheme.primary')));
    });

    test('Agenda usa tema local Web e tokens financeiros', () {
      expect(agendaSource, contains('web_theme_tokens.dart'));
      expect(agendaSource, contains('ThemeData _agendaWebTheme'));
      expect(agendaSource, contains('tokens.workspaceBackground'));
      expect(agendaSource, contains('tokens.cardBackground'));
      expect(agendaSource, contains('tokens.inputBackground'));
      expect(agendaSource, contains('tokens.menuBackground'));
      expect(agendaSource, contains('tokens.surfaceElevated'));
      expect(agendaSource, contains('tokens.selectedBackground'));
      expect(agendaSource, contains('tokens.selectedBorder'));
      expect(agendaSource, contains('tokens.financialPositive'));
      expect(agendaSource, contains('tokens.financialNegative'));
      expect(agendaSource, contains('tokens.warning'));
      expect(agendaSource, contains('tokens.danger'));
      expect(agendaSource, contains('tokens.statusNeutral'));
    });

    test('Agenda tokeniza modais, filtros e status sem blocos solidos', () {
      expect(
        agendaSource,
        contains('barrierColor: pageTokens.workspaceBackground'),
      );
      expect(agendaSource, contains('barrierColor: WebThemeTokens.of('));
      expect(agendaSource, contains('backgroundColor: tokens.surfaceElevated'));
      expect(agendaSource, contains('color: tokens.menuBackground'));
      expect(
        agendaSource,
        contains('color: selected ? tokens.selectedBackground'),
      );
      expect(agendaSource, contains('tokens.financialPositive'));
      expect(agendaSource, contains('tokens.financialNegative'));

      expect(agendaSource, isNot(contains('Color(0xFF16A34A)')));
      expect(agendaSource, isNot(contains('Color(0xFFF59E0B)')));
      expect(agendaSource, isNot(contains('Color(0xFFDC2626)')));
    });

    test('Subpainel de lancamento da Agenda nao usa fundo branco legado', () {
      expect(agendaLancamentoSource, contains('web_theme_tokens.dart'));
      expect(agendaLancamentoSource, contains('tokens.surfaceElevated'));
      expect(agendaLancamentoSource, contains('tokens.workspaceBackground'));
      expect(agendaLancamentoSource, contains('tokens.cardBackground'));
      expect(agendaLancamentoSource, contains('tokens.inputBackground'));
      expect(agendaLancamentoSource, contains('tokens.menuBackground'));
      expect(agendaLancamentoSource, contains('tokens.selectedBackground'));
      expect(agendaLancamentoSource, contains('tokens.disabledBackground'));
      expect(
        agendaLancamentoSource,
        contains('barrierColor: WebThemeTokens.of('),
      );

      expect(agendaLancamentoSource, isNot(contains('color: Colors.white')));
      expect(
        agendaLancamentoSource,
        isNot(contains('extends SubPainelWebGeneral')),
      );
    });
  });
}
