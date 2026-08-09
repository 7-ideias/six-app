import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:sixpos/core/services/notificacao_service.dart';
import 'package:sixpos/core/services/websocket_service.dart';
import 'package:sixpos/data/models/tela_inicial_models.dart';
import 'package:sixpos/data/services/telainicial_web/tela_inicial_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_app_bar_profile_action.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/coordinators/operational_procedure_flow_coordinator.dart';
import 'package:sixpos/presentation/screens/notificacoes_mobile_screen.dart';
import 'package:sixpos/presentation/screens/opcoes_venda_mobile_screen.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_mobile_screen.dart';
import 'package:sixpos/presentation/screens/receber_mobile_screen.dart';
import 'package:sixpos/presentation/screens/opcoes_servicos_atendimento_mobile_screen.dart';

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
  static const Color _serviceAccent = Color(0xFF7C3AED);
  static const Color _receiveAccent = Color(0xFF16A34A);
  static const Color _cashAccent = Color(0xFF0F766E);
  static const Color _returnAccent = Color(0xFFEF4444);

  static const String _heroAsset =
      'assets/images/atendimento mobile/atendimento-hero.webp';
  static const String _saleAsset =
      'assets/images/atendimento mobile/acao-nova-venda.png';
  static const String _serviceAsset =
      'assets/images/atendimento mobile/acao-novo-servico.png';
  static const String _receiveAsset =
      'assets/images/atendimento mobile/acao-receber.png';
  static const String _cashAsset =
      'assets/images/atendimento mobile/acao-operacoes-caixa.png';
  static const String _returnAsset =
      'assets/images/atendimento mobile/acao-devolucoes.png';

  late final TelaInicialWebApiClient _api;
  late final OperationalProcedureFlowCoordinator _procedureCoordinator;
  final NotificacaoService _notificacoes = NotificacaoService();

  TelaInicialModel? _resumo;
  int _totalNotificacoesConhecidas = 0;

  SixMobileColorScheme get _colors => context.sixMobileColors;
  Color get _bg => _colors.background;
  Color get _primary => _colors.primary;
  Color get _secondary => _colors.secondary;
  Color get _accent => _colors.accent;

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
      Future<void>.delayed(Duration(milliseconds: 180), () {
        if (mounted) connectStomp();
      });
    });
  }

  Future<void> _carregarResumo() async {
    try {
      final TelaInicialModel resumo = await _api.getResumo();
      if (!mounted) return;
      setState(() => _resumo = resumo);
    } catch (error) {
      debugPrint('[AtendimentoMobileScreen] Erro ao buscar resumo: $error');
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
      leading: SixMobileAppBarProfileAction(),
      actions: <Widget>[
        IconButton(
          tooltip: _txt(
            'gestao.settings.item.notifications.title',
            'Notificações',
          ),
          icon: _notificationIcon(),
          onPressed: () => _go(NotificacoesMobileScreen()),
        ),
      ],
      bodyBuilder: _buildContent,
      bottomNavigationBar:
          kIsWeb || !widget.showBottomNavigationBar
              ? null
              : NavBarMobile(initialIndex: 2),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double textScale = MediaQuery.textScalerOf(context).scale(1);
          final _AtendimentoLayoutSizing sizing =
              _AtendimentoLayoutSizing.resolve(
                viewportHeight: constraints.maxHeight,
                contentWidth: constraints.maxWidth - 32,
                topInset: topInset,
                textScale: textScale,
              );

          return RefreshIndicator(
            edgeOffset: topInset,
            displacement: 18,
            color: _accent,
            backgroundColor: _colors.surface,
            onRefresh: _carregarResumo,
            child: ListView(
              controller: scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
              children: <Widget>[
                SixStaggeredEntry(
                  delay: Duration(milliseconds: 40),
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
                SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: Duration(milliseconds: 95),
                  child: _AtendimentoActionsRow(
                    actions: _primaryActions(),
                    prominence: _AtendimentoActionProminence.primary,
                    heightBoost: sizing.primaryRowExtraHeight,
                  ),
                ),
                SizedBox(height: 12),
                SixStaggeredEntry(
                  delay: Duration(milliseconds: 130),
                  child: _AtendimentoActionsRow(
                    actions: _secondaryActions(),
                    prominence: _AtendimentoActionProminence.compact,
                    heightBoost: sizing.compactRowExtraHeight,
                  ),
                ),
              ],
            ),
          );
        },
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
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                  style: TextStyle(
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
        onTap: _openSalesMenu,
      ),
      _PrimaryActionData(
        id: 'new-service',
        title: _txt('atendimento.mobile.newServiceTitle', 'Serviços'),
        subtitle: _txt(
          'atendimento.mobile.newServiceSubtitle',
          'Criar ou acompanhar',
        ),
        assetPath: _serviceAsset,
        accentColor: _serviceAccent,
        onTap: () => _go(OpcoesServicosAtendimentoMobileScreen()),
      ),
    ];
  }

  List<_PrimaryActionData> _secondaryActions() {
    return <_PrimaryActionData>[
      _PrimaryActionData(
        id: 'receive',
        title: _txt('atendimento.mobile.receiveTitle', 'Receber'),
        subtitle: _txt(
          'atendimento.mobile.receiveSubtitle',
          'Vendas em aberto',
        ),
        assetPath: _receiveAsset,
        accentColor: _receiveAccent,
        onTap: () => _go(ReceberMobileScreen()),
        badgeValue: _resumo?.totalVendasAbertas,
      ),
      _PrimaryActionData(
        id: 'cash',
        title: _txt(
          'atendimento.mobile.cashOperationsTitle',
          'Operações de caixa',
        ),
        subtitle: _txt(
          'atendimento.mobile.cashOperationsSubtitle',
          'Abrir e movimentar',
        ),
        assetPath: _cashAsset,
        accentColor: _cashAccent,
        onTap: () => _go(OperacoesCaixaMobileScreen()),
      ),
      _PrimaryActionData(
        id: 'return',
        title: _txt('operacao.mobile.returnTitle', 'Devoluções'),
        subtitle: _txt('operacao.mobile.returnSubtitle', 'Registrar devolução'),
        assetPath: _returnAsset,
        accentColor: _returnAccent,
        onTap: null,
        enabled: false,
        statusLabel: _txt('operacao.mobile.returnUnavailable', 'Em breve'),
      ),
    ];
  }

  void _openSalesMenu() {
    _go(OpcoesVendaMobileScreen(procedureCoordinator: _procedureCoordinator));
  }

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

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1);

    return Semantics(
      container: true,
      header: true,
      label: '$title. $subtitle',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final SixMobileColorScheme colors = context.sixMobileColors;
          final double width = constraints.maxWidth;
          final bool compact = width < 350 || textScale >= 1.2;
          final bool tightText = textScale >= 1.35;
          final double illustrationWidth =
              (width * (compact ? 0.43 : 0.49) * 1.12).clamp(132.0, 206.0);
          final double illustrationHeight = (compact
                  ? illustrationWidth * 0.94
                  : illustrationWidth * 0.98)
              .clamp(117.0, 177.0);
          final double illustrationRightOffset = compact ? -34 : -38;
          final double illustrationBottomOffset = compact ? -30 : -35;
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
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
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
                        return SizedBox.shrink();
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
                          color: colors.titleText,
                          fontSize: titleSize,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.mutedText,
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

enum _AtendimentoActionProminence { primary, compact }

class _AtendimentoLayoutSizing {
  const _AtendimentoLayoutSizing({
    required this.primaryRowExtraHeight,
    required this.compactRowExtraHeight,
  });

  final double primaryRowExtraHeight;
  final double compactRowExtraHeight;

  static _AtendimentoLayoutSizing resolve({
    required double viewportHeight,
    required double contentWidth,
    required double topInset,
    required double textScale,
  }) {
    if (!viewportHeight.isFinite) {
      return const _AtendimentoLayoutSizing(
        primaryRowExtraHeight: 0,
        compactRowExtraHeight: 0,
      );
    }

    final bool compactHero = contentWidth < 350 || textScale >= 1.2;
    final double scaleExtra = (textScale - 1).clamp(0.0, 0.8).toDouble();
    final double heroHeight = compactHero ? 142 : 154;
    final double primaryHeight = 190 + (scaleExtra * 82);
    final double compactHeight = 146 + (scaleExtra * 58);
    final double verticalPadding = topInset + 10 + 24;
    const double verticalGaps = 16 + 12;
    final double baseContentHeight =
        heroHeight + primaryHeight + compactHeight + verticalGaps;
    final double availableHeight = viewportHeight - verticalPadding;
    final double extraHeight =
        (availableHeight - baseContentHeight)
            .clamp(0.0, double.infinity)
            .toDouble();

    return _AtendimentoLayoutSizing(
      primaryRowExtraHeight: extraHeight * 0.54,
      compactRowExtraHeight: extraHeight * 0.46,
    );
  }
}

class _AtendimentoActionsRow extends StatelessWidget {
  const _AtendimentoActionsRow({
    required this.actions,
    required this.prominence,
    this.heightBoost = 0,
  });

  final List<_PrimaryActionData> actions;
  final _AtendimentoActionProminence prominence;
  final double heightBoost;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final double gap =
            prominence == _AtendimentoActionProminence.primary ? 12 : 8;
        final double cardHeight =
            _resolveCardHeight(textScale: textScale) + heightBoost;

        return SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int index = 0; index < actions.length; index += 1) ...[
                if (index > 0) SizedBox(width: gap),
                Expanded(
                  child: _PrimaryActionCard(
                    data: actions[index],
                    prominence: prominence,
                    availableRowWidth: width,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  double _resolveCardHeight({required double textScale}) {
    final double scaleExtra = (textScale - 1).clamp(0.0, 0.8).toDouble();
    if (prominence == _AtendimentoActionProminence.primary) {
      return 190 + (scaleExtra * 82);
    }
    return 146 + (scaleExtra * 58);
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.data,
    required this.prominence,
    required this.availableRowWidth,
  });

  final _PrimaryActionData data;
  final _AtendimentoActionProminence prominence;
  final double availableRowWidth;

  bool get _isPrimary => prominence == _AtendimentoActionProminence.primary;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool enabled = data.enabled && data.onTap != null;
    final String status = data.statusLabel ?? '';
    final String badge =
        data.badgeValue != null && data.badgeValue! > 0
            ? data.badgeValue.toString()
            : '';
    final String semanticSuffix = <String>[
      if (badge.isNotEmpty) badge,
      if (status.isNotEmpty) status,
    ].join('. ');
    final String semanticLabel =
        semanticSuffix.isEmpty
            ? '${data.title}. ${data.subtitle}'
            : '${data.title}. ${data.subtitle}. $semanticSuffix';
    final double radius = _isPrimary ? 22 : 18;

    return Semantics(
      container: true,
      button: enabled,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.72,
        child: Container(
          key: ValueKey<String>('atendimento-action-${data.id}'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    _isPrimary
                        ? colors.navigationShadow
                        : colors.navigationShadow.withAlpha(18),
                blurRadius: _isPrimary ? 16 : 10,
                offset: Offset(0, _isPrimary ? 8 : 5),
              ),
            ],
          ),
          child: Material(
            color: data.accentColor.withAlpha(13),
            borderRadius: BorderRadius.circular(radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? data.onTap : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      padding:
                          _isPrimary
                              ? EdgeInsets.fromLTRB(10, 11, 10, 10)
                              : EdgeInsets.fromLTRB(7, 8, 7, 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color:
                              enabled
                                  ? data.accentColor.withAlpha(
                                    _isPrimary ? 62 : 42,
                                  )
                                  : colors.border,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          return _ActionCardContent(
                            data: data,
                            enabled: enabled,
                            prominence: prominence,
                            constraints: constraints,
                            rowWidth: availableRowWidth,
                          );
                        },
                      ),
                    ),
                  ),
                  if (badge.isNotEmpty)
                    Positioned(
                      top: _isPrimary ? 8 : 6,
                      right: _isPrimary ? 8 : 6,
                      child: _ActionCounterBadge(value: badge),
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

class _ActionCardContent extends StatelessWidget {
  const _ActionCardContent({
    required this.data,
    required this.enabled,
    required this.prominence,
    required this.constraints,
    required this.rowWidth,
  });

  final _PrimaryActionData data;
  final bool enabled;
  final _AtendimentoActionProminence prominence;
  final BoxConstraints constraints;
  final double rowWidth;

  bool get _isPrimary => prominence == _AtendimentoActionProminence.primary;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final bool compactWidth =
        constraints.maxWidth < (_isPrimary ? 150 : 102) || rowWidth < 340;
    final bool compactText = textScale >= 1.22;
    final bool compact = compactWidth || compactText;
    final double extraHeightFactor =
        ((constraints.maxHeight - (_isPrimary ? 168 : 130)) /
                (_isPrimary ? 120 : 90))
            .clamp(0.0, 1.0)
            .toDouble();
    final double imageCircleSize =
        _isPrimary
            ? ((compact ? 68 : 82) + (extraHeightFactor * 10)) * 1.4
            : ((compact ? 45 : 54) + (extraHeightFactor * 8)) * 1.4;
    final double imageSize =
        _isPrimary
            ? ((compact ? 60 : 72) + (extraHeightFactor * 9)) * 1.4
            : ((compact ? 40 : 48) + (extraHeightFactor * 7)) * 1.4;
    final double titleSize =
        _isPrimary
            ? (compact ? 13.1 : 15.0) + (extraHeightFactor * 0.8)
            : (compact ? 10.4 : 11.4) + (extraHeightFactor * 0.7);
    final double subtitleSize =
        _isPrimary
            ? (compact ? 10.5 : 11.3) + (extraHeightFactor * 0.6)
            : (compact ? 9.0 : 9.7) + (extraHeightFactor * 0.5);

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: imageCircleSize,
          height: imageCircleSize,
          decoration: BoxDecoration(
            color: data.accentColor.withAlpha(enabled ? 22 : 14),
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
                  color: enabled ? data.accentColor : colors.mutedText,
                  size: _isPrimary ? 22 : 18,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _isPrimary ? 4 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                data.title,
                maxLines: _isPrimary ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? data.accentColor : colors.mutedText,
                  fontSize: titleSize,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: _isPrimary ? 5 : 4),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: subtitleSize,
                  height: 1.12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _ActionIndicator(
          accentColor: data.accentColor,
          enabled: enabled,
          statusLabel: data.statusLabel,
          compact: !_isPrimary,
        ),
      ],
    );
  }
}

