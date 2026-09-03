import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/auth_service.dart';
import '../core/services/websocket_service.dart';
import '../data/models/colaborador_usuario_model.dart';
import '../data/models/desempenho_colaborador_model.dart';
import '../data/models/usuario_model.dart';
import '../data/services/desempenho_colaborador/desempenho_colaborador_api_client.dart';
import '../domain/services/usuario/usuario_service.dart';

typedef DesempenhoPreferenciasLoader =
    Future<PreferenciasIndividuaisDoUsuarioModel?> Function();
typedef DesempenhoPreferenciasSaver =
    Future<void> Function(Map<String, dynamic> filtros);

enum DesempenhoInicioPeriodo { hoje, ultimos7Dias, ultimos30Dias, mesAtual }

class DesempenhoInicioIntervalo {
  const DesempenhoInicioIntervalo({required this.inicio, required this.fim});

  final DateTime inicio;
  final DateTime fim;
}

extension DesempenhoInicioPeriodoIntervalo on DesempenhoInicioPeriodo {
  DesempenhoInicioIntervalo intervalo(DateTime agora) {
    final DateTime hoje = DateTime(agora.year, agora.month, agora.day);
    return switch (this) {
      DesempenhoInicioPeriodo.hoje => DesempenhoInicioIntervalo(
        inicio: hoje,
        fim: hoje,
      ),
      DesempenhoInicioPeriodo.ultimos7Dias => DesempenhoInicioIntervalo(
        inicio: hoje.subtract(const Duration(days: 6)),
        fim: hoje,
      ),
      DesempenhoInicioPeriodo.ultimos30Dias => DesempenhoInicioIntervalo(
        inicio: hoje.subtract(const Duration(days: 29)),
        fim: hoje,
      ),
      DesempenhoInicioPeriodo.mesAtual => DesempenhoInicioIntervalo(
        inicio: DateTime(hoje.year, hoje.month),
        fim: hoje,
      ),
    };
  }
}

class DesempenhoColaboradorHomeProvider extends ChangeNotifier {
  DesempenhoColaboradorHomeProvider({
    DesempenhoColaboradorApiClient? apiClient,
    Future<String?> Function()? userIdProvider,
    Future<String?> Function()? companyIdProvider,
    DateTime Function()? nowProvider,
    Stream<Map<String, dynamic>>? realtimeMessages,
    DesempenhoPreferenciasLoader? preferencesLoader,
    DesempenhoPreferenciasSaver? preferencesSaver,
  }) : _apiClient = apiClient ?? HttpDesempenhoColaboradorApiClient(),
       _userIdProvider = userIdProvider ?? AuthService().getUserId,
       _companyIdProvider = companyIdProvider ?? AuthService().getEmpresaId,
       _nowProvider = nowProvider ?? DateTime.now,
       _preferencesLoader =
           preferencesLoader ??
           UsuarioService().carregarPreferenciasIndividuaisDoCache,
       _preferencesSaver =
           preferencesSaver ??
           ((Map<String, dynamic> filtros) =>
               UsuarioService().atualizarPreferenciasIndividuais(
                 desempenhoInicioFiltrosWeb: kIsWeb ? filtros : null,
                 desempenhoInicioFiltrosMobile: kIsWeb ? null : filtros,
               )) {
    _realtimeSubscription = (realtimeMessages ?? stompMessages).listen(
      _onRealtimeMessage,
    );
  }

  static const int maxResultados = 2;

  final DesempenhoColaboradorApiClient _apiClient;
  final Future<String?> Function() _userIdProvider;
  final Future<String?> Function() _companyIdProvider;
  final DateTime Function() _nowProvider;
  final DesempenhoPreferenciasLoader _preferencesLoader;
  final DesempenhoPreferenciasSaver _preferencesSaver;

  late final StreamSubscription<Map<String, dynamic>> _realtimeSubscription;
  Timer? _realtimeDebounce;
  DesempenhoColaboradorResumoModel _resumo =
      DesempenhoColaboradorResumoModel.empty();
  List<ColaboradorUsuarioResumo> _participantes =
      const <ColaboradorUsuarioResumo>[];
  Set<String> _idsColaboradoresSelecionados = const <String>{};
  DesempenhoInicioPeriodo _periodoSelecionado =
      DesempenhoInicioPeriodo.mesAtual;
  DateTime? _periodoInicio;
  DateTime? _periodoFim;
  DateTime? _atualizadoEm;
  bool _isAdmin = false;
  bool _roleConfigured = false;
  bool _loading = false;
  bool _hasLoaded = false;
  bool _pendingReload = false;
  bool _realtimeActive = false;
  bool _preferencesRestored = false;
  bool _disposed = false;
  String? _errorCode;
  int _loadRevision = 0;
  int _requestRevision = 0;

