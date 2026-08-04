import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/agenda_financeira_acoes_financeiras.dart';
import '../../data/models/agenda_financeira_lancamento_model.dart';
import '../../data/models/caixa_models.dart';
import '../../data/models/venda_nao_liquidada_models.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../data/services/caixa/venda_nao_liquidada_api_client.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_recebimento_bottom_sheet.dart';
import '../components/mobile_motion.dart';

class VendasNaoLiquidadasMobileScreen extends StatefulWidget {
  const VendasNaoLiquidadasMobileScreen({super.key});

  @override
  State<VendasNaoLiquidadasMobileScreen> createState() =>
      _VendasNaoLiquidadasMobileScreenState();
}

class _VendasNaoLiquidadasMobileScreenState
    extends State<VendasNaoLiquidadasMobileScreen> {
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _surfaceColor = SixMobilePalette.surface;
  static const Color _mutedTextColor = SixMobilePalette.mutedText;
  static const Color _titleTextColor = SixMobilePalette.titleText;
  static const Duration _stateTransitionDuration = Duration(milliseconds: 240);

  final VendaNaoLiquidadaApiClient _api = VendaNaoLiquidadaApiClient();
  final AgendaFinanceiraAcoesFinanceiras _acoesFinanceiras =
      AgendaFinanceiraAcoesFinanceiras();
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();

  bool _loading = true;
  bool _cancelando = false;
  String? _erro;
  List<VendaNaoLiquidadaModel> _vendas = <VendaNaoLiquidadaModel>[];

  static Color _withAlpha(Color color, double opacity) {
    return color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final vendas = await _api.listar();
      if (!mounted) return;
      setState(() => _vendas = vendas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _receberVenda(VendaNaoLiquidadaModel venda) async {
    if (_cancelando) return;

    final SixMobileRecebimentoResultado? resultado =
        await SixMobileRecebimentoBottomSheet.show(
          context,
          titulo: _txt(
            'vendasNaoLiquidadas.receberTitulo',
            'Receber venda em aberto',
          ),
          descricao: venda.descricao,
          contato:
              venda.nomeCliente.trim().isEmpty
                  ? null
                  : venda.nomeCliente.trim(),
          valorAberto: venda.valorAberto,
          codigoTipoInicial: venda.codigoTipoRecebimento,
          permitirParcial: true,
          observacaoInicial: 'Recebimento realizado no PDV mobile.',
        );

    if (resultado == null) return;

    setState(() => _cancelando = true);
    try {
      final String? idSessaoCaixa = await _buscarIdSessaoCaixaAberta();
      if (resultado.total) {
        await _api.liquidar(
          idRecebimento: venda.idRecebimento,
          input: LiquidarVendaNaoLiquidadaInput(
            codigoTipoRecebimento: resultado.codigoTipoRecebimento,
            valorRecebido: resultado.valor,
            itens: venda.itens,
            observacao:
                resultado.observacao ??
                'Recebimento total realizado no PDV mobile.',
            referencia:
                venda.idOperacaoApp.isNotEmpty
                    ? venda.idOperacaoApp
                    : venda.idOperacaoFinanceira,
            idSessaoCaixa: idSessaoCaixa,
          ),
        );
        if (mounted) {
          _snack(
            _txt(
              'vendasNaoLiquidadas.recebidaSucesso',
              'Venda recebida com sucesso.',
            ),
          );
        }
      } else {
        await _acoesFinanceiras.executarAbatimento(
          idLancamento: venda.idOperacaoFinanceira,
          request: AgendaFinanceiraParcialRequest(
            tipoLiquidacao: 'PARCIAL',
            dataLiquidacao: DateTime.now(),
            valorLiquidado: resultado.valor,
            formaPagamentoRealizada: resultado.formaPagamentoBackend,
            observacoes:
                resultado.observacao ??
                'Recebimento parcial realizado no PDV mobile.',
            idSessaoCaixa: idSessaoCaixa,
          ),
        );
        if (mounted) {
          _snack(
            _txt(
              'vendasNaoLiquidadas.parcialSucesso',
              'Parcial recebida com sucesso.',
            ),
          );
        }
      }
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cancelando = false);
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
    final bool? confirmou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext bottomSheetContext) {
        final ThemeData theme = Theme.of(bottomSheetContext);
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _icon(
                      Icons.delete_outline_rounded,
                      bg: _withAlpha(SixMobilePalette.error, 0.10),
                      fg: SixMobilePalette.error,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            bottomSheetContext.t(
                              'vendasNaoLiquidadas.cancelarTitulo',
                              fallback: 'Cancelar venda em aberto?',
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: _titleTextColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bottomSheetContext.t(
                              'vendasNaoLiquidadas.cancelarDescricao',
                              fallback:
                                  'Esta ação apaga a operação e devolve os produtos ao estoque quando aplicável.',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _mutedTextColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _cancelamentoResumo(venda),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    bottomSheetContext.t(
                      'common.confirm',
                      fallback: 'Confirmar',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: SixMobilePalette.error,
                    foregroundColor: SixMobilePalette.onPrimary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    bottomSheetContext.t('common.back', fallback: 'Voltar'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _titleTextColor,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmou == true) await _cancelarVendaNaoLiquidada(venda);
  }

  Future<void> _cancelarVendaNaoLiquidada(VendaNaoLiquidadaModel venda) async {
    if (_cancelando) return;
    setState(() => _cancelando = true);
    try {
      await _api.cancelar(idRecebimento: venda.idRecebimento);
      if (!mounted) return;
      _snack(
        _txt(
          'vendasNaoLiquidadas.canceladaSucesso',
          'Venda em aberto cancelada.',
        ),
      );
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  String _formatarValor(num valor) {
    return context.read<LocaleSettingsProvider>().formatCurrency(valor);
  }

  String _formatarData(DateTime? data, {bool incluirHora = true}) {
    if (data == null) {
      return _txt('vendasNaoLiquidadas.semData', 'Sem data');
    }
    final LocaleSettingsProvider localeSettings =
        context.read<LocaleSettingsProvider>();
    final String dataFormatada = localeSettings.formatDate(data);
    if (!incluirHora) return dataFormatada;
    return '$dataFormatada ${localeSettings.formatTime(data)}';
  }

  String _formatarQuantidadeVendas(int quantidade) {
    if (quantidade == 1) {
      return _txt(
        'vendasNaoLiquidadas.umaVendaAguardando',
        '1 venda aguardando liquidação',
      );
    }
    return '$quantidade ${_txt('vendasNaoLiquidadas.vendasAguardando', 'vendas aguardando liquidação')}';
  }

  String _formatarQuantidadeItens(int quantidade) {
    final String label =
        quantidade == 1
            ? _txt('vendasNaoLiquidadas.itemSingular', 'item')
            : _txt('vendasNaoLiquidadas.itemPlural', 'itens');
    return '$quantidade $label';
  }

  double get _totalAberto =>
      _vendas.fold<double>(0, (soma, venda) => soma + venda.valorAberto);

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}|${provider.timeFormat}',
    );

    return SixMobilePageShell(
      title: _txt('vendasNaoLiquidadas.title', 'Vendas a receber'),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 8,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      leading: IconButton(
        tooltip: _txt('common.back', 'Voltar'),
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: _txt('common.refresh', 'Atualizar'),
          onPressed: _loading || _cancelando ? null : _carregar,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bodyBuilder: _buildContent,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return SafeArea(
      top: false,
      child: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _carregar,
            child: ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
              children: <Widget>[
                AnimatedSwitcher(
                  duration:
                      reduceMotion ? Duration.zero : _stateTransitionDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildState(reduceMotion: reduceMotion),
                ),
              ],
            ),
          ),
          if (_cancelando) _actionOverlay(),
        ],
      ),
    );
  }

  Widget _buildState({required bool reduceMotion}) {
    if (_loading) {
      return _loadingState(
        key: const ValueKey<String>('vendas-nao-liquidadas-loading'),
      );
    }

    if (_erro != null) {
      return _estado(
        key: const ValueKey<String>('vendas-nao-liquidadas-error'),
        icon: Icons.error_outline_rounded,
        titulo: _txt(
          'vendasNaoLiquidadas.erroTitulo',
          'Não foi possível carregar',
        ),
        mensagem: _erro!,
      );
    }

    return _successState(
      key: ValueKey<String>(
        'vendas-nao-liquidadas-success-${_vendas.length}-${_totalAberto.toStringAsFixed(2)}',
      ),
      reduceMotion: reduceMotion,
    );
  }

  Widget _successState({Key? key, required bool reduceMotion}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _entry(_header(reduceMotion: reduceMotion), reduceMotion: reduceMotion),
        const SizedBox(height: 18),
        _entry(
          _section(
            _txt('vendasNaoLiquidadas.secaoAbertas', 'Vendas em aberto'),
          ),
          delay: const Duration(milliseconds: 70),
          reduceMotion: reduceMotion,
        ),
        const SizedBox(height: 12),
        if (_vendas.isEmpty)
          _entry(
            _empty(),
            delay: const Duration(milliseconds: 110),
            reduceMotion: reduceMotion,
          )
        else
          ..._vendas.asMap().entries.map((
            MapEntry<int, VendaNaoLiquidadaModel> entry,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _entry(
                _vendaCard(entry.value),
                delay: Duration(milliseconds: 110 + entry.key * 40),
                reduceMotion: reduceMotion,
              ),
            );
          }),
      ],
    );
  }

  Widget _entry(
    Widget child, {
    Duration delay = Duration.zero,
    required bool reduceMotion,
  }) {
    if (reduceMotion) return child;
    return SixStaggeredEntry(delay: delay, child: child);
  }

  Widget _header({required bool reduceMotion}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(
                Icons.point_of_sale_outlined,
                bg: _withAlpha(SixMobilePalette.onPrimary, 0.12),
                fg: SixMobilePalette.onPrimary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'vendasNaoLiquidadas.dashboardTitulo',
                        'Recebimentos pendentes',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatarQuantidadeVendas(_vendas.length),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.heroSupportingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _withAlpha(SixMobilePalette.onPrimary, 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _withAlpha(SixMobilePalette.onPrimary, 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _txt('vendasNaoLiquidadas.totalEmAberto', 'Total em aberto'),
                  style: const TextStyle(
                    color: SixMobilePalette.heroLabelText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _AnimatedMetricValue(
                  key: ValueKey<String>(
                    'header-total-${_totalAberto.toStringAsFixed(2)}',
                  ),
                  value: _totalAberto,
                  formatter: _formatarValor,
                  reduceMotion: reduceMotion,
                  style: const TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vendaCard(VendaNaoLiquidadaModel venda) {
    final int quantidadeItens = venda.itens.fold<int>(
      0,
      (soma, item) => soma + item.quantidade,
    );
    final String colaborador =
        venda.nomeColaboradorCriacao.trim().isEmpty
            ? _txt('vendasNaoLiquidadas.colaboradorPadrao', 'colaborador')
            : venda.nomeColaboradorCriacao.trim();

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _cancelando ? null : () => _receberVenda(venda),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SixMobilePalette.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.navigationShadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _icon(
                    Icons.receipt_long_outlined,
                    bg: SixMobilePalette.softAccentSurface,
                    fg: _accentColor,
                    size: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          venda.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _titleTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_txt('vendasNaoLiquidadas.criadaPor', 'Criada por')} $colaborador',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _pill(_formatarData(venda.dataCompetencia)),
                  _pill(_formatarQuantidadeItens(quantidadeItens)),
                  if (venda.dataVencimento != null)
                    _pill(
                      '${_txt('vendasNaoLiquidadas.venceEm', 'Vence em')} '
                      '${_formatarData(venda.dataVencimento, incluirHora: false)}',
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _txt(
                            'vendasNaoLiquidadas.valorAberto',
                            'Valor em aberto',
                          ),
                          style: const TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatarValor(venda.valorAberto),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _titleTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FilledButton.icon(
                      onPressed:
                          _cancelando ? null : () => _receberVenda(venda),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(
                        _txt('vendasNaoLiquidadas.receber', 'Receber'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(96, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      _cancelando
                          ? null
                          : () => _confirmarCancelamentoVenda(venda),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(
                    _txt('vendasNaoLiquidadas.cancelarVenda', 'Cancelar venda'),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _mutedTextColor,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return _baseCard(
      child: Column(
        children: <Widget>[
          _icon(
            Icons.check_circle_outline_rounded,
            bg: SixMobilePalette.softAccentSurface,
            fg: _accentColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _txt('vendasNaoLiquidadas.vazioTitulo', 'Nenhuma venda em aberto'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _titleTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _txt(
              'vendasNaoLiquidadas.vazioDescricao',
              'Quando uma venda for marcada para receber depois, ela aparecerá aqui.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedTextColor, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _estado({
    Key? key,
    required IconData icon,
    required String titulo,
    required String mensagem,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 24),
      child: _baseCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _icon(
              icon,
              bg: _withAlpha(_accentColor, 0.10),
              fg: _accentColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _titleTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedTextColor, height: 1.4),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_txt('common.refresh', 'Atualizar')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState({Key? key}) {
    return Semantics(
      key: key,
      container: true,
      liveRegion: true,
      label: _txt(
        'vendasNaoLiquidadas.carregando',
        'Carregando vendas a receber',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _loadingHeader(),
          const SizedBox(height: 18),
          _section(
            _txt('vendasNaoLiquidadas.secaoAbertas', 'Vendas em aberto'),
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(
            3,
            (int index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _loadingVendaCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(
                Icons.point_of_sale_outlined,
                bg: _withAlpha(SixMobilePalette.onPrimary, 0.12),
                fg: SixMobilePalette.onPrimary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonLine(width: 190, colorOnDark: true),
                    const SizedBox(height: 8),
                    _skeletonLine(width: 150, height: 12, colorOnDark: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _withAlpha(SixMobilePalette.onPrimary, 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _withAlpha(SixMobilePalette.onPrimary, 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _skeletonLine(width: 98, height: 12, colorOnDark: true),
                const SizedBox(height: 8),
                _skeletonLine(width: 150, height: 24, colorOnDark: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingVendaCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(
                Icons.receipt_long_outlined,
                bg: SixMobilePalette.softAccentSurface,
                fg: _accentColor,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonLine(width: double.infinity, height: 16),
                    const SizedBox(height: 8),
                    _skeletonLine(width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _skeletonLine(width: 220, height: 28),
          const SizedBox(height: 14),
          _skeletonLine(width: 145, height: 20),
          const SizedBox(height: 10),
          _skeletonLine(width: double.infinity, height: 42),
        ],
      ),
    );
  }

  Widget _actionOverlay() {
    return Positioned.fill(
      child: Semantics(
        container: true,
        liveRegion: true,
        label: _txt('vendasNaoLiquidadas.processando', 'Processando ação'),
        child: Container(
          color: _withAlpha(Colors.black, 0.10),
          alignment: Alignment.center,
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SixMobilePalette.border),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.navigationShadow,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 14),
                Text(
                  _txt('vendasNaoLiquidadas.processando', 'Processando ação'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _txt(
                    'vendasNaoLiquidadas.aguarde',
                    'Estamos concluindo a operação.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cancelamentoResumo(VendaNaoLiquidadaModel venda) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  venda.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatarData(venda.dataCompetencia),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _formatarValor(venda.valorAberto),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _titleTextColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _icon(
    IconData icon, {
    required Color bg,
    required Color fg,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size >= 48 ? 18 : 14),
      ),
      child: Icon(icon, color: fg, size: size >= 48 ? 24 : 20),
    );
  }

  Widget _pill(
    String label, {
    Color fg = _mutedTextColor,
    Color bg = SixMobilePalette.softNeutralSurface,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _skeletonLine({
    required double width,
    double height = 14,
    bool colorOnDark = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            colorOnDark
                ? _withAlpha(SixMobilePalette.onPrimary, 0.18)
                : _withAlpha(SixMobilePalette.border, 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _titleTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _AnimatedMetricValue extends StatelessWidget {
  const _AnimatedMetricValue({
    super.key,
    required this.value,
    required this.formatter,
    required this.reduceMotion,
    required this.style,
  });

  final num value;
  final String Function(num value) formatter;
  final bool reduceMotion;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return _text(formatter(value));
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return _text(formatter(animatedValue));
      },
    );
  }

  Widget _text(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
