import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_demo_badge.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';

class OperationalProcedureExecutionSummary extends StatelessWidget {
  const OperationalProcedureExecutionSummary({
    super.key,
    required this.completed,
    required this.total,
    required this.optionalPending,
    required this.onReview,
    required this.onClose,
    this.title,
    this.message,
    this.closeLabel,
    this.badgeLabel,
  });

  final int completed;
  final int total;
  final int optionalPending;
  final VoidCallback onReview;
  final VoidCallback onClose;
  final String? title;
  final String? message;
  final String? closeLabel;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final String resolvedTitle =
        title ??
        context.t(
          'procedimentos.previewSummaryTitle',
          fallback: 'Demonstração concluída',
        );
    return Semantics(
      container: true,
      label: resolvedTitle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
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
            OperationalProcedureDemoBadge(
              label:
                  badgeLabel ??
                  context.t(
                    'procedimentos.demoData',
                    fallback: 'Dados demonstrativos',
                  ),
            ),
            const SizedBox(height: 14),
            Text(
              resolvedTitle,
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  context.t(
                    'procedimentos.previewSummarySavedMessage',
                    fallback: 'Nenhuma resposta foi salva.',
                  ),
              style: const TextStyle(
                color: SixMobilePalette.mutedText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              OperationalProcedureI18n.answeredActionsSummary(
                context,
                completed,
                total,
              ),
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              OperationalProcedureI18n.optionalPendingSummary(
                context,
                optionalPending,
              ),
              style: const TextStyle(color: SixMobilePalette.mutedText),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReview,
                    child: Text(
                      context.t(
                        'procedimentos.previewReviewStages',
                        fallback: 'Revisar etapas',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onClose,
                    child: Text(
                      closeLabel ??
                          context.t(
                            'procedimentos.previewFinishDemo',
                            fallback: 'Encerrar preview',
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
