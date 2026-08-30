import 'package:flutter/material.dart';

import '../../data/models/usuario_model.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/six_imagem_canetinha.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_reorderable_card.dart';
import '../components/mobile_motion.dart';
import '../controllers/mobile_card_order_preference_controller.dart';
import 'atendimento_tecnico_mobile_screen.dart';
import 'atendimentos_tecnicos_mobile_screen.dart';

typedef ServicosAtendimentoMobileNavigate =
    void Function(BuildContext context, Widget page);

class OpcoesServicosAtendimentoMobileScreen extends StatefulWidget {
  const OpcoesServicosAtendimentoMobileScreen({super.key, this.onNavigate});

  final ServicosAtendimentoMobileNavigate? onNavigate;

  @override
  State<OpcoesServicosAtendimentoMobileScreen> createState() =>
      _OpcoesServicosAtendimentoMobileScreenState();
}

class _OpcoesServicosAtendimentoMobileScreenState
    extends State<OpcoesServicosAtendimentoMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static const Color _accentColor = Color(0xFF7C3AED);
  static const Color _consultAccentColor = Color(0xFF0F766E);
  static Color get _approvalAccentColor => SixMobilePalette.accent;
  static const Color _closedAccentColor = Color(0xFF64748B);
  static const String _serviceAssetContorno =
      'assets/images/atendimento mobile/acao-novo-servico.webp';
  static const String _serviceAssetAcento =
      'assets/images/atendimento mobile/acao-novo-servico-acento.webp';
  static const String _inProgressAssetContorno =
      'assets/images/servicos mobile/acao-servicos-em-andamento.webp';
  static const String _inProgressAssetAcento =
      'assets/images/servicos mobile/acao-servicos-em-andamento-acento.webp';
  static const String _approvalAssetContorno =
      'assets/images/servicos mobile/acao-orcamentos-aprovacao.webp';
  static const String _approvalAssetAcento =
      'assets/images/servicos mobile/acao-orcamentos-aprovacao-acento.webp';
  static const String _closedAssetContorno =
      'assets/images/servicos mobile/acao-servicos-em-andamento.webp';
  static const String _closedAssetAcento =
      'assets/images/servicos mobile/acao-servicos-em-andamento-acento.webp';
  static const double _serviceCardHeight = 136;
  static const double _serviceCardGap = 10;

  late final MobileCardOrderPreferenceController<ServicosMobileCardPreferencia>
  _ordemCardsController;

  @override
  void initState() {
    super.initState();
    _ordemCardsController =
        MobileCardOrderPreferenceController<ServicosMobileCardPreferencia>(
            ordemPadrao: ServicosMobileCardPreferencia.values,
            selecionarOrdem:
                (preferencias) => preferencias.ordemCardsServicosMobile,
            persistirOrdem:
                (ordem) => UsuarioService().atualizarPreferenciasIndividuais(
                  ordemCardsServicosMobile: ordem
                      .map((item) => item.codigo)
                      .toList(growable: false),
                ),
            nomeDaTela: 'Servicos Mobile',
          )
          ..addListener(_aoAlterarOrdemDosCards)
          ..inicializar();
  }

  @override
  void dispose() {
    _ordemCardsController
      ..removeListener(_aoAlterarOrdemDosCards)
      ..dispose();
    super.dispose();
  }

  void _aoAlterarOrdemDosCards() {
    if (mounted) setState(() {});
  }

  String _t(BuildContext context, String key, String fallback) =>
      context.t(key, fallback: fallback);

  List<_ServiceActionData> _orderedActions(BuildContext context) {
    final Map<ServicosMobileCardPreferencia, _ServiceActionData>
    actions = <ServicosMobileCardPreferencia, _ServiceActionData>{
      ServicosMobileCardPreferencia.novoServico: _ServiceActionData(
        preferencia: ServicosMobileCardPreferencia.novoServico,
        id: 'new-service',
        title: _t(
          context,
          'atendimento.mobile.createServiceTitle',
          'Novo serviço',
        ),
        subtitle: _t(
          context,
          'atendimento.mobile.createServiceSubtitle',
          'Abrir novo atendimento técnico',
        ),
        assetContorno: _serviceAssetContorno,
        assetAcento: _serviceAssetAcento,
        accentColor: _accentColor,
        onTap: _abrirNovoServico,
      ),
      ServicosMobileCardPreferencia.servicosEmAndamento: _ServiceActionData(
        preferencia: ServicosMobileCardPreferencia.servicosEmAndamento,
        id: 'in-progress',
        title: _t(
          context,
          'atendimento.mobile.consultServicesInProgressTitle',
          'Consultar serviços em andamento',
        ),
        subtitle: _t(
          context,
          'atendimento.mobile.consultServicesInProgressSubtitle',
          'Ver atendimentos técnicos ativos',
        ),
        assetContorno: _inProgressAssetContorno,
        assetAcento: _inProgressAssetAcento,
        accentColor: _consultAccentColor,
        onTap:
            () => _go(
              context,
              const AtendimentosTecnicosMobileScreen(
                listContext: AtendimentosTecnicosMobileListContext.inProgress(),
              ),
            ),
      ),
      ServicosMobileCardPreferencia
          .orcamentosAguardandoAprovacao: _ServiceActionData(
        preferencia:
            ServicosMobileCardPreferencia.orcamentosAguardandoAprovacao,
        id: 'waiting-approval',
        title: _t(
          context,
          'atendimento.mobile.waitingApprovalBudgetsTitle',
          'Orçamentos aguardando aprovação',
        ),
        subtitle: _t(
          context,
          'atendimento.mobile.waitingApprovalBudgetsSubtitle',
          'Consulte serviços que ainda precisam da aprovação do cliente',
        ),
        assetContorno: _approvalAssetContorno,
        assetAcento: _approvalAssetAcento,
        accentColor: _approvalAccentColor,
        onTap:
            () => _go(
              context,
              AtendimentosTecnicosMobileScreen(
                listContext:
                    AtendimentosTecnicosMobileListContext.waitingCustomerApproval(),
              ),
            ),
      ),
      ServicosMobileCardPreferencia.servicosJaEncerrados: _ServiceActionData(
        preferencia: ServicosMobileCardPreferencia.servicosJaEncerrados,
        id: 'closed-services',
        title: _t(
          context,
          'atendimento.mobile.closedServicesTitle',
          'Serviços já encerrados',
        ),
        subtitle: _t(
          context,
          'atendimento.mobile.closedServicesSubtitle',
          'Consultar atendimentos técnicos encerrados',
        ),
        assetContorno: _closedAssetContorno,
        assetAcento: _closedAssetAcento,
        accentColor: _closedAccentColor,
        onTap:
            () => _go(
              context,
              const AtendimentosTecnicosMobileScreen(
                listContext: AtendimentosTecnicosMobileListContext.closed(),
              ),
            ),
      ),
    };

    return _ordemCardsController.ordem
        .map((preferencia) => actions[preferencia]!)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: _t(context, 'atendimento.mobile.servicesMenuTitle', 'Serviços'),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      toolbarHeight: 48,
      initialContentSpacing: 8,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      leading: IconButton(
        tooltip: _t(context, 'common.back', 'Voltar'),
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const double horizontalPadding = 16;
              const double topPadding = 8;
              const double bottomPadding = 24;
              final double cardHeight =
                  constraints.maxWidth < 340
                      ? _serviceCardHeight - 8
                      : _serviceCardHeight;
              final double cardWidth =
                  constraints.maxWidth - (horizontalPadding * 2);
              final List<_ServiceActionData> actions = _orderedActions(context);

              return ListView(
                controller: scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topInset + topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                children: <Widget>[
                  for (int index = 0; index < actions.length; index++) ...[
                    if (index > 0) SizedBox(height: _serviceCardGap),
                    SixStaggeredEntry(
                      key: ValueKey<String>(
                        'servicos-reorder-${actions[index].id}',
                      ),
                      delay: Duration(milliseconds: 40 + (index * 55)),
                      child: SixMobileReorderableCard<
                        ServicosMobileCardPreferencia
                      >(
                        value: actions[index].preferencia,
                        onReorder: _ordemCardsController.reordenar,
                        feedbackWidth: cardWidth,
                        feedbackHeight: cardHeight,
                        handleColor: actions[index].accentColor,
                        cardBuilder:
                            () => _buildServiceActionCard(
                              data: actions[index],
                              height: cardHeight,
                            ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceActionCard({
    required _ServiceActionData data,
    required double height,
  }) {
    return Semantics(
      container: true,
      button: true,
      label: '${data.title}. ${data.subtitle}',
      child: Container(
        key: ValueKey<String>('servicos-action-${data.id}'),
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: context.sixMobileColors.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: data.onTap,
            child: Container(
              constraints: BoxConstraints(minHeight: height),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: data.accentColor.withAlpha(58)),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: data.accentColor,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (
                      BuildContext context,
                      BoxConstraints constraints,
                    ) {
                      final bool tight = constraints.maxWidth < 330;
                      final double imageSize = (constraints.maxWidth *
                              (tight ? 0.25 : 0.28))
                          .clamp(76.0, 98.0);

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          tight ? 18 : 21,
                          tight ? 14 : 16,
                          tight ? 12 : 14,
                          tight ? 14 : 16,
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox.square(
                              dimension: imageSize,
                              child: _buildServiceActionImage(data),
                            ),
                            SizedBox(width: tight ? 14 : 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      data.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: data.accentColor,
                                        fontSize: tight ? 16.5 : 17.5,
                                        height: 1.08,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: tight ? 7 : 8),
                                  Flexible(
                                    child: Text(
                                      data.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            context.sixMobileColors.mutedText,
                                        fontSize: tight ? 11.2 : 12,
                                        height: 1.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: tight ? 8 : 10),
                            _buildServiceActionArrow(data.accentColor),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceActionImage(_ServiceActionData data) {
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              data.accentColor.withAlpha(58),
              data.accentColor.withAlpha(22),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: data.accentColor.withAlpha(84)),
        ),
        padding: const EdgeInsets.all(8),
        child: SixImagemCanetinha(
          assetContorno: data.assetContorno,
          assetAcento: data.assetAcento,
          largura: 78,
          altura: 78,
          fit: BoxFit.contain,
          corContorno: context.sixMobileColors.titleText,
          corAcento: data.accentColor,
          gradienteContorno: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              data.accentColor,
              context.sixMobileColors.titleText,
            ],
          ),
          reforcoContorno: 0.62,
          reforcoAcento: 0.76,
          opacidadeReforco: 0.44,
          opacidadeBrilho:
              Theme.of(context).brightness == Brightness.dark ? 0.44 : 0.16,
          desfoqueBrilho: 3.4,
        ),
      ),
    );
  }

  Widget _buildServiceActionArrow(Color accentColor) {
    return ExcludeSemantics(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: accentColor.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withAlpha(58)),
        ),
        child: Icon(Icons.arrow_forward_rounded, color: accentColor, size: 16),
      ),
    );
  }

  void _go(BuildContext context, Widget page) {
    final ServicosAtendimentoMobileNavigate? navigate = widget.onNavigate;
    if (navigate != null) {
      navigate(context, page);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _abrirNovoServico() async {
    final AtendimentoTecnicoCreateFlowResult? result = await Navigator.of(
      context,
    ).push<AtendimentoTecnicoCreateFlowResult>(
      MaterialPageRoute<AtendimentoTecnicoCreateFlowResult>(
        builder: (_) => AtendimentoTecnicoMobileScreen(),
      ),
    );

    if (!mounted || result == null) return;
    final Widget page = AtendimentosTecnicosMobileScreen(
      initialFeedbackMessage: result.feedbackMessage,
    );
    final ServicosAtendimentoMobileNavigate? navigate = widget.onNavigate;
    if (navigate != null) {
      navigate(context, page);
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ServiceActionData {
  const _ServiceActionData({
    required this.preferencia,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetContorno,
    required this.assetAcento,
    required this.accentColor,
    required this.onTap,
  });

  final ServicosMobileCardPreferencia preferencia;
  final String id;
  final String title;
  final String subtitle;
  final String assetContorno;
  final String assetAcento;
  final Color accentColor;
  final VoidCallback onTap;
}
