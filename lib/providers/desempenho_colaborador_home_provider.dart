import 'package:flutter/foundation.dart';

import '../core/services/auth_service.dart';
import '../data/models/desempenho_colaborador_model.dart';
import '../data/services/desempenho_colaborador/desempenho_colaborador_api_client.dart';

class DesempenhoColaboradorHomeProvider extends ChangeNotifier {
  DesempenhoColaboradorHomeProvider({
    DesempenhoColaboradorApiClient? apiClient,
    Future<String?> Function()? userIdProvider,
    DateTime Function()? nowProvider,
  }) : _apiClient = apiClient ?? HttpDesempenhoColaboradorApiClient(),
       _userIdProvider = userIdProvider ?? AuthService().getUserId,
       _nowProvider = nowProvider ?? DateTime.now;

  static const int maxResultados = 2;

  final DesempenhoColaboradorApiClient _apiClient;
  final Future<String?> Function() _userIdProvider;
  final DateTime Function() _nowProvider;

  List<DesempenhoColaboradorItemModel> _resultados =
      const <DesempenhoColaboradorItemModel>[];
  DateTime? _periodoInicio;
  DateTime? _periodoFim;
  bool _loading = false;
  bool _hasLoaded = false;
  String? _errorCode;
  int _loadRevision = 0;

  List<DesempenhoColaboradorItemModel> get resultados => _resultados;
  DateTime? get periodoInicio => _periodoInicio;
  DateTime? get periodoFim => _periodoFim;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _errorCode != null;
  String? get errorCode => _errorCode;
  int get loadRevision => _loadRevision;

  Future<void> load() async {
    if (_loading) return;

    _loading = true;
    _errorCode = null;
    notifyListeners();

    try {
      final String idColaborador = (await _userIdProvider())?.trim() ?? '';
      if (idColaborador.isEmpty) {
        throw StateError('Usuário autenticado sem identificador.');
      }

      final DateTime now = _nowProvider();
      final DateTime inicio = DateTime(now.year, now.month);
      final DateTime fim = DateTime(now.year, now.month, now.day);
      final DesempenhoColaboradorResumoModel resumo = await _apiClient
          .buscarResumo(
            dataInicio: inicio,
            dataFim: fim,
            idColaborador: idColaborador,
          );

      _resultados = List<DesempenhoColaboradorItemModel>.unmodifiable(
        resumo.resultados
            .where(
              (DesempenhoColaboradorItemModel item) =>
                  item.idColaborador.trim() == idColaborador,
            )
            .take(maxResultados),
      );
      _periodoInicio = resumo.periodoInicio ?? inicio;
      _periodoFim = resumo.periodoFim ?? fim;
      _loadRevision += 1;
    } catch (_) {
      _errorCode = 'performance.home.loadError';
    } finally {
      _hasLoaded = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  void clear() {
    _resultados = const <DesempenhoColaboradorItemModel>[];
    _periodoInicio = null;
    _periodoFim = null;
    _loading = false;
    _hasLoaded = false;
    _errorCode = null;
    notifyListeners();
  }
}
