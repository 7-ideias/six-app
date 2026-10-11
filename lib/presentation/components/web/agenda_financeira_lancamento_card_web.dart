import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/agenda_financeira_resumo_visual.dart';
import 'package:sixpos/data/models/competencia_financeira.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

/// Card compacto exclusivo da Agenda Financeira Web.
/// Acoes sao derivadas das permissoes retornadas no lancamento, nao do visual.
class AgendaFinanceiraLancamentoCardWeb extends StatelessWidget {
  static const double _ctaWidth = 152;
  static const double _ctaHeight = 48;
  static final OutlinedBorder _ctaShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  const AgendaFinanceiraLancamentoCardWeb({
    super.key,
    required this.item,
    required this.formatarMoeda,
    required this.onDetalhes,
    required this.onEditar,
    required this.onLiquidar,
    required this.onRegistrarParcial,
    required this.onCancelar,
    required this.onComprovante,
    this.bloqueado = false,
  });

  final Map<String, dynamic> item;
  final String Function(double) formatarMoeda;
  final VoidCallback onDetalhes;
  final VoidCallback onEditar;
  final VoidCallback onLiquidar;
  final VoidCallback onRegistrarParcial;
  final VoidCallback onCancelar;
  final VoidCallback onComprovante;
  final bool bloqueado;

