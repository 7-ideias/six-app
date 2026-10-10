import 'package:flutter/widgets.dart';
import 'package:sixpos/l10n/six_i18n.dart';

/// Códigos internos permanecem estáveis; textos seguem o mesmo catálogo Web.
abstract final class AgendaFinanceiraStatusLabels {
  static const opcoesEditaveis = ['Previsto', 'Pendente'];

  static String rotulo(BuildContext context, String status) {
    final chave = switch (status.trim().toUpperCase()) {
      'PENDENTE' || 'ABERTA' || 'ABERTO' => 'open',
      'PREVISTO' => 'planned',
      'PARCIAL' => 'partial',
      'PAGO' => 'paid',
      'RECEBIDO' => 'received',
      'CANCELADO' || 'CANCELADA' => 'cancelled',
      _ => null,
    };
    return chave == null
        ? status
        : context.t('agenda.form.$chave', fallback: status);
  }

  static String codigoDaEscolha(BuildContext context, String rotulo) {
    for (final codigo in opcoesEditaveis) {
      if (rotulo == AgendaFinanceiraStatusLabels.rotulo(context, codigo)) {
        return codigo;
      }
    }
    return rotulo;
  }
}
