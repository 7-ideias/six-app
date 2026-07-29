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
      expect(provider.procedures, hasLength(4));
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

      expect(provider.filteredProcedures, hasLength(4));
    });

    test('filters active procedures', () async {
      final provider = OperationalProcedureProvider(
        dataSource: const OperationalProcedureMockDataSource(
          delay: Duration.zero,
        ),
      );

      await provider.load();
      provider.setFilter(OperationalProcedureFilter.active);

      expect(provider.filteredProcedures, hasLength(3));
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

      expect(provider.procedures, hasLength(5));
      expect(provider.findById(draft.id)?.name, 'Procedimento novo');
    });

    test('edits procedure in memory', () async {
      final provider = await _loadedProvider();
      final OperationalProcedure current = provider.procedures.first;

      provider.updateProcedure(current.copyWith(name: 'Recepção editada'));

      expect(provider.findById(current.id)?.name, 'Recepção editada');
      expect(provider.procedures, hasLength(4));
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

    test('cancel draft without saving does not alter list', () async {
      final provider = await _loadedProvider();
      provider.createEmptyProcedure().copyWith(name: 'Não salvo');

      expect(provider.procedures, hasLength(4));
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
