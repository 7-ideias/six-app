import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/venda_nao_liquidada_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/caixa/venda_nao_liquidada_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/presentation/components/web/six_web_recebimento_dialog.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class VendasAReceberWebWidget extends StatefulWidget {
  const VendasAReceberWebWidget({super.key, this.onAbrirNoPdv});

  final ValueChanged<VendaNaoLiquidadaModel>? onAbrirNoPdv;

  @override
  State<VendasAReceberWebWidget> createState() =>
      _VendasAReceberWebWidgetState();
}

class _VendasAReceberWebWidgetState extends State<VendasAReceberWebWidget> {
  final VendaNaoLiquidadaApiClient _api = VendaNaoLiquidadaApiClient();
  final AgendaFinanceiraAcoesFinanceiras _acoesFinanceiras =
      AgendaFinanceiraAcoesFinanceiras();
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();

  bool _loading = true;
  bool _processando = false;
  String? _erro;
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now().add(const Duration(days: 30));
  List<VendaNaoLiquidadaModel> _vendas = <VendaNaoLiquidadaModel>[];

  List<VendaNaoLiquidadaModel> get _vendasFiltradas {
    final DateTime inicio = _inicioDoDia(_dataInicio);
    final DateTime fim = _fimDoDia(_dataFim);
    return _vendas
        .where((VendaNaoLiquidadaModel venda) {
          final DateTime? data = venda.dataVencimento ?? venda.dataCompetencia;
          if (data == null) return true;
          return !data.isBefore(inicio) && !data.isAfter(fim);
        })
        .toList(growable: false);
  }

  double get _totalAberto => _vendasFiltradas.fold<double>(
    0,
    (double soma, VendaNaoLiquidadaModel venda) => soma + venda.valorAberto,
  );
  double get _ticketMedio =>
      _vendasFiltradas.isEmpty ? 0 : _totalAberto / _vendasFiltradas.length;
  int get _totalItens => _vendasFiltradas.fold<int>(
    0,
    (int soma, VendaNaoLiquidadaModel venda) =>
        soma +
        venda.itens.fold<int>(
          0,
          (int itens, VendaNaoLiquidadaItemModel item) =>
              itens + item.quantidade,
        ),
  );

  int get _vencidas {
    final DateTime hoje = DateTime.now();
    final DateTime inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    return _vendasFiltradas
        .where(
          (VendaNaoLiquidadaModel venda) =>
              venda.dataVencimento != null &&
              venda.dataVencimento!.isBefore(inicioHoje),
        )
        .length;
  }

  int get _venceHoje {
    final DateTime hoje = DateTime.now();
    return _vendasFiltradas.where((VendaNaoLiquidadaModel venda) {
      final DateTime? vencimento = venda.dataVencimento;
      return vencimento != null &&
          vencimento.year == hoje.year &&
          vencimento.month == hoje.month &&
          vencimento.day == hoje.day;
    }).length;
  }

  double get _previsaoSeteDias {
    final DateTime hoje = _inicioDoDia(DateTime.now());
    final DateTime seteDias = _fimDoDia(hoje.add(const Duration(days: 7)));
    return _vendas
        .where((VendaNaoLiquidadaModel venda) {
          final DateTime? data = venda.dataVencimento ?? venda.dataCompetencia;
          if (data == null) return false;
          return !data.isBefore(hoje) && !data.isAfter(seteDias);
        })
        .fold<double>(
          0,
          (double soma, VendaNaoLiquidadaModel venda) =>
              soma + venda.valorAberto,
        );
  }

