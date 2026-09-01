import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/estoque_dashboard_model.dart';
import 'package:sixpos/data/models/stock_movement_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/screens/stock_movement_web_dialog.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

class EstoqueDashboardWebPage extends StatefulWidget {
  const EstoqueDashboardWebPage({
    super.key,
    this.onBack,
    this.onEntradaEstoque,
    this.onSaidaEstoque,
    this.onAjusteEstoque,
    this.onOpenListaCompleta,
  });

  final VoidCallback? onBack;
  final VoidCallback? onEntradaEstoque;
  final VoidCallback? onSaidaEstoque;
  final VoidCallback? onAjusteEstoque;
  final VoidCallback? onOpenListaCompleta;

  @override
  State<EstoqueDashboardWebPage> createState() =>
      _EstoqueDashboardWebPageState();
}

class _EstoqueDashboardWebPageState extends State<EstoqueDashboardWebPage> {
  final ProdutoService _produtoService = ProdutoService();
  late Future<EstoqueDashboardModel> _future;
  final NumberFormat _money = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
  );
  final NumberFormat _number = NumberFormat.decimalPattern('pt_BR');
  final DateFormat _date = DateFormat('dd/MM HH:mm', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _future = _produtoService.buscarDashboardEstoque();
  }

  void _reload() =>
      setState(() => _future = _produtoService.buscarDashboardEstoque());

  Future<void> _openMovement(StockMovementType type) async {
    final bool? registered = await showStockMovementWebDialog(
      context: context,
      type: type,
      produtoService: _produtoService,
    );
    if (registered != true || !mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t(
            'stockMovement.success',
            fallback: 'Movimentação registrada. O estoque foi atualizado.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  String _currency(double value) => _money.format(value);
  String _whole(double value) => _number.format(value.round());
  String _qty(double value) =>
      value == value.roundToDouble()
          ? _number.format(value.toInt())
          : value.toStringAsFixed(2).replaceAll('.', ',');

  ButtonStyle _headerOutlinedButtonStyle(WebThemeTokens tokens) {
    return OutlinedButton.styleFrom(
      foregroundColor: tokens.info,
      backgroundColor: tokens.surface,
      side: BorderSide(color: tokens.cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.workspaceBackground,
      child: FutureBuilder<EstoqueDashboardModel>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<EstoqueDashboardModel> snapshot,
        ) {
          final Widget child;
          if (snapshot.connectionState == ConnectionState.waiting) {
            child = _loading();
          } else if (snapshot.hasError) {
            child = _error(snapshot.error);
          } else {
            final EstoqueDashboardModel data = snapshot.data ?? _empty();
            child = data.isEmpty ? _emptyState() : _dashboard(data);
          }

          return Column(
            children: <Widget>[
              SixWebDashboardHeader(
                icon: Icons.warehouse_outlined,
                title: 'Estoque',
                subtitle:
                    'Controle operacional de saldos, reposição, rupturas e movimentações do estoque.',
                onBack: widget.onBack,
                actions: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Atualizar'),
                    style: _headerOutlinedButtonStyle(tokens),
                  ),
                  FilledButton.icon(
                    onPressed:
                        widget.onEntradaEstoque ??
                        () => _openMovement(StockMovementType.entry),
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Entrada'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        widget.onSaidaEstoque ??
                        () => _openMovement(StockMovementType.exit),
                    icon: const Icon(Icons.indeterminate_check_box_outlined),
                    label: const Text('Saída'),
                    style: _headerOutlinedButtonStyle(tokens),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenListaCompleta,
                    icon: const Icon(Icons.table_rows_rounded),
                    label: const Text('Produtos'),
                    style: _headerOutlinedButtonStyle(tokens),
                  ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  EstoqueDashboardModel _empty() => const EstoqueDashboardModel(
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
    situacaoEstoque: <EstoqueDashboardSerieItem>[],
    valorEstoquePorCategoria: <EstoqueDashboardSerieItem>[],
    produtosParaReposicao: <EstoqueDashboardProdutoItem>[],
    produtosComErroEstoque: <EstoqueDashboardProdutoItem>[],
    produtosMaiorValorParado: <EstoqueDashboardProdutoItem>[],
    movimentacoesRecentes: <EstoqueDashboardMovimentoItem>[],
    alertas: <EstoqueDashboardAlerta>[],
  );

  Widget _loading() => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool compact = constraints.maxWidth < 1180;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            _loadingKpis(compact),
            const SizedBox(height: 18),
            sixWebResponsiveGroup(
              compact: compact,
              children: const <Widget>[
                SixWebLoadingBlock(height: 280),
                SixWebLoadingBlock(height: 280),
              ],
            ),
            const SizedBox(height: 18),
            sixWebResponsiveGroup(
              compact: compact,
              children: const <Widget>[
                SixWebLoadingBlock(height: 240),
                SixWebLoadingBlock(height: 240),
              ],
            ),
            const SizedBox(height: 18),
            const SixWebLoadingBlock(height: 240),
          ],
        ),
      );
    },
  );

  Widget _loadingKpis(bool compact) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 8,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: compact ? 2 : 4,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      mainAxisExtent: 118,
    ),
    itemBuilder:
        (BuildContext context, int index) => SixWebEntry(
          order: index,
          child: SixWebLoadingBlock(height: 118, highlight: index == 0),
        ),
  );

  Widget _dashboard(EstoqueDashboardModel data) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool compact = constraints.maxWidth < 1180;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _kpis(data, compact),
            const SizedBox(height: 18),
            sixWebResponsiveGroup(
              compact: compact,
              children: <Widget>[
                SixWebEntry(
                  order: 8,
                  child: _serieCard(
                    'Situação do estoque',
                    'Distribuição dos produtos por risco operacional.',
                    data.situacaoEstoque,
                    false,
                  ),
                ),
                SixWebEntry(
                  order: 9,
                  child: _serieCard(
                    'Valor por categoria',
                    'Onde está concentrado o dinheiro parado em estoque.',
                    data.valorEstoquePorCategoria,
                    true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            sixWebResponsiveGroup(
              compact: compact,
              children: <Widget>[
                SixWebEntry(order: 10, child: _alerts(data.alertas)),
                SixWebEntry(
                  order: 11,
                  child: _productsToReplenish(data.produtosParaReposicao),
                ),
              ],
            ),
            const SizedBox(height: 18),
            sixWebResponsiveGroup(
              compact: compact,
              children: <Widget>[
                SixWebEntry(
                  order: 12,
                  child: _stockErrors(data.produtosComErroEstoque),
                ),
                SixWebEntry(
                  order: 13,
                  child: _stockValue(data.produtosMaiorValorParado),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SixWebEntry(
              order: 14,
              child: _movements(data.movimentacoesRecentes),
            ),
          ],
        ),
      );
    },
  );

  Widget _kpis(EstoqueDashboardModel data, bool compact) {
    final List<_Kpi> items = <_Kpi>[
      _Kpi(
        Icons.payments_outlined,
        'Valor total em estoque',
        data.valorTotalEstoque,
        _currency,
        true,
      ),
      _Kpi(
        Icons.inventory_2_outlined,
        'Quantidade total',
        data.quantidadeTotalEstoque,
        _qty,
      ),
      _Kpi(
        Icons.widgets_outlined,
        'Produtos cadastrados',
        data.totalProdutos.toDouble(),
        _whole,
      ),
      _Kpi(
        Icons.production_quantity_limits_outlined,
        'Abaixo do mínimo',
        data.produtosAbaixoMinimo.toDouble(),
        _whole,
      ),
      _Kpi(
        Icons.remove_shopping_cart_outlined,
        'Sem estoque',
        data.produtosSemEstoque.toDouble(),
        _whole,
      ),
      _Kpi(
        Icons.report_problem_outlined,
        'Estoque negativo',
        data.produtosEstoqueNegativo.toDouble(),
        _whole,
      ),
      _Kpi(
        Icons.unarchive_outlined,
        'Acima do máximo',
        data.produtosAcimaMaximo.toDouble(),
        _whole,
      ),
      _Kpi(
        Icons.history_toggle_off_outlined,
        'Sem movimentação',
        data.produtosSemMovimentacao.toDouble(),
        _whole,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 118,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _Kpi kpi = items[index];
        return SixWebEntry(
          order: index,
          child: SixWebKpiCard(
            icon: kpi.icon,
            label: kpi.label,
            value: kpi.value,
            formatter: kpi.formatter,
            highlight: kpi.highlight,
          ),
        );
      },
    );
  }

  Widget _serieCard(
    String title,
    String subtitle,
    List<EstoqueDashboardSerieItem> items,
    bool useValue,
  ) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<EstoqueDashboardSerieItem> visible =
        items
            .where(
              (EstoqueDashboardSerieItem item) =>
                  useValue ? item.valor > 0 : item.quantidade > 0,
            )
            .take(6)
            .toList();
    final double maxValue = visible.fold<double>(0, (
      double max,
      EstoqueDashboardSerieItem item,
    ) {
      final double value = useValue ? item.valor : item.quantidade;
      return value > max ? value : max;
    });
    return SixWebSectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.insights_outlined,
      child:
          visible.isEmpty
              ? const SixWebNoData(height: 180)
              : Column(
                children:
                    visible.asMap().entries.map((
                      MapEntry<int, EstoqueDashboardSerieItem> entry,
                    ) {
                      final EstoqueDashboardSerieItem item = entry.value;
                      final double value =
                          useValue ? item.valor : item.quantidade;
                      final double percent =
                          maxValue <= 0
                              ? 0
                              : (value / maxValue).clamp(0.0, 1.0).toDouble();
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == visible.length - 1 ? 0 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  useValue ? _compactMoney(value) : _qty(value),
                                  style: TextStyle(
                                    color:
                                        useValue
                                            ? tokens.primaryText
                                            : _stockSerieColor(item.label),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TweenAnimationBuilder<double>(
                              key: ValueKey<String>(
                                '$title:${item.label}:$value',
                              ),
                              tween: Tween<double>(begin: 0, end: percent),
                              duration: Duration(
                                milliseconds: 650 + (entry.key * 90),
                              ),
                              curve: Curves.easeOutCubic,
                              builder:
                                  (
                                    BuildContext context,
                                    double progress,
                                    Widget? child,
                                  ) => ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 12,
                                      backgroundColor: tokens.surfaceMuted,
                                      color:
                                          useValue
                                              ? tokens.info
                                              : _stockSerieColor(item.label),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
    );
  }

  Widget _alerts(List<EstoqueDashboardAlerta> alerts) {
    final ThemeData theme = Theme.of(context);
    return SixWebSectionCard(
      title: 'Alertas de estoque',
      icon: Icons.tips_and_updates_outlined,
      child:
          alerts.isEmpty
              ? const SixWebNoData(text: 'Nenhum alerta de estoque encontrado.')
              : Column(
                children:
                    alerts
                        .map(
                          (EstoqueDashboardAlerta alert) => _notice(
                            icon: _alertIcon(alert.tipo),
                            color: _alertColor(theme, alert.tipo),
                            title: alert.titulo,
                            subtitle: alert.descricao,
                            value: _whole(alert.quantidade.toDouble()),
                          ),
                        )
                        .toList(),
              ),
    );
  }

  Widget _productsToReplenish(List<EstoqueDashboardProdutoItem> items) =>
      SixWebSectionCard(
        title: 'Produtos para reposição',
        icon: Icons.add_shopping_cart_outlined,
        child:
            items.isEmpty
                ? const SixWebNoData(text: 'Nenhum produto abaixo do mínimo.')
                : Column(
                  children:
                      items
                          .map(
                            (EstoqueDashboardProdutoItem item) =>
                                _productTile(item, valueMode: false),
                          )
                          .toList(),
                ),
      );

  Widget _stockErrors(List<EstoqueDashboardProdutoItem> items) =>
      SixWebSectionCard(
        title: 'Erros e excessos de estoque',
        icon: Icons.report_problem_outlined,
        child:
            items.isEmpty
                ? const SixWebNoData(
                  text: 'Nenhum erro operacional identificado.',
                )
                : Column(
                  children:
                      items
                          .map(
                            (EstoqueDashboardProdutoItem item) =>
                                _productTile(item, valueMode: false),
                          )
                          .toList(),
                ),
      );

  Widget _stockValue(List<EstoqueDashboardProdutoItem> items) =>
      SixWebSectionCard(
        title: 'Maior valor parado',
        icon: Icons.account_balance_wallet_outlined,
        child:
            items.isEmpty
                ? const SixWebNoData()
                : Column(
                  children:
                      items
                          .map(
                            (EstoqueDashboardProdutoItem item) =>
                                _productTile(item, valueMode: true),
                          )
                          .toList(),
                ),
      );

  Widget _productTile(
    EstoqueDashboardProdutoItem item, {
    required bool valueMode,
  }) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color stateColor =
        valueMode ? tokens.info : _stockProblemColor(item.problema);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            valueMode ? Icons.paid_outlined : Icons.inventory_2_outlined,
            color: stateColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.nome.isEmpty ? 'Produto sem nome' : item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.categoria} • Atual ${_qty(item.quantidadeEstoque)} • Mín. ${_qty(item.estoqueMinimo)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                valueMode ? _currency(item.valorEstoque) : item.problema,
                style: TextStyle(
                  color: valueMode ? tokens.primaryText : stateColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valueMode
                    ? 'Custo ${_currency(item.ultimoCusto)}'
                    : 'Dif. ${_qty(item.diferencaParaMinimo)}',
                style: TextStyle(
                  color: tokens.secondaryText,
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

  Widget _movements(List<EstoqueDashboardMovimentoItem> items) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return SixWebSectionCard(
      title: 'Movimentações recentes',
      icon: Icons.swap_vert_rounded,
      child:
          items.isEmpty
              ? const SixWebNoData(text: 'Nenhuma movimentação encontrada.')
              : Column(
                children:
                    items.map((EstoqueDashboardMovimentoItem item) {
                      final bool entrada = item.tipo.toUpperCase().contains(
                        'ENTRADA',
                      );
                      final Color color =
                          entrada ? tokens.success : tokens.danger;
                      return _notice(
                        icon:
                            entrada
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                        color: color,
                        title: item.nomeProduto,
                        subtitle:
                            '${item.categoria} • ${item.tipo} • ${_dateLabel(item.dataCadastro)}',
                        value: _qty(item.quantidade),
                      );
                    }).toList(),
              ),
    );
  }

  Widget _notice({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(Object? error) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tokens.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.danger.withValues(alpha: 0.28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 42, color: tokens.danger),
            const SizedBox(height: 14),
            Text(
              'Não foi possível carregar o estoque.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.secondaryText,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.warehouse_outlined, size: 48, color: tokens.info),
            const SizedBox(height: 14),
            Text(
              'Nenhum produto em estoque ainda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre produtos e entradas para acompanhar reposição, rupturas, excessos e movimentações.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.secondaryText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  widget.onEntradaEstoque ??
                  () => _openMovement(StockMovementType.entry),
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Registrar entrada'),
            ),
          ],
        ),
      ),
    );
  }

  String _compactMoney(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
    }

    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  String _dateLabel(DateTime? value) =>
      value == null ? '-' : _date.format(value);

  Color _alertColor(ThemeData theme, String tipo) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    switch (tipo.toUpperCase()) {
      case 'CRITICO':
      case 'ALTO':
        return tokens.stockCritical;
      case 'MEDIO':
        return tokens.stockWarning;
      case 'OK':
        return tokens.success;
      default:
        return tokens.info;
    }
  }

  Color _stockSerieColor(String label) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String normalized = label.toUpperCase();
    if (normalized.contains('NEGAT') || normalized.contains('SEM ESTOQUE')) {
      return tokens.stockCritical;
    }
    if (normalized.contains('ABAIX') || normalized.contains('MIN')) {
      return tokens.stockWarning;
    }
    return tokens.info;
  }

  Color _stockProblemColor(String problema) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String normalized = problema.toUpperCase();
    if (normalized.contains('NEGAT') || normalized.contains('SEM')) {
      return tokens.stockCritical;
    }
    if (normalized.contains('BAIX') || normalized.contains('MIN')) {
      return tokens.stockWarning;
    }
    return tokens.statusNeutral;
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
  const _Kpi(
    this.icon,
    this.label,
    this.value,
    this.formatter, [
    this.highlight = false,
  ]);
  final IconData icon;
  final String label;
  final double value;
  final SixWebMetricFormatter formatter;
  final bool highlight;
}
