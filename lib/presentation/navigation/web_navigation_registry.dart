import 'package:flutter/material.dart';

import 'web_navigation_item.dart';

abstract final class WebNavigationIds {
  static const String home = 'home';
  static const String operations = 'operations';
  static const String operationsPos = 'operations.pos';
  static const String operationsSales = 'operations.sales';
  static const String operationsTechnicalServices =
      'operations.technical_service';
  static const String operationsPurchases = 'operations.purchases';
  static const String operationsReservations = 'operations.reservations';
  static const String operationsReturns = 'operations.returns';
  static const String catalog = 'catalog';
  static const String catalogPublicPage = 'catalog.public_page';
  static const String catalogProducts = 'catalog.products';
  static const String catalogServices = 'catalog.services';
  static const String catalogStock = 'catalog.stock';
  static const String catalogLabels = 'catalog.labels';
  static const String catalogCategories = 'catalog.categories';
  static const String people = 'people';
  static const String peopleCustomers = 'people.customers';
  static const String peopleCollaborators = 'people.collaborators';
  static const String peoplePerformance = 'people.performance';
  static const String cash = 'cash';
  static const String financial = 'financial';
  static const String financialAgenda = 'financial.agenda';
  static const String settings = 'settings';
  static const String reports = 'reports';
}

