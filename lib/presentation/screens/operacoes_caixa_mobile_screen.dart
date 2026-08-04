import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/caixa_module.dart';
import '../../data/models/caixa_completo_movimentos_models.dart';
import '../../data/models/caixa_models.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import '../components/six_backend_loading.dart';

class OperacoesCaixaMobileScreen extends StatefulWidget {
  const OperacoesCaixaMobileScreen({super.key});

  @override
  State<OperacoesCaixaMobileScreen> createState() =>
      _OperacoesCaixaMobileScreenState();
}

class _OperacoesCaixaMobileScreenState
    extends State<OperacoesCaixaMobileScreen> {
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _successColor = Color(0xFF047857);
  static const Color _warningColor = Color(0xFF92400E);
  static const Duration _transitionDuration = Duration(milliseconds: 240);

  final CaixaService _caixaService = CaixaModule.caixaService;
  final TextEditingController _trocoInicialController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _fechamentoDinheiroController =
      TextEditingController();
  final TextEditingController _fechamentoPixController =
      TextEditingController();
  final TextEditingController _fechamentoCartaoController =
      TextEditingController();
  final TextEditingController _fechamentoObservacaoController =
      TextEditingController();

  bool _loading = true;
  bool _busy = false;
  bool _vincularVenda = false;
  bool _mostrarPainelFechamento = false;
  bool _mostrarApenasHoje = false;
  String? _erro;

  CaixaSessao? _sessaoAtual;
  CaixaOuGuiche? _caixaSelecionado;
  OperacaoCaixaTipo? _tipoSelecionado;
  TiposRecebimento? _tipoRecebimentoSelecionado;
  InformacoesCaixaComSomatorioResponse? _movimentosComSomatorio;
  ResumoCaixa? _resumo;

  List<CaixaOuGuiche> _caixasDisponiveis = <CaixaOuGuiche>[];
  List<TiposRecebimento> _tiposRecebimento = <TiposRecebimento>[];
  List<MovimentoCaixa> _movimentos = <MovimentoCaixa>[];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _trocoInicialController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    _referenciaController.dispose();
    _fechamentoDinheiroController.dispose();
    _fechamentoPixController.dispose();
    _fechamentoCartaoController.dispose();
    _fechamentoObservacaoController.dispose();
    super.dispose();
  }

  static Color _withAlpha(Color color, double opacity) {
    return color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
  }

  bool get _temCaixaAberto {
    final CaixaSessao? sessao = _sessaoAtual;
    return sessao != null && _sessaoCaixaAberta(sessao);
  }

  bool _sessaoCaixaAberta(CaixaSessao sessao) {
    final String status = sessao.status.trim().toLowerCase();
    return status == 'aberta' ||
        status == 'open' ||
        status == 'active' ||
        status == 'ativa' ||
        status == 'true';
  }

  Future<void> _carregarDadosIniciais({String? idCaixaPreferencial}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }

    try {
      final InformacoesBasicasCaixaResponse informacoesBasicas =
          await _caixaService.buscarInformacoesBasicasDoCaixa();

      if (mounted && informacoesBasicas.regionalizacao != null) {
        await context
            .read<LocaleSettingsProvider>()
            .atualizarConfiguracaoDaEmpresaPorResponse(
              informacoesBasicas.regionalizacao!,
            );
      }

      final CaixaSessao? sessao = await _caixaService.buscarSessaoAtual();
      await _carregarUsuarioAtualSilencioso();

      final List<CaixaOuGuiche> caixas =
          informacoesBasicas.caixaOuGuiche.isNotEmpty
              ? informacoesBasicas.caixaOuGuiche
              : informacoesBasicas.caixas
                  .map((String nome) => CaixaOuGuiche(id: nome, nome: nome))
                  .toList(growable: false);

      final List<TiposRecebimento> tiposAtivos = informacoesBasicas
        .tiposRecebimento
        .where((TiposRecebimento item) => item.ativo)
        .toList(growable: false)..sort(
        (TiposRecebimento a, TiposRecebimento b) =>
            a.ordemExibicao.compareTo(b.ordemExibicao),
      );

      final String? idPreferencial =
          idCaixaPreferencial ?? _caixaSelecionado?.id;
      CaixaOuGuiche? caixaPreferencial;
      if (idPreferencial != null) {
        for (final CaixaOuGuiche caixa in caixas) {
          if (caixa.id == idPreferencial) {
            caixaPreferencial = caixa;
            break;
          }
        }
      }

      TiposRecebimento? tipoPreferencial;
      final String? codigoAtual = _tipoRecebimentoSelecionado?.codigoTipo;
      if (codigoAtual != null) {
        for (final TiposRecebimento tipo in tiposAtivos) {
          if (tipo.codigoTipo == codigoAtual) {
            tipoPreferencial = tipo;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _caixasDisponiveis = caixas;
        _tiposRecebimento = informacoesBasicas.tiposRecebimento;
        _caixaSelecionado =
            caixaPreferencial ??
            (_caixasDisponiveis.isNotEmpty ? _caixasDisponiveis.first : null);
        _tipoRecebimentoSelecionado =
            tipoPreferencial ??
            (tiposAtivos.isNotEmpty ? tiposAtivos.first : null);
        _sessaoAtual = sessao;
        _movimentos = <MovimentoCaixa>[];
        _movimentosComSomatorio = null;
        _resumo = null;
      });

      if (sessao != null) {
        await _carregarMovimentosEResumo(sessao.idSessaoCaixa);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _carregarUsuarioAtualSilencioso() async {
    try {
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
    } catch (_) {
      // O nome do colaborador é apoio visual; não deve bloquear o caixa.
    }
  }

  Future<void> _carregarMovimentosEResumo(String idSessaoCaixa) async {
    try {
      final List<MovimentoCaixa> movimentos = await _caixaService
          .listarMovimentacoes(idSessaoCaixa);
      if (!mounted) return;
      setState(() => _movimentos = movimentos);
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    }

    try {
      final InformacoesCaixaComSomatorioResponse movimentosComSomatorio =
          await _caixaService.buscarResumoDeMovimentosComSomatorio(
            idSessaoCaixa,
          );
      if (!mounted) return;
      setState(() {
        _movimentosComSomatorio = movimentosComSomatorio;
        if (_movimentos.isEmpty &&
            movimentosComSomatorio.movimento.isNotEmpty) {
          _movimentos = movimentosComSomatorio.movimento;
        }
      });
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    }

    try {
      final ResumoCaixa resumo = await _caixaService.buscarResumo(
        idSessaoCaixa,
      );
      if (!mounted) return;
      setState(() => _resumo = resumo);
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}|${provider.timeFormat}',
    );

    return SixMobilePageShell(
      title: _txt('caixa.operacoes.mobile.title', 'Operações de caixa'),
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
          onPressed: _loading || _busy ? null : () => _carregarDadosIniciais(),
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
            onRefresh: () => _carregarDadosIniciais(),
            child: ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
              children: <Widget>[
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : _transitionDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildState(reduceMotion: reduceMotion),
                ),
              ],
            ),
          ),
          if (_busy) _actionOverlay(),
        ],
      ),
    );
  }

  Widget _buildState({required bool reduceMotion}) {
    if (_loading && _sessaoAtual == null && _resumo == null) {
      return _loadingState(
        key: const ValueKey<String>('operacoes-caixa-loading'),
      );
    }

    if (_erro != null && _sessaoAtual == null) {
      return _stateMessage(
        key: const ValueKey<String>('operacoes-caixa-error'),
        icon: Icons.error_outline_rounded,
        title: _txt(
          'caixa.operacoes.mobile.errorTitle',
          'Não foi possível carregar',
        ),
        message: _erro!,
        actionLabel: _txt('common.tryAgain', 'Tentar novamente'),
        onAction: () => _carregarDadosIniciais(),
      );
    }

    return _successState(
      key: ValueKey<String>(
        'operacoes-caixa-${_sessaoAtual?.idSessaoCaixa ?? 'sem-sessao'}'
        '-${_resumo?.saldoEsperado.toStringAsFixed(2) ?? '0'}'
        '-${_movimentos.length}',
      ),
      reduceMotion: reduceMotion,
    );
  }

  Widget _successState({Key? key, required bool reduceMotion}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _entry(_buildHeaderCard(), reduceMotion: reduceMotion),
        const SizedBox(height: 12),
        _entry(
          _buildKpis(),
          delay: const Duration(milliseconds: 60),
          reduceMotion: reduceMotion,
        ),
        const SizedBox(height: 12),
        if (!_temCaixaAberto)
          _entry(
            _buildPainelAbertura(),
            delay: const Duration(milliseconds: 110),
            reduceMotion: reduceMotion,
          )
        else ...<Widget>[
          _entry(
            _buildContextoSessao(),
            delay: const Duration(milliseconds: 110),
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 12),
          _entry(
            _buildAtalhosOperacao(),
            delay: const Duration(milliseconds: 150),
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 12),
          _entry(
            _buildFormularioMovimento(),
            delay: const Duration(milliseconds: 190),
            reduceMotion: reduceMotion,
          ),
          if (_mostrarPainelFechamento) ...<Widget>[
            const SizedBox(height: 12),
            _entry(
              _buildPainelFechamento(),
              delay: const Duration(milliseconds: 220),
              reduceMotion: reduceMotion,
            ),
          ],
          const SizedBox(height: 12),
          _entry(
            _buildResumoOperacional(),
            delay: const Duration(milliseconds: 240),
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 12),
          _entry(
            _buildHistorico(),
            delay: const Duration(milliseconds: 280),
            reduceMotion: reduceMotion,
          ),
        ],
      ],
    );
  }

  Widget _entry(
    Widget child, {
    Duration delay = Duration.zero,
    required bool reduceMotion,
  }) {
    if (reduceMotion) return child;
    return SixStaggeredEntry(
      delay: delay,
      duration: const Duration(milliseconds: 340),
      beginOffset: const Offset(0, 0.035),
      child: child,
    );
  }

  Widget _loadingState({Key? key}) {
    return Column(
      key: key,
      children: <Widget>[
        _buildHeaderCard(loading: true),
        const SizedBox(height: 12),
        const SixBackendLoading(
          title: 'Carregando operações de caixa',
          subtitle: 'Sincronizando sessão, resumo e movimentações.',
          animation: SixBackendLoadingAnimation.skeletonPulse,
          leadingIcon: Icons.point_of_sale_rounded,
          backgroundColor: SixMobilePalette.surface,
          borderColor: SixMobilePalette.border,
        ),
      ],
    );
  }

  Widget _stateMessage({
    Key? key,
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: <Widget>[
          _iconBox(
            icon,
            bg: _withAlpha(SixMobilePalette.error, 0.10),
            fg: SixMobilePalette.error,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard({bool loading = false}) {
    final int movimentos = _resumo?.quantidadeMovimentos ?? _movimentos.length;
    final String status =
        loading
            ? _txt('common.loading', 'Carregando...')
            : _temCaixaAberto
            ? _txt('caixa.operacoes.mobile.cashOpen', 'Caixa aberto')
            : _txt('caixa.operacoes.mobile.waitingOpen', 'Aguardando abertura');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SixMobilePalette.primary,
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
              _iconBox(
                Icons.point_of_sale_rounded,
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
                        'caixa.operacoes.mobile.headerTitle',
                        'Operações de caixa',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$movimentos movimento(s) • $status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.heroSupportingText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _statusChip(
            label: status,
            icon:
                _temCaixaAberto
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
            foreground:
                _temCaixaAberto
                    ? SixMobilePalette.onPrimary
                    : SixMobilePalette.heroSupportingText,
            background: _withAlpha(SixMobilePalette.onPrimary, 0.10),
            border: _withAlpha(SixMobilePalette.onPrimary, 0.16),
          ),
        ],
      ),
    );
  }

  Widget _buildKpis() {
    final ResumoCaixa? resumo = _resumo;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double width =
            compact ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _metricCard(
              width: width,
              label: _txt(
                'caixa.operacoes.mobile.expectedBalance',
                'Saldo esperado',
              ),
              value: resumo?.saldoEsperado ?? 0,
              icon: Icons.account_balance_wallet_outlined,
              highlight: true,
            ),
            _metricCard(
              width: width,
              label: _txt('caixa.operacoes.mobile.inflows', 'Entradas'),
              value: resumo?.totalEntradas ?? 0,
              icon: Icons.south_west_rounded,
            ),
            _metricCard(
              width: width,
              label: _txt('caixa.operacoes.mobile.outflows', 'Saídas'),
              value: resumo?.totalSaidas ?? 0,
              icon: Icons.north_east_rounded,
            ),
            _countCard(
              width: width,
              label: _txt('caixa.operacoes.mobile.movements', 'Movimentos'),
              value: resumo?.quantidadeMovimentos ?? _movimentos.length,
              icon: Icons.receipt_long_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required double width,
    required String label,
    required double value,
    required IconData icon,
    bool highlight = false,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              highlight ? SixMobilePalette.primary : SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                highlight ? SixMobilePalette.primary : SixMobilePalette.border,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            _iconBox(
              icon,
              bg:
                  highlight
                      ? _withAlpha(SixMobilePalette.onPrimary, 0.12)
                      : SixMobilePalette.softAccentSurface,
              fg:
                  highlight
                      ? SixMobilePalette.onPrimary
                      : SixMobilePalette.accent,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          highlight
                              ? SixMobilePalette.heroLabelText
                              : SixMobilePalette.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _animatedCurrencyText(
                    value,
                    style: TextStyle(
                      color:
                          highlight
                              ? SixMobilePalette.onPrimary
                              : SixMobilePalette.titleText,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
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

  Widget _countCard({
    required double width,
    required String label,
    required int value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 20),
        child: Row(
          children: <Widget>[
            _iconBox(
              icon,
              bg: SixMobilePalette.softNeutralSurface,
              fg: SixMobilePalette.primary,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SixMobilePalette.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SixAnimatedNumberText(
                    key: ValueKey<String>('caixa-movimentos-$value'),
                    value: value.toString(),
                    style: const TextStyle(
                      color: SixMobilePalette.titleText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
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

  Widget _buildPainelAbertura() {
    return _sectionCard(
      icon: Icons.lock_open_rounded,
      title: _txt('caixa.operacoes.mobile.openTitle', 'Abertura de caixa'),
      subtitle: _txt(
        'caixa.operacoes.mobile.openSubtitle',
        'Defina o caixa, o troco inicial e inicie a operação do dia.',
      ),
      child: Column(
        children: <Widget>[
          _selectorField(
            label: _txt('caixa.operacoes.mobile.cashDesk', 'Caixa / guichê'),
            value:
                _caixaSelecionado?.nome ??
                _txt('caixa.operacoes.mobile.select', 'Selecione'),
            icon: Icons.store_mall_directory_outlined,
            onTap: _selecionarCaixa,
          ),
          const SizedBox(height: 12),
          _textField(
            label: _txt(
              'caixa.operacoes.mobile.initialChange',
              'Troco inicial',
            ),
            controller: _trocoInicialController,
            hint: _formatarDecimalDigitavel(0),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText:
                '${context.read<LocaleSettingsProvider>().currencyCode} ',
          ),
          const SizedBox(height: 12),
          _readOnlyInfo(
            label: _txt('caixa.operacoes.mobile.responsible', 'Responsável'),
            value: _nomeColaboradorAtual(),
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _abrirCaixa,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(_txt('caixa.operacoes.mobile.openCash', 'Abrir caixa')),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: SixMobilePalette.accent,
              foregroundColor: SixMobilePalette.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextoSessao() {
    final CaixaSessao? sessao = _sessaoAtual;
    return _sectionCard(
      icon: Icons.verified_outlined,
      title: _txt('caixa.operacoes.mobile.sessionContext', 'Sessão atual'),
      subtitle: _txt(
        'caixa.operacoes.mobile.sessionContextSubtitle',
        'Dados principais da operação em andamento.',
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          _infoTile(
            title: _txt('caixa.operacoes.mobile.session', 'Sessão'),
            value: sessao?.idSessaoCaixa ?? '--',
            icon: Icons.badge_outlined,
          ),
          _infoTile(
            title: _txt('caixa.operacoes.mobile.cashDeskShort', 'Caixa'),
            value: sessao?.nomeCaixa ?? '--',
            icon: Icons.store_mall_directory_outlined,
          ),
          _infoTile(
            title: _txt('caixa.operacoes.mobile.openedAt', 'Abertura'),
            value: _formatarDataHora(sessao?.dataHoraAbertura),
            icon: Icons.schedule_rounded,
          ),
          _infoTile(
            title: _txt(
              'caixa.operacoes.mobile.initialChange',
              'Troco inicial',
            ),
            value: _formatarValor(sessao?.valorAbertura ?? 0),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAtalhosOperacao() {
    final List<_OperacaoCaixaMobileData> atalhos = _atalhosOperacao();
    return _sectionCard(
      icon: Icons.bolt_outlined,
      title: _txt('caixa.operacoes.mobile.quickActions', 'Ações rápidas'),
      subtitle: _txt(
        'caixa.operacoes.mobile.quickActionsSubtitle',
        'Toque em uma operação para orientar o lançamento.',
      ),
      child: Column(
        children: <Widget>[
          ...atalhos.map(
            (_OperacaoCaixaMobileData item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _operationCard(item),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _busy
                          ? null
                          : () => setState(() {
                            _mostrarPainelFechamento =
                                !_mostrarPainelFechamento;
                            _tipoSelecionado = null;
                          }),
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: Text(
                    _mostrarPainelFechamento
                        ? _txt('caixa.operacoes.mobile.hideClosing', 'Ocultar')
                        : _txt(
                          'caixa.operacoes.mobile.prepareClosing',
                          'Preparar fechamento',
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _confirmarEncerramentoSessao,
                  icon: const Icon(Icons.power_settings_new_rounded),
                  label: Text(
                    _txt('caixa.operacoes.mobile.closeSession', 'Encerrar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _operationCard(_OperacaoCaixaMobileData item) {
    final bool selected = _tipoSelecionado == item.tipo;
    return Material(
      color: selected ? _withAlpha(item.color, 0.08) : SixMobilePalette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap:
            _busy
                ? null
                : () => setState(() {
                  _tipoSelecionado = item.tipo;
                  _mostrarPainelFechamento = false;
                }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected
                      ? _withAlpha(item.color, 0.55)
                      : SixMobilePalette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              _iconBox(
                item.icon,
                bg: _withAlpha(item.color, 0.10),
                fg: item.color,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? item.color : SixMobilePalette.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioMovimento() {
    return _sectionCard(
      icon: Icons.edit_note_rounded,
      title: _txt(
        'caixa.operacoes.mobile.entryTitle',
        'Lançamento operacional',
      ),
      subtitle:
          _tipoSelecionado == null
              ? _txt(
                'caixa.operacoes.mobile.entrySubtitleEmpty',
                'Escolha uma ação rápida ou selecione o tipo da operação.',
              )
              : '${_txt('caixa.operacoes.mobile.entrySubtitleFilled', 'Preencha os dados da operação')} ${_labelTipo(_tipoSelecionado!)}.',
      child: Column(
        children: <Widget>[
          _selectorField(
            label: _txt(
              'caixa.operacoes.mobile.operationType',
              'Tipo da operação',
            ),
            value:
                _tipoSelecionado == null
                    ? _txt('caixa.operacoes.mobile.select', 'Selecione')
                    : _labelTipo(_tipoSelecionado!),
            icon: Icons.category_outlined,
            onTap: _selecionarTipoOperacao,
          ),
          const SizedBox(height: 12),
          _textField(
            label: _txt('caixa.operacoes.mobile.amount', 'Valor'),
            controller: _valorController,
            hint: _formatarDecimalDigitavel(0),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText:
                '${context.read<LocaleSettingsProvider>().currencyCode} ',
          ),
          const SizedBox(height: 12),
          _selectorField(
            label: _txt(
              'caixa.operacoes.mobile.relatedMethod',
              'Forma relacionada',
            ),
            value:
                _tipoRecebimentoSelecionado == null
                    ? _txt('caixa.operacoes.mobile.select', 'Selecione')
                    : _descricaoTipoRecebimentoConfigurado(
                      _tipoRecebimentoSelecionado!,
                    ),
            icon: Icons.payments_outlined,
            onTap: _selecionarFormaRelacionada,
          ),
          const SizedBox(height: 12),
          _textField(
            label: _txt(
              'caixa.operacoes.mobile.reference',
              'Referência / comprovante',
            ),
            controller: _referenciaController,
            hint: 'MOV-001',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          _textField(
            label: _txt('caixa.operacoes.mobile.note', 'Observação'),
            controller: _observacaoController,
            hint: _txt(
              'caixa.operacoes.mobile.noteHint',
              'Descreva o motivo da movimentação.',
            ),
            keyboardType: TextInputType.multiline,
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _vincularVenda,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              _txt(
                'caixa.operacoes.mobile.hasSaleLink',
                'Possui vínculo com venda',
              ),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              _txt(
                'caixa.operacoes.mobile.hasSaleLinkSubtitle',
                'Use em estornos ou situações relacionadas a atendimento anterior.',
              ),
            ),
            onChanged:
                _busy
                    ? null
                    : (bool? value) =>
                        setState(() => _vincularVenda = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _salvarMovimento,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              _txt(
                'caixa.operacoes.mobile.saveMovement',
                'Registrar movimentação',
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: SixMobilePalette.accent,
              foregroundColor: SixMobilePalette.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _limparFormularioMovimento,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              _txt('caixa.operacoes.mobile.clearForm', 'Limpar formulário'),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoOperacional() {
    return _sectionCard(
      icon: Icons.fact_check_outlined,
      title: _txt(
        'caixa.operacoes.mobile.methodSummary',
        'Conferência por forma',
      ),
      subtitle: _txt(
        'caixa.operacoes.mobile.methodSummarySubtitle',
        'Resumo pelos tipos configurados no caixa.',
      ),
      child: Column(
        children: <Widget>[
          ..._linhasResumoPorTipoRecebimento().map(
            (_ResumoTipoRecebimentoData linha) =>
                _summaryLine(linha.label, _formatarValor(linha.valor)),
          ),
          const Divider(height: 22),
          _checkItem(
            checked: _temCaixaAberto,
            title: _txt('caixa.operacoes.mobile.cashOpen', 'Caixa aberto'),
          ),
          _checkItem(
            checked: _movimentos.isNotEmpty,
            title: _txt(
              'caixa.operacoes.mobile.hasMovements',
              'Movimentações registradas',
            ),
          ),
          _checkItem(
            checked: _movimentos.any(
              (MovimentoCaixa item) =>
                  item.status.toLowerCase() == 'pendenteconferencia',
            ),
            title: _txt(
              'caixa.operacoes.mobile.hasPending',
              'Há pendências para conferência',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelFechamento() {
    final ResumoCaixa? resumo = _resumo;
    if (resumo == null) return const SizedBox.shrink();

    return _sectionCard(
      icon: Icons.task_alt_rounded,
      title: _txt('caixa.operacoes.mobile.closingTitle', 'Fechamento de caixa'),
      subtitle: _txt(
        'caixa.operacoes.mobile.closingSubtitle',
        'Informe os valores apurados para comparar com o saldo esperado.',
      ),
      child: Column(
        children: <Widget>[
          _textField(
            label:
                '${_labelTipoRecebimentoPorCodigo('tipo1', 'Dinheiro')} apurado',
            controller: _fechamentoDinheiroController,
            hint: _formatarValor(resumo.totalDinheiro),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText:
                '${context.read<LocaleSettingsProvider>().currencyCode} ',
          ),
          const SizedBox(height: 12),
          _textField(
            label: '${_labelTipoRecebimentoPorCodigo('tipo2', 'Pix')} apurado',
            controller: _fechamentoPixController,
            hint: _formatarValor(resumo.totalPix),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText:
                '${context.read<LocaleSettingsProvider>().currencyCode} ',
          ),
          const SizedBox(height: 12),
          _textField(
            label: _txt(
              'caixa.operacoes.mobile.cardsAmount',
              'Cartões apurados',
            ),
            controller: _fechamentoCartaoController,
            hint: _formatarValor(
              resumo.totalCartaoCredito + resumo.totalCartaoDebito,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText:
                '${context.read<LocaleSettingsProvider>().currencyCode} ',
          ),
          const SizedBox(height: 12),
          _readOnlyInfo(
            label: _txt(
              'caixa.operacoes.mobile.expectedBalance',
              'Saldo esperado',
            ),
            value: _formatarValor(resumo.saldoEsperado),
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          _textField(
            label: _txt(
              'caixa.operacoes.mobile.closingNote',
              'Observação do fechamento',
            ),
            controller: _fechamentoObservacaoController,
            hint: _txt(
              'caixa.operacoes.mobile.closingNoteHint',
              'Detalhe divergências, conferências e observações finais.',
            ),
            keyboardType: TextInputType.multiline,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _fecharCaixa,
            icon: const Icon(Icons.task_alt_rounded),
            label: Text(
              _txt(
                'caixa.operacoes.mobile.finishClosing',
                'Concluir fechamento',
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: SixMobilePalette.accent,
              foregroundColor: SixMobilePalette.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed:
                _busy
                    ? null
                    : () => setState(() => _mostrarPainelFechamento = false),
            icon: const Icon(Icons.close_rounded),
            label: Text(
              _txt(
                'caixa.operacoes.mobile.cancelClosing',
                'Cancelar fechamento',
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorico() {
    final List<MovimentoCaixa> movimentosVisiveis =
        _mostrarApenasHoje
            ? _movimentos
                .where(
                  (MovimentoCaixa movimento) =>
                      _isSameDay(movimento.dataHoraMovimento, DateTime.now()),
                )
                .toList(growable: false)
            : _movimentos;

    return _sectionCard(
      icon: Icons.history_rounded,
      title: _txt('caixa.operacoes.mobile.history', 'Histórico'),
      subtitle:
          '${movimentosVisiveis.length} ${_txt('caixa.operacoes.mobile.visibleRecords', 'registro(s) visível(is).')}',
      trailing: FilterChip(
        label: Text(_txt('caixa.operacoes.mobile.onlyToday', 'Hoje')),
        selected: _mostrarApenasHoje,
        onSelected:
            _busy
                ? null
                : (bool value) => setState(() => _mostrarApenasHoje = value),
      ),
      child:
          movimentosVisiveis.isEmpty
              ? _stateMessage(
                icon: Icons.receipt_long_outlined,
                title: _txt(
                  'caixa.operacoes.mobile.emptyHistoryTitle',
                  'Nenhuma movimentação',
                ),
                message: _txt(
                  'caixa.operacoes.mobile.emptyHistoryMessage',
                  'Os lançamentos aparecerão aqui após a abertura do caixa.',
                ),
              )
              : Column(
                children: movimentosVisiveis
                    .map(
                      (MovimentoCaixa movimento) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _movimentoCard(movimento),
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }

  Widget _movimentoCard(MovimentoCaixa movimento) {
    final Color color = _corPorNatureza(movimento.natureza);
    final String forma = _descricaoTipoRecebimentoMovimento(movimento);
    final bool cancelada = movimento.status.toLowerCase() == 'cancelada';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _iconBox(
                movimento.natureza.toLowerCase() == 'entrada'
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                bg: _withAlpha(color, 0.10),
                fg: color,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _labelTipo(movimento.tipoMovimento),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.titleText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: <Widget>[
                        _statusChip(
                          label: _labelStatusMovimento(movimento.status),
                          icon: Icons.circle,
                          foreground: _corPorStatus(movimento.status),
                          background: _withAlpha(
                            _corPorStatus(movimento.status),
                            0.10,
                          ),
                          border: _withAlpha(
                            _corPorStatus(movimento.status),
                            0.16,
                          ),
                        ),
                        _statusChip(
                          label: _labelNatureza(movimento.natureza),
                          icon: Icons.swap_vert_rounded,
                          foreground: color,
                          background: _withAlpha(color, 0.10),
                          border: _withAlpha(color, 0.16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatarValor(movimento.valor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            movimento.observacao.isEmpty
                ? _txt(
                  'caixa.operacoes.mobile.noNote',
                  'Sem observação informada.',
                )
                : movimento.observacao,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              _inlineInfo(
                Icons.person_outline_rounded,
                movimento.nomeColaborador,
              ),
              _inlineInfo(Icons.payments_outlined, forma),
              _inlineInfo(
                Icons.schedule_rounded,
                _formatarDataHora(movimento.dataHoraMovimento),
              ),
              _inlineInfo(
                Icons.receipt_long_outlined,
                movimento.referencia.isEmpty
                    ? _txt(
                      'caixa.operacoes.mobile.noReference',
                      'Sem referência',
                    )
                    : movimento.referencia,
              ),
            ],
          ),
          if (!cancelada) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _cancelarMovimento(movimento),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(_txt('common.cancel', 'Cancelar')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SixMobilePalette.error,
                  side: const BorderSide(color: SixMobilePalette.errorBorder),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _iconBox(
                icon,
                bg: SixMobilePalette.softAccentSurface,
                fg: SixMobilePalette.accent,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.titleText,
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
                        color: SixMobilePalette.mutedText,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _selectorField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      value: value,
      child: Material(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _busy ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: SixMobilePalette.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: SixMobilePalette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: !_busy,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        filled: true,
        fillColor: SixMobilePalette.softNeutralSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SixMobilePalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SixMobilePalette.highlightedBorder,
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _readOnlyInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return _infoTile(title: label, value: value, icon: icon, fullWidth: true);
  }

  Widget _infoTile({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints:
          fullWidth ? null : const BoxConstraints(minWidth: 142, maxWidth: 240),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: SixMobilePalette.accent, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
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

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem({required bool checked, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 19,
            color: checked ? _successColor : SixMobilePalette.mutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: SixMobilePalette.mutedText),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(
    IconData icon, {
    required Color bg,
    required Color fg,
    double size = 46,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size >= 44 ? 16 : 14),
      ),
      child: Icon(icon, color: fg, size: size >= 44 ? 23 : 20),
    );
  }

  Widget _animatedCurrencyText(double value, {TextStyle? style}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('caixa-currency-${value.toStringAsFixed(2)}'),
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return Text(
          _formatarValor(animatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }

  Widget _actionOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Semantics(
          liveRegion: true,
          label: _txt(
            'caixa.operacoes.mobile.processing',
            'Processando operação',
          ),
          child: Container(
            color: _withAlpha(Colors.black, 0.22),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: SixMobilePalette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SixMobilePalette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _txt(
                      'caixa.operacoes.mobile.processing',
                      'Processando operação',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: SixMobilePalette.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: SixMobilePalette.border),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: SixMobilePalette.navigationShadow,
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  Future<void> _selecionarCaixa() async {
    if (_caixasDisponiveis.isEmpty) {
      _snack(
        _txt('caixa.operacoes.mobile.noCashDesk', 'Nenhum caixa disponível.'),
      );
      return;
    }
    final CaixaOuGuiche? selected = await _showSelector<CaixaOuGuiche>(
      title: _txt('caixa.operacoes.mobile.cashDesk', 'Caixa / guichê'),
      subtitle: _txt(
        'caixa.operacoes.mobile.cashDeskSelectorSubtitle',
        'Escolha o caixa que será aberto para a operação.',
      ),
      searchHint: _txt('common.search', 'Buscar'),
      selected: _caixaSelecionado,
      options: _caixasDisponiveis
          .map(
            (CaixaOuGuiche item) => _SelectorOption<CaixaOuGuiche>(
              value: item,
              title: item.nome,
              subtitle: item.id,
              icon: Icons.store_mall_directory_outlined,
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || selected == null) return;
    setState(() => _caixaSelecionado = selected);
  }

  Future<void> _selecionarTipoOperacao() async {
    final List<OperacaoCaixaTipo> tipos = OperacaoCaixaTipo.values
        .where(
          (OperacaoCaixaTipo tipo) =>
              tipo != OperacaoCaixaTipo.aberturaCaixa &&
              tipo != OperacaoCaixaTipo.fechamentoCaixa,
        )
        .toList(growable: false);
    final OperacaoCaixaTipo? selected = await _showSelector<OperacaoCaixaTipo>(
      title: _txt('caixa.operacoes.mobile.operationType', 'Tipo da operação'),
      subtitle: _txt(
        'caixa.operacoes.mobile.operationTypeSelectorSubtitle',
        'Selecione o tipo técnico que será enviado ao caixa.',
      ),
      searchHint: _txt('common.search', 'Buscar'),
      selected: _tipoSelecionado,
      options: tipos
          .map(
            (OperacaoCaixaTipo tipo) => _SelectorOption<OperacaoCaixaTipo>(
              value: tipo,
              title: _labelTipo(tipo),
              subtitle: tipo.codigoApi,
              icon: _iconeTipo(tipo),
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || selected == null) return;
    setState(() => _tipoSelecionado = selected);
  }

  Future<void> _selecionarFormaRelacionada() async {
    final List<TiposRecebimento> tipos = _tiposRecebimentoAtivosOrdenados();
    if (tipos.isEmpty) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.noPaymentTypes',
          'Nenhuma forma relacionada ativa.',
        ),
      );
      return;
    }

    final TiposRecebimento? selected = await _showSelector<TiposRecebimento>(
      title: _txt('caixa.operacoes.mobile.relatedMethod', 'Forma relacionada'),
      subtitle: _txt(
        'caixa.operacoes.mobile.relatedMethodSelectorSubtitle',
        'Use a configuração compartilhada de formas de recebimento.',
      ),
      searchHint: _txt('common.search', 'Buscar'),
      selected: _tipoRecebimentoSelecionado,
      options: tipos
          .map(
            (TiposRecebimento tipo) => _SelectorOption<TiposRecebimento>(
              value: tipo,
              title: _descricaoTipoRecebimentoConfigurado(tipo),
              subtitle: tipo.codigoTipo,
              icon: Icons.payments_outlined,
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || selected == null) return;
    setState(() => _tipoRecebimentoSelecionado = selected);
  }

  Future<T?> _showSelector<T>({
    required String title,
    required String subtitle,
    required String searchHint,
    required List<_SelectorOption<T>> options,
    required T? selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder:
          (BuildContext context) => _OperacoesCaixaMobileSelectorSheet<T>(
            title: title,
            subtitle: subtitle,
            searchHint: searchHint,
            options: options,
            selected: selected,
          ),
    );
  }

  Future<void> _abrirCaixa() async {
    if (_caixaSelecionado == null) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.selectCashDesk',
          'Selecione um caixa / guichê.',
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _caixaService.abrirCaixa(
        AbrirCaixaRequest(
          idCaixaOuGuiche: _caixaSelecionado!.id,
          nomeCaixa: _caixaSelecionado!.nome,
          valorAbertura: _parseCurrency(_trocoInicialController.text),
        ),
      );
      await _carregarDadosIniciais(idCaixaPreferencial: _caixaSelecionado!.id);
      if (!mounted) return;
      _snack(
        _txt('caixa.operacoes.mobile.openSuccess', 'Caixa aberto com sucesso.'),
      );
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _salvarMovimento() async {
    if (!_temCaixaAberto) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.cashRequired',
          'Antes de lançar operações, faça a abertura do caixa.',
        ),
      );
      return;
    }
    if (_tipoSelecionado == null) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.selectOperationType',
          'Selecione o tipo da operação.',
        ),
      );
      return;
    }
    if (_tipoRecebimentoSelecionado == null) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.selectPaymentType',
          'Selecione a forma relacionada.',
        ),
      );
      return;
    }

    final double valor = _parseCurrency(_valorController.text);
    if (valor <= 0) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.invalidAmount',
          'Informe um valor válido.',
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _caixaService.registrarMovimentacao(
        RegistrarMovimentoRequest(
          idSessaoCaixa: _sessaoAtual!.idSessaoCaixa,
          tipoMovimento: _tipoSelecionado!,
          codigoTipoRecebimento: _tipoRecebimentoSelecionado!.codigoTipo,
          valor: valor,
          observacao: _observacaoController.text.trim(),
          referencia: _referenciaController.text.trim(),
          vinculadoVenda: _vincularVenda,
        ),
      );
      await _carregarMovimentosEResumo(_sessaoAtual!.idSessaoCaixa);
      _limparFormularioMovimento();
      if (mounted) {
        _snack(
          _txt(
            'caixa.operacoes.mobile.movementSuccess',
            'Movimentação registrada com sucesso.',
          ),
        );
      }
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _limparFormularioMovimento() {
    setState(() {
      _tipoSelecionado = null;
      _valorController.clear();
      _observacaoController.clear();
      _referenciaController.clear();
      _vincularVenda = false;
      final List<TiposRecebimento> tipos = _tiposRecebimentoAtivosOrdenados();
      _tipoRecebimentoSelecionado = tipos.isNotEmpty ? tipos.first : null;
    });
  }

  Future<void> _fecharCaixa() async {
    if (!_temCaixaAberto) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.cashRequired',
          'Antes de lançar operações, faça a abertura do caixa.',
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _caixaService.fecharCaixa(_montarRequestFechamentoCaixa());
      await _carregarDadosIniciais();
      if (!mounted) return;
      setState(() {
        _mostrarPainelFechamento = false;
        _fechamentoDinheiroController.clear();
        _fechamentoPixController.clear();
        _fechamentoCartaoController.clear();
        _fechamentoObservacaoController.clear();
      });
      _snack(
        _txt(
          'caixa.operacoes.mobile.closeSuccess',
          'Caixa fechado com sucesso.',
        ),
      );
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  FecharCaixaRequest _montarRequestFechamentoCaixa() {
    final ResumoCaixa? resumo = _resumo;
    final double dinheiro =
        _fechamentoDinheiroController.text.trim().isEmpty
            ? (resumo?.totalDinheiro ?? 0)
            : _parseCurrency(_fechamentoDinheiroController.text);
    final double pix =
        _fechamentoPixController.text.trim().isEmpty
            ? (resumo?.totalPix ?? 0)
            : _parseCurrency(_fechamentoPixController.text);
    final double cartao =
        _fechamentoCartaoController.text.trim().isEmpty
            ? ((resumo?.totalCartaoCredito ?? 0) +
                (resumo?.totalCartaoDebito ?? 0))
            : _parseCurrency(_fechamentoCartaoController.text);

    return FecharCaixaRequest(
      idSessaoCaixa: _sessaoAtual!.idSessaoCaixa,
      valorDinheiroApurado: dinheiro,
      valorPixApurado: pix,
      valorCartaoApurado: cartao,
      observacaoFechamento: _fechamentoObservacaoController.text.trim(),
    );
  }

  Future<void> _confirmarEncerramentoSessao() async {
    if (!_temCaixaAberto) {
      _snack(
        _txt(
          'caixa.operacoes.mobile.cashRequired',
          'Antes de lançar operações, faça a abertura do caixa.',
        ),
      );
      return;
    }

    final bool confirmou = await _confirmarAcao(
      title: _txt(
        'caixa.operacoes.mobile.closeSessionConfirm',
        'Encerrar sessão?',
      ),
      message: _txt(
        'caixa.operacoes.mobile.closeSessionConfirmMessage',
        'Esta ação encerrará o caixa atual. Você ainda poderá consultar o histórico da sessão.',
      ),
      confirmLabel: _txt('caixa.operacoes.mobile.closeSession', 'Encerrar'),
      icon: Icons.power_settings_new_rounded,
    );
    if (!confirmou) return;

    setState(() => _busy = true);
    try {
      await _caixaService.fecharCaixa(_montarRequestFechamentoCaixa());
      await _carregarDadosIniciais();
      if (!mounted) return;
      setState(() => _mostrarPainelFechamento = false);
      _snack(_txt('caixa.operacoes.mobile.sessionClosed', 'Sessão encerrada.'));
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelarMovimento(MovimentoCaixa movimento) async {
    final String forma = _descricaoTipoRecebimentoMovimento(movimento);
    final bool confirmou = await _confirmarAcao(
      title: _txt(
        'caixa.operacoes.mobile.cancelMovementTitle',
        'Cancelar movimentação?',
      ),
      message:
          '${_txt('caixa.operacoes.mobile.cancelMovementMessage', 'Deseja cancelar a operação')} ${_labelTipo(movimento.tipoMovimento)} em $forma no valor de ${_formatarValor(movimento.valor)}?',
      confirmLabel: _txt(
        'caixa.operacoes.mobile.cancelMovement',
        'Cancelar operação',
      ),
      icon: Icons.cancel_outlined,
      danger: true,
    );
    if (!confirmou) return;

    setState(() => _busy = true);
    try {
      await _caixaService.cancelarMovimentacao(movimento.idMovimento);
      await _carregarMovimentosEResumo(_sessaoAtual!.idSessaoCaixa);
      if (mounted) {
        _snack(
          _txt(
            'caixa.operacoes.mobile.movementCanceled',
            'Movimentação cancelada.',
          ),
        );
      }
    } catch (error) {
      if (mounted) _snack(_mensagemErro(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmarAcao({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    bool danger = false,
  }) async {
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: const BoxDecoration(
              color: SixMobilePalette.surface,
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: SixMobilePalette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _iconBox(
                      icon,
                      bg: _withAlpha(
                        danger
                            ? SixMobilePalette.error
                            : SixMobilePalette.accent,
                        0.10,
                      ),
                      fg:
                          danger
                              ? SixMobilePalette.error
                              : SixMobilePalette.accent,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: const TextStyle(
                              color: SixMobilePalette.titleText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: const TextStyle(
                              color: SixMobilePalette.mutedText,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(confirmLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        danger
                            ? SixMobilePalette.error
                            : SixMobilePalette.accent,
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
                  label: Text(_txt('common.back', 'Voltar')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SixMobilePalette.titleText,
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

    return result == true;
  }

  List<TiposRecebimento> _tiposRecebimentoAtivosOrdenados() {
    return _tiposRecebimento
      .where((TiposRecebimento item) => item.ativo)
      .toList(growable: false)..sort(
      (TiposRecebimento a, TiposRecebimento b) =>
          a.ordemExibicao.compareTo(b.ordemExibicao),
    );
  }

  String _descricaoTipoRecebimentoConfigurado(TiposRecebimento tipo) {
    final String descricao = tipo.descricaoExibicao.trim();
    return descricao.isNotEmpty
        ? descricao
        : _labelTipoRecebimentoPorCodigo(tipo.codigoTipo, tipo.codigoTipo);
  }

  String _descricaoTipoRecebimentoMovimento(MovimentoCaixa movimento) {
    final String descricao = movimento.descricaoTipoRecebimento.trim();
    if (descricao.isNotEmpty) return descricao;
    return _labelTipoRecebimentoPorCodigo(
      movimento.codigoTipoRecebimento,
      movimento.descricao.trim().isNotEmpty
          ? movimento.descricao.trim()
          : _txt('caixa.operacoes.mobile.methodMissing', 'Forma não informada'),
    );
  }

  String _labelTipoRecebimentoPorCodigo(String codigoTipo, String fallback) {
    for (final TiposRecebimento tipo in _tiposRecebimento) {
      if (tipo.codigoTipo.toLowerCase() == codigoTipo.toLowerCase()) {
        final String descricao = tipo.descricaoExibicao.trim();
        if (descricao.isNotEmpty) return descricao;
      }
    }
    return fallback;
  }

  List<_ResumoTipoRecebimentoData> _linhasResumoPorTipoRecebimento() {
    final List<TiposRecebimento> tipos = _tiposRecebimentoAtivosOrdenados();
    if (tipos.isEmpty) {
      return <_ResumoTipoRecebimentoData>[
        _ResumoTipoRecebimentoData(
          _txt('caixa.operacoes.mobile.methodMissing', 'Forma não informada'),
          0,
        ),
      ];
    }

    return tipos
        .map(
          (TiposRecebimento tipo) => _ResumoTipoRecebimentoData(
            _descricaoTipoRecebimentoConfigurado(tipo),
            _valorResumoPorCodigoTipo(tipo.codigoTipo),
          ),
        )
        .toList(growable: false);
  }

  double _valorResumoPorCodigoTipo(String codigoTipo) {
    final InformacoesCaixaComSomatorioResponse? resumo =
        _movimentosComSomatorio;
    if (resumo == null) return 0;
    switch (codigoTipo.toLowerCase()) {
      case 'tipo1':
        return resumo.tipo1;
      case 'tipo2':
        return resumo.tipo2;
      case 'tipo3':
        return resumo.tipo3;
      case 'tipo4':
        return resumo.tipo4;
      case 'tipo5':
        return resumo.tipo5;
      case 'tipo6':
        return resumo.tipo6;
      case 'tipo7':
        return resumo.tipo7;
      case 'tipo8':
        return resumo.tipo8;
      case 'tipo9':
        return resumo.tipo9;
      case 'tipo10':
        return resumo.tipo10;
      default:
        return 0;
    }
  }

  List<_OperacaoCaixaMobileData> _atalhosOperacao() {
    return <_OperacaoCaixaMobileData>[
      _OperacaoCaixaMobileData(
        tipo: OperacaoCaixaTipo.suprimento,
        title: _txt('caixa.operacoes.mobile.supply', 'Suprimento'),
        subtitle: _txt(
          'caixa.operacoes.mobile.supplySubtitle',
          'Adicionar valores ao caixa.',
        ),
        icon: Icons.add_card_rounded,
        color: _successColor,
      ),
      _OperacaoCaixaMobileData(
        tipo: OperacaoCaixaTipo.sangria,
        title: _txt('caixa.operacoes.mobile.cashOut', 'Sangria'),
        subtitle: _txt(
          'caixa.operacoes.mobile.cashOutSubtitle',
          'Retirar excesso de numerário.',
        ),
        icon: Icons.outbox_rounded,
        color: _warningColor,
      ),
      _OperacaoCaixaMobileData(
        tipo: OperacaoCaixaTipo.retiradaDespesa,
        title: _txt('caixa.operacoes.mobile.expense', 'Despesa'),
        subtitle: _txt(
          'caixa.operacoes.mobile.expenseSubtitle',
          'Registrar saída operacional.',
        ),
        icon: Icons.receipt_long_rounded,
        color: SixMobilePalette.error,
      ),
      _OperacaoCaixaMobileData(
        tipo: OperacaoCaixaTipo.ajuste,
        title: _txt('caixa.operacoes.mobile.adjustment', 'Ajuste'),
        subtitle: _txt(
          'caixa.operacoes.mobile.adjustmentSubtitle',
          'Corrigir diferenças operacionais.',
        ),
        icon: Icons.tune_rounded,
        color: SixMobilePalette.accent,
      ),
      _OperacaoCaixaMobileData(
        tipo: OperacaoCaixaTipo.recebimentoAvulso,
        title: _txt(
          'caixa.operacoes.mobile.singleReceipt',
          'Recebimento avulso',
        ),
        subtitle: _txt(
          'caixa.operacoes.mobile.singleReceiptSubtitle',
          'Entrada sem vínculo direto com venda.',
        ),
        icon: Icons.arrow_downward_rounded,
        color: _successColor,
      ),
      _OperacaoCaixaMobileData(
        tipo: OperacaoCaixaTipo.pagamentoAvulso,
        title: _txt('caixa.operacoes.mobile.singlePayment', 'Pagamento avulso'),
        subtitle: _txt(
          'caixa.operacoes.mobile.singlePaymentSubtitle',
          'Saída operacional pontual.',
        ),
        icon: Icons.arrow_upward_rounded,
        color: SixMobilePalette.error,
      ),
    ];
  }

  IconData _iconeTipo(OperacaoCaixaTipo tipo) {
    switch (tipo) {
      case OperacaoCaixaTipo.suprimento:
        return Icons.add_card_rounded;
      case OperacaoCaixaTipo.sangria:
        return Icons.outbox_rounded;
      case OperacaoCaixaTipo.retiradaDespesa:
        return Icons.receipt_long_rounded;
      case OperacaoCaixaTipo.ajuste:
        return Icons.tune_rounded;
      case OperacaoCaixaTipo.estorno:
        return Icons.undo_rounded;
      case OperacaoCaixaTipo.recebimentoAvulso:
        return Icons.arrow_downward_rounded;
      case OperacaoCaixaTipo.pagamentoAvulso:
        return Icons.arrow_upward_rounded;
      case OperacaoCaixaTipo.aberturaCaixa:
        return Icons.lock_open_rounded;
      case OperacaoCaixaTipo.fechamentoCaixa:
        return Icons.lock_outline_rounded;
    }
  }

  Color _corPorNatureza(String? natureza) {
    if (natureza == null) return SixMobilePalette.mutedText;
    return natureza.toLowerCase() == 'entrada'
        ? _successColor
        : SixMobilePalette.error;
  }

  Color _corPorStatus(String? status) {
    if (status == null) return SixMobilePalette.mutedText;
    switch (status.toLowerCase()) {
      case 'aberta':
        return SixMobilePalette.accent;
      case 'concluida':
        return _successColor;
      case 'cancelada':
        return SixMobilePalette.error;
      case 'pendenteconferencia':
        return _warningColor;
      default:
        return SixMobilePalette.mutedText;
    }
  }

  String _labelTipo(dynamic tipo) {
    String? tipoStr;
    if (tipo is OperacaoCaixaTipo) {
      tipoStr = tipo.name;
    } else if (tipo is String) {
      tipoStr = tipo;
    }
    if (tipoStr == null) return '--';
    switch (tipoStr) {
      case 'aberturaCaixa':
      case 'ABERTURA_CAIXA':
        return _txt('caixa.operacoes.mobile.typeOpenCash', 'Abertura de caixa');
      case 'fechamentoCaixa':
      case 'FECHAMENTO_CAIXA':
        return _txt(
          'caixa.operacoes.mobile.typeCloseCash',
          'Fechamento de caixa',
        );
      case 'suprimento':
      case 'SUPRIMENTO':
        return _txt('caixa.operacoes.mobile.supply', 'Suprimento');
      case 'sangria':
      case 'SANGRIA':
        return _txt('caixa.operacoes.mobile.cashOut', 'Sangria');
      case 'retiradaDespesa':
      case 'RETIRADA_DESPESA':
        return _txt(
          'caixa.operacoes.mobile.typeExpenseWithdrawal',
          'Retirada para despesa',
        );
      case 'ajuste':
      case 'AJUSTE':
        return _txt('caixa.operacoes.mobile.adjustment', 'Ajuste');
      case 'estorno':
      case 'ESTORNO':
        return _txt('caixa.operacoes.mobile.reversal', 'Estorno');
      case 'recebimentoAvulso':
      case 'RECEBIMENTO_AVULSO':
        return _txt(
          'caixa.operacoes.mobile.singleReceipt',
          'Recebimento avulso',
        );
      case 'RECEBIMENTO_FINANCEIRO':
        return _txt(
          'caixa.operacoes.mobile.financialReceipt',
          'Recebimento financeiro',
        );
      case 'pagamentoAvulso':
      case 'PAGAMENTO_AVULSO':
        return _txt('caixa.operacoes.mobile.singlePayment', 'Pagamento avulso');
      default:
        return tipoStr;
    }
  }

  String _labelNatureza(String? natureza) {
    if (natureza == null) return '--';
    switch (natureza.toLowerCase()) {
      case 'entrada':
        return _txt('caixa.operacoes.mobile.inflow', 'Entrada');
      case 'saida':
        return _txt('caixa.operacoes.mobile.outflow', 'Saída');
      default:
        return natureza;
    }
  }

  String _labelStatusMovimento(String? status) {
    if (status == null) return '--';
    switch (status.toLowerCase()) {
      case 'aberta':
        return _txt('caixa.operacoes.mobile.statusOpen', 'Aberta');
      case 'concluida':
        return _txt('caixa.operacoes.mobile.statusDone', 'Concluída');
      case 'cancelada':
        return _txt('caixa.operacoes.mobile.statusCanceled', 'Cancelada');
      case 'pendenteconferencia':
        return _txt(
          'caixa.operacoes.mobile.statusPendingCheck',
          'Pendente conferência',
        );
      default:
        return status;
    }
  }

  String _nomeColaboradorAtual() {
    final usuario = UsuarioProvider().usuario;
    if (usuario == null) {
      return _txt('caixa.operacoes.mobile.collaborator', 'Colaborador');
    }
    if (usuario.nomeDeGuerra.trim().isNotEmpty) {
      return usuario.nomeDeGuerra.trim();
    }
    final String nomeCompleto = '${usuario.nome} ${usuario.sobrenome}'.trim();
    return nomeCompleto.isEmpty
        ? _txt('caixa.operacoes.mobile.collaborator', 'Colaborador')
        : nomeCompleto;
  }

  String _formatarValor(num valor) {
    return context.read<LocaleSettingsProvider>().formatCurrency(valor);
  }

  String _formatarDecimalDigitavel(num valor) {
    return context.read<LocaleSettingsProvider>().formatDecimal(valor);
  }

  double _parseCurrency(String text) {
    final LocaleSettingsProvider localeSettings =
        context.read<LocaleSettingsProvider>();
    String cleaned =
        text
            .replaceAll(localeSettings.currencyCode, '')
            .replaceAll(RegExp(r'\s'), '')
            .replaceAll(localeSettings.thousandSeparator, '')
            .replaceAll(localeSettings.decimalSeparator, '.')
            .replaceAll(RegExp(r'[^0-9.\-]'), '')
            .trim();
    if (cleaned.indexOf('.') != cleaned.lastIndexOf('.')) {
      final int lastSeparator = cleaned.lastIndexOf('.');
      cleaned =
          cleaned.substring(0, lastSeparator).replaceAll('.', '') +
          cleaned.substring(lastSeparator);
    }
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatarDataHora(String? value) {
    if (value == null || value.isEmpty) return '--';
    final DateTime? dateTime = DateTime.tryParse(value);
    if (dateTime == null) return value;
    final LocaleSettingsProvider localeSettings =
        context.read<LocaleSettingsProvider>();
    return '${localeSettings.formatDate(dateTime)} ${localeSettings.formatTime(dateTime)}';
  }

  bool _isSameDay(String? value, DateTime other) {
    if (value == null || value.isEmpty) return false;
    final DateTime? dateTime = DateTime.tryParse(value);
    if (dateTime == null) return false;
    return dateTime.year == other.year &&
        dateTime.month == other.month &&
        dateTime.day == other.day;
  }

  String _mensagemErro(Object error) {
    final String errorText = error.toString();
    if (errorText.contains('statusCode: 401') || errorText.contains(' 401')) {
      return _txt(
        'caixa.operacoes.mobile.errorUnauthorized',
        'Sessão expirada. Faça login novamente.',
      );
    }
    if (errorText.contains('statusCode: 403') || errorText.contains(' 403')) {
      return _txt(
        'caixa.operacoes.mobile.errorForbidden',
        'Você não possui permissão para operar este caixa.',
      );
    }
    if (errorText.contains('statusCode: 404') || errorText.contains(' 404')) {
      return _txt(
        'caixa.operacoes.mobile.errorNotFound',
        'Informação de caixa não encontrada.',
      );
    }
    return _txt(
      'caixa.operacoes.mobile.errorGeneric',
      'Não foi possível concluir a operação de caixa.',
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);
}

class _OperacaoCaixaMobileData {
  const _OperacaoCaixaMobileData({
    required this.tipo,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final OperacaoCaixaTipo tipo;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _ResumoTipoRecebimentoData {
  const _ResumoTipoRecebimentoData(this.label, this.valor);

  final String label;
  final double valor;
}

class _SelectorOption<T> {
  const _SelectorOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final T value;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _OperacoesCaixaMobileSelectorSheet<T> extends StatefulWidget {
  const _OperacoesCaixaMobileSelectorSheet({
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.options,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final List<_SelectorOption<T>> options;
  final T? selected;

  @override
  State<_OperacoesCaixaMobileSelectorSheet<T>> createState() =>
      _OperacoesCaixaMobileSelectorSheetState<T>();
}

class _OperacoesCaixaMobileSelectorSheetState<T>
    extends State<_OperacoesCaixaMobileSelectorSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_SelectorOption<T>> filtered = widget.options
        .where((_SelectorOption<T> option) {
          final String haystack =
              '${option.title} ${option.subtitle}'.toLowerCase();
          return haystack.contains(_query.trim().toLowerCase());
        })
        .toList(growable: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: SixMobilePalette.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: SixMobilePalette.softAccentSurface,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: SixMobilePalette.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SixMobilePalette.titleText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SixMobilePalette.mutedText,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.t('common.close', fallback: 'Fechar'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon:
                          _query.isEmpty
                              ? null
                              : IconButton(
                                tooltip: context.t(
                                  'common.clear',
                                  fallback: 'Limpar',
                                ),
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      filled: true,
                      fillColor: SixMobilePalette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: SixMobilePalette.border,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      filtered.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                context.t(
                                  'common.noResults',
                                  fallback: 'Nenhum resultado encontrado',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: SixMobilePalette.mutedText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                          : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            itemCount: filtered.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final _SelectorOption<T> option = filtered[index];
                              final bool selected =
                                  option.value == widget.selected;
                              return Material(
                                color:
                                    selected
                                        ? SixMobilePalette.softAccentSurface
                                        : SixMobilePalette.surface,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap:
                                      () => Navigator.of(
                                        context,
                                      ).pop(option.value),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color:
                                            selected
                                                ? SixMobilePalette
                                                    .highlightedBorder
                                                : SixMobilePalette.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color:
                                                selected
                                                    ? SixMobilePalette.surface
                                                    : SixMobilePalette
                                                        .softNeutralSurface,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Icon(
                                            option.icon,
                                            color: SixMobilePalette.accent,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                option.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color:
                                                      SixMobilePalette
                                                          .titleText,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              if (option
                                                  .subtitle
                                                  .isNotEmpty) ...<Widget>[
                                                const SizedBox(height: 3),
                                                Text(
                                                  option.subtitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color:
                                                        SixMobilePalette
                                                            .mutedText,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (selected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: SixMobilePalette.accent,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
