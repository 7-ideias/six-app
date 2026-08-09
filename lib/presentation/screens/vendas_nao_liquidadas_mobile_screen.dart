import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/agenda_financeira_acoes_financeiras.dart';
import '../../data/models/agenda_financeira_lancamento_model.dart';
import '../../data/models/caixa_models.dart';
import '../../data/models/venda_nao_liquidada_models.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../data/services/caixa/venda_nao_liquidada_api_client.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_recebimento_bottom_sheet.dart';
import '../components/mobile_motion.dart';

class VendasNaoLiquidadasMobileScreen extends StatefulWidget {
  const VendasNaoLiquidadasMobileScreen({
    super.key,
    this.apiClient,
    this.acoesFinanceiras,
    this.caixaApiClient,
  });

  final VendaNaoLiquidadaApiClient? apiClient;
  final AgendaFinanceiraAcoesFinanceiras? acoesFinanceiras;
  final CaixaApiClient? caixaApiClient;

  @override
  State<VendasNaoLiquidadasMobileScreen> createState() =>
      _VendasNaoLiquidadasMobileScreenState();
}

class _VendasNaoLiquidadasMobileScreenState
    extends State<VendasNaoLiquidadasMobileScreen> {
  static const Duration _stateTransitionDuration = Duration(milliseconds: 240);

  late final VendaNaoLiquidadaApiClient _api;
  late final AgendaFinanceiraAcoesFinanceiras _acoesFinanceiras;
  late final CaixaApiClient _caixaApiClient;

  SixMobileColorScheme get _colors => context.sixMobileColors;
  Color get _backgroundColor => _colors.background;
  Color get _primaryColor => _colors.primary;
  Color get _secondaryColor => _colors.secondary;
  Color get _accentColor => _colors.accent;
  Color get _surfaceColor => _colors.surface;
  Color get _mutedTextColor => _colors.mutedText;
  Color get _titleTextColor => _colors.titleText;
  Color get _softAccentSurface => _colors.softAccentSurface;
  Color get _softSurface => _colors.softSurface;
  Color get _borderColor => _colors.border;
  Color get _heroShadow => _colors.heroShadow;

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
    _api = widget.apiClient ?? VendaNaoLiquidadaApiClient();
    _acoesFinanceiras =
        widget.acoesFinanceiras ?? AgendaFinanceiraAcoesFinanceiras();
    _caixaApiClient = widget.caixaApiClient ?? HttpCaixaApiClient();
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
          valorOriginal: venda.valorOriginal,
          valorJaRecebido: _valorJaRecebido(venda),
          valorAberto: venda.valorAberto,
          codigoTipoInicial: venda.codigoTipoRecebimento,
          permitirParcial: true,
          observacaoInicial: 'Recebimento realizado no PDV mobile.',
          caixaApiClient: _caixaApiClient,
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
            recebimentos: resultado.recebimentos,
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
            recebimentos: resultado.recebimentos,
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
            padding: EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
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
                    SizedBox(width: 12),
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
                          SizedBox(height: 4),
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
                SizedBox(height: 18),
                _cancelamentoResumo(venda),
                SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    bottomSheetContext.t(
                      'common.confirm',
                      fallback: 'Confirmar',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: SixMobilePalette.error,
                    foregroundColor: SixMobilePalette.onPrimary,
                    minimumSize: Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  icon: Icon(Icons.arrow_back_rounded),
                  label: Text(
                    bottomSheetContext.t('common.back', fallback: 'Voltar'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _titleTextColor,
                    minimumSize: Size.fromHeight(46),
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

  double _valorJaRecebido(VendaNaoLiquidadaModel venda) {
    final double recebido = venda.valorOriginal - venda.valorAberto;
    return recebido > 0 ? recebido : 0;
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

  int _quantidadeItensDaVenda(VendaNaoLiquidadaModel venda) {
    return venda.itens.fold<int>(0, (soma, item) => soma + item.quantidade);
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
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: _txt('common.refresh', 'Atualizar'),
          onPressed: _loading || _cancelando ? null : _carregar,
          icon: Icon(Icons.refresh_rounded),
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
              physics: AlwaysScrollableScrollPhysics(),
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
        key: ValueKey<String>('vendas-nao-liquidadas-loading'),
      );
    }

    if (_erro != null) {
      return _estado(
        key: ValueKey<String>('vendas-nao-liquidadas-error'),
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
        SizedBox(height: 18),
        _entry(
          _section(
            _txt('vendasNaoLiquidadas.secaoAbertas', 'Vendas em aberto'),
          ),
          delay: Duration(milliseconds: 70),
          reduceMotion: reduceMotion,
        ),
        SizedBox(height: 12),
        if (_vendas.isEmpty)
          _entry(
            _empty(),
            delay: Duration(milliseconds: 110),
            reduceMotion: reduceMotion,
          )
        else
          ..._vendas.asMap().entries.map((
            MapEntry<int, VendaNaoLiquidadaModel> entry,
          ) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
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
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(color: _heroShadow, blurRadius: 20, offset: Offset(0, 10)),
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
              SizedBox(width: 14),
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
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatarQuantidadeVendas(_vendas.length),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.heroSupportingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  style: TextStyle(
                    color: SixMobilePalette.heroLabelText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                _AnimatedMetricValue(
                  key: ValueKey<String>(
                    'header-total-${_totalAberto.toStringAsFixed(2)}',
                  ),
                  value: _totalAberto,
                  formatter: _formatarValor,
                  reduceMotion: reduceMotion,
                  style: TextStyle(
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
    final int quantidadeItens = _quantidadeItensDaVenda(venda);
    final String colaborador =
        venda.nomeColaboradorCriacao.trim().isEmpty
            ? _txt('vendasNaoLiquidadas.colaboradorPadrao', 'colaborador')
            : venda.nomeColaboradorCriacao.trim();
    final String cliente =
        venda.nomeCliente.trim().isEmpty
            ? _txt(
              'vendasNaoLiquidadas.clienteNaoInformado',
              'Cliente não informado',
            )
            : venda.nomeCliente.trim();
    final Widget detailsButton = _cardDetailsButton(venda);

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _cancelando ? null : () => _abrirDetalhesVenda(venda),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _colors.navigationShadow,
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
                    bg: _softAccentSurface,
                    fg: _accentColor,
                    size: 48,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          venda.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          cliente,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${_txt('vendasNaoLiquidadas.criadaPor', 'Criada por')} $colaborador',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  detailsButton,
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _pill(_formatarData(venda.dataCompetencia)),
                  _pill(_formatarQuantidadeItens(quantidadeItens)),
                  if (venda.status.trim().isNotEmpty)
                    _pill(
                      venda.status,
                      fg: _accentColor,
                      bg: _softAccentSurface,
                    ),
                  if (venda.dataVencimento != null)
                    _pill(
                      '${_txt('vendasNaoLiquidadas.venceEm', 'Vence em')} '
                      '${_formatarData(venda.dataVencimento, incluirHora: false)}',
                    ),
                ],
              ),
              SizedBox(height: 14),
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
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatarValor(venda.valorAberto),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  _pill(
                    _txt('vendasNaoLiquidadas.verDetalhes', 'Ver detalhes'),
                    fg: _accentColor,
                    bg: _softAccentSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardDetailsButton(VendaNaoLiquidadaModel venda) {
    return Semantics(
      button: true,
      label: _txt(
        'vendasNaoLiquidadas.verDetalhesVenda',
        'Ver detalhes da venda',
      ),
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: _softAccentSurface,
          foregroundColor: _accentColor,
          fixedSize: Size(40, 40),
          minimumSize: Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        tooltip: _txt(
          'vendasNaoLiquidadas.verDetalhesVenda',
          'Ver detalhes da venda',
        ),
        onPressed: _cancelando ? null : () => _abrirDetalhesVenda(venda),
        icon: Icon(Icons.add_rounded, size: 22),
      ),
    );
  }

  Future<void> _abrirDetalhesVenda(VendaNaoLiquidadaModel venda) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.46,
          maxChildSize: 0.94,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return _vendaDetalhesSheet(
              sheetContext: sheetContext,
              scrollController: scrollController,
              venda: venda,
            );
          },
        );
      },
    );
  }

  Widget _vendaDetalhesSheet({
    required BuildContext sheetContext,
    required ScrollController scrollController,
    required VendaNaoLiquidadaModel venda,
  }) {
    final int quantidadeItens = _quantidadeItensDaVenda(venda);
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(sheetContext) ||
        MediaQuery.accessibleNavigationOf(sheetContext);
    final double valorJaRecebido = _valorJaRecebido(venda);
    final String colaborador =
        venda.nomeColaboradorCriacao.trim().isEmpty
            ? _txt('vendasNaoLiquidadas.colaboradorPadrao', 'colaborador')
            : venda.nomeColaboradorCriacao.trim();
    final bool podeReceber = !_cancelando && venda.valorAberto > 0;
    final bool podeCancelar = !_cancelando;

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _icon(
                  Icons.receipt_long_outlined,
                  bg: _softAccentSurface,
                  fg: _accentColor,
                  size: 42,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        venda.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_txt('vendasNaoLiquidadas.criadaPor', 'Criada por')} $colaborador',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _txt('common.close', 'Fechar'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: Icon(Icons.close_rounded),
                ),
              ],
            ),
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _pill(_formatarData(venda.dataCompetencia)),
                _pill(_formatarQuantidadeItens(quantidadeItens)),
                _pill(venda.status),
                if (venda.dataVencimento != null)
                  _pill(
                    '${_txt('vendasNaoLiquidadas.venceEm', 'Vence em')} '
                    '${_formatarData(venda.dataVencimento, incluirHora: false)}',
                  ),
              ],
            ),
            SizedBox(height: 16),
            _vendaDetailActions(
              sheetContext: sheetContext,
              venda: venda,
              podeReceber: podeReceber,
              podeCancelar: podeCancelar,
            ),
            SizedBox(height: 18),
            _detailSection(
              title: _txt('vendasNaoLiquidadas.resumoVenda', 'Resumo da venda'),
              icon: Icons.assignment_outlined,
              children: <Widget>[
                _detailLine(
                  _txt('vendasNaoLiquidadas.descricao', 'Descrição'),
                  venda.descricao,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.cliente', 'Cliente'),
                  venda.nomeCliente,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.colaborador', 'Colaborador'),
                  colaborador,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.status', 'Status'),
                  venda.status,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.criacao', 'Criação'),
                  _formatarData(venda.dataCompetencia),
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.vencimento', 'Vencimento'),
                  _formatarData(venda.dataVencimento, incluirHora: false),
                ),
              ],
            ),
            SizedBox(height: 14),
            _detailSection(
              title: _txt('vendasNaoLiquidadas.valores', 'Valores'),
              icon: Icons.payments_outlined,
              children: <Widget>[
                _detailMoneyLine(
                  _txt('vendasNaoLiquidadas.valorOriginal', 'Valor original'),
                  venda.valorOriginal,
                  reduceMotion: reduceMotion,
                ),
                _detailMoneyLine(
                  _txt(
                    'vendasNaoLiquidadas.valorJaRecebido',
                    'Valor já recebido',
                  ),
                  -valorJaRecebido,
                  reduceMotion: reduceMotion,
                  valueColor:
                      valorJaRecebido > 0
                          ? SixMobilePalette.error
                          : _mutedTextColor,
                ),
                _detailMoneyLine(
                  _txt('vendasNaoLiquidadas.valorAberto', 'Valor em aberto'),
                  venda.valorAberto,
                  reduceMotion: reduceMotion,
                  valueColor: venda.valorAberto > 0 ? _accentColor : null,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.itens', 'Itens'),
                  _formatarQuantidadeItens(quantidadeItens),
                ),
              ],
            ),
            SizedBox(height: 14),
            _recebimentosVendaSection(venda),
            SizedBox(height: 14),
            _itensVendaSection(venda),
          ],
        ),
      ),
    );
  }

  Widget _vendaDetailActions({
    required BuildContext sheetContext,
    required VendaNaoLiquidadaModel venda,
    required bool podeReceber,
    required bool podeCancelar,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double itemWidth =
            compact ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SizedBox(
              width: itemWidth,
              child: _sheetActionButton(
                label: _txt('vendasNaoLiquidadas.receber', 'Receber'),
                icon: Icons.payments_outlined,
                filled: true,
                onPressed:
                    podeReceber
                        ? () => _runAfterClosingSheet(
                          sheetContext,
                          () => _receberVenda(venda),
                        )
                        : null,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _sheetActionButton(
                label: _txt(
                  'vendasNaoLiquidadas.cancelarVenda',
                  'Cancelar venda',
                ),
                icon: Icons.delete_outline_rounded,
                onPressed:
                    podeCancelar
                        ? () => _runAfterClosingSheet(
                          sheetContext,
                          () => _confirmarCancelamentoVenda(venda),
                        )
                        : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheetActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final ButtonStyle style =
        filled
            ? FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: SixMobilePalette.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            )
            : OutlinedButton.styleFrom(
              foregroundColor: _titleTextColor,
              side: BorderSide(color: _borderColor),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            );
    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17),
        SizedBox(width: 7),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }

  void _runAfterClosingSheet(BuildContext sheetContext, VoidCallback action) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  Widget _detailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(icon, bg: _softAccentSurface, fg: _accentColor, size: 38),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailLine(String label, String? value, {Color? valueColor}) {
    final String display = _blankAsDash(value);
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                color: valueColor ?? _titleTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailMoneyLine(
    String label,
    num value, {
    required bool reduceMotion,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _AnimatedMetricValue(
              value: value,
              formatter: _formatarValor,
              reduceMotion: reduceMotion,
              style: TextStyle(
                color: valueColor ?? _titleTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recebimentosVendaSection(VendaNaoLiquidadaModel venda) {
    return _detailSection(
      title: _txt('vendasNaoLiquidadas.recebimentos', 'Recebimentos'),
      icon: Icons.receipt_long_outlined,
      children: <Widget>[
        if (venda.recebimentos.isEmpty)
          Text(
            _txt(
              'vendasNaoLiquidadas.semRecebimentos',
              'Nenhum recebimento lançado.',
            ),
            style: TextStyle(color: _mutedTextColor),
          )
        else
          ...venda.recebimentos.reversed.map((
            VendaNaoLiquidadaRecebimentoModel item,
          ) {
            final String observacoes = item.observacoes?.trim() ?? '';
            final String referencia = item.referencia?.trim() ?? '';
            final String? tipoLiquidacao = _tipoLiquidacaoLabel(
              item.tipoLiquidacao,
            );
            return _detailListTile(
              icon: Icons.payments_outlined,
              title: _descricaoRecebimento(item),
              subtitle: <String>[
                _formatarDataRecebimento(item),
                if (tipoLiquidacao != null) tipoLiquidacao,
                if (referencia.isNotEmpty)
                  '${_txt('vendasNaoLiquidadas.referencia', 'Referência')}: '
                      '$referencia',
                if (observacoes.isNotEmpty) observacoes,
              ].join(' • '),
              trailing: _formatarValor(item.valorLiquidado),
            );
          }),
      ],
    );
  }

  String _descricaoRecebimento(VendaNaoLiquidadaRecebimentoModel item) {
    final String descricao = item.descricaoTipoRecebimento.trim();
    if (descricao.isNotEmpty) return descricao;
    final String forma = item.formaPagamentoRealizada.trim();
    if (forma.isNotEmpty) return forma;
    final String codigo = item.codigoTipoRecebimento.trim();
    if (codigo.isNotEmpty) return codigo;
    return _txt('vendasNaoLiquidadas.recebimento', 'Recebimento');
  }

  String _formatarDataRecebimento(VendaNaoLiquidadaRecebimentoModel item) {
    if (item.registradoEm != null) return _formatarData(item.registradoEm);

    final DateTime? dataLiquidacao = item.dataLiquidacao;
    if (dataLiquidacao == null) return _formatarData(null);

    final bool possuiHora =
        dataLiquidacao.hour != 0 ||
        dataLiquidacao.minute != 0 ||
        dataLiquidacao.second != 0 ||
        dataLiquidacao.millisecond != 0 ||
        dataLiquidacao.microsecond != 0;
    return _formatarData(dataLiquidacao, incluirHora: possuiHora);
  }

  String? _tipoLiquidacaoLabel(String tipoLiquidacao) {
    switch (tipoLiquidacao.trim().toUpperCase()) {
      case 'TOTAL':
        return _txt('vendasNaoLiquidadas.recebimentoTotal', 'Total');
      case 'PARCIAL':
        return _txt('vendasNaoLiquidadas.recebimentoParcial', 'Parcial');
      default:
        return null;
    }
  }

  Widget _itensVendaSection(VendaNaoLiquidadaModel venda) {
    return _detailSection(
      title: _txt('vendasNaoLiquidadas.itensVenda', 'Itens da venda'),
      icon: Icons.inventory_2_outlined,
      children: <Widget>[
        if (venda.itens.isEmpty)
          Text(
            _txt('vendasNaoLiquidadas.semItens', 'Nenhum item vinculado.'),
            style: TextStyle(color: _mutedTextColor),
          )
        else
          ...venda.itens.map((VendaNaoLiquidadaItemModel item) {
            final double total = item.quantidade * item.valorUnitario;
            return _detailListTile(
              icon:
                  item.ehServico
                      ? Icons.handyman_outlined
                      : Icons.inventory_2_outlined,
              title: item.nome,
              subtitle:
                  '${item.quantidade} x ${_formatarValor(item.valorUnitario)}',
              trailing: _formatarValor(total),
            );
          }),
      ],
    );
  }

  Widget _detailListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _icon(icon, bg: _softSurface, fg: _primaryColor, size: 34),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _blankAsDash(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  _blankAsDash(subtitle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            SizedBox(width: 10),
            Text(
              trailing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _blankAsDash(String? value) {
    final String text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  Widget _empty() {
    return _baseCard(
      child: Column(
        children: <Widget>[
          _icon(
            Icons.check_circle_outline_rounded,
            bg: _softAccentSurface,
            fg: _accentColor,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            _txt('vendasNaoLiquidadas.vazioTitulo', 'Nenhuma venda em aberto'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            _txt(
              'vendasNaoLiquidadas.vazioDescricao',
              'Quando uma venda for marcada para receber depois, ela aparecerá aqui.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.4),
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
      padding: EdgeInsets.only(top: 24),
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
            SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedTextColor, height: 1.4),
            ),
            SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _carregar,
              icon: Icon(Icons.refresh_rounded),
              label: Text(_txt('common.refresh', 'Atualizar')),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(46),
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
          SizedBox(height: 18),
          _section(
            _txt('vendasNaoLiquidadas.secaoAbertas', 'Vendas em aberto'),
          ),
          SizedBox(height: 12),
          ...List<Widget>.generate(
            3,
            (int index) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _loadingVendaCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingHeader() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(color: _heroShadow, blurRadius: 20, offset: Offset(0, 10)),
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
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonLine(width: 190, colorOnDark: true),
                    SizedBox(height: 8),
                    _skeletonLine(width: 150, height: 12, colorOnDark: true),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                SizedBox(height: 8),
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
                bg: _softAccentSurface,
                fg: _accentColor,
                size: 48,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonLine(width: double.infinity, height: 16),
                    SizedBox(height: 8),
                    _skeletonLine(width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _skeletonLine(width: 220, height: 28),
          SizedBox(height: 14),
          _skeletonLine(width: 145, height: 20),
          SizedBox(height: 10),
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
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _colors.navigationShadow,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LinearProgressIndicator(minHeight: 3),
                SizedBox(height: 14),
                Text(
                  _txt('vendasNaoLiquidadas.processando', 'Processando ação'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _txt(
                    'vendasNaoLiquidadas.aguarde',
                    'Estamos concluindo a operação.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
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
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatarData(venda.dataCompetencia),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              _formatarValor(venda.valorAberto),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _colors.navigationShadow,
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

  Widget _pill(String label, {Color? fg, Color? bg}) {
    final Color foreground = fg ?? _mutedTextColor;
    final Color background = bg ?? _softSurface;

    return Container(
      constraints: BoxConstraints(maxWidth: 260),
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
                : _withAlpha(_borderColor, 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: TextStyle(
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
      duration: Duration(milliseconds: 620),
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
