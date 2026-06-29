import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/estoque_dashboard_model.dart';

class EstoqueDashboardWebPage extends StatefulWidget {
  const EstoqueDashboardWebPage({
    super.key,
    this.onBack,
    this.onEntradaEstoque,
    this.onSaidaEstoque,
    this.onAjusteEstoque,
    this.onOpenListaCompleta,
  });

  final VoidCallback? onBack;
  final VoidCallback? onEntradaEstoque;
  final VoidCallback? onSaidaEstoque;
  final VoidCallback? onAjusteEstoque;
  final VoidCallback? onOpenListaCompleta;

  @override
  State<EstoqueDashboardWebPage> createState() => _EstoqueDashboardWebPageState();
}

class _EstoqueDashboardWebPageState extends State<EstoqueDashboardWebPage> {
  final ProdutoService _produtoService = ProdutoService();
  late Future<EstoqueDashboardModel> _dashboardFuture;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final NumberFormat _decimalFormatter = NumberFormat.decimalPattern('pt_BR');
  final DateFormat _dateFormatter = DateFormat('dd/MM HH:mm', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _produtoService.buscarDashboardEstoque();
  }

  void _recarregar() {
    setState(() {
      _dashboardFuture = _produtoService.buscarDashboardEstoque();
    });
  }

  String _money(double value) => _currencyFormatter.format(value);

