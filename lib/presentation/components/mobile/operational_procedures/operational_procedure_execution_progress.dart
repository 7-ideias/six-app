import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';

class OperationalProcedureExecutionProgress extends StatelessWidget {
  const OperationalProcedureExecutionProgress({
    super.key,
    required this.completedActions,
    required this.totalActions,
    required this.label,
  });

  final int completedActions;
  final int totalActions;
  final String label;

  @override
  Widget build(BuildContext context) {
    final double value =
        totalActions == 0 ? 0 : completedActions / totalActions;
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                OperationalProcedureI18n.formatPercent(context, value),
                style: const TextStyle(
                  color: SixMobilePalette.mutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: value.clamp(0, 1),
              backgroundColor: SixMobilePalette.softNeutralSurface,
              color: SixMobilePalette.accent,
            ),
          ),
        ],
      ),
    );
  }
}
