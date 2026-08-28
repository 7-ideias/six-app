import 'web_navigation_item.dart';

abstract interface class WebNavigationDestinationActions {
  WebNavigationResolutionResult openHome();
  WebNavigationResolutionResult openPointOfSale();
  WebNavigationResolutionResult openTechnicalServices();
  WebNavigationResolutionResult openPurchases();
  WebNavigationResolutionResult openReservations();
  WebNavigationResolutionResult openCatalogPublicPage();
  WebNavigationResolutionResult openCatalogProducts();
  WebNavigationResolutionResult openCatalogServices();
  WebNavigationResolutionResult openCatalogStock();
  WebNavigationResolutionResult openCatalogCategories();
  WebNavigationResolutionResult openPeopleCustomers();
  WebNavigationResolutionResult openPeopleCollaborators();
  WebNavigationResolutionResult openPeoplePerformance();
  WebNavigationResolutionResult openCash();
  WebNavigationResolutionResult openFinancialAgenda();
  WebNavigationResolutionResult openSettings();
}

enum WebNavigationResolutionStatus { handled, reserved, unsupported }

class WebNavigationResolutionResult {
  const WebNavigationResolutionResult._({
    required this.status,
    this.destination,
    this.reason,
  });

  factory WebNavigationResolutionResult.handled(
    WebNavigationDestination destination,
  ) => WebNavigationResolutionResult._(
    status: WebNavigationResolutionStatus.handled,
    destination: destination,
  );

  factory WebNavigationResolutionResult.reserved(
    WebNavigationDestination destination, {
    String? reason,
  }) => WebNavigationResolutionResult._(
    status: WebNavigationResolutionStatus.reserved,
    destination: destination,
    reason: reason,
  );

  factory WebNavigationResolutionResult.unsupported({
    WebNavigationDestination? destination,
    String? reason,
  }) => WebNavigationResolutionResult._(
    status: WebNavigationResolutionStatus.unsupported,
    destination: destination,
    reason: reason,
  );

  final WebNavigationResolutionStatus status;
  final WebNavigationDestination? destination;
  final String? reason;

  bool get handled => status == WebNavigationResolutionStatus.handled;
  bool get reserved => status == WebNavigationResolutionStatus.reserved;
  bool get unsupported => status == WebNavigationResolutionStatus.unsupported;
}

class WebNavigationDestinationResolver {
  const WebNavigationDestinationResolver({required this.actions});
  final WebNavigationDestinationActions actions;

  WebNavigationResolutionResult resolve(WebNavigationDestination? destination) {
    if (destination == null) {
      return WebNavigationResolutionResult.unsupported(
        reason: 'Destino de navegacao Web ausente.',
      );
    }
    switch (destination) {
      case WebNavigationDestination.home:
        return actions.openHome();
      case WebNavigationDestination.operationsPointOfSale:
        return actions.openPointOfSale();
      case WebNavigationDestination.operationsSales:
        return WebNavigationResolutionResult.reserved(
          destination,
          reason: 'Destino gerenciado pelo shell Web.',
        );
      case WebNavigationDestination.operationsTechnicalServices:
        return actions.openTechnicalServices();
      case WebNavigationDestination.operationsPurchases:
        return actions.openPurchases();
      case WebNavigationDestination.operationsReservations:
        return actions.openReservations();
      case WebNavigationDestination.operationsReturns:
        return WebNavigationResolutionResult.reserved(
          destination,
          reason: 'Destino gerenciado pelo shell Web.',
        );
      case WebNavigationDestination.catalogPublicPage:
        return actions.openCatalogPublicPage();
      case WebNavigationDestination.catalogProducts:
        return actions.openCatalogProducts();
      case WebNavigationDestination.catalogServices:
        return actions.openCatalogServices();
      case WebNavigationDestination.catalogStock:
        return actions.openCatalogStock();
      case WebNavigationDestination.catalogLabels:
        return WebNavigationResolutionResult.reserved(
          destination,
          reason: 'Destino gerenciado pelo shell Web.',
        );
      case WebNavigationDestination.catalogCategories:
        return actions.openCatalogCategories();
      case WebNavigationDestination.peopleCustomers:
        return actions.openPeopleCustomers();
      case WebNavigationDestination.peopleCollaborators:
        return actions.openPeopleCollaborators();
      case WebNavigationDestination.peoplePerformance:
        return actions.openPeoplePerformance();
      case WebNavigationDestination.cash:
        return actions.openCash();
      case WebNavigationDestination.financialAgenda:
        return actions.openFinancialAgenda();
      case WebNavigationDestination.settings:
        return actions.openSettings();
      case WebNavigationDestination.reports:
        return WebNavigationResolutionResult.reserved(
          destination,
          reason: 'Relatorios esta reservado para evolucao futura.',
        );
    }
  }
}
