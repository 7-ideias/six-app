import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';

class OperationalProcedureCard extends StatelessWidget {
  const OperationalProcedureCard({
    super.key,
    required this.procedure,
    required this.onTap,
  });

  final OperationalProcedure procedure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String status = statusLabel(context, procedure.status);
    final String operationType = operationTypeLabel(
      context,
      procedure.operationType,
    );
    final String moment = momentLabel(context, procedure.moment);
    final String requiredLabel = requiredStateLabel(
      context,
      procedure.required,
    );
    final String structureLabel = structureSummaryLabel(context, procedure);

    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      onTap: onTap,
      label:
          '${procedure.name}, $status, $operationType, $moment, '
          '$structureLabel, $requiredLabel',
      child: Material(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SixMobilePalette.border),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.navigationShadow,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        procedure.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 16,
                          height: 1.18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(status: procedure.status, label: status),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  procedure.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _MetaLine(
                  icon: Icons.storefront_outlined,
                  text: '$operationType • $moment',
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          _CompactMeta(
                            icon: Icons.view_list_outlined,
                            text: structureLabel,
                          ),
                          _CompactMeta(
                            icon:
                                procedure.required
                                    ? Icons.lock_outline_rounded
                                    : Icons.lock_open_outlined,
                            text: requiredLabel,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SixMobilePalette.mutedText,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String statusLabel(BuildContext context, ProcedureStatus status) {
  return switch (status) {
    ProcedureStatus.draft => context.t(
      'procedimentos.statusDraft',
      fallback: 'Rascunho',
    ),
    ProcedureStatus.active => context.t('common.active', fallback: 'Ativo'),
    ProcedureStatus.inactive => context.t(
      'common.inactive',
      fallback: 'Inativo',
    ),
  };
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
  };
}

String momentLabel(BuildContext context, ProcedureMoment moment) {
  return switch (moment) {
    ProcedureMoment.beforeStart => context.t(
      'procedimentos.momentBeforeStart',
      fallback: 'Antes de iniciar',
    ),
    ProcedureMoment.beforeFinish => context.t(
      'procedimentos.momentBeforeFinish',
      fallback: 'Antes de finalizar',
    ),
    ProcedureMoment.beforeDelivery => context.t(
      'procedimentos.momentBeforeDelivery',
      fallback: 'Antes da entrega',
    ),
  };
}

String requiredStateLabel(BuildContext context, bool required) {
  return required
      ? context.t('common.required', fallback: 'Obrigatório')
      : context.t('common.optional', fallback: 'Opcional');
}

String structureSummaryLabel(
  BuildContext context,
  OperationalProcedure procedure,
) {
  final String stageLabel =
      procedure.numberOfStages == 1
          ? context.t('procedimentos.stageSingular', fallback: 'etapa')
          : context.t('procedimentos.stagePlural', fallback: 'etapas');
  final String itemLabel =
      procedure.numberOfItems == 1
          ? context.t('procedimentos.itemSingular', fallback: 'item')
          : context.t('procedimentos.itemPlural', fallback: 'itens');

  return '${procedure.numberOfStages} $stageLabel • '
      '${procedure.numberOfItems} $itemLabel';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final ProcedureStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (status) {
      ProcedureStatus.draft => Icons.edit_note_rounded,
      ProcedureStatus.active => Icons.check_circle_outline_rounded,
      ProcedureStatus.inactive => Icons.pause_circle_outline_rounded,
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 30, maxWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SixMobilePalette.highlightedBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: SixMobilePalette.accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 10.5,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: SixMobilePalette.secondary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactMeta extends StatelessWidget {
  const _CompactMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: SixMobilePalette.secondary),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 11.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
