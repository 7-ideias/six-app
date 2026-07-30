import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/providers/operational_procedure_provider.dart';

void main() {
  group('OperationalProcedureProvider', () {
    test('loads success state with demonstration procedures', () async {
      final provider = OperationalProcedureProvider(
        dataSource: const OperationalProcedureMockDataSource(
          delay: Duration.zero,
        ),
      );

      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.isEmpty, isFalse);
      expect(provider.procedures, hasLength(7));
      expect(
        provider.procedures.any(
          (procedure) => procedure.name == 'Recepção completa de aparelho',
        ),
        isTrue,
      );
      expect(provider.isDemonstrationData, isTrue);
    });

    test('loads empty state', () async {
      final provider = OperationalProcedureProvider(
        dataSource: const OperationalProcedureMockDataSource(
          scenario: OperationalProcedureMockScenario.empty,
          delay: Duration.zero,
        ),
      );

      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.isEmpty, isTrue);
      expect(provider.filteredProcedures, isEmpty);
    });

    test('loads error state', () async {
      final provider = OperationalProcedureProvider(
        dataSource: const OperationalProcedureMockDataSource(
          scenario: OperationalProcedureMockScenario.error,
          delay: Duration.zero,
        ),
      );

      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, isNotNull);
      expect(provider.procedures, isEmpty);
    });

    test('filters all procedures', () async {
      final provider = OperationalProcedureProvider(
        dataSource: const OperationalProcedureMockDataSource(
          delay: Duration.zero,
        ),
      );

      await provider.load();
      provider.setFilter(OperationalProcedureFilter.all);

      expect(provider.filteredProcedures, hasLength(7));
    });

    test('filters active procedures', () async {
      final provider = OperationalProcedureProvider(
        dataSource: const OperationalProcedureMockDataSource(
          delay: Duration.zero,
        ),
      );

      await provider.load();
      provider.setFilter(OperationalProcedureFilter.active);

      expect(provider.filteredProcedures, hasLength(6));
      expect(
        provider.filteredProcedures.every(
          (procedure) => procedure.status == ProcedureStatus.active,
        ),
        isTrue,
      );
    });

    test('filters inactive procedures', () async {
      final provider = OperationalProcedureProvider(
        dataSource: const OperationalProcedureMockDataSource(
          delay: Duration.zero,
        ),
      );

      await provider.load();
      provider.setFilter(OperationalProcedureFilter.inactive);

      expect(provider.filteredProcedures, hasLength(1));
      expect(provider.filteredProcedures.single.name, 'Finalização de venda');
    });

    test('creates procedure in memory', () async {
      final provider = await _loadedProvider();
      final OperationalProcedure draft = provider.createEmptyProcedure();

      provider.saveProcedure(
        draft.copyWith(
          name: 'Procedimento novo',
          stages: <ProcedureStage>[
            _stage(items: <ProcedureItem>[_item()]),
          ],
        ),
      );

      expect(provider.procedures, hasLength(8));
      expect(provider.findById(draft.id)?.name, 'Procedimento novo');
    });

    test('edits procedure in memory', () async {
      final provider = await _loadedProvider();
      final OperationalProcedure current = provider.procedures.first;

      provider.updateProcedure(current.copyWith(name: 'Recepção editada'));

      expect(provider.findById(current.id)?.name, 'Recepção editada');
      expect(provider.procedures, hasLength(7));
    });

    test('finds procedure by id', () async {
      final provider = await _loadedProvider();

      expect(provider.findById('device-intake')?.name, 'Recepção de aparelho');
      expect(provider.findById('missing'), isNull);
    });

    test('adds edits and removes stage', () async {
      final provider = await _loadedProvider();
      OperationalProcedure draft = provider.createEmptyProcedure();

      draft = provider.addStage(draft, _stage(title: 'Etapa A'));
      expect(draft.stages.single.title, 'Etapa A');

      draft = provider.updateStage(
        draft,
        draft.stages.single.copyWith(title: 'Etapa B'),
      );
      expect(draft.stages.single.title, 'Etapa B');

      draft = provider.removeStage(draft, draft.stages.single.id);
      expect(draft.stages, isEmpty);
    });

    test('adds edits and removes item', () async {
      final provider = await _loadedProvider();
      ProcedureStage stage = _stage(items: const <ProcedureItem>[]);

      stage = provider.addItem(stage, _item(title: 'Item A'));
      expect(stage.items.single.title, 'Item A');

      stage = provider.updateItem(
        stage,
        stage.items.single.copyWith(title: 'Item B'),
      );
      expect(stage.items.single.title, 'Item B');

      stage = provider.removeItem(stage, stage.items.single.id);
      expect(stage.items, isEmpty);
    });

    test('keeps item options and configuration immutable with copyWith', () {
      final ProcedureItem item = _item(title: 'Escolha uma condição').copyWith(
        responseType: ProcedureResponseType.singleChoice,
        options: <String>['Novo', 'Usado'],
        configuration: const ProcedureItemConfiguration(
          placeholder: 'Digite aqui',
          unit: 'unidades',
        ),
      );

      final ProcedureItem edited = item.copyWith(title: 'Condição do item');

      expect(edited.title, 'Condição do item');
      expect(edited.options, <String>['Novo', 'Usado']);
      expect(edited.configuration.placeholder, 'Digite aqui');
      expect(item.title, 'Escolha uma condição');
    });

    test('supports all experimental response types', () {
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.photo),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.signature),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.location),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.barcode),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.imei),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.document),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.audio),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.freeText),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.number),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.date),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.singleChoice),
      );
      expect(
        ProcedureResponseType.values,
        contains(ProcedureResponseType.multipleChoice),
      );
    });

    test('cancel draft without saving does not alter list', () async {
      final provider = await _loadedProvider();
      provider.createEmptyProcedure().copyWith(name: 'Não salvo');

      expect(provider.procedures, hasLength(7));
      expect(
        provider.procedures.any((item) => item.name == 'Não salvo'),
        false,
      );
    });

    test('filters keep working after creation and edition', () async {
      final provider = await _loadedProvider();
      final OperationalProcedure draft = provider.createEmptyProcedure();

      provider.saveProcedure(
        draft.copyWith(
          name: 'Inativo novo',
          status: ProcedureStatus.inactive,
          stages: <ProcedureStage>[
            _stage(items: <ProcedureItem>[_item()]),
          ],
        ),
      );
      provider.setFilter(OperationalProcedureFilter.inactive);

      expect(provider.filteredProcedures, hasLength(2));

      final OperationalProcedure saved = provider.findById(draft.id)!;
      provider.updateProcedure(saved.copyWith(status: ProcedureStatus.active));

      expect(provider.filteredProcedures, hasLength(1));
    });

    test('creates procedure without triggers by default', () async {
      final provider = await _loadedProvider();

      final OperationalProcedure draft = provider.createEmptyProcedure();

      expect(draft.triggers, isEmpty);
      expect(draft.activeTriggerCount, 0);
      expect(draft.hasAutomaticTriggers, isFalse);
    });

    test('adds edits disables and removes trigger in draft', () async {
      final provider = await _loadedProvider();
      OperationalProcedure draft = provider.createEmptyProcedure();

      final ProcedureTrigger trigger = provider.createTriggerDraft().copyWith(
        operationType: ProcedureOperationType.sale,
        triggerMoment: ProcedureTriggerMoment.beforeFinish,
        activationMode: ProcedureTriggerActivationMode.automatic,
        enforcementMode: ProcedureEnforcementMode.required,
      );

      draft = provider.addTrigger(draft, trigger);
      expect(draft.triggers.single.order, 1);
      expect(draft.activeTriggerCount, 1);
      expect(draft.hasAutomaticTriggers, isTrue);

      draft = provider.updateTrigger(
        draft,
        draft.triggers.single.copyWith(
          enforcementMode: ProcedureEnforcementMode.informative,
        ),
      );
      expect(
        draft.triggers.single.enforcementMode,
        ProcedureEnforcementMode.informative,
      );

      draft = provider.setTriggerEnabled(draft, draft.triggers.single, false);
      expect(draft.activeTriggerCount, 0);
      expect(draft.triggers.single.enabled, isFalse);

      draft = provider.removeTrigger(draft, draft.triggers.single.id);
      expect(draft.triggers, isEmpty);
    });

    test('saves procedure with triggers in memory', () async {
      final provider = await _loadedProvider();
      final OperationalProcedure draft = provider.createEmptyProcedure();
      final ProcedureTrigger trigger = provider.createTriggerDraft().copyWith(
        operationType: ProcedureOperationType.technicalService,
        triggerMoment: ProcedureTriggerMoment.beforeStart,
        activationMode: ProcedureTriggerActivationMode.automatic,
      );

      provider.saveProcedure(
        draft.copyWith(
          name: 'Procedimento com gatilho',
          stages: <ProcedureStage>[
            _stage(items: <ProcedureItem>[_item()]),
          ],
          triggers: <ProcedureTrigger>[trigger],
        ),
      );

      final OperationalProcedure saved = provider.findById(draft.id)!;
      expect(saved.triggers, hasLength(1));
      expect(saved.triggers.single.order, 1);
      expect(saved.activeTriggerCount, 1);
    });
  });
}

Future<OperationalProcedureProvider> _loadedProvider() async {
  final provider = OperationalProcedureProvider(
    dataSource: const OperationalProcedureMockDataSource(delay: Duration.zero),
  );
  await provider.load();
  return provider;
}

ProcedureStage _stage({
  String title = 'Etapa',
  List<ProcedureItem> items = const <ProcedureItem>[],
}) {
  return ProcedureStage(
    id: '',
    title: title,
    description: '',
    order: 0,
    items: items,
  );
}

ProcedureItem _item({String title = 'Item'}) {
  return ProcedureItem(
    id: '',
    title: title,
    guidance: '',
    responseType: ProcedureResponseType.confirmation,
    required: true,
    order: 0,
  );
}
