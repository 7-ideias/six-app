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
                        isCompact
                            ? Column(
                              children: <Widget>[
                                _buildCockpitMetaFinanceiraGauge(context),
                                const SizedBox(height: 14),
                                _buildCockpitFinanceiroChart(context),
                              ],
                            )
                            : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: _buildCockpitFinanceiroChart(context),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildCockpitMetaFinanceiraGauge(
                                    context,
                                  ),
                                ),
                              ],
                            ),
                        const SizedBox(height: 14),
                        isCompact
                            ? Column(
                              children: <Widget>[
                                _buildCockpitVendasCanalChart(context),
                                const SizedBox(height: 14),
                                _buildCockpitAtendimentoChart(context),
                              ],
                            )
                            : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: _buildCockpitVendasCanalChart(context),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildCockpitAtendimentoChart(context),
                                ),
                              ],
                            ),
                        const SizedBox(height: 14),
                        _buildCockpitOpcoesExemplo(context),
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
    final Map<String, dynamic> resumo = _buildResumoDashboardData();
    final List<Map<String, Object>> kpis = <Map<String, Object>>[
      <String, Object>{
        'titulo': 'Faturamento confirmado',
        'valor': _formatCurrency((resumo['faturamentoConfirmado'] as double)),
        'delta': '${resumo['quantidadeVendas'] as int} vendas via backend',
        'icone': Icons.payments_outlined,
        'destaque': (resumo['quantidadeVendas'] as int) > 0,
      },
      <String, Object>{
        'titulo': 'Meta financeira',
        'valor': '${(resumo['percentualMeta'] as double).toStringAsFixed(1)}%',
        'delta':
            '${_formatCurrency((resumo['receitaComVendaAtual'] as double))} de ${_formatCurrency((resumo['metaFinanceira'] as double))}',
        'icone': Icons.track_changes_rounded,
      },
      <String, Object>{
        'titulo': 'Ticket médio',
        'valor': _formatCurrency((resumo['ticketMedio'] as double)),
        'delta':
            '${resumo['quantidadeVendas'] as int} eventos com tipo NOVA_VENDA',
        'icone': Icons.shopping_bag_outlined,
      },
      <String, Object>{
        'titulo': 'Venda atual',
        'valor': _formatCurrency((resumo['valorVendaAtual'] as double)),
        'delta':
            '${resumo['itensVendaAtual'] as int} itens no carrinho • ${resumo['eventosComErro'] as int} eventos com erro',
        'icone': Icons.point_of_sale_rounded,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final cardWidth =
            isCompact
                ? constraints.maxWidth
                : ((constraints.maxWidth - 42) / 4).clamp(210.0, 360.0);

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children:
              kpis.map((Map<String, Object> kpi) {
                return _buildCockpitKpiCard(
                  context,
                  width: cardWidth,
                  title: kpi['titulo']?.toString() ?? '',
                  value: kpi['valor']?.toString() ?? '',
                  delta: kpi['delta']?.toString() ?? '',
                  icon: (kpi['icone'] as IconData?) ?? Icons.insights_rounded,
                  highlight: kpi['destaque'] == true,
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
            color:
                highlight
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
                color:
                    highlight
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
                      color:
                          highlight
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
                      color:
                          highlight
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

  Widget _buildCockpitMetaFinanceiraGauge(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Map<String, dynamic> resumo = _buildResumoDashboardData();
    final double percentualMeta =
        (resumo['percentualMeta'] as double).clamp(0.0, 100.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cockpitCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Meta financeira do ciclo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Progresso consolidado com vendas do backend e venda atual em edição.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 188,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  startAngle: 150,
                  endAngle: 30,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.18,
                    thicknessUnit: GaugeSizeUnit.factor,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: percentualMeta,
                      width: 0.18,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: colorScheme.primary,
                      enableAnimation: true,
                      animationDuration: 850,
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0.05,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${(resumo['percentualMeta'] as double).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'da meta',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatCurrency((resumo['receitaComVendaAtual'] as double))} / ${_formatCurrency((resumo['metaFinanceira'] as double))}',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitFinanceiroChart(BuildContext context) {
    final List<double> serieReceita = _serieFinanceiraUltimosSeisMeses();
    final List<String> labelsMeses = _labelsMesesUltimosSeis();
    final List<FlSpot> receita = List<FlSpot>.generate(
      serieReceita.length,
      (int index) => FlSpot(index.toDouble(), serieReceita[index]),
    );
    final List<FlSpot> meta = List<FlSpot>.generate(serieReceita.length, (
      int index,
    ) {
      final double receitaMes = serieReceita[index];
      final double metaMes = receitaMes <= 0 ? 100 : receitaMes * 1.12;
      return FlSpot(index.toDouble(), metaMes);
    });
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double maxReceita = receita.fold<double>(
      0,
      (double atual, FlSpot item) => item.y > atual ? item.y : atual,
    );
    final double maxMeta = meta.fold<double>(
      0,
      (double atual, FlSpot item) => item.y > atual ? item.y : atual,
    );
    final double maxY =
        ((maxReceita > maxMeta ? maxReceita : maxMeta) * 1.2)
            .clamp(100.0, 999999999.0)
            .toDouble();
    final double horizontalInterval = (maxY / 5).ceil().toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cockpitCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Resultado financeiro (últimos 6 meses)',
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
                minY: 0,
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine:
                      (_) => FlLine(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.72,
                        ),
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
                      interval: horizontalInterval,
                      getTitlesWidget:
                          (double value, TitleMeta meta) => Text(
                            _formatNumeroCompacto(value),
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
                        final int idx = value.toInt();
                        if (idx < 0 || idx >= labelsMeses.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labelsMeses[idx],
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
              _buildLegendaGrafico(
                context,
                colorScheme.primary,
                'Receita confirmada',
              ),
              _buildLegendaGrafico(
                context,
                Colors.orange.shade700,
                'Meta estimada',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitVendasCanalChart(BuildContext context) {
    final Map<String, double> canais = _vendasPorCanal();
    final List<MapEntry<String, double>> itens = canais.entries.toList();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<Color> cores = <Color>[
      const Color(0xFF0EA5E9),
      const Color(0xFF14B8A6),
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
    ];
    final double maxY =
        (itens.fold<double>(
                  0,
                  (double atual, MapEntry<String, double> item) =>
                      item.value > atual ? item.value : atual,
                ) *
                1.2)
            .clamp(10.0, 999999999.0)
            .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cockpitCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Vendas por canal (eventos recebidos)',
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
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: (maxY / 4).ceil().toDouble(),
                  getDrawingHorizontalLine:
                      (_) => FlLine(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.72,
                        ),
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
                            _formatNumeroCompacto(value),
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
                        final int idx = value.toInt();
                        if (idx < 0 || idx >= itens.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            itens[idx].key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                barGroups: List<BarChartGroupData>.generate(itens.length, (
                  int index,
                ) {
                  return BarChartGroupData(
                    x: index,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: itens[index].value,
                        width: 20,
                        borderRadius: BorderRadius.circular(8),
                        color: cores[index % cores.length],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitAtendimentoChart(BuildContext context) {
    final Map<String, double> composicao = _composicaoFinanceiraAtual();
    final List<MapEntry<String, double>> itens = composicao.entries.toList();
    final List<Color> cores = <Color>[
      const Color(0xFF22C55E),
      const Color(0xFF0EA5E9),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    final double total = itens.fold<double>(
      0,
      (double soma, MapEntry<String, double> item) => soma + item.value,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cockpitCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Composição financeira da operação',
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
                sections: List<PieChartSectionData>.generate(itens.length, (
                  int index,
                ) {
                  final double percentual =
                      total <= 0 ? 0 : (itens[index].value / total) * 100;
                  return PieChartSectionData(
                    value: itens[index].value,
                    title:
                        percentual >= 8
                            ? '${percentual.toStringAsFixed(0)}%'
                            : '',
                    radius: 62,
                    color: cores[index % cores.length],
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List<Widget>.generate(itens.length, (int index) {
              final String label =
                  itens[index].key == 'Sem dados'
                      ? itens[index].key
                      : '${itens[index].key} • ${_formatCurrency(itens[index].value)}';
              return _buildLegendaGrafico(
                context,
                cores[index % cores.length],
                label,
              );
            }),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildResumoDashboardData() {
    final List<Map<String, dynamic>> eventosVenda = _eventosVendaBackend();
    final double faturamentoConfirmado = eventosVenda.fold<double>(
      0,
      (double soma, Map<String, dynamic> evento) =>
          soma + _extrairValorMonetarioEvento(evento),
    );
    final int quantidadeVendas = eventosVenda.length;
    final double ticketMedio =
        quantidadeVendas <= 0 ? 0 : faturamentoConfirmado / quantidadeVendas;
    final double valorVendaAtual = _calcularTotal();
    final int itensVendaAtual = _calcularQuantidadeItens();
    final int eventosComErro =
        _notificacoes
            .where((Map<String, dynamic> item) => _isEventoErro(item))
            .length;
    final double receitaComVendaAtual = faturamentoConfirmado + valorVendaAtual;
    final double metaFinanceira =
        receitaComVendaAtual <= 0 ? 1000 : receitaComVendaAtual * 1.18;
    final double percentualMeta =
        metaFinanceira <= 0 ? 0 : (receitaComVendaAtual / metaFinanceira) * 100;

    return <String, dynamic>{
      'faturamentoConfirmado': faturamentoConfirmado,
      'quantidadeVendas': quantidadeVendas,
      'ticketMedio': ticketMedio,
      'valorVendaAtual': valorVendaAtual,
      'itensVendaAtual': itensVendaAtual,
      'eventosComErro': eventosComErro,
      'receitaComVendaAtual': receitaComVendaAtual,
      'metaFinanceira': metaFinanceira,
      'percentualMeta': percentualMeta,
    };
  }

  List<Map<String, dynamic>> _eventosVendaBackend() {
    return _notificacoes
        .where((Map<String, dynamic> evento) => _isEventoVenda(evento))
        .toList(growable: false);
  }

  bool _isEventoVenda(Map<String, dynamic> evento) {
    final String tipoEvento =
        (evento['tipoDeEvento'] ?? evento['tipo'] ?? '')
            .toString()
            .toUpperCase();
    final String canal = (evento['canal'] ?? '').toString().toUpperCase();
    final String mensagem = (evento['mensagem'] ?? '').toString().toUpperCase();
    return tipoEvento.contains('VENDA') ||
        canal.contains('VENDA') ||
        mensagem.contains('VENDA');
  }

  bool _isEventoErro(Map<String, dynamic> evento) {
    final String status = (evento['status'] ?? '').toString().toUpperCase();
    final String tipoEvento =
        (evento['tipoDeEvento'] ?? evento['tipo'] ?? '')
            .toString()
            .toUpperCase();
    return status.contains('ERRO') || tipoEvento.contains('ERRO');
  }

  DateTime? _extrairDataEvento(Map<String, dynamic> evento) {
    final dynamic recebidoEmIso =
        evento['recebidoEmIso'] ?? evento['recebidoEm'];
    if (recebidoEmIso == null) {
      return null;
    }
    return DateTime.tryParse(recebidoEmIso.toString())?.toLocal();
  }

  double _extrairValorMonetarioEvento(Map<String, dynamic> evento) {
    const List<String> chavesValor = <String>[
      'valorTotal',
      'valorDaVenda',
      'valorVenda',
      'totalVenda',
      'valorOperacao',
      'valorRecebido',
      'valor',
      'total',
    ];

    for (final String chave in chavesValor) {
      final double valor = _toDoubleValor(evento[chave]);
      if (valor > 0) {
        return valor;
      }
    }

    return 0;
  }

  double _toDoubleValor(dynamic valor) {
    if (valor == null) {
      return 0;
    }

    if (valor is num) {
      return valor.toDouble();
    }

    final String bruto = valor.toString().trim();
    if (bruto.isEmpty) {
      return 0;
    }

    String normalizado = bruto.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (normalizado.isEmpty) {
      return 0;
    }

    final bool temVirgula = normalizado.contains(',');
    final bool temPonto = normalizado.contains('.');

    if (temVirgula && temPonto) {
      if (normalizado.lastIndexOf(',') > normalizado.lastIndexOf('.')) {
        normalizado = normalizado.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalizado = normalizado.replaceAll(',', '');
      }
    } else if (temVirgula) {
      normalizado = normalizado.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(normalizado) ?? 0;
  }

  List<double> _serieFinanceiraUltimosSeisMeses() {
    final DateTime now = DateTime.now();
    final List<DateTime> meses = List<DateTime>.generate(6, (int index) {
      return DateTime(now.year, now.month - (5 - index), 1);
    });
    final List<double> serie = List<double>.filled(meses.length, 0);
    final List<Map<String, dynamic>> eventosVenda = _eventosVendaBackend();

    for (final Map<String, dynamic> evento in eventosVenda) {
      final DateTime? data = _extrairDataEvento(evento);
      if (data == null) {
        continue;
      }
      final double valor = _extrairValorMonetarioEvento(evento);
      if (valor <= 0) {
        continue;
      }

      for (int index = 0; index < meses.length; index++) {
        if (meses[index].year == data.year &&
            meses[index].month == data.month) {
          serie[index] += valor;
          break;
        }
      }
    }

    final double valorVendaAtual = _calcularTotal();
    if (valorVendaAtual > 0) {
      serie[serie.length - 1] += valorVendaAtual;
    }

    return serie;
  }

  List<String> _labelsMesesUltimosSeis() {
    const List<String> mesesNome = <String>[
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    final DateTime now = DateTime.now();
    return List<String>.generate(6, (int index) {
      final DateTime data = DateTime(now.year, now.month - (5 - index), 1);
      return mesesNome[data.month - 1];
    });
  }

  Map<String, double> _vendasPorCanal() {
    final Map<String, double> acumulado = <String, double>{};
    final List<Map<String, dynamic>> eventosVenda = _eventosVendaBackend();

    for (final Map<String, dynamic> evento in eventosVenda) {
      final String canal = _normalizarRotuloCanal(
        evento['canalVenda']?.toString() ??
            evento['origem']?.toString() ??
            evento['canal']?.toString(),
      );
      final double valor = _extrairValorMonetarioEvento(evento);
      acumulado[canal] = (acumulado[canal] ?? 0) + (valor > 0 ? valor : 1);
    }

    if (acumulado.isEmpty) {
      final double valorVendaAtual = _calcularTotal();
      if (valorVendaAtual > 0) {
        acumulado['PDV atual'] = valorVendaAtual;
      } else {
        acumulado['Sem vendas'] = 1;
      }
    }

    final List<MapEntry<String, double>> ordenado =
        acumulado.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
            return b.value.compareTo(a.value);
          });

    return Map<String, double>.fromEntries(ordenado.take(4));
  }

  String _normalizarRotuloCanal(String? rawCanal) {
    final String canal = rawCanal?.trim() ?? '';
    if (canal.isEmpty) {
      return 'PDV';
    }

    final String upper = canal.toUpperCase();
    if (upper.contains('WHATS')) return 'WhatsApp';
    if (upper.contains('SITE') || upper.contains('WEB')) return 'Site';
    if (upper.contains('LOJA') || upper.contains('PDV')) return 'Loja';
    if (upper.contains('B2B')) return 'B2B';
    return canal;
  }

  Map<String, double> _composicaoFinanceiraAtual() {
    double totalProdutos = 0;
    double totalServicos = 0;

    for (final Map<String, dynamic> item in _produtosSelecionados) {
      final double subtotal = _calcularSubtotal(item);
      if (_ehServicoItem(item)) {
        totalServicos += subtotal;
      } else {
        totalProdutos += subtotal;
      }
    }

    final double totalConfirmado = _eventosVendaBackend().fold<double>(
      0,
      (double soma, Map<String, dynamic> evento) =>
          soma + _extrairValorMonetarioEvento(evento),
    );

    final Map<String, double> composicao = <String, double>{};
    if (totalConfirmado > 0) {
      composicao['Confirmado backend'] = totalConfirmado;
    }
    if (totalProdutos > 0) {
      composicao['Produtos no carrinho'] = totalProdutos;
    }
    if (totalServicos > 0) {
      composicao['Serviços no carrinho'] = totalServicos;
    }
    if (composicao.isEmpty) {
      composicao['Sem dados'] = 1;
    }
    return composicao;
  }

  String _formatNumeroCompacto(double valor) {
    final double abs = valor.abs();
    if (abs >= 1000000) {
      return '${(valor / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '${(valor / 1000).toStringAsFixed(1)}k';
    }
    return valor.toStringAsFixed(0);
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
        'descricao':
            'Aponta gargalos de atendimento que afetam NPS e recompra.',
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
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.52,
              ),
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
