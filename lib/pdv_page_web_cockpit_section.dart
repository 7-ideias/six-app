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
                _buildSalesKpis(context, constraints.maxWidth),
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

  Widget _buildSalesKpis(BuildContext context, double availableWidth) {
    final bool compact = availableWidth < 760;
    final double cardWidth = compact
        ? availableWidth
        : ((availableWidth - 54) / 4).clamp(210.0, 360.0);

    final List<_SalesKpiData> kpis = <_SalesKpiData>[
      const _SalesKpiData(
        title: 'Faturamento',
        value: 'R\$ 86.420',
        variation: '+12,8%',
        icon: Icons.payments_outlined,
      ),
      const _SalesKpiData(
        title: 'Vendas concluídas',
        value: '284',
        variation: '+8,4%',
        icon: Icons.shopping_bag_outlined,
      ),
      const _SalesKpiData(
        title: 'Ticket médio',
        value: 'R\$ 304,30',
        variation: '+4,1%',
        icon: Icons.receipt_long_outlined,
      ),
      const _SalesKpiData(
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
            (_SalesKpiData item) => _buildSalesKpiCard(
              context,
              data: item,
              width: cardWidth,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildSalesKpiCard(
    BuildContext context, {
    required _SalesKpiData data,
    required double width,
  }) {
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
      child: SizedBox(
        width: width,
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
                    child: Icon(
                      data.icon,
                      size: 21,
                      color: _pdvTheme.iconColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
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
      ),
    );
  }

  Widget _buildSalesEvolutionCard(BuildContext context) {
    return _buildDashboardCard(
      context,
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
                      fontWeight: FontWeight.w600,
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
                      'Seg',
                      'Ter',
                      'Qua',
                      'Qui',
                      'Sex',
                      'Sáb',
                      'Dom',
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
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> spots) => spots
                    .map(
                      (LineBarSpot spot) => LineTooltipItem(
                        'R\$ ${spot.y.toStringAsFixed(1)} mil',
                        TextStyle(
                          color: _pdvTheme.badgeText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                    .toList(growable: false),
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
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  Widget _buildSalesDistributionCard(BuildContext context) {
    return _buildDashboardCard(
      context,
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
                  PieChartSectionData(
                    value: 56,
                    title: '56%',
                    radius: 48,
                    color: _pdvTheme.iconColor,
                    titleStyle: TextStyle(
                      color: _pdvTheme.badgeText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  PieChartSectionData(
                    value: 29,
                    title: '29%',
                    radius: 48,
                    color: _pdvTheme.highlightColor,
                    titleStyle: TextStyle(
                      color: _pdvTheme.badgeText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  PieChartSectionData(
                    value: 15,
                    title: '15%',
                    radius: 48,
                    color: _pdvTheme.warningColor,
                    titleStyle: TextStyle(
                      color: _pdvTheme.badgeText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 8),
          _buildSalesLegend(
            label: 'Produtos',
            value: '56%',
            color: _pdvTheme.iconColor,
          ),
          const SizedBox(height: 10),
          _buildSalesLegend(
            label: 'Serviços',
            value: '29%',
            color: _pdvTheme.highlightColor,
          ),
          const SizedBox(height: 10),
          _buildSalesLegend(
            label: 'Assistência técnica',
            value: '15%',
            color: _pdvTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesLegend({
    required String label,
    required String value,
    required Color color,
  }) {
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
    const List<_TopProductData> products = <_TopProductData>[
      _TopProductData('Troca de tela premium', 42, 'R\$ 18.860'),
      _TopProductData('Smartphone intermediário', 31, 'R\$ 15.490'),
      _TopProductData('Manutenção preventiva', 58, 'R\$ 11.600'),
      _TopProductData('Acessórios e proteção', 77, 'R\$ 9.240'),
    ];

    return _buildDashboardCard(
      context,
      title: 'Produtos e serviços em destaque',
      subtitle: 'Ranking por faturamento no período',
      child: Column(
        children: products.asMap().entries.map((MapEntry<int, _TopProductData> entry) {
          final int index = entry.key;
          final _TopProductData product = entry.value;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: index == products.length - 1
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: _pdvTheme.cardBorder.withValues(alpha: 0.70),
                      ),
                    ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _pdvTheme.iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: _pdvTheme.iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _pdvTheme.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${product.quantity} vendas',
                        style: TextStyle(
                          color: _pdvTheme.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  product.revenue,
                  style: TextStyle(
                    color: _pdvTheme.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _pdvTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
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
          const SizedBox(height: 18),
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

class _TopProductData {
  const _TopProductData(this.name, this.quantity, this.revenue);

  final String name;
  final int quantity;
  final String revenue;
}