  String get _riscoAtraso {
    if (_vencidas >= 5 ||
        (_vendasFiltradas.isNotEmpty &&
            _vencidas / _vendasFiltradas.length >= 0.35)) {
      return context.t('vendasAReceber.riskHigh', fallback: 'Alto');
    }
    if (_vencidas > 0 || _venceHoje > 3) {
      return context.t('vendasAReceber.riskMedium', fallback: 'Médio');
    }
    return context.t('vendasAReceber.riskLow', fallback: 'Baixo');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final List<VendaNaoLiquidadaModel> vendas = await _api.listar();
      if (!mounted) return;
      setState(() => _vendas = vendas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarData({required bool inicio}) async {
    final DateTime dataAtual = inicio ? _dataInicio : _dataFim;
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: dataAtual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selecionada == null) return;
    setState(() {
      if (inicio) {
        _dataInicio = _inicioDoDia(selecionada);
        if (_dataFim.isBefore(_dataInicio)) _dataFim = _dataInicio;
      } else {
        _dataFim = _inicioDoDia(selecionada);
        if (_dataInicio.isAfter(_dataFim)) _dataInicio = _dataFim;
      }
    });
  }

  Future<void> _receberVenda(VendaNaoLiquidadaModel venda) async {
    if (_processando) return;

    final SixWebRecebimentoResultado? resultado =
        await SixWebRecebimentoDialog.show(
          context,
          titulo: 'Receber venda em aberto',
          descricao: venda.descricao,
          contato:
              venda.nomeCliente.trim().isEmpty
                  ? null
                  : venda.nomeCliente.trim(),
          valorAberto: venda.valorAberto,
          codigoTipoInicial: venda.codigoTipoRecebimento,
          permitirParcial: true,
          observacaoInicial: context.t(
            'vendasAReceber.defaultReceiptNote',
            fallback: 'Recebimento realizado no frente de caixa web.',
          ),
        );

    if (resultado == null) return;
    if (!mounted) return;

    final String observacaoTotalPadrao = context.t(
      'vendasAReceber.defaultTotalReceiptNote',
      fallback: 'Recebimento total realizado no frente de caixa web.',
    );
    final String observacaoParcialPadrao = context.t(
      'vendasAReceber.defaultPartialReceiptNote',
      fallback: 'Recebimento parcial realizado no frente de caixa web.',
    );
    final String vendaRecebidaMensagem = context.t(
      'vendasAReceber.saleReceived',
      fallback: 'Venda recebida com sucesso.',
    );
    final String parcialRecebidaMensagem = context.t(
      'vendasAReceber.partialReceived',
      fallback: 'Parcial recebida com sucesso.',
    );

    setState(() => _processando = true);
    try {
      final String? idSessaoCaixa = await _buscarIdSessaoCaixaAberta();
      if (resultado.total) {
        await _api.liquidar(
          idRecebimento: venda.idRecebimento,
          input: LiquidarVendaNaoLiquidadaInput(
            codigoTipoRecebimento: resultado.codigoTipoRecebimento,
            valorRecebido: resultado.valor,
            itens: venda.itens,
            recebimentos: resultado.recebimentos,
            observacao: resultado.observacao ?? observacaoTotalPadrao,
            referencia:
                venda.idOperacaoApp.isNotEmpty
                    ? venda.idOperacaoApp
                    : venda.idOperacaoFinanceira,
            idSessaoCaixa: idSessaoCaixa,
          ),
        );
        if (mounted) {
          _snack(vendaRecebidaMensagem);
        }
      } else {
        await _acoesFinanceiras.executarAbatimento(
          idLancamento: venda.idOperacaoFinanceira,
          request: AgendaFinanceiraParcialRequest(
            tipoLiquidacao: 'PARCIAL',
            dataLiquidacao: DateTime.now(),
            valorLiquidado: resultado.valor,
            formaPagamentoRealizada: resultado.formaPagamentoBackend,
            recebimentos: resultado.recebimentos,
            observacoes: resultado.observacao ?? observacaoParcialPadrao,
            idSessaoCaixa: idSessaoCaixa,
          ),
        );
        if (mounted) {
          _snack(parcialRecebidaMensagem);
        }
      }
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<String?> _buscarIdSessaoCaixaAberta() async {
    final CaixaSessao? sessao = await _caixaApiClient.getSessaoAtual();
    final String? idSessaoCaixa = sessao?.idSessaoCaixa.trim();
    return idSessaoCaixa == null || idSessaoCaixa.isEmpty
        ? null
        : idSessaoCaixa;
  }

  Future<void> _confirmarCancelamentoVenda(VendaNaoLiquidadaModel venda) async {
    if (_processando) return;
    final bool confirmou =
        await showDialog<bool>(
          context: context,
          builder:
              (BuildContext dialogContext) => AlertDialog(
                title: Text(
                  context.t(
                    'vendasAReceber.cancelTitle',
                    fallback: 'Cancelar venda em aberto?',
                  ),
                ),
                content: Text(
                  '${venda.descricao}\n${_formatarValor(venda.valorAberto)}\n\n'
                  '${context.t('vendasAReceber.cancelDescription', fallback: 'Esta ação apaga a operação e devolve os produtos ao estoque quando aplicável.')}',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.t('common.back', fallback: 'Voltar')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.t('common.confirm', fallback: 'Confirmar'),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (confirmou) await _cancelarVendaNaoLiquidada(venda);
  }

  Future<void> _cancelarVendaNaoLiquidada(VendaNaoLiquidadaModel venda) async {
    if (_processando) return;
    setState(() => _processando = true);
    try {
      await _api.cancelar(idRecebimento: venda.idRecebimento);
      if (!mounted) return;
      _snack(
        context.t(
          'vendasAReceber.saleCancelled',
          fallback: 'Venda em aberto cancelada.',
        ),
      );
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleSettingsProvider>();
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.workspaceBackground,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(children: <Widget>[_header(), Expanded(child: _body())]),
            if (_processando)
              Positioned.fill(
                child: _VendasAReceberProcessingOverlay(
                  title: context.t(
                    'vendasAReceber.processingTitle',
                    fallback: 'Processando recebimento',
                  ),
                  subtitle: context.t(
                    'vendasAReceber.processingSubtitle',
                    fallback:
                        'Aguarde enquanto a operação financeira é sincronizada.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return SixWebDashboardHeader(
      icon: Icons.point_of_sale_outlined,
      title: context.t('vendasAReceber.title', fallback: 'Vendas a receber'),
      subtitle: context.t(
        'vendasAReceber.subtitle',
        fallback:
            'Acompanhe vendas em aberto, vencimentos e recebimentos pendentes.',
      ),
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: _loading || _processando ? null : _carregar,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.t('common.refresh', fallback: 'Atualizar')),
          style: _outlinedCtaStyle(),
        ),
      ],
      onBack: () => Navigator.of(context).pop(),
    );
  }

  Widget _body() {
    if (_loading) return _loadingBody();
    if (_erro != null) {
      return _estado(
        Icons.error_outline,
        context.t(
          'common.unableToLoad',
          fallback: 'Não foi possível carregar.',
        ),
        _erro!,
      );
    }

    final List<VendaNaoLiquidadaModel> vendas = _vendasFiltradas;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth >= 1480 ? 1380 : 1260,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SixWebEntry(order: 0, child: _contextCard()),
                      const SizedBox(height: 16),
                      SixWebEntry(order: 1, child: _filtrosData()),
                      const SizedBox(height: 16),
                      SixWebEntry(order: 2, child: _metrics()),
                      const SizedBox(height: 16),
                      SixWebEntry(order: 3, child: _planejados()),
                      const SizedBox(height: 18),
                      _section(vendas.length),
                      const SizedBox(height: 12),
                      if (vendas.isEmpty)
                        SixWebEntry(order: 4, child: _empty())
                      else
                        ...vendas.asMap().entries.map(
                          (MapEntry<int, VendaNaoLiquidadaModel> entry) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SixWebEntry(
                                  order: 4 + entry.key,
                                  child: _vendaCard(entry.value),
                                ),
                              ),
                        ),
                      const SizedBox(height: 4),
                      _bottomBar(vendas.length),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filtrosData() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return SixWebSectionCard(
      icon: Icons.filter_alt_outlined,
      title: context.t(
        'vendasAReceber.filtersTitle',
        fallback: 'Período de vencimento',
      ),
      subtitle: context.t(
        'vendasAReceber.filtersSubtitle',
        fallback:
            'A lista considera a data de vencimento ou competência da venda.',
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.selectedBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.selectedBorder),
        ),
        child: Text(
          context
              .t(
                'vendasAReceber.listCount',
                fallback: '{count} venda(s) exibida(s)',
              )
              .replaceFirst('{count}', _vendasFiltradas.length.toString()),
          style: TextStyle(
            color: tokens.primaryText,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 980;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _dateButton(
                    context.t(
                      'vendasAReceber.startDate',
                      fallback: 'Data inicial',
                    ),
                    _dataInicio,
                    () => _selecionarData(inicio: true),
                  ),
                  _dateButton(
                    context.t('vendasAReceber.endDate', fallback: 'Data final'),
                    _dataFim,
                    () => _selecionarData(inicio: false),
                  ),
                  FilledButton.icon(
                    onPressed: _loading || _processando ? null : _carregar,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(context.t('common.search', fallback: 'Buscar')),
                    style: _filledCtaStyle(),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _loading || _processando
                            ? null
                            : () {
                              final DateTime hoje = DateTime.now();
                              setState(() {
                                _dataInicio = _inicioDoDia(hoje);
                                _dataFim = _inicioDoDia(hoje);
                              });
                            },
                    icon: const Icon(Icons.today_outlined),
                    label: Text(context.t('common.today', fallback: 'Hoje')),
                    style: _outlinedCtaStyle(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.inputBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: <Widget>[
                    _inlineInfo(
                      context.t(
                        'vendasAReceber.totalOpen',
                        fallback: 'Total aberto',
                      ),
                      _formatarValor(_totalAberto),
                    ),
                    _inlineInfo(
                      context.t(
                        'vendasAReceber.sevenDayForecast',
                        fallback: 'Previsão 7 dias',
                      ),
                      _formatarValor(_previsaoSeteDias),
                    ),
                    _inlineInfo(
                      context.t(
                        'vendasAReceber.delayRisk',
                        fallback: 'Risco de atraso',
                      ),
                      _riscoAtraso,
                      emphasis: _riskColor(tokens),
                    ),
                    if (!compact)
                      _inlineInfo(
                        context.t(
                          'vendasAReceber.dueToday',
                          fallback: 'Vence hoje',
                        ),
                        _formatarInteiro(_venceHoje.toDouble()),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dateButton(String label, DateTime data, VoidCallback onTap) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.inputBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.calendar_month_outlined, color: tokens.info, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatarDataDia(data),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metrics() {
    final List<_Metric> metrics = <_Metric>[
      _Metric(
        context.t('vendasAReceber.totalOpen', fallback: 'Total aberto'),
        _totalAberto,
        Icons.account_balance_wallet_outlined,
        _formatarValor,
        highlight: true,
      ),
      _Metric(
        context.t('vendasAReceber.sales', fallback: 'Vendas'),
        _vendasFiltradas.length.toDouble(),
        Icons.receipt_long_outlined,
        _formatarInteiro,
      ),
      _Metric(
        context.t('vendasAReceber.averageTicket', fallback: 'Ticket médio'),
        _ticketMedio,
        Icons.trending_up_rounded,
        _formatarValor,
      ),
      _Metric(
        context.t('vendasAReceber.items', fallback: 'Itens'),
        _totalItens.toDouble(),
        Icons.inventory_2_outlined,
        _formatarInteiro,
      ),
      _Metric(
        context.t('vendasAReceber.overdue', fallback: 'Vencidas'),
        _vencidas.toDouble(),
        Icons.warning_amber_rounded,
        _formatarInteiro,
      ),
      _Metric(
        context.t('vendasAReceber.dueToday', fallback: 'Vence hoje'),
        _venceHoje.toDouble(),
        Icons.today_rounded,
        _formatarInteiro,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns =
            constraints.maxWidth >= 1180
                ? 3
                : constraints.maxWidth >= 720
                ? 2
                : 1;
        final double width =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map((metric) {
                return SizedBox(width: width, child: _metricCard(metric));
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _planejados() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 760;
        final List<Widget> children = <Widget>[
          _planned(
            context.t(
              'vendasAReceber.sevenDayForecast',
              fallback: 'Previsão 7 dias',
            ),
            _formatarValor(_previsaoSeteDias),
            Icons.auto_graph_rounded,
          ),
          _planned(
            context.t('vendasAReceber.delayRisk', fallback: 'Risco de atraso'),
            _riscoAtraso,
            Icons.insights_rounded,
          ),
        ];
        return sixWebResponsiveGroup(compact: compact, children: children);
      },
    );
  }

  Widget _planned(String title, String value, IconData icon) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(icon, size: 38),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.selectedBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.selectedBorder),
                ),
                child: Text(
                  context.t('vendasAReceber.planned', fallback: 'Planejado'),
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: tokens.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.t(
              'vendasAReceber.calculatedFromOpenSales',
              fallback: 'Calculado com as vendas em aberto',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.secondaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _vendaCard(VendaNaoLiquidadaModel venda) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final int quantidadeItens = venda.itens.fold<int>(
      0,
      (int soma, VendaNaoLiquidadaItemModel item) => soma + item.quantidade,
    );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 880;
            final Widget info = _vendaInfo(venda, quantidadeItens);
            final Widget actions = _vendaActions(venda);
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  info,
                  const SizedBox(height: 14),
                  Container(height: 1, color: tokens.divider),
                  const SizedBox(height: 14),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: info),
                const SizedBox(width: 18),
                Container(width: 1, height: 116, color: tokens.divider),
                const SizedBox(width: 18),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _vendaInfo(VendaNaoLiquidadaModel venda, int quantidadeItens) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String colaborador =
        venda.nomeColaboradorCriacao.isEmpty
            ? context.t(
              'vendasAReceber.collaboratorFallback',
              fallback: 'colaborador',
            )
            : venda.nomeColaboradorCriacao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _icon(Icons.receipt_long_outlined, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    venda.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      _statusChip(venda),
                      _chip(
                        Icons.person_outline_rounded,
                        '${context.t('vendasAReceber.createdBy', fallback: 'Criada por')} $colaborador',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            _chip(
              Icons.person_outline_rounded,
              '${context.t('vendasAReceber.createdBy', fallback: 'Criada por')} $colaborador',
            ),
            _chip(Icons.schedule_rounded, _formatarData(venda.dataCompetencia)),
            _chip(
              Icons.inventory_2_outlined,
              context
                  .t(
                    'vendasAReceber.itemCount',
                    fallback: '$quantidadeItens item(ns)',
                  )
                  .replaceFirst('{count}', quantidadeItens.toString()),
            ),
          ],
        ),
        if (venda.nomeCliente.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.inputBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.person_pin_circle_outlined,
                  size: 16,
                  color: tokens.secondaryText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    venda.nomeCliente.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _vendaActions(VendaNaoLiquidadaModel venda) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t('vendasAReceber.totalOpen', fallback: 'Total aberto'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatarValor(venda.valorAberto),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _vendaPrazo(venda),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.secondaryText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (widget.onAbrirNoPdv != null)
                OutlinedButton.icon(
                  onPressed:
                      _processando
                          ? null
                          : () => widget.onAbrirNoPdv?.call(venda),
                  icon: const Icon(Icons.point_of_sale_outlined, size: 18),
                  label: Text(
                    context.t(
                      'vendasAReceber.openInPdv',
                      fallback: 'Abrir no PDV',
                    ),
                  ),
                  style: _outlinedCtaStyle(),
                ),
              OutlinedButton(
                onPressed:
                    _processando
                        ? null
                        : () => _confirmarCancelamentoVenda(venda),
                style: _outlinedDangerCtaStyle(),
                child: Text(context.t('common.cancel', fallback: 'Cancelar')),
              ),
              FilledButton.icon(
                onPressed: _processando ? null : () => _receberVenda(venda),
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: Text(
                  context.t('vendasAReceber.receive', fallback: 'Receber'),
                ),
                style: _filledCtaStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return SixWebNoData(
      text: context.t(
        'vendasAReceber.emptyMessage',
        fallback: 'Nenhuma venda em aberto para o período selecionado.',
      ),
      height: 180,
    );
  }

  Widget _contextCard() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 900;
          final Widget summary = Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.selectedBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.selectedBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  context.t(
                    'vendasAReceber.totalOpen',
                    fallback: 'Total aberto',
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatarValor(_totalAberto),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context
                      .t(
                        'vendasAReceber.contextSubtitle',
                        fallback: '{count} venda(s) aguardando liquidação',
                      )
                      .replaceFirst(
                        '{count}',
                        _vendasFiltradas.length.toString(),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          );
          final Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _icon(Icons.receipt_long_outlined, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.t(
                            'vendasAReceber.contextTitle',
                            fallback: 'Dashboard de recebimentos',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: tokens.primaryText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.t(
                            'vendasAReceber.subtitle',
                            fallback:
                                'Acompanhe vendas em aberto, vencimentos e recebimentos pendentes.',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _inlineInfo(
                    context.t('vendasAReceber.sales', fallback: 'Vendas'),
                    _formatarInteiro(_vendasFiltradas.length.toDouble()),
                  ),
                  _inlineInfo(
                    context.t('vendasAReceber.items', fallback: 'Itens'),
                    _formatarInteiro(_totalItens.toDouble()),
                  ),
                  _inlineInfo(
                    context.t(
                      'vendasAReceber.averageTicket',
                      fallback: 'Ticket médio',
                    ),
                    _formatarValor(_ticketMedio),
                  ),
                ],
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[content, const SizedBox(height: 16), summary],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 5, child: content),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: summary),
            ],
          );
        },
      ),
    );
  }

  Widget _estado(IconData icon, String titulo, String mensagem) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _icon(icon, size: 76),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.t('common.refresh', fallback: 'Atualizar')),
              style: _outlinedCtaStyle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1260),
            child: Column(
              children: <Widget>[
                SixBackendLoading(
                  presentation: SixBackendLoadingPresentation.updateBanner,
                  title: context.t(
                    'vendasAReceber.loadingTitle',
                    fallback: 'Carregando vendas em aberto',
                  ),
                  subtitle: context.t(
                    'vendasAReceber.loadingSubtitle',
                    fallback: 'Buscando recebimentos pendentes no backend.',
                  ),
                  animation: SixBackendLoadingAnimation.skeletonPulse,
                  leadingIcon: Icons.cloud_sync_outlined,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(_Metric metric) {
    return SixWebKpiCard(
      icon: metric.icon,
      label: metric.title,
      value: metric.value,
      formatter: metric.formatter,
      highlight: metric.highlight,
    );
  }

  Widget _baseCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: child,
    );
  }

  Widget _icon(IconData icon, {double size = 50}) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size >= 48 ? 18 : 14),
      ),
      child: Icon(icon, color: tokens.info, size: size >= 48 ? 24 : 20),
    );
  }

  Widget _chip(IconData icon, String label) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.inputBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: tokens.secondaryText),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(int count) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            context.t('vendasAReceber.openSales', fallback: 'Vendas em aberto'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(int count) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context
                  .t(
                    'vendasAReceber.listCount',
                    fallback: '{count} venda(s) exibida(s)',
                  )
                  .replaceFirst('{count}', count.toString()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _loading || _processando ? null : _carregar,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.t('common.refresh', fallback: 'Atualizar')),
            style: _textCtaStyle(),
          ),
        ],
      ),
    );
  }

