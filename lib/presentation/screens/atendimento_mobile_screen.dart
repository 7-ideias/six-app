import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/data/models/tela_inicial_models.dart';
import 'package:sixpos/data/services/telainicial_web/tela_inicial_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_app_bar_profile_action.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_mobile_screen.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_mobile_screen.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_mobile_screen.dart';
import 'package:sixpos/presentation/screens/pdv_mobile_screen.dart';
import 'package:sixpos/presentation/screens/vendas_nao_liquidadas_mobile_screen.dart';

import '../components/nav_bar_mobile.dart';

typedef AtendimentoMobileNavigate =
    void Function(BuildContext context, Widget page);

class AtendimentoMobileScreen extends StatefulWidget {
  const AtendimentoMobileScreen({
    super.key,
    @visibleForTesting this.apiClient,
    @visibleForTesting this.procedureCoordinator,
    @visibleForTesting this.onNavigate,
    @visibleForTesting this.showBottomNavigationBar = true,
    @visibleForTesting this.enableWebSocket = true,
  });

  final TelaInicialWebApiClient? apiClient;
  final OperationalProcedureFlowCoordinator? procedureCoordinator;
  final AtendimentoMobileNavigate? onNavigate;
  final bool showBottomNavigationBar;
  final bool enableWebSocket;

  @override
  State<AtendimentoMobileScreen> createState() =>
      _AtendimentoMobileScreenState();
}

class _AtendimentoMobileScreenState extends State<AtendimentoMobileScreen> {
  static const Color _bg = SixMobilePalette.background;
  static const Color _primary = SixMobilePalette.primary;
  static const Color _secondary = SixMobilePalette.secondary;
  static const Color _accent = SixMobilePalette.accent;
  static const Color _serviceAccent = Color(0xFF7C3AED);
  static const Color _receiveAccent = Color(0xFF16A34A);
  static const Color _lockedAccent = Color(0xFF64748B);

  static const String _heroAsset =
      'assets/images/atendimento mobile/atendimento-hero.png';
  static const String _saleAsset =
      'assets/images/atendimento mobile/acao-nova-venda.png';
  static const String _serviceAsset =
      'assets/images/atendimento mobile/acao-novo-servico.png';
  static const String _receiveAsset =
      'assets/images/atendimento mobile/acao-receber.png';

  late final TelaInicialWebApiClient _api;
  late final OperationalProcedureFlowCoordinator _procedureCoordinator;
  final NotificacaoService _notificacoes = NotificacaoService();

