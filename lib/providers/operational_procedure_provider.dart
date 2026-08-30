import 'package:flutter/foundation.dart';
import 'package:sixpos/data/datasources/operational_procedure_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/data/services/operational_procedures/operational_procedure_api_client.dart';

class OperationalProcedureProvider extends ChangeNotifier {
  OperationalProcedureProvider({
    OperationalProcedureDataSource? dataSource,
    this.localeTag = 'pt-BR',
  }) : _dataSource = dataSource ?? HttpOperationalProcedureApiClient();

  final OperationalProcedureDataSource _dataSource;
  final String localeTag;

  OperationalProcedureSummary? _summary;
  OperationalProcedureFilter _filter = OperationalProcedureFilter.all;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  int _localIdSeed = 0;

  OperationalProcedureSummary? get summary => _summary;
  OperationalProcedureFilter get filter => _filter;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
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
      _summary = await _dataSource.fetchProcedures(idioma: localeTag);
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
      triggers: const <ProcedureTrigger>[],
      stages: const <ProcedureStage>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<OperationalProcedure?> saveProcedure(
    OperationalProcedure procedure,
  ) async {
    final DateTime now = DateTime.now();
    final OperationalProcedureSummary? previousSummary = _summary;
    final List<OperationalProcedure> current = List<OperationalProcedure>.of(
      procedures,
    );
    final int index = current.indexWhere(
      (OperationalProcedure item) => item.id == procedure.id,
    );
    final OperationalProcedure normalized = _normalizeProcedure(
      procedure.copyWith(updatedAt: now),
    );
    final bool isCreating = index < 0;

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
    _isSaving = true;
    notifyListeners();

    try {
      final OperationalProcedure persisted = await _dataSource.saveProcedure(
        procedure: normalized,
        idioma: localeTag,
        isCreating: isCreating,
      );
      final List<OperationalProcedure> persistedList =
          List<OperationalProcedure>.of(procedures);
      final int optimisticIndex = persistedList.indexWhere(
        (OperationalProcedure item) => item.id == normalized.id,
      );
      if (optimisticIndex >= 0) {
        persistedList[optimisticIndex] = _normalizeProcedure(persisted);
      }
      _summary = OperationalProcedureSummary(
        procedures: persistedList,
        isDemonstrationData: isDemonstrationData,
      );
      return persisted;
    } catch (_) {
      _summary = previousSummary;
      _errorMessage = 'Não foi possível salvar o procedimento.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<OperationalProcedure?> updateProcedure(
    OperationalProcedure procedure,
  ) => saveProcedure(procedure);

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

  ProcedureTrigger createTriggerDraft() {
    final DateTime now = DateTime.now();
    return ProcedureTrigger(
      id: _nextId('trigger'),
      operationPoint: ProcedureOperationPoint.saleStartBefore,
      operationType: ProcedureOperationType.sale,
      triggerMoment: ProcedureTriggerMoment.beforeStart,
      activationMode: ProcedureTriggerActivationMode.automatic,
      enforcementMode: ProcedureEnforcementMode.recommended,
      enabled: true,
      order: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  OperationalProcedure addTrigger(
    OperationalProcedure procedure,
    ProcedureTrigger trigger,
  ) {
    final List<ProcedureTrigger> triggers = <ProcedureTrigger>[
      ...procedure.triggers,
      trigger.copyWith(id: _ensureId(trigger.id, 'trigger')),
    ];
    return procedure.copyWith(triggers: _normalizeTriggers(triggers));
  }

  OperationalProcedure updateTrigger(
    OperationalProcedure procedure,
    ProcedureTrigger trigger,
  ) {
    return procedure.copyWith(
      triggers: _normalizeTriggers(
        procedure.triggers.map((ProcedureTrigger current) {
          return current.id == trigger.id ? trigger : current;
        }).toList(),
      ),
    );
  }

  OperationalProcedure removeTrigger(
    OperationalProcedure procedure,
    String triggerId,
  ) {
    return procedure.copyWith(
      triggers: _normalizeTriggers(
        procedure.triggers
            .where((ProcedureTrigger trigger) => trigger.id != triggerId)
            .toList(),
      ),
    );
  }

  OperationalProcedure setTriggerEnabled(
    OperationalProcedure procedure,
    ProcedureTrigger trigger,
    bool enabled,
  ) {
    return updateTrigger(procedure, trigger.copyWith(enabled: enabled));
  }

  OperationalProcedure _normalizeProcedure(OperationalProcedure procedure) {
    return procedure.copyWith(
      triggers: _normalizeTriggers(procedure.triggers),
      stages: _normalizeStages(procedure.stages),
    );
  }

  List<ProcedureTrigger> _normalizeTriggers(List<ProcedureTrigger> triggers) {
    return triggers
        .asMap()
        .entries
        .map((MapEntry<int, ProcedureTrigger> entry) {
          return entry.value.copyWith(order: entry.key + 1);
        })
        .toList(growable: false);
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
          return entry.value.copyWith(
            order: entry.key + 1,
            options: entry.value.options
                .map((String option) => option.trim())
                .where((String option) => option.isNotEmpty)
                .toList(growable: false),
          );
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
