import 'dart:io';

import 'package:sixpos/data/models/produto_imagem_model.dart';
import 'package:sixpos/presentation/components/produto_web_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalogo Dark Web', () {
    late String produtoDashboardSource;
    late String servicoDashboardSource;
    late String estoqueDashboardSource;
    late String produtoListaSource;
    late String produtoCadastroSource;
    late String produtoWebImageSource;
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
      produtoWebImageSource =
          File(
            'lib/presentation/components/produto_web_image.dart',
          ).readAsStringSync();
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
        expect(produtoListaSource, contains('_thumbnailImageContent'));
        expect(produtoListaSource, contains('ProdutoWebImage'));
        expect(produtoListaSource, contains('ProdutoWebImageResolver'));
        expect(produtoListaSource, contains('hasLocalDataSource'));
        expect(produtoWebImageSource, contains('image.imagemBase64'));
        expect(produtoWebImageSource, contains('image.urlMiniatura'));
        expect(
          produtoWebImageSource,
          contains('WebHtmlElementStrategy.prefer'),
        );
        expect(
          produtoWebImageSource,
          contains('WebHtmlElementStrategy.fallback'),
        );

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
        expect(produtoCadastroSource, contains('surface: tokens.surface,'));
        expect(
          produtoCadastroSource,
          contains('surfaceContainer: tokens.surfaceMuted,'),
        );
        expect(
          produtoCadastroSource,
          contains('surfaceContainerHigh: tokens.surfaceElevated,'),
        );
        expect(
          produtoCadastroSource,
          contains('surfaceContainerHighest: tokens.inputBackground,'),
        );
        expect(produtoCadastroSource, contains('tokens.surfaceElevated'));
        expect(produtoCadastroSource, contains('tokens.inputBackground'));
        expect(produtoCadastroSource, contains('tokens.surfaceMuted'));
        expect(produtoCadastroSource, contains('tokens.selectedBackground'));
        expect(produtoCadastroSource, contains('tokens.selectedBorder'));
        expect(produtoCadastroSource, contains('tokens.menuBackground'));
        expect(produtoCadastroSource, contains('floatingLabelStyle'));
        expect(produtoCadastroSource, contains('tokens.workspaceBackground'));
        expect(produtoCadastroSource, contains('barrierColor'));

        expect(
          produtoCadastroSource,
          isNot(contains('colorScheme.surfaceVariant')),
        );
        expect(
          produtoCadastroSource,
          isNot(contains('fillColor: colorScheme.surface')),
        );
        expect(produtoCadastroSource, isNot(contains('Colors.white')));
      },
    );

    test('cadastro de produto web renderiza imagens persistidas de upload', () {
      expect(produtoCadastroSource, contains('_buildImageContent'));
      expect(produtoCadastroSource, contains('ProdutoWebImage'));
      expect(
        produtoCadastroSource,
        contains('previewBytes: slot.previewBytes'),
      );
      expect(produtoWebImageSource, contains('base64.normalize'));
      expect(produtoWebImageSource, contains('Uri.decodeFull'));
      expect(produtoWebImageSource, contains('_mimeTypeFromBytes'));
      expect(produtoCadastroSource, contains('preferThumbnail: true'));
    });

    test('resolver web trata upload base64 e url externa de produto', () {
      const String png1x1 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p94AAAAASUVORK5CYII=';
      final ProdutoWebImageSource uploadSource =
          ProdutoWebImageResolver.resolve(
            ProdutoImagemModel(origem: 'UPLOAD', imagemBase64: png1x1),
          );

      expect(uploadSource.dataUrl, startsWith('data:image/png;base64,'));
      expect(uploadSource.url, isNull);
      expect(
        ProdutoWebImageResolver.hasLocalDataSource(
          ProdutoImagemModel(origem: 'UPLOAD', imagemBase64: png1x1),
        ),
        isTrue,
      );

      const String externalUrl =
          'https://images.pexels.com/photos/123456/produto.jpeg';
      final ProdutoWebImageSource externalSource =
          ProdutoWebImageResolver.resolve(
            ProdutoImagemModel(origem: 'SUGESTAO', url: externalUrl),
          );

      expect(externalSource.dataUrl, isNull);
      expect(externalSource.url, externalUrl);

      final ProdutoWebImageSource mixedSource = ProdutoWebImageResolver.resolve(
        ProdutoImagemModel(
          origem: 'UPLOAD',
          url: externalUrl,
          imagemBase64: png1x1,
        ),
      );

      expect(mixedSource.dataUrl, startsWith('data:image/png;base64,'));
      expect(mixedSource.url, isNull);
    });
  });
}