  TelaInicialModel? _resumo;
  bool _loading = true;
  String? _erro;
  int _totalNotificacoesConhecidas = 0;
  bool _openingNewSale = false;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpResumoDaEmpresaApiClient(canal: 'mobile');
    _procedureCoordinator =
        widget.procedureCoordinator ?? OperationalProcedureFlowCoordinator();
    _totalNotificacoesConhecidas = _notificacoes.total;
    _notificacoes.addListener(_onNotificacoesChanged);
    _garantirWebSocketMobile();
    _carregarResumo();
  }

  @override
  void dispose() {
    _notificacoes.removeListener(_onNotificacoesChanged);
    super.dispose();
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  void _onNotificacoesChanged() {
    if (!mounted) return;
    final int totalAtual = _notificacoes.total;
    final bool recebeuNova = totalAtual > _totalNotificacoesConhecidas;
    _totalNotificacoesConhecidas = totalAtual;
    setState(() {});

    final String? mensagem =
        _notificacoes.ultimaNotificacao?.description.trim();
    if (!recebeuNova || mensagem == null || mensagem.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
      );
    });
  }

  void _garantirWebSocketMobile() {
    if (kIsWeb || !widget.enableWebSocket) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) connectStomp();
      });
    });
  }

  Future<void> _carregarResumo() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final TelaInicialModel resumo = await _api.getResumo();
      if (!mounted) return;
      setState(() => _resumo = resumo);
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = error.toString());
      debugPrint('[AtendimentoMobileScreen] Erro ao buscar resumo: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: _txt('atendimento.mobile.title', 'Atendimento'),
      backgroundColor: _bg,
      primaryColor: _primary,
      secondaryColor: _secondary,
      accentColor: _accent,
      automaticallyImplyLeading: false,
      leading: const SixMobileAppBarProfileAction(),
      actions: <Widget>[
        IconButton(
          tooltip: _txt(
            'gestao.settings.item.notifications.title',
            'Notificações',
          ),
          icon: _notificationIcon(),
          onPressed: () => _go(const NotificacoesMobileScreen()),
        ),
      ],
      bodyBuilder: _buildContent,
      bottomNavigationBar:
          kIsWeb || !widget.showBottomNavigationBar
              ? null
              : const NavBarMobile(initialIndex: 2),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        edgeOffset: topInset,
        displacement: 18,
        color: _accent,
        backgroundColor: SixMobilePalette.surface,
        onRefresh: _carregarResumo,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
          children: <Widget>[
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 40),
              child: _AtendimentoHeroCard(
                title: _txt(
                  'atendimento.mobile.heroTitle',
                  'O que você deseja fazer?',
                ),
                subtitle: _txt(
                  'atendimento.mobile.heroSubtitle',
                  'Venda, serviço ou recebimento em poucos passos',
                ),
                assetPath: _heroAsset,
              ),
            ),
            const SizedBox(height: 16),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 95),
              child: _PrimaryActionsStrip(actions: _primaryActions()),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: _txt('atendimento.mobile.followToday', 'Acompanhe hoje'),
            ),
            const SizedBox(height: 12),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 160),
              child: _AtendimentoActionListCard(
                hasError: _erro != null,
                rows: _followUpRows(),
                loadingLabel: _txt('common.loading', 'Carregando...'),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: _txt('atendimento.mobile.moreOptions', 'Mais opções'),
            ),
            const SizedBox(height: 12),
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 220),
              child: _AtendimentoActionListCard(
                rows: _secondaryRows(),
                loadingLabel: _txt('common.loading', 'Carregando...'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationIcon() {
    final int naoLidas = _notificacoes.naoLidas;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          naoLidas > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
        ),
        if (naoLidas > 0)
          Positioned(
            right: -6,
            top: -6,
            child: SixPulsingBadge(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: SixMobilePalette.notificationBadge,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: SixMobilePalette.onPrimary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  naoLidas > 9 ? '+9' : naoLidas.toString(),
                  style: const TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_PrimaryActionData> _primaryActions() {
    return <_PrimaryActionData>[
      _PrimaryActionData(
        id: 'new-sale',
        title: _txt('atendimento.mobile.newSaleTitle', 'Nova venda'),
        subtitle: _txt('atendimento.mobile.newSaleSubtitle', 'Vender produtos'),
        assetPath: _saleAsset,
        accentColor: _accent,
        onTap: _startNewSale,
      ),
      _PrimaryActionData(
        id: 'new-service',
        title: _txt('atendimento.mobile.newServiceTitle', 'Novo serviço'),
        subtitle: _txt(
          'atendimento.mobile.newServiceSubtitle',
          'Abrir atendimento técnico',
        ),
        assetPath: _serviceAsset,
        accentColor: _serviceAccent,
        onTap: () => _go(const AtendimentoTecnicoMobileScreen()),
      ),
      _PrimaryActionData(
        id: 'receive',
        title: _txt('atendimento.mobile.receiveTitle', 'Receber'),
        subtitle: _txt(
          'atendimento.mobile.receiveSubtitle',
          'Baixar vendas em aberto',
        ),
        assetPath: _receiveAsset,
        accentColor: _receiveAccent,
        onTap: () => _go(const VendasNaoLiquidadasMobileScreen()),
      ),
    ];
  }

  List<_AtendimentoListRowData> _followUpRows() {
    final bool hasError = _erro != null;
    final String errorSubtitle = _txt(
      'atendimento.mobile.counterLoadError',
      'Não foi possível atualizar agora',
    );

    return <_AtendimentoListRowData>[
      _AtendimentoListRowData(
        id: 'sales',
        title: _txt(
          'atendimento.mobile.salesToReceiveTitle',
          'Vendas a receber',
        ),
        subtitle:
            hasError
                ? errorSubtitle
                : _txt(
                  'atendimento.mobile.salesToReceiveSubtitle',
                  'Vendas não liquidadas',
                ),
        icon: Icons.point_of_sale_outlined,
        accentColor: _accent,
        showCounter: true,
        value: _resumo?.totalVendasAbertas,
        loading: _loading,
        hasError: hasError,
        onTap: () => _go(const VendasNaoLiquidadasMobileScreen()),
      ),
      _AtendimentoListRowData(
        id: 'services',
        title: _txt(
          'atendimento.mobile.servicesInProgressTitle',
          'Serviços em andamento',
        ),
        subtitle:
            hasError
                ? errorSubtitle
                : _txt(
                  'atendimento.mobile.servicesInProgressSubtitle',
                  'Atendimentos técnicos ativos',
                ),
        icon: Icons.fact_check_outlined,
        accentColor: _serviceAccent,
        showCounter: true,
        value: _resumo?.totalAtendimentoTecnicoEmAndamento,
        loading: _loading,
        hasError: hasError,
        onTap: () => _go(const AtendimentosTecnicosMobileScreen()),
      ),
    ];
  }

  List<_AtendimentoListRowData> _secondaryRows() {
    final String soonLabel = _txt('common.soon', 'Em breve');

    return <_AtendimentoListRowData>[
      _AtendimentoListRowData(
        id: 'cash',
        title: _txt(
          'atendimento.mobile.cashOperationsTitle',
          'Operações de caixa',
        ),
        subtitle: _txt(
          'atendimento.mobile.cashOperationsSubtitle',
          'Abrir, movimentar e fechar caixa',
        ),
        icon: Icons.account_balance_wallet_rounded,
        accentColor: _accent,
        onTap: () => _go(const OperacoesCaixaMobileScreen()),
      ),
      _AtendimentoListRowData(
        id: 'return',
        title: _txt('operacao.mobile.returnTitle', 'Devolução'),
        subtitle: _txt('operacao.mobile.returnUnavailable', 'Em breve'),
        icon: Icons.assignment_return_outlined,
        accentColor: _lockedAccent,
        enabled: false,
        statusLabel: soonLabel,
      ),
    ];
  }

  Future<void> _startNewSale() async {
    if (_openingNewSale) return;
    _openingNewSale = true;
    try {
      final ProcedureFlowResult result = await _procedureCoordinator.execute(
        context: context,
        operationPoint: ProcedureOperationPoint.saleStartBefore,
      );
      if (!mounted) return;
      if (result.shouldContinue) _openNewSale();
    } finally {
      _openingNewSale = false;
    }
  }

  void _openNewSale() => _go(const PdvMobileScreen());

  void _go(Widget page) {
    final AtendimentoMobileNavigate? navigate = widget.onNavigate;
    if (navigate != null) {
      navigate(context, page);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _AtendimentoHeroCard extends StatelessWidget {
  const _AtendimentoHeroCard({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });

  final String title;
  final String subtitle;
  final String assetPath;

  static const Color _surface = Color(0xFFF7FAFF);

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1);

    return Semantics(
      container: true,
      header: true,
      label: '$title. $subtitle',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool compact = width < 350 || textScale >= 1.2;
          final bool tightText = textScale >= 1.35;
          final double illustrationWidth = (width * (compact ? 0.43 : 0.49))
              .clamp(118.0, 184.0);
          final double illustrationHeight = (compact
                  ? illustrationWidth * 0.94
                  : illustrationWidth * 0.98)
              .clamp(104.0, 158.0);
          final double illustrationRightOffset = compact ? -24 : -28;
          final double illustrationBottomOffset = compact ? -22 : -26;
          final double titleSize = tightText ? 18 : (compact ? 20 : 22);

          return Container(
            constraints: BoxConstraints(minHeight: compact ? 142 : 154),
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 18,
              compact ? 17 : 19,
              compact ? 16 : 18,
              compact ? 16 : 18,
            ),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: SixMobilePalette.highlightedBorder.withAlpha(70),
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.navigationShadow,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: illustrationRightOffset,
                  bottom: illustrationBottomOffset,
                  width: illustrationWidth,
                  height: illustrationHeight,
                  child: ExcludeSemantics(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: (illustrationWidth - (compact ? 24 : 34)).clamp(
                      84.0,
                      150.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: titleSize,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12.5,
                          height: 1.28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryActionsStrip extends StatelessWidget {
  const _PrimaryActionsStrip({required this.actions});

  final List<_PrimaryActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final bool scrollable = width < 326 || textScale >= 1.22;
        final double gap = scrollable ? 10 : 8;
        final double cardWidth =
            scrollable ? (width * 0.36).clamp(112.0, 136.0) : 0;
        final double cardHeight = _resolveCardHeight(
          availableWidth: width,
          textScale: textScale,
          scrollable: scrollable,
        );

        final List<Widget> cards = <Widget>[
          for (int index = 0; index < actions.length; index += 1) ...<Widget>[
            if (index > 0) SizedBox(width: gap),
            if (scrollable)
              SizedBox(
                width: cardWidth,
                child: _PrimaryActionCard(data: actions[index]),
              )
            else
              Expanded(child: _PrimaryActionCard(data: actions[index])),
          ],
        ];

        final Widget row = SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards,
          ),
        );

        if (!scrollable) return row;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: row,
        );
      },
    );
  }

  double _resolveCardHeight({
    required double availableWidth,
    required double textScale,
    required bool scrollable,
  }) {
    final double estimatedCardWidth =
        scrollable
            ? (availableWidth * 0.36).clamp(112.0, 136.0).toDouble()
            : (availableWidth - 16) / 3;
    final bool tightThreeColumnCard = !scrollable && estimatedCardWidth < 112;
    final double scaleExtra = (textScale - 1).clamp(0.0, 0.8).toDouble();
    return 196 +
        (tightThreeColumnCard ? 14 : 0) +
        (scaleExtra * 160) +
        (scrollable ? 8 : 0);
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({required this.data});

  final _PrimaryActionData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: '${data.title}. ${data.subtitle}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey<String>('atendimento-action-${data.id}'),
            onTap: data.onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 154),
              padding: const EdgeInsets.fromLTRB(9, 10, 9, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SixMobilePalette.border),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 112;
                  final double imageCircleSize = compact ? 65 : 72;
                  final double imageSize = compact ? 53 : 60;

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: imageCircleSize,
                        height: imageCircleSize,
                        decoration: BoxDecoration(
                          color: data.accentColor.withAlpha(22),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            data.assetPath,
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return Icon(
                                Icons.image_not_supported_outlined,
                                color: data.accentColor,
                                size: 22,
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                data.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: data.accentColor,
                                  fontSize: compact ? 12 : 12.5,
                                  height: 1.12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: SixMobilePalette.mutedText,
                                  fontSize: 10.5,
                                  height: 1.16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ExcludeSemantics(
                        child: Container(
                          width: compact ? 22 : 24,
                          height: compact ? 22 : 24,
                          decoration: BoxDecoration(
                            color: data.accentColor.withAlpha(18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: data.accentColor.withAlpha(48),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: data.accentColor,
                            size: compact ? 12 : 13,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AtendimentoActionListCard extends StatelessWidget {
  const _AtendimentoActionListCard({
    required this.rows,
    required this.loadingLabel,
    this.hasError = false,
  });

  final List<_AtendimentoListRowData> rows;
  final String loadingLabel;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        hasError ? SixMobilePalette.errorBorder : SixMobilePalette.border;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int index = 0; index < rows.length; index += 1) ...<Widget>[
                _AtendimentoActionListRow(
                  data: rows[index],
                  loadingLabel: loadingLabel,
                ),
                if (index < rows.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: SixMobilePalette.border,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AtendimentoActionListRow extends StatelessWidget {
  const _AtendimentoActionListRow({
    required this.data,
    required this.loadingLabel,
  });

  final _AtendimentoListRowData data;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    final String trailingSemantic = _trailingSemantic;
    final String semanticLabel =
        trailingSemantic.isEmpty
            ? '${data.title}. ${data.subtitle}'
            : '${data.title}. ${data.subtitle}. $trailingSemantic';
    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Row(
        children: <Widget>[
          _ListIcon(
            icon: data.icon,
            accentColor: data.accentColor,
            enabled: data.enabled,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ListTexts(
              title: data.title,
              subtitle: data.subtitle,
              enabled: data.enabled,
              error: data.hasError,
            ),
          ),
          const SizedBox(width: 10),
          _buildTrailing(),
          if (data.enabled)
            const Icon(
              Icons.chevron_right_rounded,
              color: SixMobilePalette.mutedText,
              size: 24,
            ),
        ],
      ),
    );

    if (!data.enabled) {
      return Semantics(
        container: true,
        enabled: false,
        label: semanticLabel,
        child: content,
      );
    }

    return Semantics(
      container: true,
      button: true,
      enabled: true,
      label: semanticLabel,
      child: InkWell(
        key: ValueKey<String>('atendimento-row-${data.id}'),
        onTap: data.onTap,
        child: content,
      ),
    );
  }

  String get _trailingSemantic {
    if (data.showCounter) {
      if (data.loading) return loadingLabel;
      return data.value?.toString() ?? '--';
    }
    return data.statusLabel ?? '';
  }

  Widget _buildTrailing() {
    if (data.showCounter) {
      if (data.loading) {
        return Semantics(
          liveRegion: true,
          label: loadingLabel,
          child: const _CounterSkeleton(),
        );
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 34),
        child: SixAnimatedNumberText(
          key: ValueKey<String>(
            'atendimento-counter-${data.id}-${data.value ?? 'empty'}',
          ),
          value: data.value?.toString() ?? '--',
          style: TextStyle(
            color:
                data.enabled
                    ? SixMobilePalette.titleText
                    : SixMobilePalette.mutedText,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    final String? statusLabel = data.statusLabel;
    if (statusLabel == null || statusLabel.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SoonChip(label: statusLabel);
  }
}

class _ListIcon extends StatelessWidget {
  const _ListIcon({
    required this.icon,
    required this.accentColor,
    required this.enabled,
  });

  final IconData icon;
  final Color accentColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color foreground = enabled ? accentColor : SixMobilePalette.mutedText;
    final Color background =
        enabled
            ? accentColor.withAlpha(20)
            : SixMobilePalette.softNeutralSurface;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: foreground, size: 22),
    );
  }
}

class _ListTexts extends StatelessWidget {
  const _ListTexts({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.error,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                enabled
                    ? SixMobilePalette.titleText
                    : SixMobilePalette.mutedText,
            fontSize: 15,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: error ? SixMobilePalette.error : SixMobilePalette.mutedText,
            fontSize: 12,
            height: 1.22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SoonChip extends StatelessWidget {
  const _SoonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: SixMobilePalette.mutedText.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SixMobilePalette.mutedText.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: SixMobilePalette.mutedText,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterSkeleton extends StatelessWidget {
  const _CounterSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 22,
      decoration: BoxDecoration(
        color: SixMobilePalette.border.withAlpha(170),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: SixMobilePalette.titleText,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _PrimaryActionData {
  const _PrimaryActionData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.accentColor,
    required this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final Color accentColor;
  final VoidCallback onTap;
}

class _AtendimentoListRowData {
  const _AtendimentoListRowData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.enabled = true,
    this.showCounter = false,
    this.value,
    this.loading = false,
    this.hasError = false,
    this.statusLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showCounter;
  final int? value;
  final bool loading;
  final bool hasError;
  final String? statusLabel;
}