  DateTime _inicioDoDia(DateTime data) =>
      DateTime(data.year, data.month, data.day);
  DateTime _fimDoDia(DateTime data) =>
      DateTime(data.year, data.month, data.day, 23, 59, 59, 999);

  String _formatarValor(double valor) =>
      context.read<LocaleSettingsProvider>().formatCurrency(valor);

  String _formatarInteiro(double valor) =>
      context.read<LocaleSettingsProvider>().formatDecimal(valor.round());

  String _formatarData(DateTime? data) {
    if (data == null) return context.t('common.noDate', fallback: 'Sem data');
    final LocaleSettingsProvider locale =
        context.read<LocaleSettingsProvider>();
    return '${locale.formatDate(data)} ${locale.formatTime(data)}';
  }

  String _formatarDataDia(DateTime data) =>
      context.read<LocaleSettingsProvider>().formatDate(data);

  Widget _inlineInfo(String label, String value, {Color? emphasis}) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: emphasis ?? tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(VendaNaoLiquidadaModel venda) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final DateTime hoje = _inicioDoDia(DateTime.now());
    final DateTime? vencimento = venda.dataVencimento;
    late final Color color;
    late final String label;
    if (vencimento == null) {
      color = tokens.statusNeutral;
      label = context.t('common.noDate', fallback: 'Sem data');
    } else if (vencimento.isBefore(hoje)) {
      color = tokens.danger;
      label = context.t('vendasAReceber.overdue', fallback: 'Vencidas');
    } else if (vencimento.year == hoje.year &&
        vencimento.month == hoje.month &&
        vencimento.day == hoje.day) {
      color = tokens.warning;
      label = context.t('vendasAReceber.dueToday', fallback: 'Vence hoje');
    } else {
      color = tokens.success;
      label = context.t('vendasAReceber.planned', fallback: 'Planejado');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _vendaPrazo(VendaNaoLiquidadaModel venda) {
    final DateTime? vencimento = venda.dataVencimento;
    if (vencimento == null) {
      return context.t(
        'vendasAReceber.calculatedFromOpenSales',
        fallback: 'Calculado com as vendas em aberto',
      );
    }
    final DateTime hoje = _inicioDoDia(DateTime.now());
    final DateTime data = _inicioDoDia(vencimento);
    if (data.isBefore(hoje)) {
      return '${context.t('vendasAReceber.overdue', fallback: 'Vencidas')}: ${_formatarDataDia(vencimento)}';
    }
    if (data == hoje) {
      return '${context.t('vendasAReceber.dueToday', fallback: 'Vence hoje')}: ${_formatarDataDia(vencimento)}';
    }
    return '${context.t('vendasAReceber.endDate', fallback: 'Data final')}: ${_formatarDataDia(vencimento)}';
  }

  Color _riskColor(WebThemeTokens tokens) {
    if (_vencidas >= 5 ||
        (_vendasFiltradas.isNotEmpty &&
            _vencidas / _vendasFiltradas.length >= 0.35)) {
      return tokens.danger;
    }
    if (_vencidas > 0 || _venceHoje > 3) {
      return tokens.warning;
    }
    return tokens.success;
  }

  ButtonStyle _outlinedCtaStyle() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: tokens.info,
      disabledForegroundColor: tokens.disabledForeground,
      side: BorderSide(color: tokens.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.disabledBackground.withValues(alpha: 0.22);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return tokens.info.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: tokens.cardBorder.withValues(alpha: 0.55));
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return BorderSide(color: tokens.selectedBorder);
        }
        return BorderSide(color: tokens.cardBorder);
      }),
    );
  }

  ButtonStyle _outlinedDangerCtaStyle() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: tokens.danger,
      disabledForegroundColor: tokens.disabledForeground,
      side: BorderSide(color: tokens.danger.withValues(alpha: 0.28)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.disabledBackground.withValues(alpha: 0.22);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return tokens.danger.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
    );
  }

  ButtonStyle _filledCtaStyle() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return FilledButton.styleFrom(
      foregroundColor: tokens.onInfo,
      backgroundColor: tokens.info,
      disabledForegroundColor: tokens.disabledForeground,
      disabledBackgroundColor: tokens.disabledBackground,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }

  ButtonStyle _textCtaStyle() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return TextButton.styleFrom(
      foregroundColor: tokens.info,
      disabledForegroundColor: tokens.disabledForeground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return tokens.info.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
    );
  }
}

class _VendasAReceberProcessingOverlay extends StatelessWidget {
  const _VendasAReceberProcessingOverlay({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent =
        theme.brightness == Brightness.dark
            ? const Color(0xFF60A5FA)
            : theme.colorScheme.primary;

    return IgnorePointer(
      child: Container(
        color: const Color(0xFF081120).withValues(alpha: 0.34),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tokens.cardBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF020617).withValues(alpha: 0.30),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.secondaryText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric(
    this.title,
    this.value,
    this.icon,
    this.formatter, {
    this.highlight = false,
  });

  final String title;
  final double value;
  final IconData icon;
  final String Function(double value) formatter;
  final bool highlight;
}
