import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/agenda_financeira_recorrencia.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

import '../agenda_recorrencia_labels.dart';
import '../date_selector_mobile_bottom_sheet.dart';

/// Bloco Mobile de repetição, usado somente nos formulários Mobile.
class AgendaRecorrenciaMobileFields extends StatelessWidget {
  const AgendaRecorrenciaMobileFields({
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

  Future<void> _selecionar(
    BuildContext context,
    String title,
    List<String> values,
    String current,
    ValueChanged<String> apply,
  ) async {
    final colors = context.sixMobileColors;
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    recorrenciaLabel(context, title),
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...values.map(
                    (code) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color:
                            code == current
                                ? colors.softAccentSurface
                                : colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(sheetContext, code),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    recorrenciaLabel(context, code),
                                    style: TextStyle(color: colors.titleText),
                                  ),
                                ),
                                if (code == current)
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: colors.accent,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    if (selected != null && context.mounted) {
      apply(selected);
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    Widget select(
      String title,
      List<String> values,
      String current,
      ValueChanged<String> apply,
    ) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.titleText,
          backgroundColor: colors.softSurface,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.all(14),
        ),
        onPressed:
            enabled
                ? () => _selecionar(context, title, values, current, apply)
                : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${recorrenciaLabel(context, title)}: ${recorrenciaLabel(context, current)}',
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            recorrenciaLabel(context, 'title'),
            style: TextStyle(
              color: colors.titleText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recorrenciaLabel(context, 'hint'),
            style: TextStyle(color: colors.mutedText),
          ),
          if (config.serieId != null)
            select(
              'scope',
              ['ESTE', 'ESTE_E_PROXIMOS'],
              config.escopo,
              (v) => config.escopo = v,
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeColor: colors.accent,
            title: Text(
              recorrenciaLabel(context, 'repeat'),
              style: TextStyle(color: colors.titleText),
            ),
            value: config.ativa,
            onChanged:
                enabled && config.permiteConfigurar
                    ? (v) {
                      config.ativa = v;
                      onChanged();
                    }
                    : null,
          ),
          if (!config.permiteConfigurar)
            Text(
              recorrenciaLabel(context, 'singleHint'),
              style: TextStyle(color: colors.mutedText),
            ),
          if (config.ativa && config.permiteConfigurar) ...[
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
              TextFormField(
                initialValue: config.quantidade.toString(),
                enabled: enabled,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.titleText),
                decoration: InputDecoration(
                  labelText: recorrenciaLabel(context, 'count'),
                  filled: true,
                  fillColor: colors.softSurface,
                ),
                onChanged: (v) => config.quantidade = int.tryParse(v) ?? 0,
                validator:
                    (_) =>
                        config.quantidade < 1 || config.quantidade > 10000
                            ? recorrenciaLabel(context, 'quantityError')
                            : null,
              ),
            if (config.termino == 'DATA')
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month_outlined),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accent,
                  backgroundColor: colors.softAccentSurface,
                ),
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
                          final date = await showModalBottomSheet<DateTime>(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder:
                                (_) => DateSelectorMobileBottomSheet(
                                  title: recorrenciaLabel(context, 'until'),
                                  initialDate: config.fim ?? vencimento,
                                  firstDate: DateTime(
                                    vencimento.year,
                                    vencimento.month,
                                    vencimento.day,
                                  ),
                                  lastDate: DateTime(2200),
                                ),
                          );
                          if (date != null && context.mounted) {
                            config.fim = date;
                            onChanged();
                          }
                        },
              ),
          ],
        ],
      ),
    );
  }
}
