import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/navigation/web_navigation_registry.dart';

void main() {
  group('WebNavigationRegistry', () {
    test('declara a estrutura ativa aprovada para a navegacao Web V1', () {
      expect(_topLevelIds(), <String>[
        WebNavigationIds.home,
        WebNavigationIds.operations,
        WebNavigationIds.catalog,
        WebNavigationIds.people,
        WebNavigationIds.cash,
        WebNavigationIds.financial,
        WebNavigationIds.settings,
      ]);

      final WebNavigationItem operations = _requiredItem(
        WebNavigationIds.operations,
      );
      expect(_childIds(operations), <String>[
        WebNavigationIds.operationsPos,
        WebNavigationIds.operationsTechnicalServices,
        WebNavigationIds.operationsPurchases,
      ]);
      expect(_childLabels(operations), <String>[
        'Frente de caixa',
        'Assistências técnicas',
        'Compras',
      ]);
      expect(
        operations.children[2].destination,
        WebNavigationDestination.operationsPurchases,
      );

      final WebNavigationItem catalog = _requiredItem(WebNavigationIds.catalog);
      expect(_childIds(catalog), <String>[
        WebNavigationIds.catalogProducts,
        WebNavigationIds.catalogServices,
        WebNavigationIds.catalogStock,
        WebNavigationIds.catalogLabels,
        WebNavigationIds.catalogCategories,
      ]);

      final WebNavigationItem people = _requiredItem(WebNavigationIds.people);
      expect(_childIds(people), <String>[
        WebNavigationIds.peopleCustomers,
        WebNavigationIds.peopleCollaborators,
        WebNavigationIds.peoplePerformance,
      ]);

      final WebNavigationItem financial = _requiredItem(
        WebNavigationIds.financial,
      );
      expect(_childIds(financial), <String>[WebNavigationIds.financialAgenda]);

      expect(_requiredItem(WebNavigationIds.home).labelFallback, 'Início');
      expect(_requiredItem(WebNavigationIds.cash).labelFallback, 'Caixa');
      expect(
        _requiredItem(WebNavigationIds.settings).labelFallback,
        'Configurações',
      );
    });

    test(
      'nao inclui itens preparatorios, legados ou acoes na arvore ativa',
      () {
        final Set<String> ids =
            _allActiveItems().map((item) => item.id).toSet();
        final Set<String> labels =
            _allActiveItems().map((item) => item.labelFallback).toSet();

        expect(ids, isNot(contains(WebNavigationIds.reports)));

        expect(labels, isNot(contains('Legado')));
        expect(labels, isNot(contains('Relatórios')));
        expect(labels, isNot(contains('Fiado')));
        expect(labels, isNot(contains('Crediário')));
        expect(labels, isNot(contains('Fornecedores')));
        expect(labels, isNot(contains('Nova venda')));
        expect(labels, isNot(contains('Novo atendimento')));
        expect(labels, isNot(contains('Novo orçamento')));
        expect(labels, isNot(contains('Abrir caixa')));
        expect(labels, isNot(contains('Fechar caixa')));
        expect(labels, isNot(contains('Sangria')));
        expect(labels, isNot(contains('Suprimento')));
      },
    );

    test('mantem IDs unicos e estaveis, independentes dos labels', () {
      final List<WebNavigationItem> items = _allActiveItems();
      final List<String> ids = items.map((item) => item.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(
        ids,
        containsAll(<String>[
          'home',
          'operations',
          'operations.pos',
          'operations.technical_service',
          'operations.purchases',
          'catalog',
          'catalog.products',
          'catalog.services',
          'catalog.stock',
          'catalog.categories',
          'people',
          'people.customers',
          'people.collaborators',
          'people.performance',
          'cash',
          'financial',
          'financial.agenda',
          'settings',
        ]),
      );

      for (final WebNavigationItem item in items) {
        expect(item.id, isNot(item.labelFallback));
        expect(item.id, matches(RegExp(r'^[a-z]+(\.[a-z_]+)*$')));
        expect(item.id, isNot(_normalizedLabel(item.labelFallback)));
      }
    });

    test('limita a hierarquia ativa a grupo e filho', () {
      for (final WebNavigationItem item in WebNavigationRegistry.activeItems) {
        expect(item.maxDepth, lessThanOrEqualTo(2));
      }
    });

    test(
      'mantem relatorios apenas como item reservado fora da arvore ativa',
      () {
        expect(WebNavigationRegistry.reservedItems, hasLength(1));
        expect(WebNavigationRegistry.reservedItems.single.id, 'reports');
        expect(
          WebNavigationRegistry.reservedItems.single.destination,
          WebNavigationDestination.reports,
        );

        expect(
          WebNavigationRegistry.findActiveById(WebNavigationIds.reports),
          isNull,
        );
      },
    );

    test('prepara filtro futuro ocultando grupos sem filhos permitidos', () {
      final List<WebNavigationItem> visible =
          WebNavigationRegistry.activeItemsForPermissions(
            <WebNavigationPermission>{WebNavigationPermission.podeFazerVenda},
            includeUnresolved: false,
          );

      expect(visible.map((item) => item.id), <String>[
        WebNavigationIds.home,
        WebNavigationIds.operations,
      ]);

      final WebNavigationItem operations = visible.singleWhere(
        (item) => item.id == WebNavigationIds.operations,
      );
      expect(_childIds(operations), <String>[WebNavigationIds.operationsPos]);
    });

    test('exibe Compras para admin com destino valido e ordem estavel', () {
      final List<WebNavigationItem> visible =
          WebNavigationRegistry.activeItemsForPermissions(
            WebNavigationPermission.values.toSet(),
            includeUnresolved: true,
          );

      final WebNavigationItem operations = visible.singleWhere(
        (item) => item.id == WebNavigationIds.operations,
      );
      final List<String> childIds = _childIds(operations);
      final int technicalIndex = childIds.indexOf(
        WebNavigationIds.operationsTechnicalServices,
      );
      final int purchasesIndex = childIds.indexOf(
        WebNavigationIds.operationsPurchases,
      );

      expect(technicalIndex, greaterThanOrEqualTo(0));
      expect(purchasesIndex, technicalIndex + 1);
      expect(
        operations.children[purchasesIndex].destination,
        WebNavigationDestination.operationsPurchases,
      );
    });
  });
}

List<WebNavigationItem> _allActiveItems() {
  return WebNavigationRegistry.flattenActiveItems().toList();
}

List<String> _topLevelIds() {
  return WebNavigationRegistry.activeItems.map((item) => item.id).toList();
}

WebNavigationItem _requiredItem(String id) {
  final WebNavigationItem? item = WebNavigationRegistry.findActiveById(id);
  expect(item, isNotNull, reason: 'Item $id deveria existir.');
  return item!;
}

List<String> _childIds(WebNavigationItem item) {
  return item.children.map((child) => child.id).toList();
}

List<String> _childLabels(WebNavigationItem item) {
  return item.children.map((child) => child.labelFallback).toList();
}

String _normalizedLabel(String label) {
  return label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
      .replaceAll(RegExp(r'^\.+|\.+$'), '');
}
