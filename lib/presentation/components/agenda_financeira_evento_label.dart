import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

/// Formats server-selected event dates without changing the original due date.
String? agendaFinanceiraEventoLabel(BuildContext context, Map<String, dynamic> item) {
  final data = DateTime.tryParse(item['dataAgenda']?.toString() ?? '');
  if (data == null || item['tipoEvento'] == null) return null;
  final vencimento = DateTime.tryParse(item['dataVencimento']?.toString() ?? '');
  final realizado = item['tipoEvento'] == 'REALIZADO';
  final entrada = item['tipo']?.toString().toLowerCase() == 'receber';
  final chave = !realizado ? 'planned' : entrada ? 'received' : 'paid';
  final regional = context.read<LocaleSettingsProvider>();
  final partes = <String>[
    context.t('agenda.event.$chave').replaceAll('{date}', regional.formatDate(data)),
  ];
  if (vencimento != null && !_mesmoDia(data, vencimento)) {
    if (realizado) {
      partes.add(context.t(data.isBefore(vencimento) ? 'agenda.event.early' : 'agenda.event.late'));
    }
    partes.add(context.t('agenda.event.originalDue').replaceAll('{date}', regional.formatDate(vencimento)));
  }
  return partes.join(' · ');
}

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
