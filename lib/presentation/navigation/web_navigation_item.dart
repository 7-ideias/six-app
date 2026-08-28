import 'package:flutter/material.dart';

/// Declarative contract for the authenticated Web navigation.
class WebNavigationItem {
  const WebNavigationItem({
    required this.id,
    required this.labelKey,
    required this.labelFallback,
    required this.icon,
    required this.visibility,
    this.destination,
    this.children = const <WebNavigationItem>[],
  });

  final String id;
  final String labelKey;
  final String labelFallback;
  final IconData icon;
  final WebNavigationDestination? destination;
  final WebNavigationVisibilityRule visibility;
  final List<WebNavigationItem> children;

  bool get hasChildren => children.isNotEmpty;
  bool get isDestination => destination != null;

  Iterable<WebNavigationItem> flatten() sync* {
    yield this;
    for (final WebNavigationItem child in children) {
      yield* child.flatten();
    }
  }

  int get maxDepth {
    if (children.isEmpty) return 1;
    int childDepth = 0;
    for (final WebNavigationItem child in children) {
      if (child.maxDepth > childDepth) childDepth = child.maxDepth;
    }
    return childDepth + 1;
  }

  WebNavigationItem? visibleForPermissions(
    Set<WebNavigationPermission> grantedPermissions, {
    bool includeUnresolved = true,
  }) {
    if (!visibility.isAllowed(
      grantedPermissions,
      includeUnresolved: includeUnresolved,
    )) {
      return null;
    }
    if (children.isEmpty) return this;

    final List<WebNavigationItem> visibleChildren = <WebNavigationItem>[
      for (final WebNavigationItem child in children)
        if (child.visibleForPermissions(
              grantedPermissions,
              includeUnresolved: includeUnresolved,
            )
            case final WebNavigationItem visibleChild)
          visibleChild,
    ];
    if (visibleChildren.isEmpty && destination == null) return null;
    return WebNavigationItem(
      id: id,
      labelKey: labelKey,
      labelFallback: labelFallback,
      icon: icon,
      visibility: visibility,
      destination: destination,
      children: visibleChildren,
    );
  }
}

enum WebNavigationDestination {
  home,
  operationsPointOfSale,
  operationsSales,
  operationsTechnicalServices,
  operationsPurchases,
  operationsReservations,
  operationsReturns,
  catalogProducts,
  catalogServices,
  catalogStock,
  catalogLabels,
  catalogCategories,
  peopleCustomers,
  peopleCollaborators,
  peoplePerformance,
  cash,
  financialAgenda,
  settings,
  reports,
}

enum WebNavigationPermission {
  podeFazerVenda,
  podeConsultarVendas,
  podeFazerDevolucao,
  podeLancarAssistenciaTecnica,
  podeEditarCliente,
  podeCadastrarProduto,
  podeEditarProduto,
  podeVerEstoqueDeProduto,
  podeAcessarCatalogo,
  podeAcessarEtiquetas,
  podeGerarRelatorio,
  podeGerenciarDesempenho,
  podeAcessarFinanceiro,
  podeReceberNoCaixa,
}

enum WebNavigationVisibilityKind { authenticated, anyOf, unresolved }

class WebNavigationVisibilityRule {
  const WebNavigationVisibilityRule.authenticated()
    : kind = WebNavigationVisibilityKind.authenticated,
      anyOf = const <WebNavigationPermission>[],
      note = null;

  const WebNavigationVisibilityRule.anyOf(this.anyOf)
    : kind = WebNavigationVisibilityKind.anyOf,
      note = null;

  const WebNavigationVisibilityRule.unresolved(this.note)
    : kind = WebNavigationVisibilityKind.unresolved,
      anyOf = const <WebNavigationPermission>[];

  final WebNavigationVisibilityKind kind;
  final List<WebNavigationPermission> anyOf;
  final String? note;

  bool isAllowed(
    Set<WebNavigationPermission> grantedPermissions, {
    bool includeUnresolved = true,
  }) {
    switch (kind) {
      case WebNavigationVisibilityKind.authenticated:
        return true;
      case WebNavigationVisibilityKind.anyOf:
        return anyOf.any(grantedPermissions.contains);
      case WebNavigationVisibilityKind.unresolved:
        return includeUnresolved;
    }
  }
}
