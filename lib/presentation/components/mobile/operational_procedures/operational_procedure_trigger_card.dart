import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        operationTypeIcon(trigger.operationType),
                        color:
                            isDark
                                ? colors.accent
                                : SixMobilePalette.secondaryLight,
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
                                color: colors.titleText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              moment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.titleText,
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
                                color: colors.mutedText,
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
                              color: colors.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _InlineTriggerActionButton(
                        onPressed: onEdit,
                        icon: Icons.edit_outlined,
                        label: context.t('common.edit', fallback: 'Editar'),
                        foregroundColor: colors.accent,
                        backgroundColor: colors.softAccentSurface,
                        borderColor: colors.accent.withValues(alpha: 0.26),
                      ),
                      _InlineTriggerActionButton(
                        onPressed: onDelete,
                        icon: Icons.delete_outline,
                        label: context.t(
                          'procedimentos.deleteTrigger',
                          fallback: 'Excluir gatilho',
                        ),
                        foregroundColor: colors.error,
                        backgroundColor: colors.surfaceElevated,
                        borderColor: colors.error.withValues(alpha: 0.24),
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

class _InlineTriggerActionButton extends StatelessWidget {
  const _InlineTriggerActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: BorderSide(color: borderColor),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
