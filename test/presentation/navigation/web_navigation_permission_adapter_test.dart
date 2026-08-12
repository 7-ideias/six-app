import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/navigation/web_navigation_permission_adapter.dart';
import 'package:sixpos/presentation/navigation/web_navigation_registry.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

void main() {
  group('WebNavigationPermissionAdapter', () {
    test(
      'ADMIN enxerga todas as areas V1, incluindo lacunas conservadoras',
      () {
        final List<WebNavigationItem> visible = _visibleItemsFor(
          _FakeAutorizacoesProvider(admin: true),
        );

        expect(_topLevelIds(visible), <String>[
          WebNavigationIds.home,
          WebNavigationIds.operations,
          WebNavigationIds.catalog,
          WebNavigationIds.people,
          WebNavigationIds.cash,
          WebNavigationIds.financial,
          WebNavigationIds.settings,
        ]);
        expect(
          _childIds(_requiredItem(visible, WebNavigationIds.people)),
          contains(WebNavigationIds.peopleCollaborators),
        );
      },
    );

    test(
      'colaborador de venda enxerga apenas Frente de caixa em Operacoes',
      () {
        final List<WebNavigationItem> visible = _visibleItemsFor(
          _FakeAutorizacoesProvider(podeFazerVenda: true),
        );

        expect(_topLevelIds(visible), <String>[
          WebNavigationIds.home,
          WebNavigationIds.operations,
        ]);
        expect(
          _childIds(_requiredItem(visible, WebNavigationIds.operations)),
          <String>[WebNavigationIds.operationsPos],
        );
      },
    );

    test('colaborador de assistencia enxerga apenas Assistencias tecnicas', () {
      final List<WebNavigationItem> visible = _visibleItemsFor(
        _FakeAutorizacoesProvider(podeLancarAssistenciaTecnica: true),
      );

      expect(_topLevelIds(visible), <String>[
        WebNavigationIds.home,
        WebNavigationIds.operations,
      ]);
      expect(
        _childIds(_requiredItem(visible, WebNavigationIds.operations)),
        <String>[WebNavigationIds.operationsTechnicalServices],
      );
    });

    test('Operacoes fica invisivel quando nenhum filho e permitido', () {
      final List<WebNavigationItem> visible = _visibleItemsFor(
        _FakeAutorizacoesProvider(),
      );

      expect(_topLevelIds(visible), <String>[WebNavigationIds.home]);
      expect(_findItem(visible, WebNavigationIds.operations), isNull);
    });

    test('Catalogo parcial com estoque nao libera Produtos nem Servicos', () {
      final List<WebNavigationItem> visible = _visibleItemsFor(
        _FakeAutorizacoesProvider(podeVerEstoqueDeProduto: true),
      );

      expect(_topLevelIds(visible), <String>[
        WebNavigationIds.home,
        WebNavigationIds.catalog,
      ]);
      expect(
        _childIds(_requiredItem(visible, WebNavigationIds.catalog)),
        <String>[WebNavigationIds.catalogStock],
      );
    });

    test(
      'Catalogo com cadastro de produto libera produtos servicos e categorias',
      () {
        final List<WebNavigationItem> visible = _visibleItemsFor(
          _FakeAutorizacoesProvider(podeCadastrarProduto: true),
        );

        expect(
          _childIds(_requiredItem(visible, WebNavigationIds.catalog)),
          <String>[
            WebNavigationIds.catalogProducts,
            WebNavigationIds.catalogServices,
            WebNavigationIds.catalogCategories,
          ],
        );
      },
    );

    test('Pessoas parcial com clientes nao libera colaboradores', () {
      final List<WebNavigationItem> visible = _visibleItemsFor(
        _FakeAutorizacoesProvider(podeEditarCliente: true),
      );

      expect(_topLevelIds(visible), <String>[
        WebNavigationIds.home,
        WebNavigationIds.people,
      ]);
      expect(
        _childIds(_requiredItem(visible, WebNavigationIds.people)),
        <String>[WebNavigationIds.peopleCustomers],
      );
    });

    test(
      'Desempenho usa permissao real de relatorio sem liberar colaboradores',
      () {
        final List<WebNavigationItem> visible = _visibleItemsFor(
          _FakeAutorizacoesProvider(podeGerarRelatorio: true),
        );

        expect(_topLevelIds(visible), <String>[
          WebNavigationIds.home,
          WebNavigationIds.people,
        ]);
        expect(
          _childIds(_requiredItem(visible, WebNavigationIds.people)),
          <String>[WebNavigationIds.peoplePerformance],
        );
      },
    );

    test('Caixa pode aparecer sem liberar Financeiro', () {
      final List<WebNavigationItem> visible = _visibleItemsFor(
        _FakeAutorizacoesProvider(podeReceberNoCaixa: true),
      );

      expect(_topLevelIds(visible), <String>[
        WebNavigationIds.home,
        WebNavigationIds.cash,
      ]);
      expect(_findItem(visible, WebNavigationIds.financial), isNull);
    });

    test('Financeiro completo libera Agenda financeira e Caixa', () {
      final List<WebNavigationItem> visible = _visibleItemsFor(
        _FakeAutorizacoesProvider(podeVerQuantoVendeu: true),
      );

      expect(_topLevelIds(visible), <String>[
        WebNavigationIds.home,
        WebNavigationIds.cash,
        WebNavigationIds.financial,
      ]);
      expect(
        _childIds(_requiredItem(visible, WebNavigationIds.financial)),
        <String>[WebNavigationIds.financialAgenda],
      );
    });

    test('Configurações fica visivel apenas para ADMIN nesta etapa', () {
      final List<WebNavigationItem> collaboratorVisible = _visibleItemsFor(
        _FakeAutorizacoesProvider(podeVerQuantoVendeu: true),
      );
      final List<WebNavigationItem> adminVisible = _visibleItemsFor(
        _FakeAutorizacoesProvider(admin: true),
      );

      expect(_findItem(collaboratorVisible, WebNavigationIds.settings), isNull);
      expect(_findItem(adminVisible, WebNavigationIds.settings), isNotNull);
    });

    test('sem autorizacoes confiaveis mostra somente Inicio', () {
      final List<WebNavigationItem> visible = _visibleItemsFor(
        _FakeAutorizacoesProvider(
          loaded: false,
          podeFazerVenda: true,
          podeEditarProduto: true,
        ),
      );

      expect(_topLevelIds(visible), <String>[WebNavigationIds.home]);
    });
  });
}