  List<DesempenhoColaboradorItemModel> get resultados =>
      List.unmodifiable(_resumo.resultados.take(maxResultados));
  List<DesempenhoColaboradorItemModel> get metasAtivas => _resumo.resultados;
  List<DesempenhoColaboradorComparativoModel> get comparativos =>
      _resumo.comparativos;
  List<ColaboradorUsuarioResumo> get participantes => _participantes;
  Set<String> get idsColaboradoresSelecionados =>
      Set<String>.unmodifiable(_idsColaboradoresSelecionados);
  DesempenhoColaboradorResumoModel get resumo => _resumo;
  DesempenhoInicioPeriodo get periodoSelecionado => _periodoSelecionado;
  DateTime? get periodoInicio => _periodoInicio;
  DateTime? get periodoFim => _periodoFim;
  DateTime? get atualizadoEm => _atualizadoEm;
  bool get isAdmin => _isAdmin;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _errorCode != null;
  String? get errorCode => _errorCode;
  int get loadRevision => _loadRevision;

  void configureRole({required bool isAdmin}) {
    if (_roleConfigured && _isAdmin == isAdmin) return;
    _requestRevision += 1;
    _roleConfigured = true;
    _isAdmin = isAdmin;
    _participantes = const <ColaboradorUsuarioResumo>[];
    _idsColaboradoresSelecionados = const <String>{};
    _resumo = DesempenhoColaboradorResumoModel.empty();
    _periodoInicio = null;
    _periodoFim = null;
    _atualizadoEm = null;
    _hasLoaded = false;
    _loading = false;
    _pendingReload = false;
    _errorCode = null;
    _preferencesRestored = false;
    _loadRevision = 0;
  }

  void setRealtimeActive(bool active) {
    _realtimeActive = active;
    if (!active) {
      _realtimeDebounce?.cancel();
      _realtimeDebounce = null;
    }
  }

  Future<void> load() async {
    if (_loading) {
      _pendingReload = true;
      return;
    }

    _loading = true;
    _errorCode = null;
    final int requestRevision = ++_requestRevision;
    final bool isAdmin = _isAdmin;
    _notify();

    try {
      await _restorePreferencesIfNeeded(
        requestRevision: requestRevision,
        isAdmin: isAdmin,
      );
      if (_disposed || requestRevision != _requestRevision) return;
      final String idColaborador = (await _userIdProvider())?.trim() ?? '';
      if (!isAdmin && idColaborador.isEmpty) {
        throw StateError('Usuário autenticado sem identificador.');
      }

      List<ColaboradorUsuarioResumo> participantes = _participantes;
      if (isAdmin && participantes.isEmpty) {
        participantes = (await _apiClient.listarParticipantes(
          incluirNaoAtivos: false,
        )).where((item) => item.ativo).toList(growable: false)..sort(
          (a, b) => _nomeParticipante(
            a,
          ).toLowerCase().compareTo(_nomeParticipante(b).toLowerCase()),
        );
      }

      if (isAdmin && _idsColaboradoresSelecionados.isNotEmpty) {
        final Set<String> idsAtivos =
            participantes
                .map(
                  (ColaboradorUsuarioResumo item) => item.idUnicoPessoal.trim(),
                )
                .where((String id) => id.isNotEmpty)
                .toSet();
        _idsColaboradoresSelecionados = Set<String>.unmodifiable(
          _idsColaboradoresSelecionados.intersection(idsAtivos),
        );
      }

      final DesempenhoInicioIntervalo intervalo = _periodoSelecionado.intervalo(
        _nowProvider(),
      );
      final DesempenhoColaboradorResumoModel resumo = await _apiClient
          .buscarResumo(
            dataInicio: intervalo.inicio,
            dataFim: intervalo.fim,
            idColaborador: isAdmin ? null : idColaborador,
            idsColaboradores:
                isAdmin
                    ? _idsColaboradoresSelecionados.toList(growable: false)
                    : const <String>[],
          );

      if (_disposed || requestRevision != _requestRevision) return;
      _participantes = List<ColaboradorUsuarioResumo>.unmodifiable(
        participantes,
      );
      _resumo = resumo;
      _periodoInicio = resumo.periodoInicio ?? intervalo.inicio;
      _periodoFim = resumo.periodoFim ?? intervalo.fim;
      _atualizadoEm = _nowProvider();
      _loadRevision += 1;
    } catch (error, stackTrace) {
      debugPrint(
        '[DesempenhoColaboradorHomeProvider] Falha ao carregar: '
        '$error\n$stackTrace',
      );
      if (!_disposed && requestRevision == _requestRevision) {
        _errorCode = 'performance.home.loadError';
      }
    } finally {
      if (!_disposed && requestRevision == _requestRevision) {
        _hasLoaded = true;
        _loading = false;
        _notify();
        if (_pendingReload) {
          _pendingReload = false;
          unawaited(load());
        }
      }
    }
  }

  Future<void> reload() => load();

  Future<void> setPeriodo(DesempenhoInicioPeriodo periodo) async {
    if (_periodoSelecionado == periodo) return;
    _periodoSelecionado = periodo;
    _notify();
    unawaited(_persistPreferences());
    await load();
  }

