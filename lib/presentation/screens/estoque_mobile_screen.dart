import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/estoque_dashboard_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/produto_list_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class EstoqueMobileScreen extends StatefulWidget {
  const EstoqueMobileScreen({super.key});

  @override
  State<EstoqueMobileScreen> createState() => _EstoqueMobileScreenState();
}

class _EstoqueMobileScreenState extends State<EstoqueMobileScreen> {
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  final ProdutoService _produtoService = ProdutoService();
  late Future<EstoqueDashboardModel> _dashboardFuture;

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
    context.watch<LocaleSettingsProvider>();

    return SixMobilePageShell(
      title: _t('estoque.mobile.title', 'Estoque'),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 4,
      scrollEffectOffset: 24,
      scrolledSurfaceOpacity: 0.66,
      actions: [
        IconButton(
          tooltip: _t('estoque.mobile.refresh', 'Atualizar'),
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _reload,
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return FutureBuilder<EstoqueDashboardModel>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.only(top: topInset),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.only(top: topInset),
                child: _ErrorState(onRetry: _reload),
              );
            }

            final dashboard = snapshot.data ?? _emptyDashboard();
            if (dashboard.isEmpty) {
              return _EmptyInventoryState(
                onRefresh: _reload,
                scrollController: scrollController,
                topInset: topInset,
              );
            }

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
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
                      title: _t(
                        'estoque.mobile.stockSituation',
                        'Situação do estoque',
                      ),
                      subtitle: _t(
                        'estoque.mobile.stockSituationSubtitle',
                        'Distribuição dos produtos por risco operacional.',
                      ),
                      icon: Icons.donut_large_rounded,
                      items: dashboard.situacaoEstoque,
                      useValue: false,
                      emptyText: _t(
                        'estoque.mobile.noStockSituationData',
                        'Sem dados de situação do estoque.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 220),
                    child: _buildProgressSection(
                      title: _t(
                        'estoque.mobile.valueByCategory',
                        'Valor por categoria',
                      ),
                      subtitle: _t(
                        'estoque.mobile.valueByCategorySubtitle',
                        'Onde está concentrado o dinheiro parado em estoque.',
                      ),
                      icon: Icons.bar_chart_rounded,
                      items: dashboard.valorEstoquePorCategoria,
                      useValue: true,
                      emptyText: _t(
                        'estoque.mobile.noCategoryValues',
                        'Sem valores por categoria.',
                      ),
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
                      title: _t(
                        'estoque.mobile.productsForRestock',
                        'Produtos para reposição',
                      ),
                      subtitle: _t(
                        'estoque.mobile.productsForRestockSubtitle',
                        'Itens abaixo do mínimo ou sem estoque.',
                      ),
                      icon: Icons.add_shopping_cart_outlined,
                      items: dashboard.produtosParaReposicao,
                      emptyText: _t(
                        'estoque.mobile.noProductsBelowMinimum',
                        'Nenhum produto abaixo do mínimo.',
                      ),
                      valueMode: _ProductValueMode.reposition,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 370),
                    child: _buildProductSection(
                      title: _t(
                        'estoque.mobile.errorsAndExcess',
                        'Erros e excessos',
                      ),
                      subtitle: _t(
                        'estoque.mobile.errorsAndExcessSubtitle',
                        'Estoque negativo ou acima do máximo configurado.',
                      ),
                      icon: Icons.report_problem_outlined,
                      items: dashboard.produtosComErroEstoque,
                      emptyText: _t(
                        'estoque.mobile.noOperationalErrors',
                        'Nenhum erro operacional identificado.',
                      ),
                      valueMode: _ProductValueMode.reposition,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 420),
                    child: _buildProductSection(
                      title: _t(
                        'estoque.mobile.highestIdleValue',
                        'Maior valor parado',
                      ),
                      subtitle: _t(
                        'estoque.mobile.highestIdleValueSubtitle',
                        'Produtos que concentram mais dinheiro em estoque.',
                      ),
                      icon: Icons.account_balance_wallet_outlined,
                      items: dashboard.produtosMaiorValorParado,
                      emptyText: _t(
                        'estoque.mobile.noIdleValueProducts',
                        'Sem produtos com valor parado.',
                      ),
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
        );
      },
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('estoque.mobile.inventoryControl', 'Controle de estoque'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  _t(
                    'estoque.mobile.inventoryControlSubtitle',
                    'Saldos, reposição, rupturas e movimentações do comércio.',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFD7E3F5),
                    height: 1.35,
                  ),
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
            label: _t('estoque.mobile.entry', 'Entrada'),
            icon: Icons.add_box_outlined,
            onTap: _showFeatureInProgress,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: _t('estoque.mobile.exit', 'Saída'),
            icon: Icons.indeterminate_check_box_outlined,
            onTap: _showFeatureInProgress,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: _t('estoque.mobile.products', 'Produtos'),
            icon: Icons.table_rows_rounded,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProdutolistMobileScreen(),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpis(EstoqueDashboardModel dashboard) {
    final items = [
      _Kpi(
        Icons.payments_outlined,
        _t('estoque.mobile.stockValue', 'Valor em estoque'),
        _money(dashboard.valorTotalEstoque),
        true,
      ),
      _Kpi(
        Icons.inventory_2_outlined,
        _t('estoque.mobile.totalQuantity', 'Quantidade total'),
        _qty(dashboard.quantidadeTotalEstoque),
      ),
      _Kpi(
        Icons.production_quantity_limits_outlined,
        _t('estoque.mobile.belowMinimum', 'Abaixo do mínimo'),
        _integer(dashboard.produtosAbaixoMinimo),
      ),
      _Kpi(
        Icons.remove_shopping_cart_outlined,
        _t('estoque.mobile.outOfStock', 'Sem estoque'),
        _integer(dashboard.produtosSemEstoque),
      ),
      _Kpi(
        Icons.report_problem_outlined,
        _t('estoque.mobile.negativeStock', 'Estoque negativo'),
        _integer(dashboard.produtosEstoqueNegativo),
      ),
      _Kpi(
        Icons.unarchive_outlined,
        _t('estoque.mobile.aboveMaximum', 'Acima do máximo'),
        _integer(dashboard.produtosAcimaMaximo),
      ),
      _Kpi(
        Icons.history_toggle_off_outlined,
        _t('estoque.mobile.noMovement', 'Sem movimentação'),
        _integer(dashboard.produtosSemMovimentacao),
      ),
      _Kpi(
        Icons.swap_vert_rounded,
        _t('estoque.mobile.entriesAndExits', 'Entradas/Saídas'),
        '${_integer(dashboard.entradasRecentes)} / ${_integer(dashboard.saidasRecentes)}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              items.map((item) {
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
    final filtered =
        items
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
      child:
          filtered.isEmpty
              ? _NoData(text: emptyText)
              : Column(
                children:
                    filtered.asMap().entries.map((entry) {
                      final item = entry.value;
                      final rawValue = useValue ? item.valor : item.quantidade;
                      final valueLabel =
                          useValue ? _money(item.valor) : _qty(item.quantidade);
                      final percent = maxValue <= 0 ? 0.0 : rawValue / maxValue;

                      return _ProgressItem(
                        color: _chartColor(entry.key),
                        title:
                            item.label.isEmpty
                                ? _t(
                                  'estoque.mobile.noCategory',
                                  'Sem categoria',
                                )
                                : item.label,
                        value: valueLabel,
                        percent: percent,
                      );
                    }).toList(),
              ),
    );
  }

  Widget _buildAlerts(List<EstoqueDashboardAlerta> items) {
    return _SectionCard(
      title: _t('estoque.mobile.stockAlerts', 'Alertas de estoque'),
      subtitle: _t(
        'estoque.mobile.stockAlertsSubtitle',
        'Pontos que precisam de atenção operacional.',
      ),
      icon: Icons.tips_and_updates_outlined,
      child:
          items.isEmpty
              ? _NoData(
                text: _t(
                  'estoque.mobile.noStockAlerts',
                  'Nenhum alerta de estoque.',
                ),
              )
              : Column(
                children:
                    items.map((alert) {
                      final color = _alertColor(alert.tipo);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: color.withValues(alpha: 0.22),
                          ),
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
                              _integer(alert.quantidade),
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
      child:
          items.isEmpty
              ? _NoData(text: emptyText)
              : Column(
                children:
                    items.take(5).map((item) {
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
      title:
          item.nome.isEmpty
              ? _t('estoque.mobile.unnamedProduct', 'Produto sem nome')
              : item.nome,
      subtitle:
          '${item.categoria} • ${_t('estoque.mobile.currentShort', 'Atual')} ${_qty(item.quantidadeEstoque)} • ${_t('estoque.mobile.minimumShort', 'Mín.')} ${_qty(item.estoqueMinimo)}',
      trailingTitle:
          item.problema.isEmpty
              ? _t('estoque.mobile.attention', 'Atenção')
              : item.problema,
      trailingSubtitle:
          '${_t('estoque.mobile.differenceShort', 'Dif.')} ${_qty(item.diferencaParaMinimo)}',
      trailingColor: normal ? _accentColor : const Color(0xFFDC2626),
    );
  }

  Widget _productValueTile(EstoqueDashboardProdutoItem item) {
    return _InventoryTile(
      icon: Icons.paid_outlined,
      title:
          item.nome.isEmpty
              ? _t('estoque.mobile.unnamedProduct', 'Produto sem nome')
              : item.nome,
      subtitle:
          '${item.categoria} • ${_t('estoque.mobile.quantityShort', 'Qtd')} ${_qty(item.quantidadeEstoque)} • ${_t('estoque.mobile.cost', 'Custo')} ${_money(item.ultimoCusto)}',
      trailingTitle: _money(item.valorEstoque),
      trailingSubtitle:
          item.problema.isEmpty
              ? _t('estoque.mobile.idleValue', 'Valor parado')
              : item.problema,
      trailingColor: _accentColor,
    );
  }

  Widget _buildMovements(List<EstoqueDashboardMovimentoItem> items) {
    return _SectionCard(
      title: _t('estoque.mobile.recentMovements', 'Movimentações recentes'),
      subtitle: _t(
        'estoque.mobile.recentMovementsSubtitle',
        'Últimas entradas e saídas registradas.',
      ),
      icon: Icons.swap_vert_rounded,
      child:
          items.isEmpty
              ? _NoData(
                text: _t(
                  'estoque.mobile.noMovements',
                  'Nenhuma movimentação encontrada.',
                ),
              )
              : Column(children: items.take(8).map(_movementTile).toList()),
    );
  }

  Widget _movementTile(EstoqueDashboardMovimentoItem item) {
    final entrada = item.tipo.toUpperCase().contains('ENTRADA');
    final color = entrada ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return _InventoryTile(
      icon: entrada ? Icons.add_circle_outline : Icons.remove_circle_outline,
      title:
          item.nomeProduto.isEmpty
              ? _t('estoque.mobile.unnamedProduct', 'Produto sem nome')
              : item.nomeProduto,
      subtitle: '${item.categoria} • ${_dateLabel(item.dataCadastro)}',
      trailingTitle: item.tipo,
      trailingSubtitle: _qty(item.quantidade),
      trailingColor: color,
    );
  }

  void _showFeatureInProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t('estoque.mobile.featureInProgress', 'Fluxo mobile em evolução.'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _money(double value) {
    return context.read<LocaleSettingsProvider>().formatCurrency(value);
  }

  String _qty(double value) {
    if (value == value.roundToDouble()) {
      return _integer(value);
    }
    final localeSettings = context.read<LocaleSettingsProvider>();
    return _formatDecimalWithLocale(value, localeSettings.decimalPlaces);
  }

  String _integer(num value) {
    return _formatIntegerWithLocale(
      value,
      context.read<LocaleSettingsProvider>(),
    );
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return _t('estoque.mobile.noDate', 'Sem data');
    final localeSettings = context.read<LocaleSettingsProvider>();
    return '${localeSettings.formatDate(value)} ${localeSettings.formatTime(value)}';
  }

  String _t(String key, String fallback) {
    return context.t(key, fallback: fallback);
  }

  String _formatDecimalWithLocale(num value, int decimalPlaces) {
    final localeSettings = context.read<LocaleSettingsProvider>();
    final int casasDecimais = decimalPlaces.clamp(0, 6).toInt();
    final String normalizado = value.toStringAsFixed(casasDecimais);
    final bool negativo = normalizado.startsWith('-');
    final List<String> partes = normalizado.replaceFirst('-', '').split('.');
    final String inteiro = _formatIntegerWithLocale(
      int.tryParse(partes.first) ?? 0,
      localeSettings,
    );
    final String decimal =
        casasDecimais > 0 && partes.length > 1
            ? '${localeSettings.decimalSeparator}${partes[1]}'
            : '';

    return '${negativo ? '-' : ''}$inteiro$decimal';
  }

  String _formatIntegerWithLocale(
    num value,
    LocaleSettingsProvider localeSettings,
  ) {
    final bool negativo = value < 0;
    final String digits = value.abs().round().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(localeSettings.thousandSeparator);
      }
      buffer.write(digits[i]);
    }

    return '${negativo ? '-' : ''}$buffer';
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
    final muted =
        item.highlight ? const Color(0xFFD7E3F5) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              item.highlight
                  ? const Color(0xFF0B1F3A)
                  : const Color(0xFFE2E8F0),
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
              color:
                  item.highlight
                      ? const Color(0x1AFFFFFF)
                      : const Color(0xFFEFF6FF),
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
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

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
              const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 14),
              Text(
                context.t(
                  'estoque.mobile.loadError',
                  fallback: 'Não foi possível carregar o estoque.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.t('common.tryAgain', fallback: 'Tentar novamente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({
    required this.onRefresh,
    required this.scrollController,
    required this.topInset,
  });

  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, topInset + 96, 24, 24),
        children: [
          const Icon(
            Icons.warehouse_outlined,
            size: 52,
            color: SixMobilePalette.accent,
          ),
          const SizedBox(height: 14),
          Text(
            context.t('estoque.mobile.emptyTitle', fallback: 'Estoque vazio'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              'estoque.mobile.emptySubtitle',
              fallback:
                  'Cadastre produtos e movimente o estoque para acompanhar os indicadores.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.35),
          ),
        ],
      ),
    );
  }
}
