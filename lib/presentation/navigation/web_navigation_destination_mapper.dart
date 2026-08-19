import 'modulo_central_pdv.dart';
import 'web_navigation_item.dart';

WebNavigationDestination? webNavigationDestinationForModuloCentralPdv(
  ModuloCentralPDV modulo,
) {
  switch (modulo) {
    case ModuloCentralPDV.seletor:
    case ModuloCentralPDV.cockpit:
      return WebNavigationDestination.home;
    case ModuloCentralPDV.vendas:
    case ModuloCentralPDV.recebimento:
    case ModuloCentralPDV.orcamento:
      return WebNavigationDestination.operationsPointOfSale;
    case ModuloCentralPDV.atendimentoTecnico:
    case ModuloCentralPDV.ordemServico:
      return WebNavigationDestination.operationsTechnicalServices;
    case ModuloCentralPDV.compras:
      return WebNavigationDestination.operationsPurchases;
    case ModuloCentralPDV.reservas:
      return WebNavigationDestination.operationsReservations;
    case ModuloCentralPDV.produtos:
      return WebNavigationDestination.catalogProducts;
    case ModuloCentralPDV.servicos:
      return WebNavigationDestination.catalogServices;
    case ModuloCentralPDV.estoque:
      return WebNavigationDestination.catalogStock;
    case ModuloCentralPDV.categorias:
      return WebNavigationDestination.catalogCategories;
    case ModuloCentralPDV.clientesList:
      return WebNavigationDestination.peopleCustomers;
    case ModuloCentralPDV.colaboradoresList:
      return WebNavigationDestination.peopleCollaborators;
    case ModuloCentralPDV.desempenho:
      return WebNavigationDestination.peoplePerformance;
    case ModuloCentralPDV.operacoesCaixa:
      return WebNavigationDestination.cash;
    case ModuloCentralPDV.agendaFinanceira:
      return WebNavigationDestination.financialAgenda;
    case ModuloCentralPDV.configuracoes:
      return WebNavigationDestination.settings;
  }
}