  Future<void> setColaboradoresSelecionados(Iterable<String> ids) async {
    if (!_isAdmin) return;
    final Set<String> normalizados =
        ids
            .map((String id) => id.trim())
            .where((String id) => id.isNotEmpty)
            .toSet();
    if (setEquals(normalizados, _idsColaboradoresSelecionados)) return;
    _idsColaboradoresSelecionados = Set<String>.unmodifiable(normalizados);
    _notify();
    unawaited(_persistPreferences());
    await load();
  }

  String nomeDoParticipante(String idColaborador) {
    for (final ColaboradorUsuarioResumo participante in _participantes) {
      if (participante.idUnicoPessoal == idColaborador) {
        return _nomeParticipante(participante);
      }
    }
    return idColaborador;
  }

  void clear() {
    _requestRevision += 1;
    _resumo = DesempenhoColaboradorResumoModel.empty();
    _participantes = const <ColaboradorUsuarioResumo>[];
    _idsColaboradoresSelecionados = const <String>{};
    _periodoInicio = null;
    _periodoFim = null;
    _atualizadoEm = null;
    _loading = false;
    _hasLoaded = false;
    _pendingReload = false;
    _errorCode = null;
    _preferencesRestored = false;
    _loadRevision = 0;
    _notify();
  }

  Future<void> _restorePreferencesIfNeeded({
    required int requestRevision,
    required bool isAdmin,
  }) async {
    if (_preferencesRestored) return;
    _preferencesRestored = true;

    try {
      final PreferenciasIndividuaisDoUsuarioModel? preferencias =
          await _preferencesLoader();
      if (_disposed || requestRevision != _requestRevision) return;
      final Map<String, dynamic> filtros =
          kIsWeb
              ? preferencias?.desempenhoInicioFiltrosWeb ??
                  const <String, dynamic>{}
              : preferencias?.desempenhoInicioFiltrosMobile ??
                  const <String, dynamic>{};

      final String periodoSalvo = filtros['periodo']?.toString().trim() ?? '';
      for (final DesempenhoInicioPeriodo periodo
          in DesempenhoInicioPeriodo.values) {
        if (periodo.name == periodoSalvo) {
          _periodoSelecionado = periodo;
          break;
        }
      }

      if (isAdmin) {
        final String empresaAtual = (await _companyIdProvider())?.trim() ?? '';
        if (_disposed || requestRevision != _requestRevision) return;
        final String empresaSalva =
            filtros['idEmpresa']?.toString().trim() ?? '';
        if (empresaSalva.isNotEmpty && empresaSalva != empresaAtual) return;

        final dynamic idsSalvos = filtros['idsColaboradores'];
        final Iterable<dynamic> ids =
            idsSalvos is Iterable<dynamic>
                ? idsSalvos
                : idsSalvos is String
                ? idsSalvos.split(',')
                : const <dynamic>[];
        _idsColaboradoresSelecionados = Set<String>.unmodifiable(
          ids
              .map((dynamic id) => id.toString().trim())
              .where((String id) => id.isNotEmpty)
              .toSet(),
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[DesempenhoColaboradorHomeProvider] Falha ao restaurar filtros: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _persistPreferences() async {
    try {
      final List<String> ids = _idsColaboradoresSelecionados.toList()..sort();
      final String idEmpresa = (await _companyIdProvider())?.trim() ?? '';
      await _preferencesSaver(<String, dynamic>{
        'periodo': _periodoSelecionado.name,
        'idEmpresa': idEmpresa,
        'idsColaboradores': _isAdmin ? ids : const <String>[],
      });
    } catch (error, stackTrace) {
      debugPrint(
        '[DesempenhoColaboradorHomeProvider] Falha ao persistir filtros: '
        '$error\n$stackTrace',
      );
    }
  }

  void _onRealtimeMessage(Map<String, dynamic> payload) {
    if (!_realtimeActive) return;
    final String type = payload['tipoDeEvento']?.toString().toUpperCase() ?? '';
    if (type != 'DASHBOARD_DESEMPENHO_ATUALIZADO' &&
        type != 'NOVA_VENDA' &&
        type != 'META_COLABORADOR_ATUALIZADA' &&
        type != 'ATENDIMENTO_TECNICO_ATUALIZADO' &&
        type != 'CAIXA_ATUALIZADO') {
      return;
    }
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 420), () {
      if (!_disposed && _hasLoaded) unawaited(load());
    });
  }

  String _nomeParticipante(ColaboradorUsuarioResumo participante) {
    final String apelido = participante.nomeDeGuerra.trim();
    if (apelido.isNotEmpty) return apelido;
    final String nome = participante.nome.trim();
    if (nome.isNotEmpty) return nome;
    return participante.email.trim();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _realtimeDebounce?.cancel();
    unawaited(_realtimeSubscription.cancel());
    super.dispose();
  }
}
