import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/servico_dashboard_model.dart';

class ServicoDashboardWebPage extends StatefulWidget {
  const ServicoDashboardWebPage({
    super.key,
    this.onBack,
    this.onNovoServico,
    this.onOpenListaCompleta,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNovoServico;
  final VoidCallback? onOpenListaCompleta;

  @override
  State<ServicoDashboardWebPage> createState() => _ServicoDashboardWebPageState();
}

class _ServicoDashboardWebPageState extends State<ServicoDashboardWebPage> {
  final ProdutoService _produtoService = ProdutoService();
  late Future<ServicoDashboardModel> _dashboardFuture;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final NumberFormat _decimalFormatter = NumberFormat.decimalPattern('pt_BR');

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _produtoService.buscarDashboardServicos();
  }

  void _recarregar() {
    setState(() {
      _dashboardFuture = _produtoService.buscarDashboardServicos();
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
      child: FutureBuilder<ServicoDashboardModel>(
        future: _dashboardFuture,
        builder: (BuildContext context, AsyncSnapshot<ServicoDashboardModel> snapshot) {
          Widget child;

          if (snapshot.connectionState == ConnectionState.waiting) {
            child = const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            child = _buildError(snapshot.error);
          } else {
            final ServicoDashboardModel dashboard = snapshot.data ?? _emptyDashboard();
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

  ServicoDashboardModel _emptyDashboard() {
    return const ServicoDashboardModel(
      totalServicos: 0,
      servicosAtivos: 0,
      precoMedio: 0,
      servicosSemPreco: 0,
      servicosComGarantia: 0,
      servicosSemGarantia: 0,
      servicosValorAlteravel: 0,
      servicosSemCategoria: 0,
      servicosCadastroIncompleto: 0,
      servicosPorCategoria: <ServicoDashboardSerieItem>[],
      servicosPorFaixaPreco: <ServicoDashboardSerieItem>[],
      configuracaoOperacional: <ServicoDashboardSerieItem>[],
      servicosAtencao: <ServicoDashboardItem>[],
      servicosEstrategicos: <ServicoDashboardItem>[],
      alertas: <ServicoDashboardAlerta>[],
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
              Icons.home_repair_service_outlined,
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
                  'Serviços',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visão executiva do catálogo técnico, preços, garantias e pontos de atenção operacional.',
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
                onPressed: widget.onNovoServico,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Novo serviço'),
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

  Widget _buildDashboard(ServicoDashboardModel dashboard) {
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
                          title: 'Serviços por categoria',
                          subtitle: 'Organização do catálogo por tipo de serviço técnico.',
                          child: _barChart(dashboard.servicosPorCategoria),
                        ),
                        const SizedBox(height: 18),
                        _chartCard(
                          title: 'Faixa de preço',
                          subtitle: 'Distribuição dos serviços por posicionamento comercial.',
                          child: _barChart(dashboard.servicosPorFaixaPreco),
                        ),
                        const SizedBox(height: 18),
                        _chartCard(
                          title: 'Configuração operacional',
                          subtitle: 'Garantia e flexibilidade de valor no atendimento.',
                          child: _pieChart(dashboard.configuracaoOperacional),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _chartCard(
                            title: 'Serviços por categoria',
                            subtitle: 'Organização do catálogo por tipo de serviço técnico.',
                            child: _barChart(dashboard.servicosPorCategoria),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _chartCard(
                            title: 'Faixa de preço',
                            subtitle: 'Distribuição dos serviços por posicionamento comercial.',
                            child: _barChart(dashboard.servicosPorFaixaPreco),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _chartCard(
                            title: 'Configuração operacional',
                            subtitle: 'Garantia e flexibilidade de valor no atendimento.',
                            child: _pieChart(dashboard.configuracaoOperacional),
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
                        _servicesAttention(dashboard.servicosAtencao),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _alerts(dashboard.alertas)),
                        const SizedBox(width: 18),
                        Expanded(child: _servicesAttention(dashboard.servicosAtencao)),
                      ],
                    ),
              const SizedBox(height: 18),
              _strategicServices(dashboard.servicosEstrategicos),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpis(ServicoDashboardModel dashboard, bool compact) {
    final List<_Kpi> kpis = <_Kpi>[
      _Kpi(Icons.design_services_outlined, 'Serviços cadastrados', _decimalFormatter.format(dashboard.totalServicos)),
      _Kpi(Icons.verified_outlined, 'Serviços ativos', _decimalFormatter.format(dashboard.servicosAtivos)),
      _Kpi(Icons.sell_outlined, 'Preço médio', _money(dashboard.precoMedio), true),
      _Kpi(Icons.money_off_outlined, 'Sem preço', _decimalFormatter.format(dashboard.servicosSemPreco)),
      _Kpi(Icons.workspace_premium_outlined, 'Com garantia', _decimalFormatter.format(dashboard.servicosComGarantia)),
      _Kpi(Icons.no_accounts_outlined, 'Sem garantia', _decimalFormatter.format(dashboard.servicosSemGarantia)),
      _Kpi(Icons.edit_note_rounded, 'Valor alterável', _decimalFormatter.format(dashboard.servicosValorAlteravel)),
      _Kpi(Icons.rule_folder_outlined, 'Cadastro incompleto', _decimalFormatter.format(dashboard.servicosCadastroIncompleto)),
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

  Widget _barChart(List<ServicoDashboardSerieItem> itens) {
    final ThemeData theme = Theme.of(context);
    final List<ServicoDashboardSerieItem> chartItems = itens
        .where((ServicoDashboardSerieItem item) => item.quantidade > 0)
        .take(6)
        .toList();

    if (chartItems.isEmpty) {
      return _noData();
    }

    final double maxValue = chartItems.fold<double>(0, (double max, ServicoDashboardSerieItem item) {
      return math.max(max, item.quantidade);
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
                reservedSize: 40,
                getTitlesWidget: (double axisValue, TitleMeta meta) => Text(
                  axisValue.toInt().toString(),
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
            return BarChartGroupData(
              x: index,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: chartItems[index].quantidade,
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

  Widget _pieChart(List<ServicoDashboardSerieItem> itens) {
    final ThemeData theme = Theme.of(context);
    final List<ServicoDashboardSerieItem> chartItems = itens
        .where((ServicoDashboardSerieItem item) => item.quantidade > 0)
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
                final ServicoDashboardSerieItem item = chartItems[index];
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

  Widget _alerts(List<ServicoDashboardAlerta> alertas) {
    final ThemeData theme = Theme.of(context);

    return _sectionCard(
      title: 'Atenção necessária',
      icon: Icons.tips_and_updates_outlined,
      child: Column(
        children: alertas.map((ServicoDashboardAlerta alerta) {
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

  Widget _servicesAttention(List<ServicoDashboardItem> items) {
    return _sectionCard(
      title: 'Serviços que precisam de atenção',
      icon: Icons.rule_folder_outlined,
      child: items.isEmpty
          ? _noData(text: 'Nenhum serviço com pendência cadastral.')
          : Column(children: items.map(_compactService).toList()),
    );
  }

  Widget _strategicServices(List<ServicoDashboardItem> items) {
    final ThemeData theme = Theme.of(context);

    return _sectionCard(
      title: 'Serviços estratégicos por preço',
      icon: Icons.leaderboard_outlined,
      child: items.isEmpty
          ? _noData()
          : Column(
              children: items.map((ServicoDashboardItem item) {
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
                      Expanded(flex: 2, child: _tableText(_money(item.precoVenda), alignEnd: true, bold: true)),
                      Expanded(flex: 2, child: _tableText(_garantiaLabel(item.tempoGarantia), alignEnd: true)),
                      Expanded(flex: 2, child: _tableText(item.podeAlterarValorNaHora ? 'Alterável' : 'Fixo', alignEnd: true)),
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

  Widget _compactService(ServicoDashboardItem item) {
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
          Icon(Icons.home_repair_service_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.nome.isEmpty ? 'Serviço sem nome' : item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.categoria} • ${_garantiaLabel(item.tempoGarantia)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _money(item.precoVenda),
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                item.problema,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 11, fontWeight: FontWeight.w800),
              ),
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
              'Não foi possível carregar o resumo de serviços.',
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
    );
  }

  Widget _buildEmpty() {
    final ThemeData theme = Theme.of(context);

    return Center(
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
            Icon(Icons.home_repair_service_outlined, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              'Nenhum serviço cadastrado ainda.',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre os primeiros serviços para acompanhar preços, garantias, categorias e pendências operacionais.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: widget.onNovoServico,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cadastrar serviço'),
            ),
          ],
        ),
      ),
    );
  }

  String _garantiaLabel(String tempoGarantia) {
    final String value = tempoGarantia.trim();
    return value.isEmpty ? 'Sem garantia' : value;
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
