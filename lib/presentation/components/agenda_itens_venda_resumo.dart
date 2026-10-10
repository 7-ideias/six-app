import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';

/// Resumo de produtos e serviços do snapshot da venda, compartilhado Web/Mobile.
class AgendaItensVendaResumo extends StatelessWidget {
  const AgendaItensVendaResumo({
    super.key,
    required this.itens,
    required this.formatarMoeda,
    this.mostrarVazio = false,
  });

  final List<Map<String, dynamic>> itens;
  final String Function(double) formatarMoeda;
  final bool mostrarVazio;

  static List<Map<String, dynamic>> lerItens(Map<String, dynamic> detalhe) {
    final raw = detalhe['itensVenda'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: false);
  }

  static bool ehVenda(Map<String, dynamic> detalhe) {
    final origem = detalhe['origem'];
    final codigo = origem is Map
        ? origem['tipo']?.toString().toUpperCase() ?? ''
        : origem?.toString().toUpperCase() ?? '';
    return <String>{'VENDA', 'VENDA_NAO_LIQUIDADA', 'RECEBIMENTO_VENDA'}
        .contains(codigo);
  }

  static double numero(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty && !mostrarVazio) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.inventory_2_outlined, color: colors.primary, size: 20),
          const SizedBox(width: 9),
          Text(
            context.t('agenda.saleItems.title', fallback: 'Produtos e serviços'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text('${itens.length}', style: theme.textTheme.labelMedium),
        ]),
        const SizedBox(height: 12),
        if (itens.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              context.t('agenda.saleItems.empty',
                fallback: 'Os itens dessa venda antiga não estão disponíveis no histórico.'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        for (final item in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        item['tipo'] == 'SERVICO'
                            ? Icons.build_outlined : Icons.shopping_bag_outlined,
                        size: 18, color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['descricao']?.toString() ?? '-',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          item['tipo'] == 'SERVICO'
                              ? context.t('agenda.saleItems.service', fallback: 'Serviço')
                              : context.t('agenda.saleItems.product', fallback: 'Produto'),
                          style: theme.textTheme.bodySmall,
                        ),
                        if ((item['responsavel']?.toString() ?? '').trim().isNotEmpty)
                          Text(item['responsavel'].toString(), style: theme.textTheme.bodySmall),
                      ],
                    )),
                    const SizedBox(width: 8),
                    Text(formatarMoeda(numero(item['valorTotal'])),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 7),
                  Text(
                    '${context.t('agenda.saleItems.quantity', fallback: 'Qtd.')} ${_formatarQuantidade(numero(item['quantidade']))}'
                    '  ×  ${formatarMoeda(numero(item['valorUnitario']))}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if ((item['idSKU']?.toString() ?? '').trim().isNotEmpty)
                    Text('SKU: ${item['idSKU']}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _formatarQuantidade(double valor) =>
      valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toString();
}