  String _qty(double value) {
    if (value == value.roundToDouble()) {
      return _decimalFormatter.format(value.toInt());
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder<EstoqueDashboardModel>(
        future: _dashboardFuture,
        builder: (BuildContext context, AsyncSnapshot<EstoqueDashboardModel> snapshot) {
          Widget child;
          if (snapshot.connectionState == ConnectionState.waiting) {
            child = const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            child = _buildError(snapshot.error);
          } else {
            final EstoqueDashboardModel dashboard = snapshot.data ?? _emptyDashboard();
            child = dashboard.isEmpty ? _buildEmpty() : _buildDashboard(dashboard);
          }

          return Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }

  EstoqueDashboardModel _emptyDashboard() {
    return const EstoqueDashboardModel(
      valorTotalEstoque: 0,
      quantidadeTotalEstoque: 0,
      totalProdutos: 0,
      produtosAbaixoMinimo: 0,
      produtosSemEstoque: 0,
      produtosEstoqueNegativo: 0,
      produtosAcimaMaximo: 0,
      produtosSemMovimentacao: 0,
      entradasRecentes: 0,
      saidasRecentes: 0,
      situacaoEstoque: <EstoqueDashboardSerieItem>[],
      valorEstoquePorCategoria: <EstoqueDashboardSerieItem>[],
      produtosParaReposicao: <EstoqueDashboardProdutoItem>[],
      produtosComErroEstoque: <EstoqueDashboardProdutoItem>[],
      produtosMaiorValorParado: <EstoqueDashboardProdutoItem>[],
      movimentacoesRecentes: <EstoqueDashboardMovimentoItem>[],
      alertas: <EstoqueDashboardAlerta>[],
    );
  }

  Widget _buildHeader() {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.warehouse_outlined,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Estoque',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Controle operacional de saldos, reposição, rupturas e movimentações do estoque.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _recarregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
              FilledButton.icon(
                onPressed: widget.onEntradaEstoque,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Entrada'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onSaidaEstoque,
                icon: const Icon(Icons.indeterminate_check_box_outlined),
                label: const Text('Saída'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onOpenListaCompleta,
                icon: const Icon(Icons.table_rows_rounded),
                label: const Text('Produtos'),
              ),
              IconButton.filledTonal(
                onPressed: widget.onBack,
                tooltip: 'Fechar',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(EstoqueDashboardModel dashboard) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 1180;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildKpis(dashboard, compact),
              const SizedBox(height: 18),
              compact
                  ? Column(
                      children: <Widget>[
                        _chartCard(
                          title: 'Situação do estoque',
                          subtitle: 'Distribuição dos produtos por risco operacional.',
                          child: _pieChart(dashboard.situacaoEstoque),
                        ),
                        const SizedBox(height: 18),
                        _chartCard(
                          title: 'Valor por categoria',
                          subtitle: 'Onde está concentrado o dinheiro parado em estoque.',
                          child: _barChart(dashboard.valorEstoquePorCategoria, useValue: true),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _chartCard(
                            title: 'Situação do estoque',
                            subtitle: 'Distribuição dos produtos por risco operacional.',
                            child: _pieChart(dashboard.situacaoEstoque),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _chartCard(
                            title: 'Valor por categoria',
                            subtitle: 'Onde está concentrado o dinheiro parado em estoque.',
                            child: _barChart(dashboard.valorEstoquePorCategoria, useValue: true),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 18),
              compact
                  ? Column(
                      children: <Widget>[
                        _alerts(dashboard.alertas),
                        const SizedBox(height: 18),
                        _productsToReplenish(dashboard.produtosParaReposicao),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _alerts(dashboard.alertas)),
                        const SizedBox(width: 18),
                        Expanded(child: _productsToReplenish(dashboard.produtosParaReposicao)),
                      ],
                    ),
              const SizedBox(height: 18),
              compact
                  ? Column(
                      children: <Widget>[
                        _stockErrors(dashboard.produtosComErroEstoque),
                        const SizedBox(height: 18),
                        _stockValue(dashboard.produtosMaiorValorParado),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _stockErrors(dashboard.produtosComErroEstoque)),
                        const SizedBox(width: 18),
                        Expanded(child: _stockValue(dashboard.produtosMaiorValorParado)),
                      ],
                    ),
              const SizedBox(height: 18),
              _movements(dashboard.movimentacoesRecentes),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpis(EstoqueDashboardModel dashboard, bool compact) {
    final List<_Kpi> kpis = <_Kpi>[
      _Kpi(Icons.payments_outlined, 'Valor total em estoque', _money(dashboard.valorTotalEstoque), true),
      _Kpi(Icons.inventory_2_outlined, 'Quantidade total', _qty(dashboard.quantidadeTotalEstoque)),
      _Kpi(Icons.production_quantity_limits_outlined, 'Abaixo do mínimo', _decimalFormatter.format(dashboard.produtosAbaixoMinimo)),
      _Kpi(Icons.remove_shopping_cart_outlined, 'Sem estoque', _decimalFormatter.format(dashboard.produtosSemEstoque)),
      _Kpi(Icons.report_problem_outlined, 'Estoque negativo', _decimalFormatter.format(dashboard.produtosEstoqueNegativo)),
      _Kpi(Icons.unarchive_outlined, 'Acima do máximo', _decimalFormatter.format(dashboard.produtosAcimaMaximo)),
      _Kpi(Icons.history_toggle_off_outlined, 'Sem movimentação', _decimalFormatter.format(dashboard.produtosSemMovimentacao)),
      _Kpi(Icons.swap_vert_rounded, 'Entradas/Saídas', '${_decimalFormatter.format(dashboard.entradasRecentes)} / ${_decimalFormatter.format(dashboard.saidasRecentes)}'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kpis.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 118,
      ),
      itemBuilder: (BuildContext context, int index) => _kpiCard(kpis[index]),
    );
  }

  Widget _kpiCard(_Kpi kpi) {
    final ThemeData theme = Theme.of(context);
    final Color background = kpi.highlight ? theme.colorScheme.primary : theme.colorScheme.surface;
    final Color foreground = kpi.highlight ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final Color muted = kpi.highlight
        ? theme.colorScheme.onPrimary.withOpacity(0.80)
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: kpi.highlight ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kpi.highlight
                  ? theme.colorScheme.onPrimary.withOpacity(0.14)
                  : theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              kpi.icon,
              color: kpi.highlight ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  kpi.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  kpi.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: foreground, fontWeight: FontWeight.w900, fontSize: 21),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({required String title, required String subtitle, required Widget child}) {
    final ThemeData theme = Theme.of(context);
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _barChart(List<EstoqueDashboardSerieItem> itens, {bool useValue = false}) {
    final ThemeData theme = Theme.of(context);
    final List<EstoqueDashboardSerieItem> chartItems = itens
        .where((EstoqueDashboardSerieItem item) => useValue ? item.valor > 0 : item.quantidade > 0)
        .take(6)
        .toList();

    if (chartItems.isEmpty) {
      return _noData();
    }

    final double maxValue = chartItems.fold<double>(0, (double max, EstoqueDashboardSerieItem item) {
      return math.max(max, useValue ? item.valor : item.quantidade);
    });

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: maxValue <= 0 ? 10.0 : maxValue * 1.18,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxValue <= 0 ? 2.0 : math.max(1.0, maxValue / 4),
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withOpacity(0.55),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (double axisValue, TitleMeta meta) => Text(
                  useValue ? _compactMoney(axisValue) : axisValue.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (double axisValue, TitleMeta meta) {
                  final int index = axisValue.toInt();
                  if (index < 0 || index >= chartItems.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 76,
                      child: Text(
                        chartItems[index].label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List<BarChartGroupData>.generate(chartItems.length, (int index) {
            final double value = useValue ? chartItems[index].valor : chartItems[index].quantidade;
            return BarChartGroupData(
              x: index,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: value,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                  color: _chartColor(theme, index),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _pieChart(List<EstoqueDashboardSerieItem> itens) {
    final ThemeData theme = Theme.of(context);
    final List<EstoqueDashboardSerieItem> chartItems = itens
        .where((EstoqueDashboardSerieItem item) => item.quantidade > 0)
        .toList();

    if (chartItems.isEmpty) {
      return _noData();
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 230,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 48,
              sectionsSpace: 3,
              sections: List<PieChartSectionData>.generate(chartItems.length, (int index) {
                final EstoqueDashboardSerieItem item = chartItems[index];
                return PieChartSectionData(
                  value: item.quantidade,
                  title: _qty(item.quantidade),
                  radius: 66,
                  color: _chartColor(theme, index),
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List<Widget>.generate(chartItems.length, (int index) {
            return _legend(_chartColor(theme, index), chartItems[index].label);
          }),
        ),
      ],
    );
  }

  Widget _alerts(List<EstoqueDashboardAlerta> alertas) {
    final ThemeData theme = Theme.of(context);
    return _sectionCard(
      title: 'Alertas de estoque',
      icon: Icons.tips_and_updates_outlined,
      child: Column(
        children: alertas.map((EstoqueDashboardAlerta alerta) {
          final Color color = _alertColor(theme, alerta.tipo);
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(_alertIcon(alerta.tipo), color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(alerta.titulo, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        alerta.descricao,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _decimalFormatter.format(alerta.quantidade),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _productsToReplenish(List<EstoqueDashboardProdutoItem> items) {
    return _sectionCard(
      title: 'Produtos para reposição',
      icon: Icons.add_shopping_cart_outlined,
      child: items.isEmpty ? _noData(text: 'Nenhum produto abaixo do mínimo.') : Column(children: items.map(_compactProduct).toList()),
    );
  }

  Widget _stockErrors(List<EstoqueDashboardProdutoItem> items) {
    return _sectionCard(
      title: 'Erros e excessos de estoque',
      icon: Icons.report_problem_outlined,
      child: items.isEmpty ? _noData(text: 'Nenhum erro operacional identificado.') : Column(children: items.map(_compactProduct).toList()),
    );
  }

  Widget _stockValue(List<EstoqueDashboardProdutoItem> items) {
    return _sectionCard(
      title: 'Maior valor parado',
      icon: Icons.account_balance_wallet_outlined,
      child: items.isEmpty ? _noData() : Column(children: items.map(_compactProductValue).toList()),
    );
  }

  Widget _movements(List<EstoqueDashboardMovimentoItem> items) {
    final ThemeData theme = Theme.of(context);
    return _sectionCard(
      title: 'Movimentações recentes',
      icon: Icons.swap_vert_rounded,
      child: items.isEmpty
          ? _noData(text: 'Nenhuma movimentação encontrada.')
          : Column(
              children: items.map((EstoqueDashboardMovimentoItem item) {
                final bool entrada = item.tipo.toUpperCase().contains('ENTRADA');
                final Color color = entrada ? Colors.green.shade700 : theme.colorScheme.error;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.70))),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(entrada ? Icons.add_circle_outline : Icons.remove_circle_outline, color: color),
                      const SizedBox(width: 10),
                      Expanded(flex: 4, child: _tableText(item.nomeProduto, bold: true)),
                      Expanded(flex: 2, child: _tableText(item.categoria)),
                      Expanded(flex: 2, child: _tableText(item.tipo, alignEnd: true, bold: true)),
                      Expanded(flex: 2, child: _tableText(_qty(item.quantidade), alignEnd: true)),
                      Expanded(flex: 2, child: _tableText(_dateLabel(item.dataCadastro), alignEnd: true)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    final ThemeData theme = Theme.of(context);
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _sectionContainer({required Widget child}) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _compactProduct(EstoqueDashboardProdutoItem item) {
    final ThemeData theme = Theme.of(context);
    return _listTileShell(
      leading: Icons.inventory_2_outlined,
      title: item.nome.isEmpty ? 'Produto sem nome' : item.nome,
      subtitle: '${item.categoria} • Atual ${_qty(item.quantidadeEstoque)} • Mín. ${_qty(item.estoqueMinimo)}',
      trailingTitle: item.problema,
      trailingSubtitle: 'Dif. ${_qty(item.diferencaParaMinimo)}',
      trailingColor: item.problema == 'Normal' ? theme.colorScheme.primary : theme.colorScheme.error,
    );
  }

  Widget _compactProductValue(EstoqueDashboardProdutoItem item) {
    final ThemeData theme = Theme.of(context);
    return _listTileShell(
      leading: Icons.paid_outlined,
      title: item.nome.isEmpty ? 'Produto sem nome' : item.nome,
      subtitle: '${item.categoria} • Qtd ${_qty(item.quantidadeEstoque)} • Custo ${_money(item.ultimoCusto)}',
      trailingTitle: _money(item.valorEstoque),
      trailingSubtitle: item.problema,
      trailingColor: theme.colorScheme.primary,
    );
  }

  Widget _listTileShell({
    required IconData leading,
    required String title,
    required String subtitle,
    required String trailingTitle,
    required String trailingSubtitle,
    required Color trailingColor,
  }) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(leading, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(trailingTitle, style: TextStyle(color: trailingColor, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(trailingSubtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableText(String value, {bool alignEnd = false, bool bold = false}) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: bold ? FontWeight.w900 : FontWeight.w600),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _noData({String text = 'Sem dados suficientes para exibir esta informação.'}) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildError(Object? error) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.30),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 42, color: theme.colorScheme.error),
            const SizedBox(height: 14),
            Text('Não foi possível carregar o estoque.', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(error?.toString() ?? 'Erro desconhecido', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _recarregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.outlineVariant)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.warehouse_outlined, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text('Nenhum produto em estoque ainda.', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Cadastre produtos e entradas para acompanhar reposição, rupturas, excessos e movimentações.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: widget.onEntradaEstoque, icon: const Icon(Icons.add_box_outlined), label: const Text('Registrar entrada')),
          ],
        ),
      ),
    );
  }

  String _compactMoney(double value) {
    if (value >= 1000000) return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return '-';
    return _dateFormatter.format(value);
  }

  Color _chartColor(ThemeData theme, int index) {
    final List<Color> colors = <Color>[
      theme.colorScheme.primary,
      theme.colorScheme.tertiary,
      theme.colorScheme.secondary,
      Colors.orange.shade700,
      Colors.green.shade700,
      Colors.red.shade600,
      Colors.indigo.shade500,
      Colors.blueGrey.shade600,
    ];
    return colors[index % colors.length];
  }

  Color _alertColor(ThemeData theme, String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CRITICO':
      case 'ALTO':
        return theme.colorScheme.error;
      case 'MEDIO':
        return Colors.orange.shade700;
      case 'OK':
        return Colors.green.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _alertIcon(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CRITICO':
      case 'ALTO':
        return Icons.priority_high_rounded;
      case 'MEDIO':
        return Icons.warning_amber_rounded;
      case 'OK':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _Kpi {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _Kpi(this.icon, this.label, this.value, [this.highlight = false]);
}
