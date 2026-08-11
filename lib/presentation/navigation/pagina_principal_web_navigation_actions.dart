import 'modulo_central_pdv.dart';
import 'web_navigation_destination_resolver.dart';
import 'web_navigation_item.dart';

typedef AbrirModuloCentralPdv = void Function(ModuloCentralPDV modulo);
typedef ExecutarAcaoNavegacaoWeb = void Function();

class PaginaPrincipalWebNavigationActions
    implements WebNavigationDestinationActions {
  const PaginaPrincipalWebNavigationActions({
    required this.abrirModuloCentral,
    required ExecutarAcaoNavegacaoWeb abrirFrenteCaixa,
    required ExecutarAcaoNavegacaoWeb abrirCaixa,
  }) : _abrirFrenteCaixa = abrirFrenteCaixa,
       _abrirCaixa = abrirCaixa;

  final AbrirModuloCentralPdv abrirModuloCentral;
  final ExecutarAcaoNavegacaoWeb _abrirFrenteCaixa;
  final ExecutarAcaoNavegacaoWeb _abrirCaixa;

  @override
  WebNavigationResolutionResult openHome() {
    return _abrirModulo(
      WebNavigationDestination.home,
      ModuloCentralPDV.seletor,
    );
  }

  @override
  WebNavigationResolutionResult openPointOfSale() {
    _abrirFrenteCaixa();
    return WebNavigationResolutionResult.handled(
      WebNavigationDestination.operationsPointOfSale,
    );
  }

  @override
  WebNavigationResolutionResult openTechnicalServices() {
    return _abrirModulo(
      WebNavigationDestination.operationsTechnicalServices,
      ModuloCentralPDV.atendimentoTecnico,
    );
  }

  @override
  WebNavigationResolutionResult openCatalogProducts() {
    return _abrirModulo(
      WebNavigationDestination.catalogProducts,
      ModuloCentralPDV.produtos,
    );
  }

  @override
  WebNavigationResolutionResult openCatalogServices() {
    return _abrirModulo(
      WebNavigationDestination.catalogServices,
      ModuloCentralPDV.servicos,
    );
  }

  @override
  WebNavigationResolutionResult openCatalogStock() {
    return _abrirModulo(
      WebNavigationDestination.catalogStock,
      ModuloCentralPDV.estoque,
    );
  }

  @override
  WebNavigationResolutionResult openCatalogCategories() {
    return _abrirModulo(
      WebNavigationDestination.catalogCategories,
      ModuloCentralPDV.categorias,
    );
  }

  @override
  WebNavigationResolutionResult openPeopleCustomers() {
    return _abrirModulo(
      WebNavigationDestination.peopleCustomers,
      ModuloCentralPDV.clientesList,
    );
  }

  @override
  WebNavigationResolutionResult openPeopleCollaborators() {
    return _abrirModulo(
      WebNavigationDestination.peopleCollaborators,
      ModuloCentralPDV.colaboradoresList,
    );
  }

  @override
  WebNavigationResolutionResult openPeoplePerformance() {
    return _abrirModulo(
      WebNavigationDestination.peoplePerformance,
      ModuloCentralPDV.desempenho,
    );
  }

  @override
  WebNavigationResolutionResult openCash() {
    _abrirCaixa();
    return WebNavigationResolutionResult.handled(WebNavigationDestination.cash);
  }

  @override
  WebNavigationResolutionResult openFinancialAgenda() {
    return _abrirModulo(
      WebNavigationDestination.financialAgenda,
      ModuloCentralPDV.agendaFinanceira,
    );
  }

  @override
  WebNavigationResolutionResult openSettings() {
    return _abrirModulo(
      WebNavigationDestination.settings,
      ModuloCentralPDV.configuracoes,
    );
  }

  WebNavigationResolutionResult _abrirModulo(
    WebNavigationDestination destination,
    ModuloCentralPDV modulo,
  ) {
    abrirModuloCentral(modulo);
    return WebNavigationResolutionResult.handled(destination);
  }
}
