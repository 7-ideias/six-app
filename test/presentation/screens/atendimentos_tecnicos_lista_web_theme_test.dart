import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AtendimentosTecnicosListaWebPage Dark Web', () {
    late String source;

    setUpAll(() {
      source =
          File(
            'lib/presentation/screens/atendimentos_tecnicos_lista_web_page.dart',
          ).readAsStringSync();
    });

    test('usa WebThemeTokens nas superficies operacionais', () {
      expect(source, contains("../theme/web_theme_tokens.dart"));
      expect(source, contains('tokens.workspaceBackground'));
      expect(source, contains('tokens.cardBackground'));
      expect(source, contains('tokens.inputBackground'));
      expect(source, contains('tokens.menuBackground'));
      expect(source, contains('WebThemeTokens.transitionDuration'));
      expect(source, contains('WebThemeTokens.transitionCurve'));
    });

    test('usa semantica Web para financeiro, assinatura, atraso e status', () {
      expect(source, contains('tokens.financialNegative'));
      expect(source, contains('WebThemeTokens.of(context).warning'));
      expect(source, contains('WebThemeTokens.of(context).danger'));
      expect(source, contains('WebThemeTokens.of(context).success'));
      expect(source, contains('_statusAccentForSurface'));
      expect(source, contains('_contrastRatio'));
    });

    test('evita blocos solidos problemáticos no Dark', () {
      expect(source, isNot(contains('Color(0xFFE53935)')));
      expect(
        source,
        isNot(contains('highlight ? destaque : colorScheme.surface')),
      );
      expect(source, isNot(contains('pagamentoAberto ? colorScheme.error')));
    });
  });
}
