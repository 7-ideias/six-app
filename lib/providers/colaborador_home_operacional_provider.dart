import 'package:flutter/foundation.dart';

import '../core/services/auth_service.dart';
import '../core/services/catalogo_reserva_service.dart';
import '../data/models/atendimento_tecnico_models.dart';
import '../data/models/catalogo_reserva_model.dart';
import '../data/models/consulta_vendas_models.dart';
import '../data/models/dominio_models.dart';
import '../data/models/venda_nao_liquidada_models.dart';
import '../data/services/caixa/venda_nao_liquidada_api_client.dart';
import '../data/services/vendas/consulta_vendas_api_client.dart';
import '../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';

class ColaboradorHomeOperacionalProvider extends ChangeNotifier {
  ColaboradorHomeOperacionalProvider({
    ConsultaVendasApiClient? consultaVendasApiClient,
    VendaNaoLiquidadaApiClient? vendaNaoLiquidadaApiClient,
    AtendimentoTecnicoService? atendimentoTecnicoService,
    CatalogoReservaService? catalogoReservaService,
    Future<String?> Function()? userIdProvider,
    DateTime Function()? nowProvider,
  }) : _consultaVendasApiClient =
           consultaVendasApiClient ?? HttpConsultaVendasApiClient(),
       _vendaNaoLiquidadaApiClient =
           vendaNaoLiquidadaApiClient ?? VendaNaoLiquidadaApiClient(),
       _atendimentoTecnicoService =
           atendimentoTecnicoService ?? AtendimentoTecnicoService(),
       _catalogoReservaService =
           catalogoReservaService ?? CatalogoReservaService(),
       _userIdProvider = userIdProvider ?? AuthService().getUserId,
       _nowProvider = nowProvider ?? DateTime.now;

  final ConsultaVendasApiClient _consultaVendasApiClient;
  final VendaNaoLiquidadaApiClient _vendaNaoLiquidadaApiClient;
  final AtendimentoTecnicoService _atendimentoTecnicoService;
  final CatalogoReservaService _catalogoReservaService;
  final Future<String?> Function() _userIdProvider;
  final DateTime Function() _nowProvider;

  ConsultaVendasResponse? _vendasMes;
  List<VendaNaoLiquidadaModel> _vendasEmAberto =
      const <VendaNaoLiquidadaModel>[];
  List<AtendimentoTecnicoModel> _servicos = const <AtendimentoTecnicoModel>[];
  List<ColaboradorServicoStatusResumo> _servicosPorStatus =
      const <ColaboradorServicoStatusResumo>[];
  Map<CatalogoReservaStatus, int> _reservasPorStatus =
      const <CatalogoReservaStatus, int>{};

  bool _loading = false;
  bool _hasLoaded = false;
  String? _accessKey;
  String? _globalErrorCode;
  String? _vendasMesErrorCode;
  String? _vendasEmAbertoErrorCode;
  String? _servicosErrorCode;
  String? _reservasErrorCode;
  DateTime? _periodoInicio;
  DateTime? _periodoFim;

  ConsultaVendasResponse? get vendasMes => _vendasMes;
  List<VendaNaoLiquidadaModel> get vendasEmAberto => _vendasEmAberto;
  List<AtendimentoTecnicoModel> get servicos => _servicos;
  List<ColaboradorServicoStatusResumo> get servicosPorStatus =>
      _servicosPorStatus;
  Map<CatalogoReservaStatus, int> get reservasPorStatus => _reservasPorStatus;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get globalErrorCode => _globalErrorCode;
  String? get vendasMesErrorCode => _vendasMesErrorCode;
  String? get vendasEmAbertoErrorCode => _vendasEmAbertoErrorCode;
  String? get servicosErrorCode => _servicosErrorCode;
  String? get reservasErrorCode => _reservasErrorCode;
  DateTime? get periodoInicio => _periodoInicio;
  DateTime? get periodoFim => _periodoFim;

  bool needsLoad({
    required bool canAccessSales,
    required bool canAccessServices,
    required bool canAccessReservations,
  }) {
    return !_hasLoaded ||
        _accessKey !=
            _buildAccessKey(
              canAccessSales: canAccessSales,
              canAccessServices: canAccessServices,
              canAccessReservations: canAccessReservations,
            );
  }

