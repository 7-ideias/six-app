import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/modulo_central_pdv.dart';
import 'package:sixpos/presentation/navigation/pagina_principal_web_navigation_actions.dart';
import 'package:sixpos/presentation/navigation/web_navigation_destination_resolver.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/navigation/web_navigation_registry.dart';

void main() {
  group('PaginaPrincipalWebNavigationActions', () {
    test('resolve destinos com ModuloCentralPDV para os modulos reais', () {
      final Map<WebNavigationDestination, ModuloCentralPDV>
      expectedModules = <WebNavigationDestination, ModuloCentralPDV>{
        WebNavigationDestination.home: ModuloCentralPDV.seletor,
        WebNavigationDestination.operationsPointOfSale: ModuloCentralPDV.vendas,
        WebNavigationDestination.operationsTechnicalServices:
            ModuloCentralPDV.atendimentoTecnico,
        WebNavigationDestination.operationsPurchases: ModuloCentralPDV.compras,
        WebNavigationDestination.catalogProducts: ModuloCentralPDV.produtos,
        WebNavigationDestination.catalogServices: ModuloCentralPDV.servicos,
        WebNavigationDestination.catalogStock: ModuloCentralPDV.estoque,
        WebNavigationDestination.catalogCategories: ModuloCentralPDV.categorias,
        WebNavigationDestination.peopleCustomers: ModuloCentralPDV.clientesList,
        WebNavigationDestination.peopleCollaborators:
            ModuloCentralPDV.colaboradoresList,
        WebNavigationDestination.peoplePerformance: ModuloCentralPDV.desempenho,
        WebNavigationDestination.cash: ModuloCentralPDV.operacoesCaixa,
        WebNavigationDestination.financialAgenda:
            ModuloCentralPDV.agendaFinanceira,
        WebNavigationDestination.settings: ModuloCentralPDV.configuracoes,
      };

      for (final MapEntry<WebNavigationDestination, ModuloCentralPDV> entry
          in expectedModules.entries) {
        final List<ModuloCentralPDV> openedModules = <ModuloCentralPDV>[];
        final PaginaPrincipalWebNavigationActions
        actions = PaginaPrincipalWebNavigationActions(
          abrirModuloCentral: openedModules.add,
          abrirFrenteCaixa: () => openedModules.add(ModuloCentralPDV.vendas),
          abrirCaixa: () => openedModules.add(ModuloCentralPDV.operacoesCaixa),
        );
        final WebNavigationDestinationResolver resolver =
            WebNavigationDestinationResolver(actions: actions);

        final WebNavigationResolutionResult result = resolver.resolve(
          entry.key,
        );

        expect(result.handled, isTrue, reason: entry.key.name);
        expect(result.destination, entry.key);
        expect(openedModules, <ModuloCentralPDV>[
          entry.value,
        ], reason: entry.key.name);
      }
    });

    test('todos os destinos ativos do registry possuem resolucao real', () {
      final List<ModuloCentralPDV> openedModules = <ModuloCentralPDV>[];
      final PaginaPrincipalWebNavigationActions actions =
          PaginaPrincipalWebNavigationActions(
            abrirModuloCentral: openedModules.add,
            abrirFrenteCaixa: () => openedModules.add(ModuloCentralPDV.vendas),
            abrirCaixa:
                () => openedModules.add(ModuloCentralPDV.operacoesCaixa),
          );
      final WebNavigationDestinationResolver resolver =
          WebNavigationDestinationResolver(actions: actions);

      final List<WebNavigationDestination> activeDestinations =
          WebNavigationRegistry.flattenActiveItems()
              .map((WebNavigationItem item) => item.destination)
              .whereType<WebNavigationDestination>()
              .where(
                (WebNavigationDestination destination) =>
                    destination != WebNavigationDestination.catalogLabels,
              )
              .toList(growable: false);

      for (final WebNavigationDestination destination in activeDestinations) {
        final WebNavigationResolutionResult result = resolver.resolve(
          destination,
        );

        expect(result.handled, isTrue, reason: destination.name);
        expect(result.destination, destination);
      }

      expect(openedModules, hasLength(activeDestinations.length));
      expect(
        activeDestinations,
        isNot(contains(WebNavigationDestination.reports)),
      );
    });
  });
}
