import 'package:flutter/foundation.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';

class OperationalProcedureProvider extends ChangeNotifier {
  OperationalProcedureProvider({
    required OperationalProcedureMockDataSource dataSource,
  }) : _dataSource = dataSource;

  final OperationalProcedureMockDataSource _dataSource;

  OperationalProcedureSummary? _summary;
  OperationalProcedureFilter _filter = OperationalProcedureFilter.all;
  bool _isLoading = false;
  String? _errorMessage;
  int _localIdSeed = 0;

  OperationalProcedureSummary? get summary => _summary;
  OperationalProcedureFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty =>
      !_isLoading && !hasError && (_summary?.procedures.isEmpty ?? true);
  bool get isDemonstrationData => _summary?.isDemonstrationData ?? true;

  List<OperationalProcedure> get procedures =>
      _summary?.procedures ?? const <OperationalProcedure>[];

  List<OperationalProcedure> get filteredProcedures {
    return switch (_filter) {
      OperationalProcedureFilter.all => procedures,
      OperationalProcedureFilter.active =>
        procedures.where((OperationalProcedure item) => item.isActive).toList(),
      OperationalProcedureFilter.inactive =>
        procedures
            .where((OperationalProcedure item) => item.isInactive)
            .toList(),
    };
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _dataSource.fetchProcedures();
    } catch (_) {
      _summary = null;
      _errorMessage = 'Não foi possível carregar os procedimentos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  void setFilter(OperationalProcedureFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  OperationalProcedure? findById(String id) {
    for (final OperationalProcedure procedure in procedures) {
      if (procedure.id == id) return procedure;
    }
    return null;
  }

  OperationalProcedure createEmptyProcedure() {
    final DateTime now = DateTime.now();
    return OperationalProcedure(
      id: _nextId('procedure'),
      name: '',
      description: '',
      operationType: ProcedureOperationType.sale,
      moment: ProcedureMoment.beforeStart,
      status: ProcedureStatus.active,
      required: false,
      stages: const <ProcedureStage>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  void saveProcedure(OperationalProcedure procedure) {
    final DateTime now = DateTime.now();
    final List<OperationalProcedure> current = List<OperationalProcedure>.of(
      procedures,
    );
    final int index = current.indexWhere(
      (OperationalProcedure item) => item.id == procedure.id,
    );
    final OperationalProcedure normalized = _normalizeProcedure(
      procedure.copyWith(updatedAt: now),
    );

    if (index >= 0) {
      current[index] = normalized;
    } else {
      current.add(normalized.copyWith(createdAt: procedure.createdAt));
    }

    _summary = OperationalProcedureSummary(
      procedures: current,
      isDemonstrationData: isDemonstrationData,
    );
    _errorMessage = null;
    notifyListeners();
  }

  void updateProcedure(OperationalProcedure procedure) =>
      saveProcedure(procedure);

  OperationalProcedure addStage(
    OperationalProcedure procedure,
    ProcedureStage stage,
  ) {
    final List<ProcedureStage> stages = <ProcedureStage>[
      ...procedure.stages,
      stage.copyWith(id: _ensureId(stage.id, 'stage')),
    ];
    return procedure.copyWith(stages: _normalizeStages(stages));
  }

  OperationalProcedure updateStage(
    OperationalProcedure procedure,
    ProcedureStage stage,
  ) {
    return procedure.copyWith(
      stages: _normalizeStages(
        procedure.stages.map((ProcedureStage item) {
          return item.id == stage.id ? stage : item;
        }).toList(),
      ),
    );
  }

  OperationalProcedure removeStage(
    OperationalProcedure procedure,
    String stageId,
  ) {
    return procedure.copyWith(
      stages: _normalizeStages(
        procedure.stages
            .where((ProcedureStage stage) => stage.id != stageId)
            .toList(),
      ),
    );
  }

  ProcedureStage addItem(ProcedureStage stage, ProcedureItem item) {
    final List<ProcedureItem> items = <ProcedureItem>[
      ...stage.items,
      item.copyWith(id: _ensureId(item.id, 'item')),
    ];
    return stage.copyWith(items: _normalizeItems(items));
  }

  ProcedureStage updateItem(ProcedureStage stage, ProcedureItem item) {
    return stage.copyWith(
      items: _normalizeItems(
        stage.items.map((ProcedureItem current) {
          return current.id == item.id ? item : current;
        }).toList(),
      ),
    );
  }

  ProcedureStage removeItem(ProcedureStage stage, String itemId) {
    return stage.copyWith(
      items: _normalizeItems(
        stage.items.where((ProcedureItem item) => item.id != itemId).toList(),
      ),
    );
  }

  OperationalProcedure setProcedureActive(
    OperationalProcedure procedure,
    bool active,
  ) {
    return procedure.copyWith(
      status: active ? ProcedureStatus.active : ProcedureStatus.inactive,
    );
  }

  OperationalProcedure _normalizeProcedure(OperationalProcedure procedure) {
    return procedure.copyWith(stages: _normalizeStages(procedure.stages));
  }

  List<ProcedureStage> _normalizeStages(List<ProcedureStage> stages) {
    return stages
        .asMap()
        .entries
        .map((MapEntry<int, ProcedureStage> entry) {
          return entry.value.copyWith(
            order: entry.key + 1,
            items: _normalizeItems(entry.value.items),
          );
        })
        .toList(growable: false);
  }

  List<ProcedureItem> _normalizeItems(List<ProcedureItem> items) {
    return items
        .asMap()
        .entries
        .map((MapEntry<int, ProcedureItem> entry) {
          return entry.value.copyWith(order: entry.key + 1);
        })
        .toList(growable: false);
  }

  String _ensureId(String id, String prefix) {
    if (id.trim().isNotEmpty) return id;
    return _nextId(prefix);
  }

  String _nextId(String prefix) {
    _localIdSeed++;
    return '$prefix-local-$_localIdSeed';
  }
}