  Future<void> load({
    required bool canAccessSales,
    required bool canAccessServices,
    required bool canAccessReservations,
    bool force = false,
  }) async {
    final String accessKey = _buildAccessKey(
      canAccessSales: canAccessSales,
      canAccessServices: canAccessServices,
      canAccessReservations: canAccessReservations,
    );
    if (_loading || (!force && _hasLoaded && _accessKey == accessKey)) return;

    final bool accessChanged = _accessKey != accessKey;
    _accessKey = accessKey;
    _loading = true;
    _globalErrorCode = null;
    _vendasMesErrorCode = null;
    _vendasEmAbertoErrorCode = null;
    _servicosErrorCode = null;
    _reservasErrorCode = null;
    if (accessChanged) {
      _clearDisabledData(
        canAccessSales: canAccessSales,
        canAccessServices: canAccessServices,
        canAccessReservations: canAccessReservations,
      );
    }
    notifyListeners();

    try {
      final String idColaborador = _normalizeId(await _userIdProvider());
      if (idColaborador.isEmpty) {
        _globalErrorCode = 'collaboratorHome.error.user';
        return;
      }

      final DateTime now = _nowProvider();
      _periodoInicio = DateTime(now.year, now.month);
      _periodoFim = DateTime(now.year, now.month, now.day);

      await Future.wait<void>(<Future<void>>[
        if (canAccessSales) _loadSales(idColaborador: idColaborador, now: now),
        if (canAccessServices) _loadServices(idColaborador: idColaborador),
        if (canAccessReservations) _loadReservations(),
      ]);
    } finally {
      _hasLoaded = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload({
    required bool canAccessSales,
    required bool canAccessServices,
    required bool canAccessReservations,
  }) {
    return load(
      canAccessSales: canAccessSales,
      canAccessServices: canAccessServices,
      canAccessReservations: canAccessReservations,
      force: true,
    );
  }

  Future<void> _loadSales({
    required String idColaborador,
    required DateTime now,
  }) async {
    await Future.wait<void>(<Future<void>>[
      _loadSalesSummary(idColaborador: idColaborador, now: now),
      _loadOpenSales(idColaborador: idColaborador),
    ]);
  }

  Future<void> _loadSalesSummary({
    required String idColaborador,
    required DateTime now,
  }) async {
    try {
      _vendasMes = await _consultaVendasApiClient.consultar(
        ConsultaVendasFiltro(
          dataInicial: DateTime(now.year, now.month),
          dataFinal: DateTime(now.year, now.month, now.day),
          idColaborador: idColaborador,
          pagina: 0,
          tamanho: 5,
        ),
      );
    } catch (_) {
      _vendasMesErrorCode = 'collaboratorHome.sales.loadError';
    }
  }

  Future<void> _loadOpenSales({required String idColaborador}) async {
    try {
      final List<VendaNaoLiquidadaModel> response =
          await _vendaNaoLiquidadaApiClient.listar();
      final List<VendaNaoLiquidadaModel> personal = response
          .where(
            (VendaNaoLiquidadaModel venda) =>
                _normalizeId(venda.idColaboradorCriacao) == idColaborador,
          )
          .toList(growable: false);
      personal.sort(_compareOpenSales);
      _vendasEmAberto = List<VendaNaoLiquidadaModel>.unmodifiable(personal);
    } catch (_) {
      _vendasEmAbertoErrorCode = 'collaboratorHome.openSales.loadError';
    }
  }

  Future<void> _loadServices({required String idColaborador}) async {
    try {
      final List<Object> response = await Future.wait<Object>(<Future<Object>>[
        _atendimentoTecnicoService.listar(),
        _loadServiceDomainsSafely(),
      ]);
      final List<AtendimentoTecnicoModel> personal =
          (response[0] as List<AtendimentoTecnicoModel>)
              .where(
                (AtendimentoTecnicoModel atendimento) =>
                    _serviceBelongsToCollaborator(atendimento, idColaborador),
              )
              .toList(growable: false);
      final List<DominioOpcaoModel> domains =
          response[1] as List<DominioOpcaoModel>;
      _servicos = List<AtendimentoTecnicoModel>.unmodifiable(personal);
      _servicosPorStatus = List<ColaboradorServicoStatusResumo>.unmodifiable(
        _groupServicesByStatus(personal, domains),
      );
    } catch (_) {
      _servicosErrorCode = 'collaboratorHome.services.loadError';
    }
  }

  Future<List<DominioOpcaoModel>> _loadServiceDomainsSafely() async {
    try {
      final AtendimentoTecnicoDominiosBaseModel domains =
          await _atendimentoTecnicoService.buscarDominiosBase();
      return domains.statusAtendimentoTecnico;
    } catch (_) {
      return const <DominioOpcaoModel>[];
    }
  }

  Future<void> _loadReservations() async {
    try {
      const List<CatalogoReservaStatus> statuses = <CatalogoReservaStatus>[
        CatalogoReservaStatus.recebida,
        CatalogoReservaStatus.emAnalise,
        CatalogoReservaStatus.confirmada,
        CatalogoReservaStatus.convertida,
      ];
      final List<CatalogoReservaPaginaModel> pages =
          await Future.wait<CatalogoReservaPaginaModel>(
            statuses.map(
              (CatalogoReservaStatus status) => _catalogoReservaService.listar(
                status: status,
                pagina: 0,
                tamanho: 1,
              ),
            ),
          );
      _reservasPorStatus = Map<CatalogoReservaStatus, int>.unmodifiable(
        <CatalogoReservaStatus, int>{
          for (int index = 0; index < statuses.length; index++)
            statuses[index]: pages[index].totalElementos,
        },
      );
    } catch (_) {
      _reservasErrorCode = 'collaboratorHome.reservations.loadError';
    }
  }

  List<ColaboradorServicoStatusResumo> _groupServicesByStatus(
    List<AtendimentoTecnicoModel> services,
    List<DominioOpcaoModel> domains,
  ) {
    final Map<String, _MutableServiceStatus> grouped =
        <String, _MutableServiceStatus>{};
    for (final AtendimentoTecnicoModel service in services) {
      final DominioOpcaoModel? domain = _findStatusDomain(service, domains);
      final String code = service.statusCodigo.trim().toUpperCase();
      final String key = service.statusId > 0
          ? 'id:${service.statusId}'
          : code.isNotEmpty
          ? 'code:$code'
          : 'unknown';
      final _MutableServiceStatus? current = grouped[key];
      if (current != null) {
        current.count += 1;
        continue;
      }
      grouped[key] = _MutableServiceStatus(
        key: key,
        statusCode: code,
        i18nKey: _firstNonBlank(<String?>[
          service.statusI18nKey,
          domain?.i18nKey,
        ]),
        namePtBr: _firstNonBlank(<String?>[
          service.statusNomePtBr,
          domain?.nomePadraoPtBr,
          code,
        ]),
        nameEnUs: _firstNonBlank(<String?>[
          service.statusNomeEnUs,
          domain?.nomePadraoEnUs,
          code,
        ]),
        nameEsEs: _firstNonBlank(<String?>[
          service.statusNomeEsEs,
          domain?.nomePadraoEsEs,
          code,
        ]),
        order: domain?.ordem ?? 999,
        colorHex: domain?.cor ?? '',
        finalizer: domain?.finalizador ?? _knownFinalStatus(code),
        count: 1,
      );
    }

    final List<ColaboradorServicoStatusResumo> result = grouped.values
        .map(
          (_MutableServiceStatus status) => status.toImmutable(),
        )
        .toList(growable: false);
    result.sort((
      ColaboradorServicoStatusResumo a,
      ColaboradorServicoStatusResumo b,
    ) {
      final int orderComparison = a.order.compareTo(b.order);
      if (orderComparison != 0) return orderComparison;
      return b.count.compareTo(a.count);
    });
    return result;
  }

  DominioOpcaoModel? _findStatusDomain(
    AtendimentoTecnicoModel service,
    List<DominioOpcaoModel> domains,
  ) {
    for (final DominioOpcaoModel domain in domains) {
      if (service.statusId > 0 && domain.id == service.statusId) return domain;
      if (domain.codigo.trim().toUpperCase() ==
          service.statusCodigo.trim().toUpperCase()) {
        return domain;
      }
    }
    return null;
  }

  bool _serviceBelongsToCollaborator(
    AtendimentoTecnicoModel service,
    String idColaborador,
  ) {
    if (_normalizeId(service.idTecnicoResponsavel) == idColaborador) {
      return true;
    }
    return service.itens.any(
      (AtendimentoTecnicoItemModel item) =>
          _normalizeId(item.idTecnicoResponsavel) == idColaborador,
    );
  }

  void _clearDisabledData({
    required bool canAccessSales,
    required bool canAccessServices,
    required bool canAccessReservations,
  }) {
    if (!canAccessSales) {
      _vendasMes = null;
      _vendasEmAberto = const <VendaNaoLiquidadaModel>[];
    }
    if (!canAccessServices) {
      _servicos = const <AtendimentoTecnicoModel>[];
      _servicosPorStatus = const <ColaboradorServicoStatusResumo>[];
    }
    if (!canAccessReservations) {
      _reservasPorStatus = const <CatalogoReservaStatus, int>{};
    }
  }

  int get vendasVencidas {
    final DateTime today = _dateOnly(_nowProvider());
    return _vendasEmAberto.where((VendaNaoLiquidadaModel sale) {
      final DateTime? dueDate = sale.dataVencimento;
      return sale.valorAberto > 0 &&
          dueDate != null &&
          _dateOnly(dueDate).isBefore(today);
    }).length;
  }

  double get valorTotalVendasEmAberto => _vendasEmAberto.fold<double>(
    0,
    (double total, VendaNaoLiquidadaModel sale) => total + sale.valorAberto,
  );

  int get servicosEmAndamento => _servicosPorStatus
      .where((ColaboradorServicoStatusResumo status) => !status.finalizer)
      .fold<int>(0, (int total, ColaboradorServicoStatusResumo status) {
        return total + status.count;
      });

  int get servicosAtrasados {
    final DateTime today = _dateOnly(_nowProvider());
    return _servicos.where((AtendimentoTecnicoModel service) {
      final DateTime? dueDate = service.dataEntregaPrevista;
      return dueDate != null &&
          !_isServiceFinalized(service) &&
          _dateOnly(dueDate).isBefore(today);
    }).length;
  }

  int get servicosComEntregaHoje {
    final DateTime today = _dateOnly(_nowProvider());
    return _servicos.where((AtendimentoTecnicoModel service) {
      final DateTime? dueDate = service.dataEntregaPrevista;
      return dueDate != null &&
          !_isServiceFinalized(service) &&
          _dateOnly(dueDate).isAtSameMomentAs(today);
    }).length;
  }

  int reservaCount(CatalogoReservaStatus status) =>
      _reservasPorStatus[status] ?? 0;

  int get reservasPendentes =>
      reservaCount(CatalogoReservaStatus.recebida) +
      reservaCount(CatalogoReservaStatus.emAnalise) +
      reservaCount(CatalogoReservaStatus.confirmada);

  int get reservasAguardandoAcao =>
      reservaCount(CatalogoReservaStatus.recebida) +
      reservaCount(CatalogoReservaStatus.emAnalise);

  bool _isServiceFinalized(AtendimentoTecnicoModel service) {
    for (final ColaboradorServicoStatusResumo status in _servicosPorStatus) {
      final String serviceKey = service.statusId > 0
          ? 'id:${service.statusId}'
          : 'code:${service.statusCodigo.trim().toUpperCase()}';
      if (status.key == serviceKey) return status.finalizer;
    }
    return _knownFinalStatus(service.statusCodigo);
  }

  bool _knownFinalStatus(String code) {
    return <String>{
      'DELIVERED',
      'ENTREGUE',
      'CANCELED',
      'CANCELADO',
      'CANCELADA',
      'NO_REPAIR',
      'SEM_REPARO',
      'FINALIZED',
      'FINALIZADO',
      'CONCLUIDO',
      'CONCLUÍDO',
    }.contains(code.trim().toUpperCase());
  }

  int _compareOpenSales(
    VendaNaoLiquidadaModel first,
    VendaNaoLiquidadaModel second,
  ) {
    final DateTime? firstDue = first.dataVencimento;
    final DateTime? secondDue = second.dataVencimento;
    if (firstDue == null && secondDue == null) return 0;
    if (firstDue == null) return 1;
    if (secondDue == null) return -1;
    return firstDue.compareTo(secondDue);
  }

  String _buildAccessKey({
    required bool canAccessSales,
    required bool canAccessServices,
    required bool canAccessReservations,
  }) {
    return '${canAccessSales ? 1 : 0}:${canAccessServices ? 1 : 0}:'
        '${canAccessReservations ? 1 : 0}';
  }

  static String _normalizeId(String? value) =>
      (value ?? '').trim().toLowerCase();

  static String _firstNonBlank(List<String?> values) {
    for (final String? value in values) {
      final String normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class ColaboradorServicoStatusResumo {
  const ColaboradorServicoStatusResumo({
    required this.key,
    required this.statusCode,
    required this.i18nKey,
    required this.namePtBr,
    required this.nameEnUs,
    required this.nameEsEs,
    required this.order,
    required this.colorHex,
    required this.finalizer,
    required this.count,
  });

  final String key;
  final String statusCode;
  final String i18nKey;
  final String namePtBr;
  final String nameEnUs;
  final String nameEsEs;
  final int order;
  final String colorHex;
  final bool finalizer;
  final int count;
}

class _MutableServiceStatus {
  _MutableServiceStatus({
    required this.key,
    required this.statusCode,
    required this.i18nKey,
    required this.namePtBr,
    required this.nameEnUs,
    required this.nameEsEs,
    required this.order,
    required this.colorHex,
    required this.finalizer,
    required this.count,
  });

  final String key;
  final String statusCode;
  final String i18nKey;
  final String namePtBr;
  final String nameEnUs;
  final String nameEsEs;
  final int order;
  final String colorHex;
  final bool finalizer;
  int count;

  ColaboradorServicoStatusResumo toImmutable() {
    return ColaboradorServicoStatusResumo(
      key: key,
      statusCode: statusCode,
      i18nKey: i18nKey,
      namePtBr: namePtBr,
      nameEnUs: nameEnUs,
      nameEsEs: nameEsEs,
      order: order,
      colorHex: colorHex,
      finalizer: finalizer,
      count: count,
    );
  }
}
