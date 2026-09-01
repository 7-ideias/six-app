import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';

const Map<ProcedureOperationType, List<ProcedureTriggerMoment>>
procedureTriggerMomentOptions =
    <ProcedureOperationType, List<ProcedureTriggerMoment>>{
      ProcedureOperationType.sale: <ProcedureTriggerMoment>[
        ProcedureTriggerMoment.beforeStart,
        ProcedureTriggerMoment.afterStart,
        ProcedureTriggerMoment.beforeFinish,
        ProcedureTriggerMoment.afterFinish,
      ],
      ProcedureOperationType.quote: <ProcedureTriggerMoment>[
        ProcedureTriggerMoment.beforeStart,
        ProcedureTriggerMoment.beforeFinish,
        ProcedureTriggerMoment.afterFinish,
      ],
      ProcedureOperationType.technicalService: <ProcedureTriggerMoment>[
        ProcedureTriggerMoment.beforeStart,
        ProcedureTriggerMoment.afterStart,
        ProcedureTriggerMoment.beforeFinish,
        ProcedureTriggerMoment.afterFinish,
        ProcedureTriggerMoment.beforeDelivery,
      ],
      ProcedureOperationType.delivery: <ProcedureTriggerMoment>[
        ProcedureTriggerMoment.beforeDelivery,
        ProcedureTriggerMoment.afterDelivery,
      ],
      ProcedureOperationType.cashRegister: <ProcedureTriggerMoment>[
        ProcedureTriggerMoment.beforeStart,
        ProcedureTriggerMoment.afterStart,
        ProcedureTriggerMoment.beforeFinish,
        ProcedureTriggerMoment.afterFinish,
      ],
      ProcedureOperationType.customerRegistration: <ProcedureTriggerMoment>[
        ProcedureTriggerMoment.beforeFinish,
        ProcedureTriggerMoment.afterFinish,
      ],
    };

List<ProcedureTriggerMoment> triggerMomentsForOperation(
  ProcedureOperationType operationType,
) {
  return procedureTriggerMomentOptions[operationType] ??
      const <ProcedureTriggerMoment>[];
}

List<ProcedureOperationType> publishedMobileOperationTypes({
  ProcedureOperationType? current,
}) {
  final List<ProcedureOperationType> values =
      procedureOperationPointCatalog
          .publishedFor(ProcedurePlatform.mobile)
          .map((ProcedureOperationPoint point) => point.operationType)
          .toSet()
          .toList();
  if (current != null && !values.contains(current)) values.add(current);
  return values;
}

List<ProcedureTriggerMoment> publishedMobileMomentsForOperation(
  ProcedureOperationType operationType, {
  ProcedureTriggerMoment? current,
}) {
  final List<ProcedureTriggerMoment> values =
      procedureOperationPointCatalog
          .publishedFor(ProcedurePlatform.mobile)
          .where(
            (ProcedureOperationPoint point) =>
                point.operationType == operationType,
          )
          .map((ProcedureOperationPoint point) => point.triggerMoment)
          .toSet()
          .toList();
  if (current != null && !values.contains(current)) values.add(current);
  return values;
}

List<ProcedureMoment> publishedMobileProcedureMomentsForOperation(
  ProcedureOperationType operationType, {
  ProcedureMoment? current,
}) {
  final List<ProcedureMoment> values =
      procedureOperationPointCatalog
          .publishedFor(ProcedurePlatform.mobile)
          .where(
            (ProcedureOperationPoint point) =>
                point.operationType == operationType,
          )
          .map(
            (ProcedureOperationPoint point) =>
                procedureMomentForTriggerMoment(point.triggerMoment),
          )
          .whereType<ProcedureMoment>()
          .toSet()
          .toList();
  if (current != null && !values.contains(current)) values.add(current);
  return values;
}

bool isTriggerMomentValid(
  ProcedureOperationType operationType,
  ProcedureTriggerMoment moment,
) {
  return triggerMomentsForOperation(operationType).contains(moment);
}

bool hasDuplicateTrigger(
  List<ProcedureTrigger> triggers,
  ProcedureTrigger candidate, {
  String? ignoringId,
}) {
  return triggers.any((ProcedureTrigger trigger) {
    if (trigger.id == ignoringId) return false;
    return trigger.operationType == candidate.operationType &&
        trigger.triggerMoment == candidate.triggerMoment &&
        trigger.activationMode == candidate.activationMode;
  });
}

