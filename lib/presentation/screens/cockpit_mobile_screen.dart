import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CockpitMobileScreen extends StatefulWidget {
  const CockpitMobileScreen({super.key});

  @override
  State<CockpitMobileScreen> createState() => _CockpitMobileScreenState();
}

class _CockpitMobileScreenState extends State<CockpitMobileScreen> {
  int _opcaoSelecionada = 0;

  final List<Map<String, dynamic>> _opcoesCockpit = const [
    {
      'titulo': 'Rentabilidade por cliente',
      'descricao': 'Identifica clientes que compram muito e deixam pouca margem.'
    },
    {
      'titulo': 'Conversao de orcamento em venda',
      'descricao': 'Mostra gargalos entre proposta enviada e fechamento.'
    },
    {
      'titulo': 'SLA de atendimento',
      'descricao': 'Monitora tempo de resposta e impacto na satisfacao do cliente.'
    },
    {
      'titulo': 'Risco de churn',
      'descricao': 'Sinaliza clientes com queda de compra e aumento de reclamacoes.'
    },
  ];

  final List<FlSpot> _faturamentoSpots = const [
    FlSpot(0, 74),
    FlSpot(1, 81),
    FlSpot(2, 88),
    FlSpot(3, 93),
    FlSpot(4, 102),
    FlSpot(5, 109),
  ];

  final List<FlSpot> _metaSpots = const [
    FlSpot(0, 80),
    FlSpot(1, 85),
    FlSpot(2, 90),
    FlSpot(3, 95),
    FlSpot(4, 100),
    FlSpot(5, 105),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cockpit estrategico'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContextoCard(),
            const SizedBox(height: 12),
            _buildKpis(),
            const SizedBox(height: 20),
            _buildSectionTitle('Financeiro e vendas'),
            const SizedBox(height: 10),
            _buildFaturamentoVsMetaChart(),
            const SizedBox(height: 16),
            _buildVendasPorCanalChart(),
            const SizedBox(height: 20),
            _buildSectionTitle('Atendimento e experiencia do cliente'),
            const SizedBox(height: 10),
            _buildSatisfacaoChart(),
            const SizedBox(height: 20),
            _buildSectionTitle('Opcoes de analise (exemplo)'),
            const SizedBox(height: 8),
            _buildOpcoesExemplo(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContextoCard() {
    return Card(
      color: const Color(0xFFEEF7FF),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights, color: Color(0xFF0A5A9C)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Painel orientado a resultado: cruza caixa, margem, vendas e atendimento para apoiar decisoes de crescimento com rentabilidade.',
                style: TextStyle(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpis() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: const [
        _KpiCard(
          title: 'Receita liquida',
          value: 'R\$ 109.400',
          delta: '+9.8% vs mes anterior',
          icon: Icons.payments_outlined,
          color: Color(0xFF0E7490),
        ),
        _KpiCard(
          title: 'Margem operacional',
          value: '22.4%',
          delta: '+1.9 p.p.',
          icon: Icons.trending_up,
          color: Color(0xFF0F766E),
        ),
        _KpiCard(
          title: 'Ticket medio',
          value: 'R\$ 284',
          delta: '+6.1%',
          icon: Icons.shopping_bag_outlined,
          color: Color(0xFF1D4ED8),
        ),
        _KpiCard(
          title: 'NPS atendimento',
          value: '71',
          delta: 'Meta 75',
          icon: Icons.support_agent,
          color: Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildFaturamentoVsMetaChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faturamento x Meta (R\$ mil)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 5,
                  minY: 60,
                  maxY: 120,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE5E7EB),
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
                        reservedSize: 36,
                        interval: 20,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const meses = ['Nov', 'Dez', 'Jan', 'Fev', 'Mar', 'Abr'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              meses[value.toInt()],
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _metaSpots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.orange.shade700,
                      dashArray: [6, 3],
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: _faturamentoSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFF0F766E),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                _LegendDot(color: Color(0xFF0F766E), label: 'Faturamento'),
                SizedBox(width: 16),
                _LegendDot(color: Colors.orange, label: 'Meta'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendasPorCanalChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendas por canal (ultimos 30 dias)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  maxY: 120,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE5E7EB),
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
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const labels = ['Loja', 'Whats', 'Site', 'B2B'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: 95, color: const Color(0xFF0EA5E9), width: 18),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(toY: 72, color: const Color(0xFF14B8A6), width: 18),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(toY: 58, color: const Color(0xFF6366F1), width: 18),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(toY: 44, color: const Color(0xFFF59E0B), width: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSatisfacaoChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 36,
                    sectionsSpace: 2,
                    sections: [
                      PieChartSectionData(
                        value: 56,
                        color: const Color(0xFF16A34A),
                        title: '56%',
                        radius: 44,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      PieChartSectionData(
                        value: 26,
                        color: const Color(0xFFF59E0B),
                        title: '26%',
                        radius: 44,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      PieChartSectionData(
                        value: 18,
                        color: const Color(0xFFEF4444),
                        title: '18%',
                        radius: 44,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualidade do atendimento',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  _LegendDot(color: Color(0xFF16A34A), label: 'Satisfeitos'),
                  SizedBox(height: 6),
                  _LegendDot(color: Color(0xFFF59E0B), label: 'Neutros'),
                  SizedBox(height: 6),
                  _LegendDot(color: Color(0xFFEF4444), label: 'Insatisfeitos'),
                  SizedBox(height: 12),
                  Text(
                    'Dor coberta: queda de recompra por atendimento lento ou inconsistente.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcoesExemplo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(_opcoesCockpit.length, (index) {
            final bool selected = _opcaoSelecionada == index;
            return ChoiceChip(
              label: Text(_opcoesCockpit[index]['titulo'] as String),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _opcaoSelecionada = index;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _opcoesCockpit[_opcaoSelecionada]['descricao'] as String,
              style: const TextStyle(height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12)),
            const Spacer(),
            Text(
              delta,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
