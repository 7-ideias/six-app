import 'package:flutter/material.dart';
import 'package:sixpos/data/models/agenda_financeira_recorrencia.dart';

/// Resultado do preview. Um cancelamento retorna também o motivo informado.
class AgendaRecorrenciaConfirmacao {
  const AgendaRecorrenciaConfirmacao(this.escopo, this.motivo);
  final String escopo;
  final String motivo;
}

/// Confirmação compartilhada no domínio, com apresentação própria por plataforma:
/// bottom sheet no Mobile e diálogo compacto na Web.
Future<AgendaRecorrenciaConfirmacao?> confirmarImpactoRecorrencia(
  BuildContext context, {
  required bool mobile,
  required AgendaFinanceiraRecorrencia recorrencia,
  required String descricao,
  required String valorFormatado,
  required String vencimentoFormatado,
  required bool cancelar,
  bool permitirTrocarEscopo = false,
}) async {
  final motivoController = TextEditingController();
  String escopo = recorrencia.escopo;
  final int numero = recorrencia.numeroOcorrencia;
  final int? total = recorrencia.totalOcorrencias;
  final bool temTotal = total != null && total >= numero;

  Widget conteudo(BuildContext popupContext) {
    return StatefulBuilder(
      builder: (BuildContext localContext, StateSetter setLocalState) {
        final tema = Theme.of(localContext);
        final cores = tema.colorScheme;
        final isSerie = escopo == 'ESTE_E_PROXIMOS';
        final alcance = isSerie
            ? (temTotal ? '${total - numero + 1} ocorrências' : 'esta e as seguintes')
            : 'somente a ${numero}ª ocorrência';
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 490),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, mobile ? 24 : 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(cancelar ? Icons.event_busy_outlined : Icons.edit_calendar_outlined,
                        color: cancelar ? cores.error : cores.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(cancelar ? 'Cancelar recorrência' : 'Confirmar alteração',
                        style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cores.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(descricao, style: tema.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(valorFormatado, style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Vencimento: $vencimentoFormatado',
                          style: tema.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('Ocorrência $numero${temTotal ? ' de $total' : ''}',
                          style: tema.textTheme.bodySmall?.copyWith(color: cores.primary)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text('Quais lançamentos serão afetados?',
                      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (permitirTrocarEscopo)
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      ChoiceChip(
                        label: const Text('Somente este'),
                        selected: !isSerie,
                        onSelected: (_) => setLocalState(() => escopo = 'ESTE'),
                      ),
                      ChoiceChip(
                        label: const Text('Este e os próximos'),
                        selected: isSerie,
                        onSelected: (_) => setLocalState(() => escopo = 'ESTE_E_PROXIMOS'),
                      ),
                    ])
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: cores.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(isSerie ? 'Este e os próximos' : 'Somente este lançamento'),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    cancelar
                        ? 'Serão cancelados $alcance. O histórico será preservado e valores cancelados deixarão o fluxo previsto.'
                        : 'A alteração será aplicada a $alcance. Lançamentos anteriores permanecem intactos.',
                    style: tema.textTheme.bodyMedium,
                  ),
                  if (isSerie) ...[
                    const SizedBox(height: 10),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, size: 18, color: cores.tertiary),
                      const SizedBox(width: 8),
                      const Expanded(child: Text(
                        'A série será redefinida a partir desta ocorrência. Pagamentos registrados são protegidos.',
                      )),
                    ]),
                  ],
                  if (cancelar) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: motivoController,
                      maxLines: 2,
                      maxLength: 255,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (opcional)',
                        hintText: 'Por que este vencimento foi cancelado?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.of(popupContext).pop(),
                      child: const Text('Voltar'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: FilledButton(
                      style: cancelar
                          ? FilledButton.styleFrom(backgroundColor: cores.error, foregroundColor: cores.onError)
                          : null,
                      onPressed: () => Navigator.of(popupContext).pop(
                          AgendaRecorrenciaConfirmacao(escopo, motivoController.text.trim())),
                      child: Text(cancelar ? 'Cancelar lançamento' : 'Confirmar alterações'),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  try {
    if (mobile) {
      return await showModalBottomSheet<AgendaRecorrenciaConfirmacao>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: conteudo(ctx),
        ),
      );
    }
    return await showDialog<AgendaRecorrenciaConfirmacao>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: conteudo(ctx),
      ),
    );
  } finally {
    motivoController.dispose();
  }
}
