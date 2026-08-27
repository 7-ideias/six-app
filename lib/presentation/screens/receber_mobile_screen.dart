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
import 'atendimentos_tecnicos_pendentes_pagamento_mobile_screen.dart';
import 'vendas_nao_liquidadas_mobile_screen.dart';

typedef ReceberMobileNavigate =
    void Function(BuildContext context, Widget page);

class ReceberMobileScreen extends StatefulWidget {
  const ReceberMobileScreen({super.key, this.onNavigate});

  final ReceberMobileNavigate? onNavigate;

  @override
  State<ReceberMobileScreen> createState() => _ReceberMobileScreenState();
}

class _ReceberMobileScreenState extends State<ReceberMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static const Color _accentColor = Color(0xFF16A34A);
  static const Color _serviceAccentColor = Color(0xFF0F766E);
  static const String _salesAssetContorno =
      'assets/images/atendimento mobile/acao-receber.webp';
  static const String _salesAssetAcento =
      'assets/images/atendimento mobile/acao-receber-acento.webp';
  static const String _servicesAssetContorno =
      'assets/images/receber mobile/acao-servicos-a-receber.webp';
  static const String _servicesAssetAcento =
      'assets/images/receber mobile/acao-servicos-a-receber-acento.webp';

  late final MobileCardOrderPreferenceController<ReceberMobileCardPreferencia>
  _ordemCardsController;

  @override
  void initState() {
    super.initState();
    _ordemCardsController =
        MobileCardOrderPreferenceController<ReceberMobileCardPreferencia>(
            ordemPadrao: ReceberMobileCardPreferencia.values,
            selecionarOrdem: (preferencias) =>
                preferencias.ordemCardsReceberMobile,
            persistirOrdem: (ordem) =>
                UsuarioService().atualizarPreferenciasIndividuais(
                  ordemCardsReceberMobile: ordem
                      .map((item) => item.codigo)
                      .toList(growable: false),
                ),
            nomeDaTela: 'Receber Mobile',
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

  List<_ReceiveActionData> _orderedActions(BuildContext context) {
    final Map<ReceberMobileCardPreferencia, _ReceiveActionData> actions =
        <ReceberMobileCardPreferencia, _ReceiveActionData>{
          ReceberMobileCardPreferencia.vendasAReceber: _ReceiveActionData(
            preferencia: ReceberMobileCardPreferencia.vendasAReceber,
            id: 'sales',
            title: _t(
              context,
              'atendimento.mobile.salesToReceiveTitle',
              'Vendas a receber',
            ),
            subtitle: _t(
              context,
              'atendimento.mobile.salesToReceiveSubtitle',
              'Vendas não liquidadas',
            ),
            assetContorno: _salesAssetContorno,
            assetAcento: _salesAssetAcento,
            accentColor: _accentColor,
            onTap: () => _go(context, VendasNaoLiquidadasMobileScreen()),
          ),
          ReceberMobileCardPreferencia.servicosAReceber: _ReceiveActionData(
            preferencia: ReceberMobileCardPreferencia.servicosAReceber,
            id: 'services',
            title: _t(
              context,
              'atendimento.mobile.servicesToReceiveTitle',
              'Serviços a receber',
            ),
            subtitle: _t(
              context,
              'atendimento.mobile.servicesToReceiveSubtitle',
              'Atendimentos técnicos com financeiro aberto',
            ),
            assetContorno: _servicesAssetContorno,
            assetAcento: _servicesAssetAcento,
            accentColor: _serviceAccentColor,
            onTap: () => _go(
              context,
              AtendimentosTecnicosPendentesPagamentoMobileScreen(),
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
      title: _t(context, 'atendimento.mobile.receiveTitle', 'Receber'),
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
      bodyBuilder:
          (
            BuildContext context,
            ScrollController scrollController,
            double topInset,
          ) {
            final List<_ReceiveActionData> actions = _orderedActions(context);
            final double cardWidth = MediaQuery.sizeOf(context).width - 32;
            return SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 24),
                children: <Widget>[
                  for (int index = 0; index < actions.length; index++) ...[
                    if (index > 0) SizedBox(height: 12),
                    SixStaggeredEntry(
                      key: ValueKey<String>(
                        'receber-reorder-${actions[index].id}',
                      ),
                      delay: Duration(milliseconds: 40 + (index * 55)),
                      child:
                          SixMobileReorderableCard<
                            ReceberMobileCardPreferencia
                          >(
                            value: actions[index].preferencia,
                            onReorder: _ordemCardsController.reordenar,
                            feedbackWidth: cardWidth,
                            feedbackHeight: 118,
                            handleColor: actions[index].accentColor,
                            cardBuilder: () => _ReceiveActionButton(
                              key: ValueKey<String>(
                                'receber-action-${actions[index].id}',
                              ),
                              title: actions[index].title,
                              subtitle: actions[index].subtitle,
                              assetContorno: actions[index].assetContorno,
                              assetAcento: actions[index].assetAcento,
                              accentColor: actions[index].accentColor,
                              onTap: actions[index].onTap,
                            ),
                          ),
                    ),
                  ],
                ],
              ),
            );
          },
    );
  }

  void _go(BuildContext context, Widget page) {
    final ReceberMobileNavigate? navigate = widget.onNavigate;
    if (navigate != null) {
      navigate(context, page);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _ReceiveActionButton extends StatelessWidget {
  const _ReceiveActionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.assetContorno,
    required this.assetAcento,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String assetContorno;
  final String assetAcento;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: '$title. $subtitle',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(minHeight: 118),
              padding: EdgeInsets.fromLTRB(16, 16, 14, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accentColor.withAlpha(58)),
              ),
              child: Row(
                children: <Widget>[
                  _ReceiveActionIcon(
                    assetContorno: assetContorno,
                    assetAcento: assetAcento,
                    accentColor: accentColor,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 17,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 12.5,
                            height: 1.24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  _ReceiveActionArrow(accentColor: accentColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiveActionIcon extends StatelessWidget {
  const _ReceiveActionIcon({
    required this.assetContorno,
    required this.assetAcento,
    required this.accentColor,
  });

  final String assetContorno;
  final String assetAcento;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 72,
        height: 72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accentColor.withAlpha(58),
                accentColor.withAlpha(22),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withAlpha(84)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SixImagemCanetinha(
              assetContorno: assetContorno,
              assetAcento: assetAcento,
              largura: 58,
              altura: 58,
              fit: BoxFit.contain,
              corContorno: context.sixMobileColors.titleText,
              corAcento: accentColor,
              gradienteContorno: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[accentColor, context.sixMobileColors.titleText],
              ),
              reforcoContorno: 0.64,
              reforcoAcento: 0.78,
              opacidadeReforco: 0.44,
              opacidadeBrilho: Theme.of(context).brightness == Brightness.dark
                  ? 0.44
                  : 0.16,
              desfoqueBrilho: 3.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiveActionArrow extends StatelessWidget {
  const _ReceiveActionArrow({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
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
}

class _ReceiveActionData {
  const _ReceiveActionData({
    required this.preferencia,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetContorno,
    required this.assetAcento,
    required this.accentColor,
    required this.onTap,
  });

  final ReceberMobileCardPreferencia preferencia;
  final String id;
  final String title;
  final String subtitle;
  final String assetContorno;
  final String assetAcento;
  final Color accentColor;
  final VoidCallback onTap;
}
