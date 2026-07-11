import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/produto_dashboard_model.dart';

class ProdutoDashboardWebPage extends StatefulWidget {
  const ProdutoDashboardWebPage({super.key, this.onBack, this.onNovoProduto, this.onOpenListaCompleta});

  final VoidCallback? onBack;
  final VoidCallback? onNovoProduto;
  final VoidCallback? onOpenListaCompleta;

  @override
  State<ProdutoDashboardWebPage> createState() => _ProdutoDashboardWebPageState();
}

class _ProdutoDashboardWebPageState extends State<ProdutoDashboardWebPage> {
  static const Duration _entryDuration = Duration(milliseconds: 520);
  static const Duration _chartDuration = Duration(milliseconds: 1100);
  static const Duration _numberDuration = Duration(milliseconds: 750);
  static const Curve _entryCurve = Curves.easeOutCubic;

  final ProdutoService _produtoService = ProdutoService();
  late Future<ProdutoDashboardModel> _dashboardFuture;
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final NumberFormat _decimalFormatter = NumberFormat.decimalPattern('pt_BR');

  int _produtosPorCategoriaTouchedIndex = -1;
  int _situacaoEstoqueTouchedIndex = -1;
  int _valorPorCategoriaTouchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _produtoService.buscarDashboardProdutos();
  }

  void _recarregar() {
    setState(() {
      _produtosPorCategoriaTouchedIndex = -1;
      _situacaoEstoqueTouchedIndex = -1;
      _valorPorCategoriaTouchedIndex = -1;
      _dashboardFuture = _produtoService.buscarDashboardProdutos();
    });
  }

  void _setProdutosPorCategoriaTouchedIndex(int index) {
    if (_produtosPorCategoriaTouchedIndex != index) setState(() => _produtosPorCategoriaTouchedIndex = index);
  }

  void _setSituacaoEstoqueTouchedIndex(int index) {
    if (_situacaoEstoqueTouchedIndex != index) setState(() => _situacaoEstoqueTouchedIndex = index);
  }

  void _setValorPorCategoriaTouchedIndex(int index) {
    if (_valorPorCategoriaTouchedIndex != index) setState(() => _valorPorCategoriaTouchedIndex = index);
  }

  String _money(double value) => _currencyFormatter.format(value);
  String _whole(double value) => _decimalFormatter.format(value.round());
  String _percent(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')}%';

  String _qty(double value) {
    if (value == value.roundToDouble()) return _decimalFormatter.format(value.toInt());
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder<ProdutoDashboardModel>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final Widget child;
          if (snapshot.connectionState == ConnectionState.waiting) {
            child = KeyedSubtree(key: const ValueKey<String>('produtos-dashboard-loading'), child: _buildLoadingDashboard());
          } else if (snapshot.hasError) {
            child = KeyedSubtree(key: const ValueKey<String>('produtos-dashboard-error'), child: _buildError(snapshot.error));
          } else {
            final dashboard = snapshot.data ?? _emptyDashboard();
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          _headerIcon(Icons.inventory_2_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Produtos', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'Resumo executivo do catálogo, estoque, valor parado e alertas de reposição.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(onPressed: _recarregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
              FilledButton.icon(onPressed: widget.onNovoProduto, icon: const Icon(Icons.add_rounded), label: const Text('Novo produto')),
              OutlinedButton.icon(onPressed: widget.onOpenListaCompleta, icon: const Icon(Icons.table_rows_rounded), label: const Text('Lista completa')),
              IconButton.filledTonal(onPressed: widget.onBack, tooltip: 'Fechar', icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    final theme = Theme.of(context);
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
      child: Icon(icon, color: theme.colorScheme.primary, size: 28),
    );
  }

  Widget _buildLoadingDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1180;
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
                itemBuilder: (context, index) => _entry(order: index, child: _loadingKpiCard(highlight: index == 2)),
              ),
              const SizedBox(height: 18),
              _responsiveChildren(
                compact: compact,
                children: <Widget>[
                  _loadingChartCard(title: 'Produtos por categoria', subtitle: 'Quantidade em estoque por agrupamento.', order: 8),
                  _loadingChartCard(title: 'Situação do estoque', subtitle: 'Distribuição por saúde operacional.', order: 9),
                  _loadingChartCard(title: 'Valor por categoria', subtitle: 'Onde o dinheiro em estoque está concentrado.', order: 10),
                ],
              ),
              const SizedBox(height: 18),
              _responsiveChildren(
                compact: compact,
                children: <Widget>[
                  _loadingSectionCard(title: 'Atenção necessária', order: 11),
                  _loadingSectionCard(title: 'Produtos com estoque baixo', order: 12),
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
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1180;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildKpis(dashboard, compact),
              const SizedBox(height: 18),
              _responsiveChildren(
                compact: compact,
                children: <Widget>[
                  _entry(
                    order: 8,
                    child: _chartCard(
                      title: 'Produtos por categoria',
                      subtitle: 'Quantidade em estoque por agrupamento.',
                      child: _barChart(
                        dashboard.produtosPorCategoria,
                        value: (item) => item.quantidade,
                        touchedIndex: _produtosPorCategoriaTouchedIndex,
                        onTouchedIndexChanged: _setProdutosPorCategoriaTouchedIndex,
                      ),
                    ),
                  ),
                  _entry(
                    order: 9,
                    child: _chartCard(
                      title: 'Situação do estoque',
                      subtitle: 'Distribuição por saúde operacional.',
                      child: _pieChart(
                        dashboard.situacaoEstoque,
                        touchedIndex: _situacaoEstoqueTouchedIndex,
                        onTouchedIndexChanged: _setSituacaoEstoqueTouchedIndex,
                      ),
                    ),
                  ),
                  _entry(
                    order: 10,
                    child: _chartCard(
                      title: 'Valor por categoria',
                      subtitle: 'Onde o dinheiro em estoque está concentrado.',
                      child: _barChart(
                        dashboard.valorEstoquePorCategoria,
                        value: (item) => item.valor,
                        touchedIndex: _valorPorCategoriaTouchedIndex,
                        onTouchedIndexChanged: _setValorPorCategoriaTouchedIndex,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _responsiveChildren(
                compact: compact,
                children: <Widget>[
                  _entry(order: 11, child: _alerts(dashboard.alertas)),
                  _entry(order: 12, child: _lowStock(dashboard.produtosEstoqueBaixoLista)),
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

  Widget _responsiveChildren({required bool compact, required List<Widget> children}) {
    if (compact) {
      return Column(children: _withSpacing(children, vertical: true));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _withSpacing(children.map((child) => Expanded(child: child)).toList(), vertical: false),
    );
  }

  List<Widget> _withSpacing(List<Widget> children, {required bool vertical}) {
    final spaced = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) spaced.add(SizedBox(width: vertical ? 0 : 18, height: vertical ? 18 : 0));
      spaced.add(children[index]);
    }
    return spaced;
  }

  Widget _buildKpis(ProdutoDashboardModel dashboard, bool compact) {
    final kpis = <_Kpi>[
      _Kpi(Icons.widgets_outlined, 'Produtos cadastrados', dashboard.totalProdutos.toDouble(), _whole),
      _Kpi(Icons.verified_outlined, 'Produtos ativos', dashboard.produtosAtivos.toDouble(), _whole),
      _Kpi(Icons.account_balance_wallet_outlined, 'Valor em estoque', dashboard.valorTotalEstoque, _money, true),
      _Kpi(Icons.inventory_outlined, 'Quantidade em estoque', dashboard.quantidadeTotalEstoque, _qty),
      _Kpi(Icons.warning_amber_rounded, 'Estoque baixo', dashboard.produtosEstoqueBaixo.toDouble(), _whole),
      _Kpi(Icons.remove_shopping_cart_outlined, 'Sem estoque', dashboard.produtosSemEstoque.toDouble(), _whole),
      _Kpi(Icons.error_outline_rounded, 'Estoque negativo', dashboard.produtosEstoqueNegativo.toDouble(), _whole),
      _Kpi(Icons.trending_up_rounded, 'Margem média', dashboard.margemMediaPercentual, _percent),
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
      itemBuilder: (context, index) => _entry(order: index, child: _kpiCard(kpis[index])),
    );
  }

  Widget _kpiCard(_Kpi kpi) {
    final theme = Theme.of(context);
    final background = kpi.highlight ? theme.colorScheme.primary : theme.colorScheme.surface;
    final foreground = kpi.highlight ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final muted = kpi.highlight ? theme.colorScheme.onPrimary.withOpacity(0.80) : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kpi.highlight ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kpi.highlight ? theme.colorScheme.onPrimary.withOpacity(0.14) : theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(kpi.icon, color: kpi.highlight ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(kpi.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>('${kpi.label}:${kpi.value}'),
                  tween: Tween<double>(begin: 0, end: kpi.value),
                  duration: _numberDuration,
                  curve: _entryCurve,
                  builder: (context, value, child) {
                    return Text(
                      kpi.formatter(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: foreground, fontWeight: FontWeight.w900, fontSize: 22),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({required String title, required String subtitle, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _barChart(List<ProdutoDashboardSerieItem> itens, {required double Function(ProdutoDashboardSerieItem item) value, required int touchedIndex, required ValueChanged<int> onTouchedIndexChanged}) {
    final theme = Theme.of(context);
    final chartItems = itens.take(6).toList();
    if (chartItems.isEmpty) return _noData();

    final maxValue = chartItems.fold<double>(0, (max, item) => math.max(max, value(item)));
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(chartItems.map((item) => '${item.label}:${value(item)}').join('|')),
      tween: Tween<double>(begin: 0, end: 1),
      duration: _chartDuration,
      curve: Curves.linear,
      builder: (context, progress, child) {
        return SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: maxValue <= 0 ? 10.0 : maxValue * 1.18,
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (_, response) {
                  final index = response?.spot?.touchedBarGroupIndex ?? -1;
                  onTouchedIndexChanged(index >= 0 && index < chartItems.length ? index : -1);
                },
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxValue <= 0 ? 2.0 : math.max(1.0, maxValue / 4),
                getDrawingHorizontalLine: (_) => FlLine(color: theme.colorScheme.outlineVariant.withOpacity(0.55), strokeWidth: 1),
              ),
              titlesData: _barTitles(theme, chartItems),
              barGroups: List<BarChartGroupData>.generate(chartItems.length, (index) {
                final itemProgress = _staggeredItemProgress(progress, index);
                final touched = index == touchedIndex;
                final opacity = touchedIndex == -1 || touched ? 1.0 : 0.45;
                return BarChartGroupData(
                  x: index,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: value(chartItems[index]) * itemProgress,
                      width: touched ? 30 : 22,
                      borderRadius: BorderRadius.circular(touched ? 10 : 8),
                      color: _chartColor(theme, index).withOpacity(opacity),
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

  FlTitlesData _barTitles(ThemeData theme, List<ProdutoDashboardSerieItem> chartItems) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 46,
          getTitlesWidget: (axisValue, meta) => Text(
            axisValue >= 1000 ? '${(axisValue / 1000).toStringAsFixed(0)}k' : axisValue.toInt().toString(),
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (axisValue, meta) {
            final index = axisValue.toInt();
            if (index < 0 || index >= chartItems.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 72,
                child: Text(
                  chartItems[index].label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pieChart(List<ProdutoDashboardSerieItem> itens, {required int touchedIndex, required ValueChanged<int> onTouchedIndexChanged}) {
    final theme = Theme.of(context);
    final chartItems = itens.where((item) => item.quantidade > 0).toList();
    if (chartItems.isEmpty) return _noData();

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(chartItems.map((item) => '${item.label}:${item.quantidade}').join('|')),
      tween: Tween<double>(begin: 0, end: 1),
      duration: _chartDuration,
      curve: Curves.linear,
      builder: (context, progress, child) {
        return Column(
          children: <Widget>[
            SizedBox(
              height: 230,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (_, response) {
                      final index = response?.touchedSection?.touchedSectionIndex ?? -1;
                      onTouchedIndexChanged(index >= 0 && index < chartItems.length ? index : -1);
                    },
                  ),
                  startDegreeOffset: -90,
                  centerSpaceRadius: 48,
                  sectionsSpace: touchedIndex == -1 ? 3 : 5,
                  sections: List<PieChartSectionData>.generate(chartItems.length, (index) {
                    final item = chartItems[index];
                    final itemProgress = _staggeredItemProgress(progress, index);
                    final touched = index == touchedIndex;
                    final opacity = touchedIndex == -1 || touched ? 1.0 : 0.48;
                    return PieChartSectionData(
                      value: math.max(0.001, item.quantidade * itemProgress),
                      title: itemProgress > 0.72 ? _qty(item.quantidade) : '',
                      radius: touched ? 78 : 54 + (12 * progress),
                      color: _chartColor(theme, index).withOpacity(opacity),
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
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
                children: List<Widget>.generate(chartItems.length, (index) => _legend(_chartColor(theme, index), chartItems[index].label)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _alerts(List<ProdutoDashboardAlerta> alertas) {
    final theme = Theme.of(context);
    return _sectionCard(
      title: 'Atenção necessária',
      icon: Icons.tips_and_updates_outlined,
      child: Column(
        children: alertas.map((alerta) {
          final color = _alertColor(theme, alerta.tipo);
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.22))),
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
                      Text(alerta.descricao, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(_decimalFormatter.format(alerta.quantidade), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
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
      child: items.isEmpty ? _noData(text: 'Nenhum produto abaixo do estoque mínimo.') : Column(children: items.map(_compactProduct).toList()),
    );
  }

  Widget _topStockValue(List<ProdutoDashboardItem> items) {
    final theme = Theme.of(context);
    return _sectionCard(
      title: 'Top produtos por valor em estoque',
      icon: Icons.leaderboard_outlined,
      child: items.isEmpty
          ? _noData()
          : Column(
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.70)))),
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: 10), Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)))]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _compactProduct(ProdutoDashboardItem item) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.45), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Row(
        children: <Widget>[
          Icon(Icons.inventory_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${item.categoria} • mínimo ${_qty(item.estoqueMinimo)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(_qty(item.quantidadeEstoque), style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _tableText(String value, {bool alignEnd = false, bool bold = false}) {
    final theme = Theme.of(context);
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
    );
  }

  Widget _legend(Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _entry({required int order, required Widget child}) {
    final stagger = order > 8 ? 8 : order;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _entryDuration + Duration(milliseconds: stagger * 55),
      curve: _entryCurve,
      child: child,
      builder: (context, progress, child) {
        final normalized = math.max(0.0, math.min(1.0, progress));
        return Opacity(
          opacity: normalized,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - normalized)),
            child: Transform.scale(alignment: Alignment.topCenter, scale: 0.985 + (0.015 * normalized), child: child),
          ),
        );
      },
    );
  }

  double _staggeredItemProgress(double progress, int index) {
    final delayedProgress = ((progress - (index * 0.07)) / 0.72).clamp(0.0, 1.0).toDouble();
    return Curves.easeOutCubic.transform(delayedProgress);
  }

  Widget _loadingKpiCard({required bool highlight}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? theme.colorScheme.primary.withOpacity(0.90) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: highlight ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          _skeletonBox(width: 48, height: 48, radius: 16, color: highlight ? theme.colorScheme.onPrimary.withOpacity(0.16) : null),
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

  Widget _loadingChartCard({required String title, required String subtitle, required int order}) {
    return _entry(order: order, child: _chartCard(title: title, subtitle: subtitle, child: _chartSkeleton()));
  }

  Widget _loadingSectionCard({required String title, required int order}) {
    final theme = Theme.of(context);
    return _entry(
      order: order,
      child: _sectionCard(
        title: title,
        icon: Icons.hourglass_empty_rounded,
        child: Column(
          children: List<Widget>.generate(3, (index) {
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.28), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.70))),
              child: Row(
                children: <Widget>[
                  _skeletonBox(width: 34, height: 34, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[_skeletonBox(width: 150, height: 12), const SizedBox(height: 8), _skeletonBox(width: double.infinity, height: 10)])),
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
    final theme = Theme.of(context);
    return SizedBox(
      height: 260,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List<Widget>.generate(5, (index) => Container(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.55))),
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

  Widget _skeletonBox({double? width, required double height, double radius = 999, Color? color}) {
    final theme = Theme.of(context);
    return Container(width: width, height: height, decoration: BoxDecoration(color: color ?? theme.colorScheme.surfaceVariant.withOpacity(0.55), borderRadius: BorderRadius.circular(radius)));
  }

  Widget _noData({String text = 'Sem dados suficientes para exibir esta informação.'}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.35), borderRadius: BorderRadius.circular(16)),
      child: Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildError(Object? error) {
    final theme = Theme.of(context);
    return Center(
      child: _entry(
        order: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withOpacity(0.30), borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.colorScheme.error.withOpacity(0.25))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.cloud_off_rounded, size: 42, color: theme.colorScheme.error),
              const SizedBox(height: 14),
              Text('Não foi possível carregar o resumo de produtos.', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(error?.toString() ?? 'Erro desconhecido', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: _recarregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    return Center(
      child: _entry(
        order: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.outlineVariant)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 14),
              Text('Nenhum produto cadastrado ainda.', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Cadastre os primeiros itens para visualizar valor em estoque, categorias, margem e alertas executivos.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: widget.onNovoProduto, icon: const Icon(Icons.add_rounded), label: const Text('Cadastrar produto')),
            ],
          ),
        ),
      ),
    );
  }

  Color _chartColor(ThemeData theme, int index) {
    final colors = <Color>[theme.colorScheme.primary, theme.colorScheme.tertiary, theme.colorScheme.secondary, Colors.orange.shade700, Colors.green.shade700, Colors.red.shade600, Colors.indigo.shade500, Colors.blueGrey.shade600];
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
  final double value;
  final String Function(double value) formatter;
  final bool highlight;

  const _Kpi(this.icon, this.label, this.value, this.formatter, [this.highlight = false]);
}
