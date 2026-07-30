import 'package:sixpos/data/models/operational_procedure_models.dart';

class ProcedureExecutionValidation {
  const ProcedureExecutionValidation({
    required this.totalItems,
    required this.answeredItems,
    required this.requiredItems,
    required this.pendingRequiredItems,
    required this.pendingItemIds,
    required this.validationIssues,
    required this.canSkip,
  });

  final int totalItems;
  final int answeredItems;
  final int requiredItems;
  final int pendingRequiredItems;
  final List<String> pendingItemIds;
  final List<ProcedureExecutionValidationIssue> validationIssues;
  final bool canSkip;

  double get progress {
    if (totalItems == 0) return 1;
    return answeredItems / totalItems;
  }

  bool get canComplete => pendingRequiredItems == 0;
}

class ProcedureExecutionValidationIssue {
  const ProcedureExecutionValidationIssue({
    required this.itemId,
    required this.reason,
  });

  final String itemId;
  final ProcedureExecutionValidationIssueReason reason;
}

enum ProcedureExecutionValidationIssueReason {
  missingRequiredResponse,
  missingRequiredNegativeText,
}

class ProcedureExecutionRules {
  const ProcedureExecutionRules();

  ProcedureExecutionValidation validateProcedure({
    required OperationalProcedure procedure,
    required ProcedureExecutionDraft execution,
    required ProcedureEnforcementMode enforcementMode,
  }) {
    final List<ProcedureItem> items = procedure.stages
        .expand((ProcedureStage stage) => stage.items)
        .toList(growable: false);
    return _validateItems(
      items: items,
      responses: execution.responses,
      enforcementMode: enforcementMode,
    );
  }

  ProcedureExecutionValidation validateStage({
    required ProcedureStage stage,
    required Map<String, ProcedureItemResponse> responses,
    required ProcedureEnforcementMode enforcementMode,
  }) {
    return _validateItems(
      items: stage.items,
      responses: responses,
      enforcementMode: enforcementMode,
    );
  }

  bool isItemAnswered({
    required ProcedureItem item,
    required ProcedureItemResponse? response,
  }) {
    if (response == null) return false;
    return switch (item.responseType) {
      ProcedureResponseType.instruction ||
      ProcedureResponseType.confirmation => response.completed,
      ProcedureResponseType.yesNo => _isYesNoAnswered(item, response),
      ProcedureResponseType.freeText => response.textValue.trim().isNotEmpty,
      ProcedureResponseType.number => response.numberValue != null,
      ProcedureResponseType.date => response.dateValue != null,
      ProcedureResponseType.singleChoice => response.selectedOptions.isNotEmpty,
      ProcedureResponseType.multipleChoice =>
        response.selectedOptions.isNotEmpty,
      ProcedureResponseType.imei => response.textValue.trim().isNotEmpty,
      ProcedureResponseType.photo ||
      ProcedureResponseType.signature ||
      ProcedureResponseType.location ||
      ProcedureResponseType.barcode ||
      ProcedureResponseType.document ||
      ProcedureResponseType.audio => response.evidence != null,
    };
  }

  bool canSkip(ProcedureEnforcementMode enforcementMode) {
    return enforcementMode != ProcedureEnforcementMode.required;
  }

  bool _isYesNoAnswered(ProcedureItem item, ProcedureItemResponse response) {
    final bool? value = response.boolValue;
    if (value == null) return false;
    if (value == false && item.configuration.requireTextWhenNo) {
      return response.textValue.trim().isNotEmpty;
    }
    return true;
  }

  ProcedureExecutionValidation _validateItems({
    required List<ProcedureItem> items,
    required Map<String, ProcedureItemResponse> responses,
    required ProcedureEnforcementMode enforcementMode,
  }) {
    final List<String> pending = <String>[];
    final List<ProcedureExecutionValidationIssue> issues =
        <ProcedureExecutionValidationIssue>[];
    int answered = 0;
    int required = 0;

    for (final ProcedureItem item in items) {
      final ProcedureItemResponse? response = responses[item.id];
      final bool itemAnswered = isItemAnswered(item: item, response: response);
      if (itemAnswered) answered++;
      if (!item.required) continue;

      required++;
      if (!itemAnswered) {
        pending.add(item.id);
        issues.add(
          ProcedureExecutionValidationIssue(
            itemId: item.id,
            reason:
                _isMissingNegativeText(item, response)
                    ? ProcedureExecutionValidationIssueReason
                        .missingRequiredNegativeText
                    : ProcedureExecutionValidationIssueReason
                        .missingRequiredResponse,
          ),
        );
      }
    }

    return ProcedureExecutionValidation(
      totalItems: items.length,
      answeredItems: answered,
      requiredItems: required,
      pendingRequiredItems: pending.length,
      pendingItemIds: pending,
      validationIssues: issues,
      canSkip: canSkip(enforcementMode),
    );
  }

  bool _isMissingNegativeText(
    ProcedureItem item,
    ProcedureItemResponse? response,
  ) {
    return item.responseType == ProcedureResponseType.yesNo &&
        item.configuration.requireTextWhenNo &&
        response?.boolValue == false &&
        (response?.textValue.trim().isEmpty ?? true);
  }
}
