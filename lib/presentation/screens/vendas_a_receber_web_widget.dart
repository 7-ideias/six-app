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
import 'package:sixpos/providers/locale_settings_provider.dart';

class VendasAReceberWebWidget extends StatefulWidget {
  const VendasAReceberWebWidget({super.key});

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
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(children: <Widget>[_header(), Expanded(child: _body())]),
            if (_processando)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SixBackendLoading(
                      title: context.t(
                        'vendasAReceber.processingTitle',
                        fallback: 'Processando recebimento',
                      ),
                      subtitle: context.t(
                        'vendasAReceber.processingSubtitle',
                        fallback:
                            'Aguarde enquanto a operação financeira é sincronizada.',
                      ),
                      animation: SixBackendLoadingAnimation.progressSweep,
                      leadingIcon: Icons.sync_rounded,
                    ),
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
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          SixWebEntry(order: 0, child: _contextCard()),
          const SizedBox(height: 16),
          SixWebEntry(order: 1, child: _filtrosData()),
          const SizedBox(height: 16),
          SixWebEntry(order: 2, child: _metrics()),
          const SizedBox(height: 16),
          SixWebEntry(order: 3, child: _planejados()),
          const SizedBox(height: 18),
          _section(
            context.t('vendasAReceber.openSales', fallback: 'Vendas em aberto'),
          ),
          const SizedBox(height: 12),
          if (vendas.isEmpty)
            SixWebEntry(order: 4, child: _empty())
          else
            ...vendas.asMap().entries.map(
              (MapEntry<int, VendaNaoLiquidadaModel> entry) => Padding(
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
    );
  }

  Widget _filtrosData() {
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
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _dateButton(
            context.t('vendasAReceber.startDate', fallback: 'Data inicial'),
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
          ),
        ],
      ),
    );
  }

  Widget _dateButton(String label, DateTime data, VoidCallback onTap) {
    return SizedBox(
      width: 210,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            Text(
              _formatarDataDia(data),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.t('vendasAReceber.planned', fallback: 'Planejado'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vendaCard(VendaNaoLiquidadaModel venda) {
    final ThemeData theme = Theme.of(context);
    final int quantidadeItens = venda.itens.fold<int>(
      0,
      (int soma, VendaNaoLiquidadaItemModel item) => soma + item.quantidade,
    );
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 760;
            final Widget info = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _icon(Icons.receipt_long_outlined, size: 46),
                const SizedBox(width: 14),
                Expanded(child: _vendaInfo(venda, quantidadeItens)),
              ],
            );
            final Widget actions = _vendaActions(venda);
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[info, const SizedBox(height: 12), actions],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: info),
                const SizedBox(width: 16),
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
        Text(
          venda.descricao,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
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
          const SizedBox(height: 7),
          Text(
            venda.nomeCliente.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _vendaActions(VendaNaoLiquidadaModel venda) {
    final ThemeData theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            _formatarValor(venda.valorAberto),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: <Widget>[
              OutlinedButton(
                onPressed:
                    _processando
                        ? null
                        : () => _confirmarCancelamentoVenda(venda),
                child: Text(context.t('common.cancel', fallback: 'Cancelar')),
              ),
              FilledButton.icon(
                onPressed: _processando ? null : () => _receberVenda(venda),
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: Text(
                  context.t('vendasAReceber.receive', fallback: 'Receber'),
                ),
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
    return _baseCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          _icon(Icons.receipt_long_outlined, size: 48),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              _formatarValor(_totalAberto),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingBody() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        SixBackendLoading(
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
        const SizedBox(height: 16),
        LayoutBuilder(
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
              children: List<Widget>.generate(
                6,
                (int index) => SizedBox(
                  width: width,
                  child: SixWebLoadingBlock(height: 96, highlight: index == 0),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const SixWebLoadingBlock(height: 220),
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
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _icon(IconData icon, {double size = 50}) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size >= 48 ? 18 : 14),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.primary,
        size: size >= 48 ? 24 : 20,
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
  );

  Widget _bottomBar(int count) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(16),
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
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _loading || _processando ? null : _carregar,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.t('common.refresh', fallback: 'Atualizar')),
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
