import 'package:flutter/foundation.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/models/colaborador_usuario_model.dart';
import 'package:sixpos/data/services/catalog_health/catalog_health_api_client.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';

class ManagementOverviewProvider extends ChangeNotifier {
  ManagementOverviewProvider({
    CatalogHealthApiClient? catalogHealthApiClient,
    CategoriaCatalogoApiClient? categoriaCatalogoApiClient,
    ClienteUsuarioApiClient? clienteUsuarioApiClient,
    ColaboradorUsuarioApiClient? colaboradorUsuarioApiClient,
    AgendaFinanceiraLancamentoService? agendaFinanceiraService,
    ManagementOverviewSnapshot? initialSnapshot,
  }) : _catalogHealthApiClient =
           catalogHealthApiClient ?? HttpCatalogHealthApiClient(),
       _categoriaCatalogoApiClient =
           categoriaCatalogoApiClient ?? HttpCategoriaCatalogoApiClient(),
       _clienteUsuarioApiClient =
           clienteUsuarioApiClient ?? HttpClienteUsuarioApiClient(),
       _colaboradorUsuarioApiClient =
           colaboradorUsuarioApiClient ?? HttpColaboradorUsuarioApiClient(),
       _agendaFinanceiraService =
           agendaFinanceiraService ?? AgendaFinanceiraLancamentoService(),
       _snapshot = initialSnapshot ?? ManagementOverviewSnapshot.loading();

  final CatalogHealthApiClient _catalogHealthApiClient;
  final CategoriaCatalogoApiClient _categoriaCatalogoApiClient;
  final ClienteUsuarioApiClient _clienteUsuarioApiClient;
  final ColaboradorUsuarioApiClient _colaboradorUsuarioApiClient;
  final AgendaFinanceiraLancamentoService _agendaFinanceiraService;

  ManagementOverviewSnapshot _snapshot;
  bool _isLoading = false;
  bool _hasLoaded = false;

  ManagementOverviewSnapshot get snapshot => _snapshot;
  bool get isLoading => _isLoading;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !force) return;

    _isLoading = true;
    _snapshot = ManagementOverviewSnapshot.loading();
    notifyListeners();

    final Future<ManagementSectionLoadState<ManagementCatalogOverview>>
    catalogFuture = _loadCatalogOverview();
    final Future<ManagementSectionLoadState<ManagementPeopleOverview>>
    peopleFuture = _loadPeopleOverview();
    final Future<ManagementSectionLoadState<ManagementFinanceOverview>>
    financeFuture = _loadFinanceOverview();

    final ManagementSectionLoadState<ManagementCatalogOverview> catalog =
        await catalogFuture;
    final ManagementSectionLoadState<ManagementPeopleOverview> people =
        await peopleFuture;
    final ManagementSectionLoadState<ManagementFinanceOverview> finance =
        await financeFuture;

    _snapshot = ManagementOverviewSnapshot(
      catalog: catalog,
      people: people,
      finance: finance,
    );
    _hasLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> reload() => load(force: true);

  Future<ManagementSectionLoadState<ManagementCatalogOverview>>
  _loadCatalogOverview() async {
    CatalogHealthSummary? health;
    CategoriaCatalogoListResponse? categories;

    try {
      health = await _catalogHealthApiClient.buscarSaudeCatalogo();
    } catch (_) {}

    try {
      categories = await _categoriaCatalogoApiClient.listarCategorias();
    } catch (_) {}

    if (health == null && categories == null) {
      return const ManagementSectionLoadState.error('gestao.catalog.loadError');
    }

    final int? products = health?.overview.products.quantity;
    final int? services = health?.overview.services.quantity;
    final int? lowStockItems =
        health?.metric(CatalogHealthMetricType.lowStock)?.value;
    final int? attentionItems = health?.attentionItems;
    final int? categoryCount = categories?.total;

    final bool noCatalogData =
        (products ?? 0) == 0 &&
        (services ?? 0) == 0 &&
        (lowStockItems ?? 0) == 0 &&
        (attentionItems ?? 0) == 0 &&
        (categoryCount ?? 0) == 0;

    if (noCatalogData) {
      return const ManagementSectionLoadState.empty();
    }

    return ManagementSectionLoadState.data(
      ManagementCatalogOverview(
        productCount: products,
        serviceCount: services,
        categoryCount: categoryCount,
        lowStockItems: lowStockItems,
        attentionItems: attentionItems,
        isDemonstrationData: health?.isDemonstrationData ?? false,
      ),
    );
  }

  Future<ManagementSectionLoadState<ManagementPeopleOverview>>
  _loadPeopleOverview() async {
    ClienteUsuarioListResponse? clients;
    List<ColaboradorUsuarioResumo>? collaborators;

    try {
      clients = await _clienteUsuarioApiClient.listarClientesUsuario();
    } catch (_) {}

    try {
      collaborators = await _colaboradorUsuarioApiClient.listarColaboradores();
    } catch (_) {}

    if (clients == null && collaborators == null) {
      return const ManagementSectionLoadState.error('gestao.people.loadError');
    }

    return ManagementSectionLoadState.data(
      ManagementPeopleOverview(
        clientCount: clients?.total,
        collaboratorCount: collaborators?.length,
        activeCollaboratorCount:
            collaborators
                ?.where((ColaboradorUsuarioResumo item) => item.ativo)
                .length,
        supplierCount: null,
      ),
    );
  }

  Future<ManagementSectionLoadState<ManagementFinanceOverview>>
  _loadFinanceOverview() async {
    try {
      final Map<String, dynamic> payload = await _agendaFinanceiraService
          .consultarLancamentos(_financeRequest());
      final ManagementFinanceOverview overview = _parseFinancePayload(payload);
      if (overview.totalEvents == 0) {
        return const ManagementSectionLoadState.empty();
      }
      return ManagementSectionLoadState.data(overview);
    } catch (_) {
      return const ManagementSectionLoadState.error('gestao.finance.loadError');
    }
  }

  AgendaFinanceiraConsultaRequest _financeRequest() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return AgendaFinanceiraConsultaRequest(
      periodo: AgendaFinanceiraPeriodoRequest(
        modo: 'PROXIMOS_7_DIAS',
        dataInicio: today,
        dataFim: today.add(const Duration(days: 7)),
      ),
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo: 'TODOS',
        status: const <String>[],
        origens: const <String>[],
        categorias: const <String>[],
        formasPagamento: const <String>[],
        codigosTipoRecebimento: const <String>[],
        clienteFornecedor: null,
        somenteCriticos: false,
      ),
      visaoSelecionada: 'AGENDA',
    );
  }

  ManagementFinanceOverview _parseFinancePayload(Map<String, dynamic> payload) {
    int total = 0;
    int receivable = 0;
    int payable = 0;
    int attention = 0;

    final dynamic groups = payload['gruposAgenda'];
    if (groups is List) {
      for (final dynamic group in groups) {
        if (group is! Map) continue;
        final dynamic items = group['itens'];
        if (items is! List) continue;
        for (final dynamic item in items) {
          if (item is! Map) continue;
          total += 1;
          final String type = item['tipo']?.toString().toUpperCase() ?? '';
          if (type == 'PAGAR') {
            payable += 1;
          } else {
            receivable += 1;
          }

          final String status =
              item['status']?.toString().toUpperCase().trim() ?? '';
          if (status.contains('VENCID') || status == 'VENCE_HOJE') {
            attention += 1;
          }
        }
      }
    }

    return ManagementFinanceOverview(
      totalEvents: total,
      receivableEvents: receivable,
      payableEvents: payable,
      attentionEvents: attention,
    );
  }
}

