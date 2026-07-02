part of 'pdv_page_web.dart';

extension _PdvPageWebCockpitSection on _PDVWebState {
  Widget _buildCockpitEstrategico() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 920;
          final horizontalPadding = isCompact ? 16.0 : 28.0;

          return Container(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.16),
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
                        _buildCockpitResumoKpis(),
                        const SizedBox(height: 14),
                        _buildCockpitFinanceiroChart(),
                        const SizedBox(height: 14),
                        isCompact
                            ? Column(
                              children: <Widget>[
                                _buildCockpitVendasCanalChart(),
                                const SizedBox(height: 14),
                                _buildCockpitAtendimentoChart(),
                              ],
                            )
                            : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: _buildCockpitVendasCanalChart(),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildCockpitAtendimentoChart(),
                                ),
                              ],
                            ),
                        const SizedBox(height: 14),
                        _buildCockpitOpcoesExemplo(),
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

  Widget _buildCockpitResumoKpis() {
    final List<Map<String, String>> kpis = <Map<String, String>>[
      <String, String>{
        'titulo': 'Receita líquida',
        'valor': 'R\$ 486.300',
        'delta': '+8,6% vs mês anterior',
      },
      <String, String>{
        'titulo': 'Margem operacional',
        'valor': '24,2%',
        'delta': '+2,1 p.p',
      },
      <String, String>{
        'titulo': 'Ticket médio',
        'valor': 'R\$ 312',
        'delta': '+5,4%',
      },
      <String, String>{
        'titulo': 'NPS atendimento',
        'valor': '74',
        'delta': 'Meta: 80',
      },
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children:
          kpis.map((Map<String, String> kpi) {
            return Container(
              width: 270,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _pdvTheme.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _pdvTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    kpi['titulo'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _pdvTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    kpi['valor'] ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _pdvTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kpi['delta'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: _pdvTheme.iconColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCockpitFinanceiroChart() {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Resultado financeiro (R\$ mil): receita x meta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _pdvTheme.primaryText,
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
                  getDrawingHorizontalLine:
                      (_) => FlLine(
                        color: _pdvTheme.cardBorder.withValues(alpha: 0.50),
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
                      getTitlesWidget:
                          (double value, TitleMeta meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _pdvTheme.secondaryText,
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
                              color: _pdvTheme.secondaryText,
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
                    color: _pdvTheme.highlightColor,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _pdvTheme.highlightColor.withValues(alpha: 0.10),
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
              _buildLegendaGrafico(_pdvTheme.highlightColor, 'Receita'),
              _buildLegendaGrafico(Colors.orange.shade700, 'Meta'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitVendasCanalChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Vendas por canal (últimos 30 dias)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _pdvTheme.primaryText,
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
                  getDrawingHorizontalLine:
                      (_) => FlLine(
                        color: _pdvTheme.cardBorder.withValues(alpha: 0.50),
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
                      getTitlesWidget:
                          (double value, TitleMeta meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _pdvTheme.secondaryText,
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
                              color: _pdvTheme.secondaryText,
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

  Widget _buildCockpitAtendimentoChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Qualidade de atendimento',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _pdvTheme.primaryText,
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
              _buildLegendaGrafico(const Color(0xFF22C55E), 'Satisfeitos'),
              _buildLegendaGrafico(const Color(0xFFF59E0B), 'Neutros'),
              _buildLegendaGrafico(const Color(0xFFEF4444), 'Insatisfeitos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitOpcoesExemplo() {
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
        'descricao':
            'Aponta gargalos de atendimento que afetam NPS e recompra.',
      },
      <String, String>{
        'titulo': 'Risco de churn',
        'descricao':
            'Detecta clientes com queda de frequência, aumento de reclamação e queda no ticket.',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Opções de exemplo para priorização',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _pdvTheme.primaryText,
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
              color: _pdvTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _pdvTheme.cardBorder),
            ),
            child: Text(
              opcoes[_opcaoCockpitSelecionada]['descricao'] ?? '',
              style: TextStyle(
                height: 1.45,
                color: _pdvTheme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaGrafico(Color color, String label) {
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
            color: _pdvTheme.secondaryText,
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
            color: colorScheme.primary.withOpacity(0.10),
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
                  color: colorScheme.onSurface.withOpacity(0.66),
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
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.14)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child:
          isCompact
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
}
