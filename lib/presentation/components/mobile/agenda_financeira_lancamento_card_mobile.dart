import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/data/models/agenda_financeira_calendario_resumo.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/presentation/components/agenda_financeira_resumo_visual.dart';

/// Mesmo card nas abas Agenda e Calendário: cores, valor e navegação coerentes.
class AgendaFinanceiraLancamentoCardMobile extends StatelessWidget {
  const AgendaFinanceiraLancamentoCardMobile({
    super.key,
    required this.item,
    required this.formatarMoeda,
    required this.onTap,
    this.rotuloRecorrente = 'Recorrente',
    this.mostrarVencimento = true,
    this.mostrarRotuloValor = false,
  });

  final Map<String, dynamic> item;
  final String Function(double) formatarMoeda;
  final VoidCallback? onTap;
  final String rotuloRecorrente;
  final bool mostrarVencimento;
  final bool mostrarRotuloValor;

  static Color corNatureza(BuildContext context, bool entrada) {
    final cores = context.sixMobileColors;
    if (!entrada) return cores.error;
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF34D399)
        : const Color(0xFF047857);
  }

  static Color corStatus(BuildContext context, String status) {
    final cores = context.sixMobileColors;
    switch (status.trim().toLowerCase()) {
      case 'recebido':
      case 'pago':
        return corNatureza(context, true);
      case 'vencido':
        return cores.error;
      case 'parcial':
      case 'vence hoje':
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFB45309);
      case 'pendente':
      case 'previsto':
        return cores.accent;
      default:
        return cores.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.sixMobileColors;
    final entrada = item['tipo']?.toString().toLowerCase() == 'receber';
    final cor = corNatureza(context, entrada);
    final titulo = item['descricao']?.toString().trim() ?? '';
    final status = item['status']?.toString().trim() ?? '';
    final contato = AgendaFinanceiraResumoVisual.contatoInformado(item['contato']);
    final vencimento = item['vencimento']?.toString().trim() ?? '';
    final meta = <InlineSpan>[
      if (item['recorrente'] == true) TextSpan(text: '$rotuloRecorrente • '),
      if (contato != null) TextSpan(text: '$contato • '),
      TextSpan(
        text: status.isEmpty ? 'Pendente' : status,
        style: TextStyle(
          color: corStatus(context, status), fontWeight: FontWeight.w700,
        ),
      ),
      if (mostrarVencimento && vencimento.isNotEmpty && vencimento != '-')
        TextSpan(text: ' • vence $vencimento'),
    ];
    final valor = AgendaFinanceiraCalendarioResumo.valorPrincipal(item);
    final valorRotulo = AgendaFinanceiraCalendarioResumo.aberto(item) > 0
        ? context.t('agenda.calendar.outstanding')
        : context.t(entrada ? 'agenda.calendar.received' : 'agenda.calendar.paid');

    return Semantics(
      button: true,
      label: 'Abrir lançamento ${titulo.isEmpty ? 'financeiro' : titulo}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cores.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cores.border),
              boxShadow: [
                BoxShadow(
                  color: cores.navigationShadow.withValues(alpha: 0.58),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    entrada ? Icons.south_west_rounded : Icons.north_east_rounded,
                    color: cor, size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo.isEmpty ? 'Lançamento financeiro' : titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cores.titleText, fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(children: meta),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cores.mutedText, fontSize: 11.5, height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatarMoeda(valor),
                      style: TextStyle(
                        color: cor, fontSize: 12, fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (mostrarRotuloValor)
                      Text(
                        valorRotulo,
                        style: TextStyle(color: cores.mutedText, fontSize: 10),
                      ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cores.mutedText, size: 20,
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
