import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/produto_dashboard_model.dart';

class ProdutoDashboardWebPage extends StatefulWidget {
  const ProdutoDashboardWebPage({
    super.key,
    this.onBack,
    this.onNovoProduto,
    this.onOpenListaCompleta,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNovoProduto;
  final VoidCallback? onOpenListaCompleta;

  @override
  State<ProdutoDashboardWebPage> createState() => _ProdutoDashboardWebPageState();
}

class _ProdutoDashboardWebPageState extends State<ProdutoDashboardWebPage> {
  static const Duration _entryDuration = Duration(milliseconds: 520);
  static const Duration _chartDuration = Duration(milliseconds: 900);
  static const Curve _entryCurve = Curves.easeOutCubic;

  final ProdutoService _produtoService = ProdutoService();
  late Future<ProdutoDashboardModel> _dashboardFuture;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final NumberFormat _decimalFormatter = NumberFormat.decimalPattern('pt_BR');

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _produtoService.buscarDashboardProdutos();
  }

  void _recarregar() {
    setState(() {
      _dashboardFuture = _produtoService.buscarDashboardProdutos();
    });
  }

  String _money(double value) => _currencyFormatter.format(value);

  String _qty(double value) {
    if (value == value.roundToDouble()) {
      return _decimalFormatter.format(value.toInt());
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _percent(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')}%';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder<ProdutoDashboardModel>(
        future: _dashboardFuture,
        builder: (BuildContext context, AsyncSnapshot<ProdutoDashboardModel> snapshot) {
          Widget child;

          if (snapshot.connectionState == ConnectionState.waiting) {
            child = KeyedSubtree(
              key: const ValueKey<String>('produtos-dashboard-loading'),
              child: _buildLoadingDashboard(),
            );
          } else if (snapshot.hasError) {
            child = KeyedSubtree(
              key: const ValueKey<String>('produtos-dashboard-error'),
              child: _buildError(snapshot.error),
            );
          } else {
            final ProdutoDashboardModel dashboard = snapshot.data ?? _emptyDashboard();
            child = KeyedSubtree(
              key: const ValueKey<String>('produtos-dashboard-content'),
              child: dashboard.isEmpty ? _buildEmpty() : _buildDashboard(dashboard),
            );
          }

          return Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: _entryCurve,
                  switchOutCurve: Curves.easeInCubic,
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ProdutoDashboardModel _emptyDashboard() {
    return const ProdutoDashboardModel(
      totalProdutos: 0,
      produtosAtivos: 0,
      valorTotalEstoque: 0,
      quantidadeTotalEstoque: 0,
      produtosEstoqueBaixo: 0,
      produtosSemEstoque: 0,
      produtosEstoqueNegativo: 0,
      margemMediaPercentual: 0,
      produtosPorCategoria: <ProdutoDashboardSerieItem>[],
      valorEstoquePorCategoria: <ProdutoDashboardSerieItem>[],
      situacaoEstoque: <ProdutoDashboardSerieItem>[],
      topProdutosMaiorValorEstoque: <ProdutoDashboardItem>[],
      produtosEstoqueBaixoLista: <ProdutoDashboardItem>[],
      alertas: <ProdutoDashboardAlerta>[],
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
              Icons.inventory_2_outlined,
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
                  'Produtos',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resumo executivo do catálogo, estoque, valor parado e alertas de reposição.',
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
                onPressed: widget.onNovoProduto,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Novo produto'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onOpenListaCompleta,
                icon: const Icon(Icons.table_rows_rounded),
                label: const Text('Lista completa'),
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

  Widget _buildLoadingDashboard() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 1180;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: compact ? 2 : 4,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 118,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _entry(
                    order: index,
                    child: _loadingKpiCard(highlight: index == 2),
                  );
                },
              ),
              const SizedBox(height: 18),
              compact
                  ? Column(
                      children: <Widget>[
                        _loadingChartCard(
                          title: 'Produtos por categoria',
                          subtitle: 'Quantidade em estoque por agrupamento.',
                          order: 8,
                        ),
                        const SizedBox(height: 18),
                        _loadingChartCard(
                          title: 'Situação do estoque',
                          subtitle: 'Distribuição por saúde operacional.',
                          order: 9,
                        ),
                        const SizedBox(height: 18),
                        _loadingChartCard(
                          title: 'Valor por categoria',
                          subtitle: 'Onde o dinheiro em estoque está concentrado.',
                          order: 10,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _loadingChartCard(
                            title: 'Produtos por categoria',
                            subtitle: 'Quantidade em estoque por agrupamento.',
                            order: 8,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _loadingChartCard(
                            title: 'Situação do estoque',
                            subtitle: 'Distribuição por saúde operacional.',
                            order: 9,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _loadingChartCard(
                            title: 'Valor por categoria',
                            subtitle: 'Onde o dinheiro em estoque está concentrado.',
                            order: 10,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 18),
              compact
                  ? Column(
                      children: <Widget>[
                        _loadingSectionCard(title: 'Atenção necessária', order: 11),
                        const SizedBox(height: 18),
                        _loadingSectionCard(title: 'Produtos com estoque baixo', order: 12),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _loadingSectionCard(title: 'Atenção necessária', order: 11)),
                        const SizedBox(width: 18),
                        Expanded(child: _loadingSectionCard(title: 'Produtos com estoque baixo', order: 12)),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboard(ProdutoDashboardModel dashboard) {
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
                        _entry(
                          order: 8,
                          child: _chartCard(
                            title: 'Produtos por categoria',
                            subtitle: 'Quantidade em estoque por agrupamento.',
                            child: _barChart(
                              dashboard.produtosPorCategoria,
                              value: (ProdutoDashboardSerieItem item) => item.quantidade,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _entry(
                          order: 9,
                          child: _chartCard(
                            title: 'Situação do estoque',
                            subtitle: 'Distribuição por saúde operacional.',
                            child: _pieChart(dashboard.situacaoEstoque),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _entry(
                          order: 10,
                          child: _chartCard(
                            title: 'Valor por categoria',
                            subtitle: 'Onde o dinheiro em estoque está concentrado.',
                            child: _barChart(
                              dashboard.valorEstoquePorCategoria,
                              value: (ProdutoDashboardSerieItem item) => item.valor,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _entry(
                            order: 8,
                            child: _chartCard(
                              title: 'Produtos por categoria',
                              subtitle: 'Quantidade em estoque por agrupamento.',
                              child: _barChart(
                                dashboard.produtosPorCategoria,
                                value: (ProdutoDashboardSerieItem item) => item.quantidade,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _entry(
                            order: 9,
                            child: _chartCard(
                              title: 'Situação do estoque',
                              subtitle: 'Distribuição por saúde operacional.',
                              child: _pieChart(dashboard.situacaoEstoque),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _entry(
                            order: 10,
                            child: _chartCard(
                              title: 'Valor por categoria',
                              subtitle: 'Onde o dinheiro em estoque está concentrado.',
                              child: _barChart(
                                dashboard.valorEstoquePorCategoria,
                                value: (ProdutoDashboardSerieItem item) => item.valor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 18),
              compact
                  ? Column(
                      children: <Widget>[
                        _entry(order: 11, child: _alerts(dashboard.alertas)),
                        const SizedBox(height: 18),
                        _entry(order: 12, child: _lowStock(dashboard.produtosEstoqueBaixoLista)),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _entry(order: 11, child: _alerts(dashboard.alertas))),
                        const SizedBox(width: 18),
                        Expanded(child: _entry(order: 12, child: _lowStock(dashboard.produtosEstoqueBaixoLista))),
                      ],
                    ),
              const SizedBox(height: 18),
              _entry(order: 13, child: _topStockValue(dashboard.topProdutosMaiorValorEstoque)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpis(ProdutoDashboardModel dashboard, bool compact) {
    final List<_Kpi> kpis = <_Kpi>[
      _Kpi(Icons.widgets_outlined, 'Produtos cadastrados', _decimalFormatter.format(dashboard.totalProdutos)),
      _Kpi(Icons.verified_outlined, 'Produtos ativos', _decimalFormatter.format(dashboard.produtosAtivos)),
      _Kpi(Icons.account_balance_wallet_outlined, 'Valor em estoque', _money(dashboard.valorTotalEstoque), true),
      _Kpi(Icons.inventory_outlined, 'Quantidade em estoque', _qty(dashboard.quantidadeTotalEstoque)),
      _Kpi(Icons.warning_amber_rounded, 'Estoque baixo', _decimalFormatter.format(dashboard.produtosEstoqueBaixo)),
      _Kpi(Icons.remove_shopping_cart_outlined, 'Sem estoque', _decimalFormatter.format(dashboard.produtosSemEstoque)),
      _Kpi(Icons.error_outline_rounded, 'Estoque negativo', _decimalFormatter.format(dashboard.produtosEstoqueNegativo)),
      _Kpi(Icons.trending_up_rounded, 'Margem média', _percent(dashboard.margemMediaPercentual)),
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
      itemBuilder: (BuildContext context, int index) {
        return _entry(order: index, child: _kpiCard(kpis[index]));
      },
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
                  style: TextStyle(color: foreground, fontWeight: FontWeight.w900, fontSize: 22),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
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

  Widget _barChart(
    List<ProdutoDashboardSerieItem> itens, {
    required double Function(ProdutoDashboardSerieItem item) value,
  }) {
    final ThemeData theme = Theme.of(context);
    final List<ProdutoDashboardSerieItem> chartItems = itens.take(6).toList();

    if (chartItems.isEmpty) {
      return _noData();
    }

    final double maxValue = chartItems.fold<double>(0, (double max, ProdutoDashboardSerieItem item) {
      return math.max(max, value(item));
    });

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _chartDuration,
      curve: _entryCurve,
      builder: (BuildContext context, double progress, Widget? child) {
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
                    reservedSize: 46,
                    getTitlesWidget: (double axisValue, TitleMeta meta) => Text(
                      axisValue >= 1000
                          ? '${(axisValue / 1000).toStringAsFixed(0)}k'
                          : axisValue.toInt().toString(),
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
                      if (index < 0 || index >= chartItems.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: 72,
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
                return BarChartGroupData(
                  x: index,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: value(chartItems[index]) * progress,
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
      },
    );
  }

  Widget _pieChart(List<ProdutoDashboardSerieItem> itens) {
    final ThemeData theme = Theme.of(context);
    final List<ProdutoDashboardSerieItem> chartItems = itens
        .where((ProdutoDashboardSerieItem item) => item.quantidade > 0)
        .toList();

    if (chartItems.isEmpty) {
      return _noData();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _chartDuration,
      curve: _entryCurve,
      builder: (BuildContext context, double progress, Widget? child) {
        return Column(
          children: <Widget>[
            SizedBox(
              height: 230,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 48,
                  sectionsSpace: 3,
                  sections: List<PieChartSectionData>.generate(chartItems.length, (int index) {
                    final ProdutoDashboardSerieItem item = chartItems[index];
                    return PieChartSectionData(
                      value: math.max(0.001, item.quantidade * progress),
                      title: progress > 0.72 ? _qty(item.quantidade) : '',
                      radius: 54 + (12 * progress),
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
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: progress > 0.65 ? 1 : 0,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: List<Widget>.generate(chartItems.length, (int index) {
                  return _legend(_chartColor(theme, index), chartItems[index].label);
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _alerts(List<ProdutoDashboardAlerta> alertas) {
    final ThemeData theme = Theme.of(context);

    return _sectionCard(
      title: 'Atenção necessária',
      icon: Icons.tips_and_updates_outlined,
      child: Column(
        children: alertas.map((ProdutoDashboardAlerta alerta) {
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
                      Text(
                        alerta.titulo,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
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

  Widget _lowStock(List<ProdutoDashboardItem> items) {
    return _sectionCard(
      title: 'Produtos com estoque baixo',
      icon: Icons.production_quantity_limits_rounded,
      child: items.isEmpty
          ? _noData(text: 'Nenhum produto abaixo do estoque mínimo.')
          : Column(children: items.map(_compactProduct).toList()),
    );
  }

  Widget _topStockValue(List<ProdutoDashboardItem> items) {
    final ThemeData theme = Theme.of(context);

    return _sectionCard(
      title: 'Top produtos por valor em estoque',
      icon: Icons.leaderboard_outlined,
      child: items.isEmpty
          ? _noData()
          : Column(
              children: items.map((ProdutoDashboardItem item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.70)),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(flex: 4, child: _tableText(item.nome, bold: true)),
                      Expanded(flex: 2, child: _tableText(item.categoria)),
                      Expanded(child: _tableText(_qty(item.quantidadeEstoque), alignEnd: true)),
                      Expanded(flex: 2, child: _tableText(_money(item.precoVenda), alignEnd: true)),
                      Expanded(flex: 2, child: _tableText(_money(item.valorEstoque), alignEnd: true, bold: true)),
                      Expanded(child: _tableText(_percent(item.margemPercentual), alignEnd: true)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _compactProduct(ProdutoDashboardItem item) {
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
          Icon(Icons.inventory_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.categoria} • mínimo ${_qty(item.estoqueMinimo)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _qty(item.quantidadeEstoque),
            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w900, fontSize: 18),
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
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _entry({required int order, required Widget child}) {
    final int stagger = order > 8 ? 8 : order;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _entryDuration + Duration(milliseconds: stagger * 55),
      curve: _entryCurve,
      child: child,
      builder: (BuildContext context, double progress, Widget? child) {
        final double normalized = math.max(0.0, math.min(1.0, progress));
        final double dy = 18 * (1 - normalized);

        return Opacity(
          opacity: normalized,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              alignment: Alignment.topCenter,
              scale: 0.985 + (0.015 * normalized),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _loadingKpiCard({required bool highlight}) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? theme.colorScheme.primary.withOpacity(0.90) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlight ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          _skeletonBox(
            width: 48,
            height: 48,
            radius: 16,
            color: highlight ? theme.colorScheme.onPrimary.withOpacity(0.16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _skeletonBox(width: 96, height: 10, color: highlight ? theme.colorScheme.onPrimary.withOpacity(0.22) : null),
                const SizedBox(height: 10),
                _skeletonBox(width: 134, height: 22, color: highlight ? theme.colorScheme.onPrimary.withOpacity(0.28) : null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingChartCard({
    required String title,
    required String subtitle,
    required int order,
  }) {
    return _entry(
      order: order,
      child: _chartCard(
        title: title,
        subtitle: subtitle,
        child: _chartSkeleton(),
      ),
    );
  }

  Widget _loadingSectionCard({required String title, required int order}) {
    final ThemeData theme = Theme.of(context);

    return _entry(
      order: order,
      child: _sectionCard(
        title: title,
        icon: Icons.hourglass_empty_rounded,
        child: Column(
          children: List<Widget>.generate(3, (int index) {
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.28),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.70)),
              ),
              child: Row(
                children: <Widget>[
                  _skeletonBox(width: 34, height: 34, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _skeletonBox(width: 150, height: 12),
                        const SizedBox(height: 8),
                        _skeletonBox(width: double.infinity, height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _skeletonBox(width: 36, height: 18),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _chartSkeleton() {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 260,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List<Widget>.generate(5, (int index) {
                return Container(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.55),
                );
              }),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _skeletonBox(width: 22, height: 120, radius: 8),
                _skeletonBox(width: 22, height: 180, radius: 8),
                _skeletonBox(width: 22, height: 92, radius: 8),
                _skeletonBox(width: 22, height: 150, radius: 8),
                _skeletonBox(width: 22, height: 70, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox({
    double? width,
    required double height,
    double radius = 999,
    Color? color,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _noData({String text = 'Sem dados suficientes para exibir esta informação.'}) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildError(Object? error) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: _entry(
        order: 0,
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
              Text(
                'Não foi possível carregar o resumo de produtos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Erro desconhecido',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _recarregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: _entry(
        order: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                'Nenhum produto cadastrado ainda.',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Cadastre os primeiros itens para visualizar valor em estoque, categorias, margem e alertas executivos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onNovoProduto,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Cadastrar produto'),
              ),
            ],
          ),
        ),
      ),
    );
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
