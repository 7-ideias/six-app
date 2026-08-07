import 'package:flutter/foundation.dart' show kIsWeb;
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

class AtendimentoMobileScreen extends StatefulWidget {
  const AtendimentoMobileScreen({super.key});

  @override
  State<AtendimentoMobileScreen> createState() =>
      _AtendimentoMobileScreenState();
}

class _AtendimentoMobileScreenState extends State<AtendimentoMobileScreen> {
  static const Color _bg = SixMobilePalette.background;
  static const Color _primary = SixMobilePalette.primary;
  static const Color _secondary = SixMobilePalette.secondary;
  static const Color _accent = SixMobilePalette.accent;
  static const Color _muted = SixMobilePalette.mutedText;
  static const Color _title = SixMobilePalette.titleText;

  final TelaInicialWebApiClient _api = HttpResumoDaEmpresaApiClient(
    canal: 'mobile',
  );
  final NotificacaoService _notificacoes = NotificacaoService();
  final OperationalProcedureFlowCoordinator _procedureCoordinator =
      OperationalProcedureFlowCoordinator();

  TelaInicialModel? _resumo;
  bool _loading = true;
  String? _erro;
  int _totalNotificacoesConhecidas = 0;
  bool _openingNewSale = false;

  @override
  void initState() {
    super.initState();
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
    if (kIsWeb) return;
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
      debugPrint('[OperacaoMobileScreen] Erro ao buscar resumo: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: 'Atendimento',
      backgroundColor: _bg,
      primaryColor: _primary,
      secondaryColor: _secondary,
      accentColor: _accent,
      automaticallyImplyLeading: false,
      leading: const SixMobileAppBarProfileAction(),
      actions: <Widget>[
        IconButton(
          tooltip: 'Notificações',
          icon: _notificationIcon(),
          onPressed: () => _go(const NotificacoesMobileScreen()),
        ),
      ],
      bodyBuilder: (
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
                _section('Atendimento rápido'),
                const SizedBox(height: 12),
                _primaryActionGroup(
                  actions: <_PrimaryActionData>[
                    _PrimaryActionData(
                      title: 'Nova venda',
                      subtitle: 'Abrir atendimento no caixa',
                      icon: Icons.point_of_sale_rounded,
                      onTap: _startNewSale,
                    ),
                    _PrimaryActionData(
                      title: 'Atendimento técnico',
                      subtitle: 'Iniciar diagnóstico, orçamento e execução',
                      icon: Icons.build_circle_rounded,
                      onTap: () => _go(const AtendimentoTecnicoMobileScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _lockedAction(
                  title: context.t(
                    'operacao.mobile.returnTitle',
                    fallback: 'Devolução',
                  ),
                  subtitle: context.t(
                    'operacao.mobile.returnUnavailable',
                    fallback: 'em breve',
                  ),
                  icon: Icons.assignment_return_outlined,
                ),
                const SizedBox(height: 12),
                _primaryAction(
                  title: context.t(
                    'pdv.openCashOperations',
                    fallback: 'Operações de caixa',
                  ),
                  subtitle: context.t(
                    'caixa.operacoes.mobile.quickAccessSubtitle',
                    fallback: 'Abrir, movimentar e fechar caixa',
                  ),
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: () => _go(const OperacoesCaixaMobileScreen()),
                ),
                const SizedBox(height: 24),
                _section('Acompanhamento'),
                const SizedBox(height: 12),
                ..._trackingCards(),
              ],
            ),
          ),
        );
      },
      bottomNavigationBar: kIsWeb ? null : const NavBarMobile(initialIndex: 2),
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

  List<Widget> _trackingCards() {
    final bool hasError = _erro != null;
    final String subtitleErro = 'Não foi possível atualizar agora';
    final List<_TrackingCardData> cards = <_TrackingCardData>[
      _TrackingCardData(
        title: 'Vendas a receber',
        subtitle: hasError ? subtitleErro : 'Vendas não liquidadas',
        value: (_resumo?.totalVendasAbertas ?? 0).toString(),
        icon: Icons.point_of_sale_outlined,
        onTap: () => _go(const VendasNaoLiquidadasMobileScreen()),
      ),
      _TrackingCardData(
        title: 'Atendimentos Técnicos',
        subtitle:
            hasError ? subtitleErro : 'Dashboard executivo do fluxo técnico',
        value: (_resumo?.totalAtendimentoTecnicosNaoEntregues ?? 0).toString(),
        icon: Icons.fact_check_outlined,
        onTap: () => _go(const AtendimentosTecnicosMobileScreen()),
      ),
    ];

    return <Widget>[
      SixStaggeredEntry(
        delay: const Duration(milliseconds: 230),
        child: _trackingCardGroup(cards: cards, hasError: hasError),
      ),
    ];
  }

  Widget _primaryActionGroup({required List<_PrimaryActionData> actions}) {
    return Material(
      color: SixMobilePalette.surface,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: actions
              .asMap()
              .entries
              .map((MapEntry<int, _PrimaryActionData> entry) {
                final bool isLast = entry.key == actions.length - 1;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _primaryActionTile(entry.value),
                    if (!isLast)
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: SixMobilePalette.border,
                      ),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _primaryActionTile(_PrimaryActionData action) {
    return InkWell(
      onTap: action.onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            _iconBox(
              action.icon,
              bg: SixMobilePalette.softAccentSurface,
              fg: _accent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _texts(action.title, action.subtitle, titleSize: 16),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _primaryAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _card(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          _iconBox(icon, bg: SixMobilePalette.softAccentSurface, fg: _accent),
          const SizedBox(width: 14),
          Expanded(child: _texts(title, subtitle, titleSize: 16)),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
  }

  Widget _lockedAction({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Semantics(
      container: true,
      enabled: false,
      label: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            _iconBox(icon, bg: SixMobilePalette.softNeutralSurface, fg: _muted),
            const SizedBox(width: 14),
            Expanded(child: _texts(title, subtitle, titleSize: 16)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _muted.withAlpha(18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _muted.withAlpha(36)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: _muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.t('common.soon', fallback: 'Em breve'),
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
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

  Widget _trackingCardGroup({
    required List<_TrackingCardData> cards,
    required bool hasError,
  }) {
    final Color borderColor =
        hasError ? SixMobilePalette.errorBorder : SixMobilePalette.border;

    return Material(
      color: SixMobilePalette.surface,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: cards
              .asMap()
              .entries
              .map((MapEntry<int, _TrackingCardData> entry) {
                final bool isLast = entry.key == cards.length - 1;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _trackingCardTile(entry.value, hasError: hasError),
                    if (!isLast)
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: SixMobilePalette.border,
                      ),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _trackingCardTile(_TrackingCardData card, {required bool hasError}) {
    return InkWell(
      onTap: card.onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            _iconBox(
              card.icon,
              bg: SixMobilePalette.softNeutralSurface,
              fg: _primary,
              size: 46,
            ),
            const SizedBox(width: 14),
            Expanded(child: _texts(card.title, card.subtitle, error: hasError)),
            const SizedBox(width: 12),
            _loading
                ? Container(
                  width: 34,
                  height: 22,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                )
                : SixAnimatedNumberText(
                  key: ValueKey<String>('inicio-${card.title}-${card.value}'),
                  value: card.value,
                  style: const TextStyle(
                    color: _title,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    required VoidCallback onTap,
    Color borderColor = SixMobilePalette.border,
  }) {
    return Material(
      color: SixMobilePalette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _texts(
    String title,
    String subtitle, {
    bool error = false,
    double titleSize = 15,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _title,
            fontWeight: FontWeight.w900,
            fontSize: titleSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: error ? SixMobilePalette.error : _muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _iconBox(
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
      child: Icon(icon, color: fg, size: size >= 48 ? 24 : 22),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _title,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
    );
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _TrackingCardData {
  const _TrackingCardData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
}

class _PrimaryActionData {
  const _PrimaryActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}
