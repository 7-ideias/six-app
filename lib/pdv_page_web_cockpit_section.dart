part of 'pdv_page_web.dart';

extension _PdvPageWebCockpitSection on _PDVWebState {
  Widget _buildCockpitEstrategico() {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 980;

          return SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildSalesDashboardHeader(context),
                const SizedBox(height: 18),
                _buildSalesKpis(constraints.maxWidth),
                const SizedBox(height: 18),
                if (compact) ...<Widget>[
                  _buildSalesEvolutionCard(context),
                  const SizedBox(height: 18),
                  _buildSalesDistributionCard(context),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: _buildSalesEvolutionCard(context),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 2,
                        child: _buildSalesDistributionCard(context),
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                _buildTopProductsCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesDashboardHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Resultados de vendas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _pdvTheme.primaryText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Visão consolidada do desempenho comercial no período atual.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _pdvTheme.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _pdvTheme.backgroundSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _pdvTheme.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.calendar_month_outlined,
                size: 17,
                color: _pdvTheme.iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Últimos 30 dias',
                style: TextStyle(
                  color: _pdvTheme.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesKpis(double availableWidth) {
    final bool compact = availableWidth < 760;
    final double cardWidth = compact
        ? availableWidth
        : ((availableWidth - 54) / 4).clamp(210.0, 360.0);

    const List<_SalesKpiData> kpis = <_SalesKpiData>[
      _SalesKpiData(
        title: 'Faturamento',
        value: 'R\$ 86.420',
        variation: '+12,8%',
        icon: Icons.payments_outlined,
      ),
      _SalesKpiData(
        title: 'Vendas concluídas',
        value: '284',
        variation: '+8,4%',
        icon: Icons.shopping_bag_outlined,
      ),
      _SalesKpiData(
        title: 'Ticket médio',
        value: 'R\$ 304,30',
        variation: '+4,1%',
        icon: Icons.receipt_long_outlined,
      ),
      _SalesKpiData(
        title: 'Conversão',
        value: '68,7%',
        variation: '+3,2 p.p.',
        icon: Icons.trending_up_rounded,
      ),
    ];

    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: kpis
          .map(
            (_SalesKpiData data) => SizedBox(
              width: cardWidth,
              child: _buildSalesKpiCard(data),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildSalesKpiCard(_SalesKpiData data) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _pdvTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _pdvTheme.cardBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _pdvTheme.cardShadow,
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _pdvTheme.iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(data.icon, color: _pdvTheme.iconColor, size: 21),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    data.variation,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              data.value,
              style: TextStyle(
                color: _pdvTheme.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data.title,
              style: TextStyle(
                color: _pdvTheme.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesEvolutionCard(BuildContext context) {
    return _buildDashboardCard(
      title: 'Evolução de vendas',
      subtitle: 'Faturamento diário dos últimos 7 dias',
      child: SizedBox(
        height: 280,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: 18,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 6,
              getDrawingHorizontalLine: (_) => FlLine(
                color: _pdvTheme.cardBorder.withValues(alpha: 0.65),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: 6,
                  getTitlesWidget: (double value, TitleMeta meta) => Text(
                    '${value.toInt()}k',
                    style: TextStyle(
                      color: _pdvTheme.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    const List<String> labels = <String>[
                      'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom',
                    ];
                    final int index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          color: _pdvTheme.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: <LineChartBarData>[
              LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.30,
                barWidth: 3,
                color: _pdvTheme.iconColor,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: _pdvTheme.iconColor.withValues(alpha: 0.10),
                ),
                spots: const <FlSpot>[
                  FlSpot(0, 8.4),
                  FlSpot(1, 10.2),
                  FlSpot(2, 9.6),
                  FlSpot(3, 13.8),
                  FlSpot(4, 15.4),
                  FlSpot(5, 12.6),
                  FlSpot(6, 16.1),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesDistributionCard(BuildContext context) {
    return _buildDashboardCard(
      title: 'Composição das vendas',
      subtitle: 'Participação por tipo de operação',
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 210,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 54,
                sectionsSpace: 4,
                startDegreeOffset: -90,
                sections: <PieChartSectionData>[
                  _buildPieSection(56, '56%', _pdvTheme.iconColor),
                  _buildPieSection(29, '29%', _pdvTheme.highlightColor),
                  _buildPieSection(15, '15%', _pdvTheme.warningColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSalesLegend('Produtos', '56%', _pdvTheme.iconColor),
          const SizedBox(height: 10),
          _buildSalesLegend('Serviços', '29%', _pdvTheme.highlightColor),
          const SizedBox(height: 10),
          _buildSalesLegend('Assistência técnica', '15%', _pdvTheme.warningColor),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(
    double value,
    String title,
    Color color,
  ) {
    return PieChartSectionData(
      value: value,
      title: title,
      radius: 48,
      color: color,
      titleStyle: TextStyle(
        color: _pdvTheme.badgeText,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildSalesLegend(String label, String value, Color color) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: _pdvTheme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _pdvTheme.primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsCard(BuildContext context) {
    const List<_TopSalesData> items = <_TopSalesData>[
      _TopSalesData('Troca de tela premium', 'R\$ 18.540', 0.92),
      _TopSalesData('Smartphone linha A', 'R\$ 14.280', 0.76),
      _TopSalesData('Reparo de placa', 'R\$ 11.920', 0.64),
      _TopSalesData('Acessórios e proteção', 'R\$ 9.870', 0.53),
    ];

    return _buildDashboardCard(
      title: 'Mais vendidos',
      subtitle: 'Produtos e serviços com maior faturamento',
      child: Column(
        children: items
            .map(
              (_TopSalesData item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _pdvTheme.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 8,
                            backgroundColor: _pdvTheme.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _pdvTheme.iconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        item.value,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: _pdvTheme.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _pdvTheme.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: _pdvTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: _pdvTheme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SalesKpiData {
  const _SalesKpiData({
    required this.title,
    required this.value,
    required this.variation,
    required this.icon,
  });

  final String title;
  final String value;
  final String variation;
  final IconData icon;
}

class _TopSalesData {
  const _TopSalesData(this.label, this.value, this.progress);

  final String label;
  final String value;
  final double progress;
}
