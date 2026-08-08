import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_metadata.dart';

class OperationalProcedureTriggerCard extends StatelessWidget {
  const OperationalProcedureTriggerCard({
    super.key,
    required this.trigger,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onEnabledChanged,
  });

  final ProcedureTrigger trigger;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final String operation = operationTypeLabel(context, trigger.operationType);
    final String moment = triggerMomentLabel(context, trigger.triggerMoment);
    final String activation = activationModeLabel(
      context,
      trigger.activationMode,
    );
    final String enforcement = enforcementModeLabel(
      context,
      trigger.enforcementMode,
    );
    final String status = triggerStatusLabel(context, trigger.enabled);

    return Semantics(
      container: true,
      button: true,
      label: triggerSemanticsLabel(context, trigger),
      child: Opacity(
        opacity: trigger.enabled ? 1 : 0.78,
        child: Material(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SixMobilePalette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        operationTypeIcon(trigger.operationType),
                        color: SixMobilePalette.secondary,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              operation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SixMobilePalette.titleText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              moment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SixMobilePalette.titleText,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '$activation • $enforcement',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SixMobilePalette.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Switch.adaptive(
                            value: trigger.enabled,
                            onChanged: onEnabledChanged,
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              color: SixMobilePalette.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined, size: 18),
                        label: Text(
                          context.t('common.edit', fallback: 'Editar'),
                        ),
                      ),
                      SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline, size: 18),
                        label: Text(
                          context.t(
                            'procedimentos.deleteTrigger',
                            fallback: 'Excluir gatilho',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