class ManagementOverviewSnapshot {
  const ManagementOverviewSnapshot({
    required this.catalog,
    required this.people,
    required this.finance,
  });

  factory ManagementOverviewSnapshot.loading() {
    return const ManagementOverviewSnapshot(
      catalog: ManagementSectionLoadState<ManagementCatalogOverview>.loading(),
      people: ManagementSectionLoadState<ManagementPeopleOverview>.loading(),
      finance: ManagementSectionLoadState<ManagementFinanceOverview>.loading(),
    );
  }

  final ManagementSectionLoadState<ManagementCatalogOverview> catalog;
  final ManagementSectionLoadState<ManagementPeopleOverview> people;
  final ManagementSectionLoadState<ManagementFinanceOverview> finance;
}

class ManagementSectionLoadState<T> {
  const ManagementSectionLoadState._({
    required this.isLoading,
    this.data,
    this.errorKey,
    this.isEmpty = false,
  });

  const ManagementSectionLoadState.loading()
    : this._(isLoading: true, isEmpty: false);

  const ManagementSectionLoadState.data(T data)
    : this._(isLoading: false, data: data, isEmpty: false);

  const ManagementSectionLoadState.empty()
    : this._(isLoading: false, isEmpty: true);

  const ManagementSectionLoadState.error(String errorKey)
    : this._(isLoading: false, errorKey: errorKey, isEmpty: false);

  final bool isLoading;
  final T? data;
  final String? errorKey;
  final bool isEmpty;

  bool get hasError => errorKey != null;
  bool get hasData => data != null;
}

class ManagementCatalogOverview {
  const ManagementCatalogOverview({
    required this.productCount,
    required this.serviceCount,
    required this.categoryCount,
    required this.lowStockItems,
    required this.attentionItems,
    required this.isDemonstrationData,
  });

  final int? productCount;
  final int? serviceCount;
  final int? categoryCount;
  final int? lowStockItems;
  final int? attentionItems;
  final bool isDemonstrationData;

  int? get productServiceCount {
    if (productCount == null && serviceCount == null) return null;
    return (productCount ?? 0) + (serviceCount ?? 0);
  }
}

class ManagementPeopleOverview {
  const ManagementPeopleOverview({
    required this.clientCount,
    required this.collaboratorCount,
    required this.activeCollaboratorCount,
    required this.supplierCount,
  });

  final int? clientCount;
  final int? collaboratorCount;
  final int? activeCollaboratorCount;
  final int? supplierCount;
}

class ManagementFinanceOverview {
  const ManagementFinanceOverview({
    required this.totalEvents,
    required this.receivableEvents,
    required this.payableEvents,
    required this.attentionEvents,
  });

  final int totalEvents;
  final int receivableEvents;
  final int payableEvents;
  final int attentionEvents;
}