class _ActionIndicator extends StatelessWidget {
  const _ActionIndicator({
    required this.accentColor,
    required this.enabled,
    required this.statusLabel,
    required this.compact,
  });

  final Color accentColor;
  final bool enabled;
  final String? statusLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    if (!enabled && statusLabel != null && statusLabel!.isNotEmpty) {
      return _SoonChip(label: statusLabel!, compact: compact);
    }

    return ExcludeSemantics(
      child: Container(
        width: compact ? 23 : 28,
        height: compact ? 23 : 28,
        decoration: BoxDecoration(
          color: accentColor.withAlpha(enabled ? 22 : 12),
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withAlpha(enabled ? 58 : 28)),
        ),
        child: Icon(
          enabled ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
          color: enabled ? accentColor : colors.mutedText,
          size: compact ? 13 : 15,
        ),
      ),
    );
  }
}

class _ActionCounterBadge extends StatelessWidget {
  const _ActionCounterBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        constraints: BoxConstraints(minWidth: 20),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: SixMobilePalette.notificationBadge,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SixMobilePalette.onPrimary, width: 1.2),
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SixMobilePalette.onPrimary,
            fontSize: 10,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SoonChip extends StatelessWidget {
  const _SoonChip({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 70 : 118),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: colors.mutedText.withAlpha(18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.mutedText.withAlpha(35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: compact ? 10 : 12,
              color: colors.mutedText,
            ),
            SizedBox(width: compact ? 3 : 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: compact ? 9 : 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
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
    this.enabled = true,
    this.badgeValue,
    this.statusLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool enabled;
  final int? badgeValue;
  final String? statusLabel;
}