String operationTypeLabel(BuildContext context, ProcedureOperationType type) {
  return switch (type) {
    ProcedureOperationType.sale => context.t(
      'procedimentos.operationSale',
      fallback: 'Venda',
    ),
    ProcedureOperationType.technicalService => context.t(
      'procedimentos.operationTechnicalService',
      fallback: 'Atendimento técnico',
    ),
    ProcedureOperationType.quote => context.t(
      'procedimentos.operationQuote',
      fallback: 'Orçamento',
    ),
    ProcedureOperationType.delivery => context.t(
      'procedimentos.operationDelivery',
      fallback: 'Entrega',
    ),
    ProcedureOperationType.cashRegister => context.t(
      'procedimentos.operationCashRegister',
      fallback: 'Caixa',
    ),
    ProcedureOperationType.customerRegistration => context.t(
      'procedimentos.operationCustomerRegistration',
      fallback: 'Cadastro de cliente',
    ),
  };
}

String triggerMomentLabel(BuildContext context, ProcedureTriggerMoment moment) {
  return switch (moment) {
    ProcedureTriggerMoment.beforeStart => context.t(
      'procedimentos.triggerMomentBeforeStart',
      fallback: 'Antes de iniciar',
    ),
    ProcedureTriggerMoment.afterStart => context.t(
      'procedimentos.triggerMomentAfterStart',
      fallback: 'Após iniciar',
    ),
    ProcedureTriggerMoment.beforeFinish => context.t(
      'procedimentos.triggerMomentBeforeFinish',
      fallback: 'Antes de concluir',
    ),
    ProcedureTriggerMoment.afterFinish => context.t(
      'procedimentos.triggerMomentAfterFinish',
      fallback: 'Após concluir',
    ),
    ProcedureTriggerMoment.beforeDelivery => context.t(
      'procedimentos.triggerMomentBeforeDelivery',
      fallback: 'Antes da entrega',
    ),
    ProcedureTriggerMoment.afterDelivery => context.t(
      'procedimentos.triggerMomentAfterDelivery',
      fallback: 'Após a entrega',
    ),
    ProcedureTriggerMoment.onDemand => context.t(
      'procedimentos.triggerMomentOnDemand',
      fallback: 'Sob demanda',
    ),
  };
}

String operationPointLabel(
  BuildContext context,
  ProcedureOperationPoint point,
) {
  return switch (point) {
    ProcedureOperationPoint.saleStartBefore => context.t(
      'procedimentos.operationPointSaleStartBefore',
      fallback: 'Antes de iniciar uma venda',
    ),
    ProcedureOperationPoint.saleFinishBefore => context.t(
      'procedimentos.operationPointSaleFinishBefore',
      fallback: 'Antes de finalizar uma venda',
    ),
    ProcedureOperationPoint.technicalServiceStartBefore => context.t(
      'procedimentos.operationPointTechnicalServiceStartBefore',
      fallback: 'Antes de iniciar um atendimento técnico',
    ),
    ProcedureOperationPoint.cashRegisterStartBefore => context.t(
      'procedimentos.operationPointCashRegisterStartBefore',
      fallback: 'Antes de acessar as operações de caixa',
    ),
  };
}

String operationPointDescription(
  BuildContext context,
  ProcedureOperationPoint point,
) {
  return switch (point) {
    ProcedureOperationPoint.saleStartBefore => context.t(
      'procedimentos.operationPointSaleStartBeforeDescription',
      fallback: 'Executado antes de abrir o fluxo de uma nova venda.',
    ),
    ProcedureOperationPoint.saleFinishBefore => context.t(
      'procedimentos.operationPointSaleFinishBeforeDescription',
      fallback: 'Executado antes de concluir a venda em andamento.',
    ),
    ProcedureOperationPoint.technicalServiceStartBefore => context.t(
      'procedimentos.operationPointTechnicalServiceStartBeforeDescription',
      fallback: 'Executado antes de abrir o fluxo de atendimento técnico.',
    ),
    ProcedureOperationPoint.cashRegisterStartBefore => context.t(
      'procedimentos.operationPointCashRegisterStartBeforeDescription',
      fallback: 'Executado antes de abrir as operações de caixa.',
    ),
  };
}

