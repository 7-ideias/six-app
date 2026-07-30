import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/procedure_execution_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ProcedureExecutionRules rules = ProcedureExecutionRules();

  test('empty procedure can complete', () {
    final ProcedureExecutionValidation validation = rules.validateProcedure(
      procedure: _procedure(items: const <ProcedureItem>[]),
      execution: _execution(),
      enforcementMode: ProcedureEnforcementMode.required,
    );

    expect(validation.totalItems, 0);
    expect(validation.progress, 1);
    expect(validation.canComplete, true);
  });

  test('required item without response is pending', () {
    final ProcedureItem item = _item(
      id: 'required',
      responseType: ProcedureResponseType.confirmation,
    );
    final ProcedureExecutionValidation validation = rules.validateProcedure(
      procedure: _procedure(items: <ProcedureItem>[item]),
      execution: _execution(),
      enforcementMode: ProcedureEnforcementMode.required,
    );

    expect(validation.canComplete, false);
    expect(validation.pendingItemIds, <String>['required']);
    expect(validation.requiredItems, 1);
  });

  test('required item with response can complete', () {
    final ProcedureItem item = _item(
      id: 'confirmation',
      responseType: ProcedureResponseType.confirmation,
    );
    final ProcedureExecutionValidation validation = rules.validateProcedure(
      procedure: _procedure(items: <ProcedureItem>[item]),
      execution: _execution(
        responses: <String, ProcedureItemResponse>{
          'confirmation': _response(
            itemId: 'confirmation',
            responseType: ProcedureResponseType.confirmation,
            completed: true,
          ),
        },
      ),
      enforcementMode: ProcedureEnforcementMode.required,
    );

    expect(validation.canComplete, true);
    expect(validation.answeredItems, 1);
  });

  test('boolean false is a valid response', () {
    final ProcedureItem item = _item(
      id: 'yes-no',
      responseType: ProcedureResponseType.yesNo,
    );
    final ProcedureExecutionValidation validation = rules.validateProcedure(
      procedure: _procedure(items: <ProcedureItem>[item]),
      execution: _execution(
        responses: <String, ProcedureItemResponse>{
          'yes-no': _response(
            itemId: 'yes-no',
            responseType: ProcedureResponseType.yesNo,
            boolValue: false,
          ),
        },
      ),
      enforcementMode: ProcedureEnforcementMode.required,
    );

    expect(validation.canComplete, true);
    expect(validation.answeredItems, 1);
  });

  test('negative text is required when configured', () {
    final ProcedureItem item = _item(
      id: 'negative-text',
      responseType: ProcedureResponseType.yesNo,
      configuration: const ProcedureItemConfiguration(requireTextWhenNo: true),
    );
    final ProcedureExecutionValidation validation = rules.validateProcedure(
      procedure: _procedure(items: <ProcedureItem>[item]),
      execution: _execution(
        responses: <String, ProcedureItemResponse>{
          'negative-text': _response(
            itemId: 'negative-text',
            responseType: ProcedureResponseType.yesNo,
            boolValue: false,
          ),
        },
      ),
      enforcementMode: ProcedureEnforcementMode.required,
    );

    expect(validation.canComplete, false);
    expect(validation.pendingItemIds, <String>['negative-text']);
    expect(
      validation.validationIssues.single.reason,
      ProcedureExecutionValidationIssueReason.missingRequiredNegativeText,
    );
  });

  test('negative text satisfies configured validation', () {
    final ProcedureItem item = _item(
      id: 'negative-text',
      responseType: ProcedureResponseType.yesNo,
      configuration: const ProcedureItemConfiguration(requireTextWhenNo: true),
    );
    final ProcedureExecutionValidation validation = rules.validateProcedure(
      procedure: _procedure(items: <ProcedureItem>[item]),
      execution: _execution(
        responses: <String, ProcedureItemResponse>{
          'negative-text': _response(
            itemId: 'negative-text',
            responseType: ProcedureResponseType.yesNo,
            boolValue: false,
            textValue: 'Faltou um produto.',
          ),
        },
      ),
      enforcementMode: ProcedureEnforcementMode.required,
    );

    expect(validation.canComplete, true);
    expect(validation.answeredItems, 1);
  });

  test('progress counts answered actions', () {
    final List<ProcedureItem> items = <ProcedureItem>[
      _item(id: 'a', responseType: ProcedureResponseType.confirmation),
      _item(id: 'b', responseType: ProcedureResponseType.freeText),
      _item(id: 'c', responseType: ProcedureResponseType.number),
    ];
    final ProcedureExecutionValidation validation = rules.validateProcedure(
      procedure: _procedure(items: items),
      execution: _execution(
        responses: <String, ProcedureItemResponse>{
          'a': _response(
            itemId: 'a',
            responseType: ProcedureResponseType.confirmation,
            completed: true,
          ),
          'b': _response(
            itemId: 'b',
            responseType: ProcedureResponseType.freeText,
            textValue: 'Texto',
          ),
        },
      ),
      enforcementMode: ProcedureEnforcementMode.required,
    );

    expect(validation.answeredItems, 2);
    expect(validation.totalItems, 3);
    expect(validation.progress, closeTo(2 / 3, 0.001));
    expect(validation.canComplete, false);
  });

  test('enforcement controls skip permission', () {
    expect(rules.canSkip(ProcedureEnforcementMode.informative), true);
    expect(rules.canSkip(ProcedureEnforcementMode.recommended), true);
    expect(rules.canSkip(ProcedureEnforcementMode.required), false);
  });

  test('multiple response types are transportable and validatable', () {
    final List<ProcedureItem> items = <ProcedureItem>[
      _item(id: 'date', responseType: ProcedureResponseType.date),
      _item(id: 'single', responseType: ProcedureResponseType.singleChoice),
      _item(id: 'multiple', responseType: ProcedureResponseType.multipleChoice),
      _item(id: 'photo', responseType: ProcedureResponseType.photo),
    ];
    final ProcedureExecutionValidation validation = rules.validateProcedure(
      procedure: _procedure(items: items),
      execution: _execution(
        responses: <String, ProcedureItemResponse>{
          'date': _response(
            itemId: 'date',
            responseType: ProcedureResponseType.date,
            dateValue: DateTime(2026, 7, 29),
          ),
          'single': _response(
            itemId: 'single',
            responseType: ProcedureResponseType.singleChoice,
            selectedOptions: <String>['A'],
          ),
          'multiple': _response(
            itemId: 'multiple',
            responseType: ProcedureResponseType.multipleChoice,
            selectedOptions: <String>['A', 'B'],
          ),
          'photo': _response(
            itemId: 'photo',
            responseType: ProcedureResponseType.photo,
            evidence: const ProcedureSimulatedEvidence(
              label: 'Foto',
              detail: 'foto.jpg',
              iconKey: 'photo',
            ),
          ),
        },
      ),
      enforcementMode: ProcedureEnforcementMode.required,
    );

    expect(validation.canComplete, true);
    expect(validation.answeredItems, 4);
  });
}

