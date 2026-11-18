import 'modulo_central_pdv.dart';
import 'web_navigation_destination_mapper.dart';
import 'web_navigation_item.dart';

const webDestinationRoutes = <WebNavigationDestination, String>{
  WebNavigationDestination.home: '/app',
  WebNavigationDestination.operationsPointOfSale: '/app/frente-de-caixa',
  WebNavigationDestination.operationsSales: '/app/vendas',
  WebNavigationDestination.operationsTechnicalServices: '/app/assistencias',
  WebNavigationDestination.operationsPurchases: '/app/compras',
  WebNavigationDestination.operationsReservations: '/app/reservas',
  WebNavigationDestination.operationsReturns: '/app/devolucoes',
  WebNavigationDestination.catalogPublicPage: '/app/catalogo',
  WebNavigationDestination.catalogProducts: '/app/produtos',
  WebNavigationDestination.catalogServices: '/app/servicos',
  WebNavigationDestination.catalogStock: '/app/estoque',
  WebNavigationDestination.catalogLabels: '/app/etiquetas',
  WebNavigationDestination.catalogCategories: '/app/categorias',
  WebNavigationDestination.peopleCustomers: '/app/clientes',
  WebNavigationDestination.peopleSuppliers: '/app/fornecedores',
  WebNavigationDestination.peopleCollaborators: '/app/colaboradores',
  WebNavigationDestination.peopleSixoUsers: '/app/usuarios',
  WebNavigationDestination.peoplePerformance: '/app/desempenho',
  WebNavigationDestination.visualAssets: '/app/imagens',
  WebNavigationDestination.adminPlans: '/app/admin/planos',
  WebNavigationDestination.pushCampaigns: '/app/campanhas-push',
  WebNavigationDestination.superPanel: '/app/painel-super',
  WebNavigationDestination.productIdeas: '/app/novas-ideias',
  WebNavigationDestination.cash: '/app/caixa',
  WebNavigationDestination.financialAgenda: '/app/agenda-financeira',
  WebNavigationDestination.settings: '/app/configuracoes',
};

WebNavigationDestination? webDestinationForUri(Uri uri) {
  final path =
      uri.path.length > 1 && uri.path.endsWith('/')
          ? uri.path.substring(0, uri.path.length - 1)
          : uri.path;
  for (final entry in webDestinationRoutes.entries) {
    if (entry.value == path) return entry.key;
  }
  return null;
}

ModuloCentralPDV? webModuleForDestination(
  WebNavigationDestination destination,
) {
  for (final module in ModuloCentralPDV.values) {
    if (webNavigationDestinationForModuloCentralPdv(module) == destination) {
      return module;
    }
  }
  return null;
}
