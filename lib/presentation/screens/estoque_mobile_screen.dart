import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/estoque_dashboard_model.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/produto_list_mobile_screen.dart';

class EstoqueMobileScreen extends StatefulWidget {
  const EstoqueMobileScreen({super.key});

  @override
  State<EstoqueMobileScreen> createState() => _EstoqueMobileScreenState();
}

class _EstoqueMobileScreenState extends State<EstoqueMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  final ProdutoService _produtoService = ProdutoService();
  late Future<EstoqueDashboardModel> _dashboardFuture;

  final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final NumberFormat _numberFormat = NumberFormat.decimalPattern('pt_BR');
  final DateFormat _dateFormat = DateFormat('dd/MM HH:mm', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _produtoService.buscarDashboardEstoque();
  }

  Future<void> _reload() async {
    setState(() {
      _dashboardFuture = _produtoService.buscarDashboardEstoque();
    });
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Estoque',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<EstoqueDashboardModel>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(onRetry: _reload);
          }

          final dashboard = snapshot.data ?? _emptyDashboard();
          if (dashboard.isEmpty) {
            return _EmptyInventoryState(onRefresh: _reload);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                SixStaggeredEntry(child: _buildHeaderCard()),
                const SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 70),
                  child: _buildActions(),
                ),
                const SizedBox(height: 18),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 120),
                  child: _buildKpis(dashboard),
                ),
                const SizedBox(height: 22),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 170),
                  child: _buildProgressSection(
                    title: 'Situação do estoque',
                    subtitle: 'Distribuição dos produtos por risco operacional.',
                    icon: Icons.donut_large_rounded,
                    items: dashboard.situacaoEstoque,
                    useValue: false,
                    emptyText: 'Sem dados de situação do estoque.',
                  ),
                ),
                const SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 220),
                  child: _buildProgressSection(
                    title: 'Valor por categoria',
                    subtitle: 'Onde está concentrado o dinheiro parado em estoque.',
                    icon: Icons.bar_chart_rounded,
                    items: dashboard.valorEstoquePorCategoria,
                    useValue: true,
                    emptyText: 'Sem valores por categoria.',
                  ),
                ),
                const SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 270),
                  child: _buildAlerts(dashboard.alertas),
                ),
                const SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 320),
                  child: _buildProductSection(
                    title: 'Produtos para reposição',
                    subtitle: 'Itens abaixo do mínimo ou sem estoque.',
                    icon: Icons.add_shopping_cart_outlined,
                    items: dashboard.produtosParaReposicao,
                    emptyText: 'Nenhum produto abaixo do mínimo.',
                    valueMode: _ProductValueMode.reposition,
                  ),
                ),
                const SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 370),
                  child: _buildProductSection(
                    title: 'Erros e excessos',
                    subtitle: 'Estoque negativo ou acima do máximo configurado.',
                    icon: Icons.report_problem_outlined,
                    items: dashboard.produtosComErroEstoque,
                    emptyText: 'Nenhum erro operacional identificado.',
                    valueMode: _ProductValueMode.reposition,
                  ),
                ),
                const SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 420),
                  child: _buildProductSection(
                    title: 'Maior valor parado',
                    subtitle: 'Produtos que concentram mais dinheiro em estoque.',
                    icon: Icons.account_balance_wallet_outlined,
                    items: dashboard.produtosMaiorValorParado,
                    emptyText: 'Sem produtos com valor parado.',
                    valueMode: _ProductValueMode.value,
                  ),
                ),
                const SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 470),
                  child: _buildMovements(dashboard.movimentacoesRecentes),
                ),
              ],
            ),
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
      situacaoEstoque: [],
      valorEstoquePorCategoria: [],
      produtosParaReposicao: [],
      produtosComErroEstoque: [],
      produtosMaiorValorParado: [],
      movimentacoesRecentes: [],
      alertas: [],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Icon(Icons.warehouse_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Controle de estoque',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Saldos, reposição, rupturas e movimentações do comércio.',
                  style: TextStyle(color: Color(0xFFD7E3F5), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Entrada',
            icon: Icons.add_box_outlined,
            onTap: _showFeatureInProgress,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Saída',
            icon: Icons.indeterminate_check_box_outlined,
            onTap: _showFeatureInProgress,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Produtos',
            icon: Icons.table_rows_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProdutolistMobileScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpis(EstoqueDashboardModel dashboard) {
    final items = [
      _Kpi(Icons.payments_outlined, 'Valor em estoque', _money(dashboard.valorTotalEstoque), true),
      _Kpi(Icons.inventory_2_outlined, 'Quantidade total', _qty(dashboard.quantidadeTotalEstoque)),
      _Kpi(Icons.production_quantity_limits_outlined, 'Abaixo do mínimo', _numberFormat.format(dashboard.produtosAbaixoMinimo)),
      _Kpi(Icons.remove_shopping_cart_outlined, 'Sem estoque', _numberFormat.format(dashboard.produtosSemEstoque)),
      _Kpi(Icons.report_problem_outlined, 'Estoque negativo', _numberFormat.format(dashboard.produtosEstoqueNegativo)),
      _Kpi(Icons.unarchive_outlined, 'Acima do máximo', _numberFormat.format(dashboard.produtosAcimaMaximo)),
      _Kpi(Icons.history_toggle_off_outlined, 'Sem movimentação', _numberFormat.format(dashboard.produtosSemMovimentacao)),
      _Kpi(Icons.swap_vert_rounded, 'Entradas/Saídas', '${_numberFormat.format(dashboard.entradasRecentes)} / ${_numberFormat.format(dashboard.saidasRecentes)}'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(width: width, child: _KpiCard(item: item));
          }).toList(),
        );
      },
    );
  }

  Widget _buildProgressSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<EstoqueDashboardSerieItem> items,
    required bool useValue,
    required String emptyText,
  }) {
    final filtered = items
        .where((item) => useValue ? item.valor > 0 : item.quantidade > 0)
        .take(6)
        .toList();

    final maxValue = filtered.fold<double>(0, (max, item) {
      final value = useValue ? item.valor : item.quantidade;
      return value > max ? value : max;
    });

    return _SectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: filtered.isEmpty
          ? _NoData(text: emptyText)
          : Column(
              children: filtered.asMap().entries.map((entry) {
                final item = entry.value;
                final rawValue = useValue ? item.valor : item.quantidade;
                final valueLabel = useValue ? _money(item.valor) : _qty(item.quantidade);
                final percent = maxValue <= 0 ? 0.0 : rawValue / maxValue;

                return _ProgressItem(
                  color: _chartColor(entry.key),
                  title: item.label.isEmpty ? 'Sem categoria' : item.label,
                  value: valueLabel,
                  percent: percent,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAlerts(List<EstoqueDashboardAlerta> items) {
    return _SectionCard(
      title: 'Alertas de estoque',
      subtitle: 'Pontos que precisam de atenção operacional.',
      icon: Icons.tips_and_updates_outlined,
      child: items.isEmpty
          ? const _NoData(text: 'Nenhum alerta de estoque.')
          : Column(
              children: items.map((alert) {
                final color = _alertColor(alert.tipo);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_alertIcon(alert.tipo), color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.titulo,
                              style: const TextStyle(
                                color: _titleTextColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.descricao,
                              style: const TextStyle(
                                color: _mutedTextColor,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _numberFormat.format(alert.quantidade),
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<EstoqueDashboardProdutoItem> items,
    required String emptyText,
    required _ProductValueMode valueMode,
  }) {
    return _SectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: items.isEmpty
          ? _NoData(text: emptyText)
          : Column(
              children: items.take(5).map((item) {
                return valueMode == _ProductValueMode.value
                    ? _productValueTile(item)
                    : _productRepositionTile(item);
              }).toList(),
            ),
    );
  }

  Widget _productRepositionTile(EstoqueDashboardProdutoItem item) {
    final normal = item.problema.toLowerCase() == 'normal';
    return _InventoryTile(
      icon: Icons.inventory_2_outlined,
      title: item.nome.isEmpty ? 'Produto sem nome' : item.nome,
      subtitle: '${item.categoria} • Atual ${_qty(item.quantidadeEstoque)} • Mín. ${_qty(item.estoqueMinimo)}',
      trailingTitle: item.problema.isEmpty ? 'Atenção' : item.problema,
      trailingSubtitle: 'Dif. ${_qty(item.diferencaParaMinimo)}',
      trailingColor: normal ? _accentColor : const Color(0xFFDC2626),
    );
  }

  Widget _productValueTile(EstoqueDashboardProdutoItem item) {
    return _InventoryTile(
      icon: Icons.paid_outlined,
      title: item.nome.isEmpty ? 'Produto sem nome' : item.nome,
      subtitle: '${item.categoria} • Qtd ${_qty(item.quantidadeEstoque)} • Custo ${_money(item.ultimoCusto)}',
      trailingTitle: _money(item.valorEstoque),
      trailingSubtitle: item.problema.isEmpty ? 'Valor parado' : item.problema,
      trailingColor: _accentColor,
    );
  }

  Widget _buildMovements(List<EstoqueDashboardMovimentoItem> items) {
    return _SectionCard(
      title: 'Movimentações recentes',
      subtitle: 'Últimas entradas e saídas registradas.',
      icon: Icons.swap_vert_rounded,
      child: items.isEmpty
          ? const _NoData(text: 'Nenhuma movimentação encontrada.')
          : Column(children: items.take(8).map(_movementTile).toList()),
    );
  }

  Widget _movementTile(EstoqueDashboardMovimentoItem item) {
    final entrada = item.tipo.toUpperCase().contains('ENTRADA');
    final color = entrada ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return _InventoryTile(
      icon: entrada ? Icons.add_circle_outline : Icons.remove_circle_outline,
      title: item.nomeProduto.isEmpty ? 'Produto sem nome' : item.nomeProduto,
      subtitle: '${item.categoria} • ${_dateLabel(item.dataCadastro)}',
      trailingTitle: item.tipo,
      trailingSubtitle: _qty(item.quantidade),
      trailingColor: color,
    );
  }

  void _showFeatureInProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fluxo mobile em evolução.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _money(double value) => _moneyFormat.format(value);

  String _qty(double value) {
    if (value == value.roundToDouble()) {
      return _numberFormat.format(value.toInt());
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Sem data';
    return _dateFormat.format(value);
  }

  Color _chartColor(int index) {
    const colors = [
      _accentColor,
      Color(0xFF16A34A),
      Color(0xFFDC2626),
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
    ];
    return colors[index % colors.length];
  }

  Color _alertColor(String tipo) {
    final normalized = tipo.toUpperCase();
    if (normalized.contains('ERRO') || normalized.contains('NEGATIVO')) {
      return const Color(0xFFDC2626);
    }
    if (normalized.contains('SEM') || normalized.contains('MINIMO')) {
      return const Color(0xFFF59E0B);
    }
    return _accentColor;
  }

  IconData _alertIcon(String tipo) {
    final normalized = tipo.toUpperCase();
    if (normalized.contains('ERRO') || normalized.contains('NEGATIVO')) {
      return Icons.error_outline_rounded;
    }
    if (normalized.contains('SEM') || normalized.contains('MINIMO')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.info_outline_rounded;
  }
}

enum _ProductValueMode { reposition, value }

class _Kpi {
  const _Kpi(this.icon, this.label, this.value, [this.highlight = false]);

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final _Kpi item;

  @override
  Widget build(BuildContext context) {
    final background = item.highlight ? const Color(0xFF0B1F3A) : Colors.white;
    final foreground = item.highlight ? Colors.white : const Color(0xFF0F172A);
    final muted = item.highlight ? const Color(0xFFD7E3F5) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.highlight ? const Color(0xFF0B1F3A) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.highlight ? const Color(0x1AFFFFFF) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              color: item.highlight ? Colors.white : const Color(0xFF2563EB),
              size: 21,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: foreground, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 21),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.color,
    required this.title,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String title;
  final String value;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final safePercent = percent < 0.0 ? 0.0 : (percent > 1.0 ? 1.0 : percent);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: safePercent,
              minHeight: 8,
              color: color,
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingTitle,
    required this.trailingSubtitle,
    required this.trailingColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingTitle;
  final String trailingSubtitle;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailingTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: trailingColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                trailingSubtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 42, color: Color(0xFFDC2626)),
              const SizedBox(height: 14),
              const Text(
                'Não foi possível carregar o estoque.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.warehouse_outlined, size: 52, color: Color(0xFF2563EB)),
          SizedBox(height: 14),
          Text(
            'Estoque vazio',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cadastre produtos e movimente o estoque para acompanhar os indicadores.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.35),
          ),
        ],
      ),
    );
  }
}
