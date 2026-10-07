import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

import '../date_selector_mobile_bottom_sheet.dart';

/// Campos exclusivos dos formulários Mobile. Não executa liquidação:
/// a confirmação financeira acontece na agenda, depois de salvar.
class AgendaPagamentoMobileFields extends StatelessWidget {
  const AgendaPagamentoMobileFields({
    super.key,
    required this.receber,
    required this.previsao,
    required this.registrarPagamento,
    required this.dataEfetiva,
    required this.onPrevisaoChanged,
    required this.onRegistrarChanged,
    required this.onDataEfetivaChanged,
    this.enabled = true,
    this.permitirLiquidacao = true,
    this.recorrente = false,
    this.liquidacaoPersistida,
  });

  final bool receber;
  final DateTime? previsao;
  final bool registrarPagamento;
  final DateTime dataEfetiva;
  final ValueChanged<DateTime?> onPrevisaoChanged;
  final ValueChanged<bool> onRegistrarChanged;
  final ValueChanged<DateTime> onDataEfetivaChanged;
  final bool enabled;
  final bool permitirLiquidacao;
  final bool recorrente;
  final DateTime? liquidacaoPersistida;

  Future<void> _selecionar(
    BuildContext context, {
    required String title,
    required DateTime initial,
    required ValueChanged<DateTime> onChanged,
    bool efetiva = false,
  }) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DateSelectorMobileBottomSheet(
            title: title,
            initialDate: initial,
            firstDate: DateTime(2020),
            lastDate: efetiva ? now : DateTime(2100),
            applyButtonLabel: context.t('common.apply'),
          ),
    );
    if (selected != null && context.mounted) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    final regional = context.watch<LocaleSettingsProvider>();
    final forecastLabel = context.t(
      receber ? 'agenda.form.forecastReceive' : 'agenda.form.forecastPay',
    );
    Widget dateField(String key, String label, String value, VoidCallback tap) {
      return Material(
        color: colors.softSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        child: ListTile(
          key: ValueKey(key),
          enabled: enabled,
          onTap: enabled ? tap : null,
          leading: Icon(Icons.event_outlined, color: colors.accent),
          title: Text(label, style: TextStyle(color: colors.mutedText)),
          subtitle: Text(value, style: TextStyle(color: colors.titleText)),
          trailing: Icon(Icons.expand_more, color: colors.mutedText),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        dateField(
          'agenda-previsao',
          forecastLabel,
          previsao == null
              ? context.t('agenda.form.notSet')
              : regional.formatDate(previsao!),
          () => _selecionar(
            context,
            title: forecastLabel,
            initial: previsao ?? DateTime.now(),
            onChanged: onPrevisaoChanged,
          ),
        ),
        if (previsao != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              key: const ValueKey('agenda-limpar-previsao'),
              onPressed: enabled ? () => onPrevisaoChanged(null) : null,
              style: OutlinedButton.styleFrom(foregroundColor: colors.accent),
              icon: const Icon(Icons.clear),
              label: Text(context.t('agenda.form.clearForecast')),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          context.t('agenda.form.forecastHint'),
          style: TextStyle(color: colors.mutedText),
        ),
        if (recorrente && previsao != null)
          Text(
            context.t('agenda.form.forecastRecurrenceHint'),
            style: TextStyle(color: colors.mutedText),
          ),
        if (liquidacaoPersistida != null) ...[
          const SizedBox(height: 12),
          Text(
            '${context.t('agenda.form.actualDate')}: ${regional.formatDate(liquidacaoPersistida!)}',
            key: const ValueKey('agenda-liquidacao-persistida'),
            style: TextStyle(color: colors.titleText),
          ),
        ],
        if (permitirLiquidacao) ...[
          CheckboxListTile(
            key: const ValueKey('agenda-registrar-pagamento'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: colors.accent,
            checkColor: colors.onAccent,
            value: registrarPagamento,
            title: Text(
              context.t(
                receber
                    ? 'agenda.form.alreadyReceived'
                    : 'agenda.form.alreadyPaid',
              ),
            ),
            subtitle: Text(context.t('agenda.form.settleAfterSave')),
            onChanged:
                enabled ? (value) => onRegistrarChanged(value ?? false) : null,
          ),
          if (registrarPagamento)
            dateField(
              'agenda-data-efetiva',
              context.t('agenda.form.actualDate'),
              regional.formatDate(dataEfetiva),
              () => _selecionar(
                context,
                title: context.t('agenda.form.actualDate'),
                initial: dataEfetiva,
                efetiva: true,
                onChanged: onDataEfetivaChanged,
              ),
            ),
        ],
      ],
    );
  }
}