  static double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    final texto = valor?.toString().trim() ?? '';
    final normalizado = texto.contains(',') && texto.contains('.')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto.replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
  }

  static String _texto(dynamic valor) => valor?.toString().trim() ?? '';

  static bool _finalizado(String status) =>
      const {'recebido', 'pago', 'cancelado', 'cancelada'}
          .contains(status.toLowerCase());

  static bool _ehVenda(Map<String, dynamic> item) {
    final origem = _texto(item['origem']).toUpperCase();
    return const {'VENDA', 'VENDA_NAO_LIQUIDADA', 'RECEBIMENTO_VENDA'}
        .contains(origem);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final entrada = _texto(item['tipo']).toLowerCase() == 'receber';
    final status = _texto(item['status']);
    final parcial = status.toLowerCase() == 'parcial';
    final finalizado = _finalizado(status);
    final original = _numero(item['valorOriginal'] ?? item['valor']);
    final restante = _numero(item['valorRestante'] ?? original);
    final confirmado = _numero(item['valorConfirmado']);
    final valorPrincipal = !finalizado && restante > 0 ? restante : original;
    final naturezaCor =
        entrada ? tokens.financialPositive : tokens.financialNegative;
    final acoes = ((item['acoes'] as List?) ?? const <dynamic>[])
        .map((e) => e.toString().toLowerCase())
        .toSet();
    final podeLiquidar = !finalizado && restante > 0 &&
        acoes.any((a) => const {'liquidar', 'receber', 'pagar'}.contains(a));
    final podeEditar = !finalizado && !parcial && acoes.contains('editar');
    final podeParcial = podeLiquidar && acoes.contains('registrar parcial');
    final podeCancelar = !finalizado && acoes.contains('cancelar');
    final podeComprovante = _ehVenda(item) &&
        const {'recebido', 'pago'}.contains(status.toLowerCase());

    final corStatus = switch (status.toLowerCase()) {
      'recebido' || 'pago' => tokens.success,
      'vencido' => tokens.danger,
      'parcial' || 'vence hoje' => tokens.warning,
      'previsto' || 'pendente' => tokens.info,
      _ => tokens.statusNeutral,
    };
    final iconeStatus = switch (status.toLowerCase()) {
      'recebido' || 'pago' => Icons.check_circle_outline_rounded,
      'vencido' => Icons.schedule_outlined,
      'parcial' => Icons.pie_chart_outline_rounded,
      'previsto' => Icons.event_outlined,
      'cancelado' => Icons.block_outlined,
      _ => Icons.schedule_outlined,
    };

    final contato = AgendaFinanceiraResumoVisual.contatoInformado(item['contato']);
    final codigo = _texto(item['codigoOperacao']);
    final vencimento = _texto(item['vencimento']);
    final competencia = CompetenciaFinanceira.formatarValor(item['dataCompetencia']);
    final metadados = <String>[
      if (vencimento.isNotEmpty && vencimento != '-')
        'Vencimento: $vencimento',
      if (competencia != '-') 'Competência: $competencia',
    ];
    final informacoes = <String>[
      if (codigo.isNotEmpty && codigo != 'null') '#$codigo',
      if (contato != null) contato,
    ];

    final iconBox = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            naturezaCor.withValues(alpha: .12), tokens.cardBackground),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        entrada ? Icons.south_west_rounded : Icons.north_east_rounded,
        color: naturezaCor, size: 26,
      ),
    );
    final identificacao = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _texto(item['descricao']).isEmpty
              ? 'Lançamento financeiro' : _texto(item['descricao']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: tokens.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (informacoes.isNotEmpty)
          Text(
            informacoes.join('  ·  '),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
          ),
        if (metadados.isNotEmpty)
          Text(
            metadados.join('  ·  '),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
          ),
        if (item['recorrente'] == true || item['ocorrenciaAjustada'] == true)
          Text(
            [
              if (item['recorrente'] == true) 'Recorrente',
              if (item['ocorrenciaAjustada'] == true) 'Ajustado',
            ].join('  ·  '),
            style: theme.textTheme.labelSmall?.copyWith(color: tokens.mutedText),
          ),
      ],
    );
    final indicador = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          corStatus.withValues(alpha: .11), tokens.cardBackground),
        border: Border.all(color: corStatus.withValues(alpha: .23)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(iconeStatus, size: 16, color: corStatus),
        const SizedBox(width: 5),
        Text(
          status.isEmpty ? 'Pendente' : status,
          style: theme.textTheme.labelMedium?.copyWith(
            color: corStatus, fontWeight: FontWeight.w800),
        ),
      ]),
    );
    final valores = SizedBox(
      width: 174,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatarMoeda(valorPrincipal),
            maxLines: 1,
            style: theme.textTheme.titleMedium?.copyWith(
              color: naturezaCor, fontWeight: FontWeight.w900),
          ),
          Text(
            'Original: ${formatarMoeda(original)}',
            maxLines: 1,
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
          ),
          if (parcial && original > 0) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (confirmado / original).clamp(0.0, 1.0),
                minHeight: 3,
                color: tokens.warning,
                backgroundColor: tokens.divider,
              ),
            ),
          ],
        ],
      ),
    );

    final botoes = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (podeEditar)
          OutlinedButton.icon(
            key: const Key('agenda-card-editar'),
            onPressed: bloqueado ? null : onEditar,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Editar'),
          ),
        if (podeLiquidar)
          SizedBox(
            width: _ctaWidth,
            height: _ctaHeight,
            child: FilledButton.icon(
              key: const Key('agenda-card-liquidar'),
              onPressed: bloqueado ? null : onLiquidar,
              icon: const Icon(Icons.check_rounded, size: 18),
              // O status Parcial e o saldo em destaque ja informam o
              // restante. Mantemos o CTA curto para alinhar com os demais.
              label: Text(
                entrada ? 'Receber' : 'Pagar',
                maxLines: 1,
                softWrap: false,
              ),
              style: FilledButton.styleFrom(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: _ctaShape,
                backgroundColor: naturezaCor,
                foregroundColor: theme.colorScheme.surface,
              ),
            ),
          ),
        if (podeComprovante)
          SizedBox(
            width: _ctaWidth,
            height: _ctaHeight,
            child: OutlinedButton.icon(
              key: const Key('agenda-card-comprovante'),
              onPressed: bloqueado ? null : onComprovante,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Comprovante', maxLines: 1),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: _ctaShape,
              ),
            ),
          ),
        PopupMenuButton<String>(
          key: const Key('agenda-card-menu'),
          tooltip: 'Mais ações',
          enabled: !bloqueado,
          icon: const Icon(Icons.more_vert_rounded),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'detalhes', child: Text('Detalhes')),
            if (podeParcial)
              const PopupMenuItem(value: 'parcial', child: Text('Registrar parcial')),
            if (podeCancelar)
              const PopupMenuItem(value: 'cancelar', child: Text('Cancelar ocorrência')),
          ],
          onSelected: (acao) {
            if (acao == 'parcial') {
              onRegistrarParcial();
            } else if (acao == 'cancelar') {
              onCancelar();
            } else {
              onDetalhes();
            }
          },
        ),
      ],
    );

    return Card(
      key: ValueKey('agenda-card-${item['id'] ?? ''}'),
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: InkWell(
        onTap: bloqueado ? null : onDetalhes,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: LayoutBuilder(builder: (context, constraints) {
            final umaLinha = constraints.maxWidth >= 1040;
            final faixa = Row(children: [
              iconBox,
              const SizedBox(width: 12),
              Expanded(child: identificacao),
              const SizedBox(width: 14),
              indicador,
              const SizedBox(width: 20),
              valores,
            ]);
            if (umaLinha) {
              return Row(children: [
                Expanded(child: faixa),
                const SizedBox(width: 12),
                botoes,
              ]);
            }
            if (constraints.maxWidth < 690) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    iconBox,
                    const SizedBox(width: 12),
                    Expanded(child: identificacao),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    indicador,
                    const Spacer(),
                    valores,
                  ]),
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: botoes),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                faixa,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: botoes),
              ],
            );
          }),
        ),
      ),
    );
  }
}