List<WebNavigationItem> _visibleItemsFor(
  ColaboradorAutorizacoesProvider provider,
) {
  return WebNavigationRegistry.activeItemsForPermissions(
    WebNavigationPermissionAdapter.permissionsFor(provider),
    includeUnresolved: WebNavigationPermissionAdapter.includeUnresolvedFor(
      provider,
    ),
  );
}

List<String> _topLevelIds(List<WebNavigationItem> items) {
  return items.map((WebNavigationItem item) => item.id).toList();
}

List<String> _childIds(WebNavigationItem item) {
  return item.children.map((WebNavigationItem child) => child.id).toList();
}

WebNavigationItem _requiredItem(List<WebNavigationItem> items, String id) {
  final WebNavigationItem? item = _findItem(items, id);
  expect(item, isNotNull, reason: 'Item $id deveria existir.');
  return item!;
}

WebNavigationItem? _findItem(List<WebNavigationItem> items, String id) {
  for (final WebNavigationItem item in items) {
    for (final WebNavigationItem flattenedItem in item.flatten()) {
      if (flattenedItem.id == id) return flattenedItem;
    }
  }
  return null;
}

class _FakeAutorizacoesProvider extends ColaboradorAutorizacoesProvider {
  _FakeAutorizacoesProvider({
    this.admin = false,
    this.loaded = true,
    this.podeFazerVenda = false,
    this.podeLancarAssistenciaTecnica = false,
    this.podeEditarCliente = false,
    this.podeCadastrarProduto = false,
    this.podeEditarProduto = false,
    this.podeVerEstoqueDeProduto = false,
    this.podeGerarRelatorio = false,
    this.podeReceberNoCaixa = false,
    this.podeVerQuantoVendeu = false,
  });

  final bool admin;
  final bool loaded;

  @override
  final bool podeFazerVenda;

  @override
  final bool podeLancarAssistenciaTecnica;

  @override
  final bool podeEditarCliente;

  @override
  final bool podeCadastrarProduto;

  @override
  final bool podeEditarProduto;

  @override
  final bool podeVerEstoqueDeProduto;

  @override
  final bool podeGerarRelatorio;

  @override
  final bool podeReceberNoCaixa;

  @override
  final bool podeVerQuantoVendeu;

  @override
  bool get ehAdministrador => admin;

  @override
  bool get autorizacoesCarregadasComSucesso => loaded;
}
