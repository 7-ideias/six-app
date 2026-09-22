import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/agenda_financeira_recorrencia.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

import 'agenda_recorrencia_labels.dart';

/// Composição exclusiva Web; somente o estado de domínio é compartilhado.
class AgendaRecorrenciaWebFields extends StatelessWidget {
  const AgendaRecorrenciaWebFields({
    super.key,
    required this.config,
    required this.vencimento,
    required this.onChanged,
    this.enabled = true,
  });
  final AgendaFinanceiraRecorrencia config;
  final DateTime vencimento;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    Widget select(
      String title,
      List<String> values,
      String current,
      ValueChanged<String> apply,
    ) => PopupMenuButton<String>(
      enabled: enabled,
      tooltip: recorrenciaLabel(context, title),
      initialValue: current,
      color: tokens.menuBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        apply(value);
        onChanged();
      },
      itemBuilder:
          (_) =>
              values
                  .map(
                    (code) => PopupMenuItem(
                      value: code,
                      child: Row(
                        children: [
                          Icon(
                            code == current
                                ? Icons.check_circle_outline
                                : Icons.circle_outlined,
                            size: 18,
                            color: tokens.info,
                          ),
                          const SizedBox(width: 10),
                          Text(recorrenciaLabel(context, code)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${recorrenciaLabel(context, title)}: ${recorrenciaLabel(context, current)}',
                style: TextStyle(color: tokens.primaryText),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recorrenciaLabel(context, 'title'),
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recorrenciaLabel(context, 'hint'),
            style: TextStyle(color: tokens.secondaryText),
          ),
          if (config.serieId != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: select(
                'scope',
                ['ESTE', 'ESTE_E_PROXIMOS'],
                config.escopo,
                (v) => config.escopo = v,
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(recorrenciaLabel(context, 'repeat')),
            value: config.ativa,
            onChanged:
                enabled && config.permiteConfigurar
                    ? (value) {
                      config.ativa = value;
                      onChanged();
                    }
                    : null,
          ),
          if (!config.permiteConfigurar)
            Text(recorrenciaLabel(context, 'singleHint')),
          if (config.ativa && config.permiteConfigurar)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                select(
                  'frequency',
                  AgendaFinanceiraRecorrencia.frequencias,
                  config.frequencia,
                  (v) => config.frequencia = v,
                ),
                select(
                  'end',
                  ['SEM_FIM', 'DATA', 'QUANTIDADE'],
                  config.termino,
                  (v) => config.termino = v,
                ),
                if (config.termino == 'QUANTIDADE')
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      initialValue: config.quantidade.toString(),
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: recorrenciaLabel(context, 'count'),
                      ),
                      onChanged:
                          (v) => config.quantidade = int.tryParse(v) ?? 0,
                      validator:
                          (_) =>
                              config.quantidade < 1 || config.quantidade > 10000
                                  ? recorrenciaLabel(context, 'quantityError')
                                  : null,
                    ),
                  ),
                if (config.termino == 'DATA')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      config.fim == null
                          ? recorrenciaLabel(context, 'selectDate')
                          : context.read<LocaleSettingsProvider>().formatDate(
                            config.fim!,
                          ),
                    ),
                    onPressed:
                        !enabled
                            ? null
                            : () async {
                              final first = DateTime(
                                vencimento.year,
                                vencimento.month,
                                vencimento.day,
                              );
                              final selected =
                                  config.fim == null ||
                                          config.fim!.isBefore(first)
                                      ? first
                                      : config.fim!;
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selected,
                                firstDate: first,
                                lastDate: DateTime(2200),
                              );
                              if (date != null && context.mounted) {
                                config.fim = date;
                                onChanged();
                              }
                            },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
