part of 'pdv_page_web.dart';

extension _PdvPageWebCockpitSection on _PDVWebState {
  Widget _buildCockpitEstrategico() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = Theme.of(context);
          final isCompact = constraints.maxWidth < 920;
          final horizontalPadding = isCompact ? 16.0 : 28.0;

          return ColoredBox(
            color: theme.colorScheme.surfaceContainerLowest,
            child: Column(
              children: <Widget>[
                _buildCockpitHeader(context, isCompact),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildCockpitResumoKpis(context),
                        const SizedBox(height: 14),
                        SixWebEntry(
                          order: 4,
                          duration: const Duration(milliseconds: 640),
                          child: _buildCockpitFinanceiroChart(context),
                        ),
                        const SizedBox(height: 14),
                        isCompact
                            ? Column(
                                children: <Widget>[
                                  SixWebEntry(
                                    order: 5,
                                    duration: const Duration(milliseconds: 640),
                                    child: _buildCockpitVendasCanalChart(context),
                                  ),
                                  const SizedBox(height: 14),
                                  SixWebEntry(
                                    order: 6,
                                    duration: const Duration(milliseconds: 640),
                                    child: _buildCockpitAtendimentoChart(context),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: SixWebEntry(
                                      order: 5,
                                      duration: const Duration(milliseconds: 640),
                                      child: _buildCockpitVendasCanalChart(context),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: SixWebEntry(
                                      order: 6,
                                      duration: const Duration(milliseconds: 640),
                                      child: _buildCockpitAtendimentoChart(context),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 14),
                        SixWebEntry(
                          order: 7,
                          duration: const Duration(milliseconds: 640),
                          child: _buildCockpitOpcoesExemplo(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCockpitResumoKpis(BuildContext context) {
    final List<Map<String, Object>> kpis = <Map<String, Object>>[
      <String, Object>{
        'titulo': 'Receita líquida',
        'valor': 'R\$ 486.300',
        'delta': '+8,6% vs mês anterior',
        'icone': Icons.payments_outlined,
        'destaque': true,
      },
      <String, Object>{
        'titulo': 'Margem operacional',
        'valor': '24,2%',
        'delta': '+2,1 p.p',
        'icone': Icons.trending_up_rounded,
      },
      <String, Object>{
        'titulo': 'Ticket médio',
        'valor': 'R\$ 312',
        'delta': '+5,4%',
        'icone': Icons.shopping_bag_outlined,
      },
      <String, Object>{
        'titulo': 'NPS atendimento',
        'valor': '74',
        'delta': 'Meta: 80',
        'icone': Icons.support_agent_rounded,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final cardWidth = isCompact
            ? constraints.maxWidth
            : ((constraints.maxWidth - 42) / 4).clamp(210.0, 360.0);

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: kpis.asMap().entries.map((entry) {
            final index = entry.key;
            final kpi = entry.value;
            return SixWebEntry(
              order: index,
              duration: const Duration(milliseconds: 620),
              child: _buildCockpitKpiCard(
                context,
                width: cardWidth,
                title: kpi['titulo']?.toString() ?? '',
                value: kpi['valor']?.toString() ?? '',
                delta: kpi['delta']?.toString() ?? '',
                icon: (kpi['icone'] as IconData?) ?? Icons.insights_rounded,
                highlight: kpi['destaque'] == true,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCockpitKpiCard(
    BuildContext context, {
    required double width,
    required String title,
    required String value,
    required String delta,
    required IconData icon,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.12),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: highlight
                    ? Colors.white.withValues(alpha: 0.15)
                    : colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: highlight ? Colors.white : colorScheme.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlight
                          ? Colors.white.withValues(alpha: 0.86)
                          : colorScheme.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlight ? Colors.white : colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    delta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlight
                          ? Colors.white.withValues(alpha: 0.78)
                          : colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCockpitFinanceiroChart(BuildContext context) {
    const List<FlSpot> receita = <FlSpot>[
      FlSpot(0, 390),
      FlSpot(1, 410),
      FlSpot(2, 428),
      FlSpot(3, 446),
      FlSpot(4, 472),
      FlSpot(5, 486),
    ];
    const List<FlSpot> meta = <FlSpot>[
      FlSpot(0, 400),
      FlSpot(1, 415),
      FlSpot(2, 430),
      FlSpot(3, 445),
      FlSpot(4, 460),
      FlSpot(5, 475),
    ];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cockpitCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Resultado financeiro (R\$ mil): receita x meta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 360,
                maxY: 520,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                    strokeWidth: 1,
                  ),
                ),
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
                      reservedSize: 48,
                      interval: 40,
                      getTitlesWidget: (double value, TitleMeta meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const List<String> meses = <String>[
                          'Nov',
                          'Dez',
                          'Jan',
                          'Fev',
                          'Mar',
                          'Abr',
                        ];
                        final int idx = value.toInt();
                        if (idx < 0 || idx >= meses.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            meses[idx],
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: receita,
                    isCurved: true,
                    barWidth: 3.5,
                    color: colorScheme.primary,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  LineChartBarData(
                    spots: meta,
                    isCurved: true,
                    barWidth: 2.5,
                    color: Colors.orange.shade700,
                    dashArray: const <int>[7, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: <Widget>[
              _buildLegendaGrafico(context, colorScheme.primary, 'Receita'),
              _buildLegendaGrafico(context, Colors.orange.shade700, 'Meta'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitVendasCanalChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cockpitCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Vendas por canal (últimos 30 dias)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: 220,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 40,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                    strokeWidth: 1,
                  ),
                ),
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
                      reservedSize: 35,
                      getTitlesWidget: (double value, TitleMeta meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const List<String> canais = <String>[
                          'Loja',
                          'Whats',
                          'Site',
                          'B2B',
                        ];
                        final int idx = value.toInt();
                        if (idx < 0 || idx >= canais.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            canais[idx],
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: <BarChartGroupData>[
                  BarChartGroupData(
                    x: 0,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: 198,
                        width: 20,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: 172,
                        width: 20,
                        color: const Color(0xFF14B8A6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: 146,
                        width: 20,
                        color: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: 119,
                        width: 20,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitAtendimentoChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cockpitCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Qualidade de atendimento',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 44,
                sectionsSpace: 3,
                sections: <PieChartSectionData>[
                  PieChartSectionData(
                    value: 58,
                    title: '58%',
                    radius: 62,
                    color: const Color(0xFF22C55E),
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 27,
                    title: '27%',
                    radius: 62,
                    color: const Color(0xFFF59E0B),
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 15,
                    title: '15%',
                    radius: 62,
                    color: const Color(0xFFEF4444),
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              _buildLegendaGrafico(context, const Color(0xFF22C55E), 'Satisfeitos'),
              _buildLegendaGrafico(context, const Color(0xFFF59E0B), 'Neutros'),
              _buildLegendaGrafico(context, const Color(0xFFEF4444), 'Insatisfeitos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitOpcoesExemplo(BuildContext context) {
    final List<Map<String, String>> opcoes = <Map<String, String>>[
      <String, String>{
        'titulo': 'Rentabilidade por cliente',
        'descricao':
            'Mostra clientes com alta receita e baixa margem para renegociação de mix ou política comercial.',
      },
      <String, String>{
        'titulo': 'Conversão de orçamento em venda',
        'descricao':
            'Evidencia onde o funil trava e quais equipes/canais têm maior perda de fechamento.',
      },
      <String, String>{
        'titulo': 'SLA e tempo de resposta',
        'descricao': 'Aponta gargalos de atendimento que afetam NPS e recompra.',
      },
      <String, String>{
        'titulo': 'Risco de churn',
        'descricao':
            'Detecta clientes com queda de frequência, aumento de reclamação e queda no ticket.',
      },
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cockpitCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Opções de exemplo para priorização',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(opcoes.length, (int index) {
              return ChoiceChip(
                label: Text(opcoes[index]['titulo'] ?? ''),
                selected: _opcaoCockpitSelecionada == index,
                onSelected: (_) {
                  _selecionarOpcaoCockpit(index);
                },
              );
            }),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.10),
              ),
            ),
            child: Text(
              opcoes[_opcaoCockpitSelecionada]['descricao'] ?? '',
              style: TextStyle(
                height: 1.45,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaGrafico(BuildContext context, Color color, String label) {
    final colorScheme = Theme.of(context).colorScheme;
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCockpitHeader(BuildContext context, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;

    final titleBlock = Row(
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.space_dashboard_rounded,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Cockpit estratégico',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 21 : 24,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Visão executiva de vendas, orçamentos, assistência e qualidade de atendimento.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: <Widget>[
        _cockpitHeaderButton(
          context,
          Icons.refresh_rounded,
          'Atualizar',
          _limparFiltrosCockpit,
        ),
        _cockpitHeaderButton(
          context,
          Icons.arrow_back_rounded,
          'Voltar',
          _voltarParaSeletor,
        ),
        _cockpitCloseButton(context),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 28,
        isCompact ? 16 : 22,
        isCompact ? 16 : 28,
        isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              children: <Widget>[
                titleBlock,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                actions,
              ],
            ),
    );
  }

  Widget _cockpitHeaderButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _cockpitCloseButton(BuildContext context) {
    return Material(
      color: const Color(0xFFE53935),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _voltarParaSeletor,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  BoxDecoration _cockpitCardDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