OperationalProcedure _procedure({required List<ProcedureItem> items}) {
  return OperationalProcedure(
    id: 'procedure',
    name: 'Procedimento',
    description: '',
    operationType: ProcedureOperationType.sale,
    moment: ProcedureMoment.beforeStart,
    status: ProcedureStatus.active,
    required: true,
    stages: <ProcedureStage>[
      ProcedureStage(
        id: 'stage',
        title: 'Etapa',
        description: '',
        order: 1,
        items: items,
      ),
    ],
    createdAt: DateTime(2026, 7, 29),
    updatedAt: DateTime(2026, 7, 29),
  );
}

ProcedureItem _item({
  required String id,
  required ProcedureResponseType responseType,
  ProcedureItemConfiguration configuration = const ProcedureItemConfiguration(),
}) {
  return ProcedureItem(
    id: id,
    title: id,
    guidance: '',
    responseType: responseType,
    required: true,
    order: 1,
    configuration: configuration,
  );
}

ProcedureExecutionDraft _execution({
  Map<String, ProcedureItemResponse> responses =
      const <String, ProcedureItemResponse>{},
}) {
  return ProcedureExecutionDraft(
    procedureId: 'procedure',
    currentStageIndex: 0,
    responses: responses,
    startedAt: DateTime(2026, 7, 29),
  );
}

ProcedureItemResponse _response({
  required String itemId,
  required ProcedureResponseType responseType,
  bool completed = false,
  bool? boolValue,
  String textValue = '',
  num? numberValue,
  DateTime? dateValue,
  List<String> selectedOptions = const <String>[],
  ProcedureSimulatedEvidence? evidence,
}) {
  return ProcedureItemResponse(
    itemId: itemId,
    responseType: responseType,
    completed: completed,
    boolValue: boolValue,
    textValue: textValue,
    numberValue: numberValue,
    dateValue: dateValue,
    selectedOptions: selectedOptions,
    evidence: evidence,
    updatedAt: DateTime(2026, 7, 29),
  );
}
