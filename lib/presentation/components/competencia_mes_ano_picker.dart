import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/data/models/competencia_financeira.dart';

/// Seletor de período, sem qualquer escolha de dia.
/// Web: diálogo compacto; Mobile: bottom sheet com grid responsivo.
Future<DateTime?> selecionarCompetenciaMesAno(
  BuildContext context, {
  required DateTime competencia,
  required bool mobile,
}) async {
  final inicial = CompetenciaFinanceira.normalizar(competencia);
  int ano = inicial.year.clamp(1900, 2200);
  int mes = inicial.month;

  Widget conteudo(BuildContext dialogContext) {
    return StatefulBuilder(
      builder: (context, atualizar) {
        final cores = Theme.of(context).colorScheme;
        final locale = Localizations.localeOf(context).toString();
        final mesFormatter = DateFormat.MMM(locale);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Competência · mês/ano',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Selecione somente o mês e o ano.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Ano anterior',
                      onPressed: ano > 1900 ? () => atualizar(() => ano--) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      '$ano',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Próximo ano',
                      onPressed: ano < 2200 ? () => atualizar(() => ano++) : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.4,
                  ),
                  itemBuilder: (context, i) {
                    final numeroMes = i + 1;
                    final selecionado = mes == numeroMes;
                    final nome = mesFormatter.format(DateTime(ano, numeroMes));
                    return Material(
                      color: selecionado
                          ? cores.primaryContainer
                          : cores.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () => atualizar(() => mes = numeroMes),
                        child: Center(
                          child: Text(
                            nome,
                            style: TextStyle(
                              fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
                              color: selecionado
                                  ? cores.onPrimaryContainer
                                  : cores.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Voltar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(
                          DateTime(ano, mes),
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  if (mobile) {
    return showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(child: conteudo(ctx)),
      ),
    );
  }
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => AlertDialog(
      contentPadding: const EdgeInsets.only(top: 22),
      content: conteudo(ctx),
    ),
  );
}