abstract final class WebNavigationRegistry {
  static const List<WebNavigationItem> activeItems = <WebNavigationItem>[
    WebNavigationItem(
      id: WebNavigationIds.home,
      labelKey: 'web.navigation.home',
      labelFallback: 'Início',
      icon: Icons.home_outlined,
      visibility: WebNavigationVisibilityRule.authenticated(),
      destination: WebNavigationDestination.home,
    ),
    WebNavigationItem(
      id: WebNavigationIds.operations,
      labelKey: 'web.navigation.operations',
      labelFallback: 'Atendimento',
      icon: Icons.support_agent_outlined,
      visibility: WebNavigationVisibilityRule.authenticated(),
      children: <WebNavigationItem>[
        WebNavigationItem(
          id: WebNavigationIds.operationsPos,
          labelKey: 'web.navigation.operations.pos',
          labelFallback: 'Frente de caixa',
          icon: Icons.point_of_sale_outlined,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[WebNavigationPermission.podeFazerVenda],
          ),
          destination: WebNavigationDestination.operationsPointOfSale,
        ),
        WebNavigationItem(
          id: WebNavigationIds.operationsSales,
          labelKey: 'web.navigation.operations.sales',
          labelFallback: 'Vendas',
          icon: Icons.receipt_long_outlined,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[
              WebNavigationPermission.podeConsultarVendas,
            ],
          ),
          destination: WebNavigationDestination.operationsSales,
        ),
        WebNavigationItem(
          id: WebNavigationIds.cash,
          labelKey: 'web.navigation.cash',
          labelFallback: 'Caixa',
          icon: Icons.payments_outlined,
          visibility:
              WebNavigationVisibilityRule.anyOf(<WebNavigationPermission>[
                WebNavigationPermission.podeAcessarFinanceiro,
                WebNavigationPermission.podeReceberNoCaixa,
              ]),
          destination: WebNavigationDestination.cash,
        ),
        WebNavigationItem(
          id: WebNavigationIds.operationsTechnicalServices,
          labelKey: 'web.navigation.operations.technicalService',
          labelFallback: 'Assistências técnicas',
          icon: Icons.engineering_outlined,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[
              WebNavigationPermission.podeLancarAssistenciaTecnica,
            ],
          ),
          destination: WebNavigationDestination.operationsTechnicalServices,
        ),
        WebNavigationItem(
          id: WebNavigationIds.operationsPurchases,
          labelKey: 'web.navigation.operations.purchases',
          labelFallback: 'Compras',
          icon: Icons.shopping_cart_outlined,
          visibility: WebNavigationVisibilityRule.unresolved(
            'Permissao de Compras ainda nao disponivel no backend.',
          ),
          destination: WebNavigationDestination.operationsPurchases,
        ),
      ],
    ),
    WebNavigationItem(
      id: WebNavigationIds.catalog,
      labelKey: 'web.navigation.catalog',
      labelFallback: 'Catálogo',
      icon: Icons.view_module_outlined,
      visibility: WebNavigationVisibilityRule.authenticated(),
      children: <WebNavigationItem>[
        WebNavigationItem(
          id: WebNavigationIds.catalogPublicPage,
          labelKey: 'web.navigation.catalog.publicPage',
          labelFallback: 'Página pública',
          icon: Icons.storefront_outlined,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[
              WebNavigationPermission.podeAcessarCatalogo,
            ],
          ),
          destination: WebNavigationDestination.catalogPublicPage,
        ),
        WebNavigationItem(
          id: WebNavigationIds.operationsReservations,
          labelKey: 'web.navigation.catalog.reservations',
          labelFallback: 'Reservas',
          icon: Icons.bookmarks_outlined,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[WebNavigationPermission.podeFazerVenda],
          ),
          destination: WebNavigationDestination.operationsReservations,
        ),
        WebNavigationItem(
          id: WebNavigationIds.catalogProducts,
          labelKey: 'web.navigation.catalog.products',
          labelFallback: 'Produtos',
          icon: Icons.inventory_2_outlined,
          visibility:
              WebNavigationVisibilityRule.anyOf(<WebNavigationPermission>[
                WebNavigationPermission.podeCadastrarProduto,
                WebNavigationPermission.podeEditarProduto,
              ]),
          destination: WebNavigationDestination.catalogProducts,
        ),
        WebNavigationItem(
          id: WebNavigationIds.catalogServices,
          labelKey: 'web.navigation.catalog.services',
          labelFallback: 'Serviços',
          icon: Icons.home_repair_service_outlined,
          visibility:
              WebNavigationVisibilityRule.anyOf(<WebNavigationPermission>[
                WebNavigationPermission.podeCadastrarProduto,
                WebNavigationPermission.podeEditarProduto,
              ]),
          destination: WebNavigationDestination.catalogServices,
        ),
        WebNavigationItem(
          id: WebNavigationIds.catalogStock,
          labelKey: 'web.navigation.catalog.stock',
          labelFallback: 'Estoque',
          icon: Icons.warehouse_outlined,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[
              WebNavigationPermission.podeVerEstoqueDeProduto,
            ],
          ),
          destination: WebNavigationDestination.catalogStock,
        ),
        WebNavigationItem(
          id: WebNavigationIds.catalogLabels,
          labelKey: 'web.navigation.catalog.labels',
          labelFallback: 'Etiquetas',
          icon: Icons.local_offer_outlined,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[
              WebNavigationPermission.podeAcessarEtiquetas,
            ],
          ),
          destination: WebNavigationDestination.catalogLabels,
        ),
        WebNavigationItem(
          id: WebNavigationIds.catalogCategories,
          labelKey: 'web.navigation.catalog.categories',
          labelFallback: 'Categorias',
          icon: Icons.category_outlined,
          visibility:
              WebNavigationVisibilityRule.anyOf(<WebNavigationPermission>[
                WebNavigationPermission.podeCadastrarProduto,
                WebNavigationPermission.podeEditarProduto,
              ]),
          destination: WebNavigationDestination.catalogCategories,
        ),
      ],
    ),
    WebNavigationItem(
      id: WebNavigationIds.people,
      labelKey: 'web.navigation.people',
      labelFallback: 'Pessoas',
      icon: Icons.people_alt_outlined,
      visibility: WebNavigationVisibilityRule.authenticated(),
      children: <WebNavigationItem>[
        WebNavigationItem(
          id: WebNavigationIds.peopleCustomers,
          labelKey: 'web.navigation.people.customers',
          labelFallback: 'Clientes',
          icon: Icons.person_outline,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[
              WebNavigationPermission.podeEditarCliente,
            ],
          ),
          destination: WebNavigationDestination.peopleCustomers,
        ),
        WebNavigationItem(
          id: WebNavigationIds.peopleCollaborators,
          labelKey: 'web.navigation.people.collaborators',
          labelFallback: 'Colaboradores',
          icon: Icons.groups_2_outlined,
          visibility: WebNavigationVisibilityRule.unresolved(
            'Nao existe getter especifico para gerenciar colaboradores.',
          ),
          destination: WebNavigationDestination.peopleCollaborators,
        ),
        WebNavigationItem(
          id: WebNavigationIds.peoplePerformance,
          labelKey: 'web.navigation.people.performance',
          labelFallback: 'Desempenho',
          icon: Icons.trending_up_rounded,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[
              WebNavigationPermission.podeGerenciarDesempenho,
            ],
          ),
          destination: WebNavigationDestination.peoplePerformance,
        ),
      ],
    ),
    WebNavigationItem(
      id: WebNavigationIds.financial,
      labelKey: 'web.navigation.financial',
      labelFallback: 'Financeiro',
      icon: Icons.account_balance_wallet_outlined,
      visibility: WebNavigationVisibilityRule.authenticated(),
      children: <WebNavigationItem>[
        WebNavigationItem(
          id: WebNavigationIds.financialAgenda,
          labelKey: 'web.navigation.financial.agenda',
          labelFallback: 'Agenda financeira',
          icon: Icons.event_note_outlined,
          visibility: WebNavigationVisibilityRule.anyOf(
            <WebNavigationPermission>[
              WebNavigationPermission.podeAcessarFinanceiro,
            ],
          ),
          destination: WebNavigationDestination.financialAgenda,
        ),
      ],
    ),
    WebNavigationItem(
      id: WebNavigationIds.settings,
      labelKey: 'web.navigation.settings',
      labelFallback: 'Configurações',
      icon: Icons.settings_outlined,
      visibility: WebNavigationVisibilityRule.unresolved(
        'A regra de acesso de configuracoes Web ainda precisa de decisao.',
      ),
      destination: WebNavigationDestination.settings,
    ),
  ];

  static const List<WebNavigationItem> reservedItems = <WebNavigationItem>[
    WebNavigationItem(
      id: WebNavigationIds.reports,
      labelKey: 'web.navigation.reports',
      labelFallback: 'Relatórios',
      icon: Icons.bar_chart_outlined,
      visibility: WebNavigationVisibilityRule.anyOf(<WebNavigationPermission>[
        WebNavigationPermission.podeGerarRelatorio,
      ]),
      destination: WebNavigationDestination.reports,
    ),
  ];

  static Iterable<WebNavigationItem> flattenActiveItems() sync* {
    for (final WebNavigationItem item in activeItems) {
      yield* item.flatten();
    }
  }

  static const WebNavigationItem _operationsReturnsItem = WebNavigationItem(
    id: WebNavigationIds.operationsReturns,
    labelKey: 'web.navigation.operations.returns',
    labelFallback: 'Devoluções e trocas',
    icon: Icons.assignment_return_outlined,
    visibility: WebNavigationVisibilityRule.anyOf(<WebNavigationPermission>[
      WebNavigationPermission.podeFazerDevolucao,
    ]),
    destination: WebNavigationDestination.operationsReturns,
  );

  static List<WebNavigationItem> activeItemsForPermissions(
    Set<WebNavigationPermission> grantedPermissions, {
    bool includeUnresolved = true,
  }) {
    final List<WebNavigationItem> visible = <WebNavigationItem>[
      for (final WebNavigationItem item in activeItems)
        if (item.visibleForPermissions(
              grantedPermissions,
              includeUnresolved: includeUnresolved,
            )
            case final WebNavigationItem visibleItem)
          visibleItem,
    ];

    if (!grantedPermissions.contains(
      WebNavigationPermission.podeFazerDevolucao,
    )) {
      return visible;
    }

    final int operationsIndex = visible.indexWhere(
      (WebNavigationItem item) => item.id == WebNavigationIds.operations,
    );
    if (operationsIndex < 0) return visible;

    final WebNavigationItem operations = visible[operationsIndex];
    final List<WebNavigationItem> children = <WebNavigationItem>[
      ...operations.children,
    ];
    final int salesIndex = children.indexWhere(
      (WebNavigationItem item) => item.id == WebNavigationIds.operationsSales,
    );
    children.insert(
      salesIndex >= 0 ? salesIndex + 1 : children.length,
      _operationsReturnsItem,
    );

    visible[operationsIndex] = WebNavigationItem(
      id: operations.id,
      labelKey: operations.labelKey,
      labelFallback: operations.labelFallback,
      icon: operations.icon,
      visibility: operations.visibility,
      destination: operations.destination,
      children: children,
    );
    return visible;
  }

  static WebNavigationItem? findActiveById(String id) {
    if (id == WebNavigationIds.operationsReturns) {
      return _operationsReturnsItem;
    }
    for (final WebNavigationItem item in flattenActiveItems()) {
      if (item.id == id) return item;
    }
    return null;
  }
}
