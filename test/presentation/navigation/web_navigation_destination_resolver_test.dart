import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_navigation_destination_resolver.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';

void main() {
  group('WebNavigationDestinationResolver', () {
    test('resolve todos os destinos ativos para uma unica acao', () {
      final Map<WebNavigationDestination, String> expectedActions =
          <WebNavigationDestination, String>{
            WebNavigationDestination.home: 'home',
            WebNavigationDestination.operationsPointOfSale: 'pointOfSale',
            WebNavigationDestination.operationsTechnicalServices:
                'technicalServices',
            WebNavigationDestination.operationsPurchases: 'purchases',
            WebNavigationDestination.catalogProducts: 'catalogProducts',
            WebNavigationDestination.catalogServices: 'catalogServices',
            WebNavigationDestination.catalogStock: 'catalogStock',
            WebNavigationDestination.catalogCategories: 'catalogCategories',
            WebNavigationDestination.peopleCustomers: 'peopleCustomers',
            WebNavigationDestination.peopleCollaborators: 'peopleCollaborators',
            WebNavigationDestination.peoplePerformance: 'peoplePerformance',
            WebNavigationDestination.cash: 'cash',
            WebNavigationDestination.financialAgenda: 'financialAgenda',
            WebNavigationDestination.settings: 'settings',
          };

      for (final MapEntry<WebNavigationDestination, String> entry
          in expectedActions.entries) {
        final _FakeWebNavigationActions actions = _FakeWebNavigationActions();
        final WebNavigationDestinationResolver resolver =
            WebNavigationDestinationResolver(actions: actions);

        final WebNavigationResolutionResult result = resolver.resolve(
          entry.key,
        );

        expect(result.handled, isTrue, reason: entry.key.name);
        expect(result.destination, entry.key);
        expect(result.reserved, isFalse);
        expect(result.unsupported, isFalse);
        expect(actions.calls, <String>[entry.value], reason: entry.key.name);
      }
    });

    test('nao dispara acao para destino reservado de relatorios', () {
      final _FakeWebNavigationActions actions = _FakeWebNavigationActions();
      final WebNavigationDestinationResolver resolver =
          WebNavigationDestinationResolver(actions: actions);

      final WebNavigationResolutionResult result = resolver.resolve(
        WebNavigationDestination.reports,
      );

      expect(result.reserved, isTrue);
      expect(result.destination, WebNavigationDestination.reports);
      expect(result.reason, isNotEmpty);
      expect(actions.calls, isEmpty);
    });

    test('retorna unsupported para destino ausente', () {
      final _FakeWebNavigationActions actions = _FakeWebNavigationActions();
      final WebNavigationDestinationResolver resolver =
          WebNavigationDestinationResolver(actions: actions);

      final WebNavigationResolutionResult result = resolver.resolve(null);

      expect(result.unsupported, isTrue);
      expect(result.destination, isNull);
      expect(result.reason, isNotEmpty);
      expect(actions.calls, isEmpty);
    });
  });
}

class _FakeWebNavigationActions implements WebNavigationDestinationActions {
  final List<String> calls = <String>[];

  WebNavigationResolutionResult _handled(
    String call,
    WebNavigationDestination destination,
  ) {
    calls.add(call);
    return WebNavigationResolutionResult.handled(destination);
  }

  @override
  WebNavigationResolutionResult openHome() {
    return _handled('home', WebNavigationDestination.home);
  }

  @override
  WebNavigationResolutionResult openPointOfSale() {
    return _handled(
      'pointOfSale',
      WebNavigationDestination.operationsPointOfSale,
    );
  }

  @override
  WebNavigationResolutionResult openTechnicalServices() {
    return _handled(
      'technicalServices',
      WebNavigationDestination.operationsTechnicalServices,
    );
  }

  @override
  WebNavigationResolutionResult openPurchases() {
    return _handled('purchases', WebNavigationDestination.operationsPurchases);
  }

  @override
  WebNavigationResolutionResult openCatalogProducts() {
    return _handled(
      'catalogProducts',
      WebNavigationDestination.catalogProducts,
    );
  }

  @override
  WebNavigationResolutionResult openCatalogServices() {
    return _handled(
      'catalogServices',
      WebNavigationDestination.catalogServices,
    );
  }

  @override
  WebNavigationResolutionResult openCatalogStock() {
    return _handled('catalogStock', WebNavigationDestination.catalogStock);
  }

  @override
  WebNavigationResolutionResult openCatalogCategories() {
    return _handled(
      'catalogCategories',
      WebNavigationDestination.catalogCategories,
    );
  }

  @override
  WebNavigationResolutionResult openPeopleCustomers() {
    return _handled(
      'peopleCustomers',
      WebNavigationDestination.peopleCustomers,
    );
  }

  @override
  WebNavigationResolutionResult openPeopleCollaborators() {
    return _handled(
      'peopleCollaborators',
      WebNavigationDestination.peopleCollaborators,
    );
  }

  @override
  WebNavigationResolutionResult openPeoplePerformance() {
    return _handled(
      'peoplePerformance',
      WebNavigationDestination.peoplePerformance,
    );
  }

  @override
  WebNavigationResolutionResult openCash() {
    return _handled('cash', WebNavigationDestination.cash);
  }

  @override
  WebNavigationResolutionResult openFinancialAgenda() {
    return _handled(
      'financialAgenda',
      WebNavigationDestination.financialAgenda,
    );
  }

  @override
  WebNavigationResolutionResult openSettings() {
    return _handled('settings', WebNavigationDestination.settings);
  }
}
