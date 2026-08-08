import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_metadata.dart';

class OperationalProcedureTriggerSummary extends StatelessWidget {
  const OperationalProcedureTriggerSummary({
    super.key,
    required this.triggers,
    this.compact = false,
  });

  final List<ProcedureTrigger> triggers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String text = triggerSummaryLabel(context, triggers);
    return Semantics(
      container: true,
      label: text,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.route_outlined,
            color: SixMobilePalette.secondary,
            size: 18,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: compact ? 1 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    compact
                        ? SixMobilePalette.mutedText
                        : SixMobilePalette.titleText,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String triggerSummaryLabel(
  BuildContext context,
  List<ProcedureTrigger> triggers,
) {
  final List<ProcedureTrigger> activeTriggers =
      triggers.where((ProcedureTrigger trigger) => trigger.enabled).toList();
  if (triggers.isEmpty) {
    return context.t(
      'procedimentos.triggerSummaryNone',
      fallback: 'Sem gatilhos configurados',
    );
  }
  if (activeTriggers.isEmpty) {
    return context.t(
      'procedimentos.triggerSummaryOnlyInactive',
      fallback: 'Gatilhos inativos',
    );
  }
  final ProcedureTrigger first = activeTriggers.first;
  final String firstLabel = OperationalProcedureI18n.triggerSummarySingle(
    context,
    operation: operationTypeLabel(context, first.operationType),
    moment: triggerMomentLabel(context, first.triggerMoment),
  );
  final int remaining = activeTriggers.length - 1;
  if (remaining <= 0) return firstLabel;
  return OperationalProcedureI18n.triggerSummaryMultiple(
    context,
    first: firstLabel,
    remaining: remaining,
  );
}