String activationModeLabel(
  BuildContext context,
  ProcedureTriggerActivationMode mode,
) {
  return switch (mode) {
    ProcedureTriggerActivationMode.manual => context.t(
      'procedimentos.activationManual',
      fallback: 'Manual',
    ),
    ProcedureTriggerActivationMode.automatic => context.t(
      'procedimentos.activationAutomatic',
      fallback: 'Automático',
    ),
  };
}

String activationModeDescription(
  BuildContext context,
  ProcedureTriggerActivationMode mode,
) {
  return switch (mode) {
    ProcedureTriggerActivationMode.manual => context.t(
      'procedimentos.activationManualDescription',
      fallback:
          'O colaborador poderá iniciar este procedimento quando necessário.',
    ),
    ProcedureTriggerActivationMode.automatic => context.t(
      'procedimentos.activationAutomaticDescription',
      fallback: 'O procedimento será apresentado no momento configurado.',
    ),
  };
}

String enforcementModeLabel(
  BuildContext context,
  ProcedureEnforcementMode mode,
) {
  return switch (mode) {
    ProcedureEnforcementMode.informative => context.t(
      'procedimentos.enforcementInformative',
      fallback: 'Informativo',
    ),
    ProcedureEnforcementMode.recommended => context.t(
      'procedimentos.enforcementRecommended',
      fallback: 'Recomendado',
    ),
    ProcedureEnforcementMode.required => context.t(
      'procedimentos.enforcementRequired',
      fallback: 'Obrigatório',
    ),
  };
}

String enforcementModeDescription(
  BuildContext context,
  ProcedureEnforcementMode mode,
) {
  return switch (mode) {
    ProcedureEnforcementMode.informative => context.t(
      'procedimentos.enforcementInformativeDescription',
      fallback: 'Apresenta o procedimento sem exigir conclusão.',
    ),
    ProcedureEnforcementMode.recommended => context.t(
      'procedimentos.enforcementRecommendedDescription',
      fallback: 'Recomenda a conclusão, mas não deve bloquear a operação.',
    ),
    ProcedureEnforcementMode.required => context.t(
      'procedimentos.enforcementRequiredDescription',
      fallback: 'Exige conclusão antes de continuar.',
    ),
  };
}

IconData operationTypeIcon(ProcedureOperationType type) {
  return switch (type) {
    ProcedureOperationType.sale => Icons.point_of_sale_rounded,
    ProcedureOperationType.quote => Icons.request_quote_outlined,
    ProcedureOperationType.technicalService => Icons.build_circle_outlined,
    ProcedureOperationType.delivery => Icons.local_shipping_outlined,
    ProcedureOperationType.cashRegister => Icons.payments_outlined,
    ProcedureOperationType.customerRegistration => Icons.person_add_alt_rounded,
  };
}

IconData activationModeIcon(ProcedureTriggerActivationMode mode) {
  return switch (mode) {
    ProcedureTriggerActivationMode.manual => Icons.touch_app_outlined,
    ProcedureTriggerActivationMode.automatic => Icons.bolt_outlined,
  };
}

IconData enforcementModeIcon(ProcedureEnforcementMode mode) {
  return switch (mode) {
    ProcedureEnforcementMode.informative => Icons.info_outline_rounded,
    ProcedureEnforcementMode.recommended => Icons.flag_outlined,
    ProcedureEnforcementMode.required => Icons.lock_outline_rounded,
  };
}

String triggerStatusLabel(BuildContext context, bool enabled) {
  return enabled
      ? context.t('common.active', fallback: 'Ativo')
      : context.t('common.inactive', fallback: 'Inativo');
}

String triggerSemanticsLabel(BuildContext context, ProcedureTrigger trigger) {
  return OperationalProcedureI18n.triggerSemantics(
    context,
    operation: operationTypeLabel(context, trigger.operationType),
    moment: triggerMomentLabel(context, trigger.triggerMoment),
    activation: activationModeLabel(context, trigger.activationMode),
    enforcement: enforcementModeLabel(context, trigger.enforcementMode),
    status: triggerStatusLabel(context, trigger.enabled),
  );
}
