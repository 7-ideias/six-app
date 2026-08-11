import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalogo Dark Web', () {
    late String produtoDashboardSource;
    late String servicoDashboardSource;
    late String estoqueDashboardSource;
    late String produtoListaSource;
    late String produtoCadastroSource;
    late String dashboardWidgetsSource;

    setUpAll(() {
      produtoDashboardSource =
          File(
            'lib/presentation/screens/produto_dashboard_web_page.dart',
          ).readAsStringSync();
      servicoDashboardSource =
          File(
            'lib/presentation/screens/servico_dashboard_web_page.dart',
          ).readAsStringSync();
      estoqueDashboardSource =
          File(
            'lib/presentation/screens/estoque_dashboard_web_page.dart',
          ).readAsStringSync();
      produtoListaSource =
          File(
            'lib/presentation/screens/produto_lista_sub_painel_web.dart',
          ).readAsStringSync();
      produtoCadastroSource =
          File('lib/sub_painel_cadastro_produto_web.dart').readAsStringSync();
      dashboardWidgetsSource =
          File(
            'lib/presentation/components/web_dashboard_widgets.dart',
          ).readAsStringSync();
    });

    test('dashboards de catalogo usam WebThemeTokens nas superficies', () {
      expect(produtoDashboardSource, contains('web_theme_tokens.dart'));
      expect(servicoDashboardSource, contains('web_theme_tokens.dart'));
      expect(estoqueDashboardSource, contains('web_theme_tokens.dart'));
      expect(dashboardWidgetsSource, contains('web_theme_tokens.dart'));

      expect(produtoDashboardSource, contains('tokens.workspaceBackground'));
      expect(produtoDashboardSource, contains('tokens.cardBackground'));
      expect(servicoDashboardSource, contains('tokens.workspaceBackground'));
      expect(servicoDashboardSource, contains('tokens.surfaceMuted'));
      expect(estoqueDashboardSource, contains('tokens.workspaceBackground'));
      expect(estoqueDashboardSource, contains('tokens.surfaceMuted'));
      expect(dashboardWidgetsSource, contains('tokens.cardBackground'));
      expect(dashboardWidgetsSource, contains('tokens.cardBorder'));
    });

    test('semantica de estoque nao depende de blocos solidos legados', () {
      expect(produtoDashboardSource, contains('tokens.stockWarning'));
      expect(produtoDashboardSource, contains('tokens.stockCritical'));
      expect(estoqueDashboardSource, contains('tokens.stockWarning'));
      expect(estoqueDashboardSource, contains('tokens.stockCritical'));
      expect(estoqueDashboardSource, contains('_stockSerieColor'));
      expect(estoqueDashboardSource, contains('_stockProblemColor'));
      expect(estoqueDashboardSource, contains('tokens.surfaceMuted'));
      expect(produtoDashboardSource, contains('tokens.surfaceMuted'));
      expect(servicoDashboardSource, contains('tokens.surfaceMuted'));

      expect(estoqueDashboardSource, isNot(contains('Colors.green.shade700')));
      expect(estoqueDashboardSource, isNot(contains('Colors.orange.shade700')));
      expect(
        produtoDashboardSource,
        isNot(contains('color.withValues(alpha: 0.10)')),
      );
      expect(
        produtoDashboardSource,
        isNot(contains('color.withValues(alpha: 0.28)')),
      );
      expect(
        servicoDashboardSource,
        isNot(contains('color.withValues(alpha: 0.08)')),
      );
      expect(
        servicoDashboardSource,
        isNot(contains('color.withValues(alpha: 0.22)')),
      );
      expect(
        estoqueDashboardSource,
        isNot(contains('color.withValues(alpha: 0.08)')),
      );
      expect(servicoDashboardSource, isNot(contains('Colors.green.shade700')));
      expect(servicoDashboardSource, isNot(contains('Colors.orange.shade700')));
    });

    test(
      'lista de produtos tokeniza modo catalogo e preserva seletor do PDV',
      () {
        expect(produtoListaSource, contains('_usarTokensSelecaoWeb'));
        expect(produtoListaSource, contains('tokens.workspaceBackground'));
        expect(produtoListaSource, contains('tokens.inputBackground'));
        expect(produtoListaSource, contains('tokens.menuBackground'));
        expect(produtoListaSource, contains('tokens.selectedBackground'));
        expect(produtoListaSource, contains('tokens.selectedBorder'));
        expect(produtoListaSource, contains('tokens.statusNeutral'));

        expect(
          produtoListaSource,
          isNot(contains('surfaceContainerHighest.withValues')),
        );
        expect(produtoListaSource, isNot(contains('Colors.green.shade700')));
      },
    );

    test(
      'cadastro de produto web usa tokens em modal e preview de imagens',
      () {
        expect(produtoCadastroSource, contains('web_theme_tokens.dart'));
        expect(produtoCadastroSource, contains('WebThemeTokens.of(context)'));
        expect(produtoCadastroSource, contains('tokens.surfaceElevated'));
        expect(produtoCadastroSource, contains('tokens.inputBackground'));
        expect(produtoCadastroSource, contains('tokens.surfaceMuted'));
        expect(produtoCadastroSource, contains('tokens.selectedBackground'));
        expect(produtoCadastroSource, contains('tokens.selectedBorder'));
        expect(produtoCadastroSource, contains('tokens.workspaceBackground'));
        expect(produtoCadastroSource, contains('barrierColor'));

        expect(
          produtoCadastroSource,
          isNot(contains('colorScheme.surfaceVariant')),
        );
        expect(produtoCadastroSource, isNot(contains('Colors.white')));
      },
    );
  });
}
