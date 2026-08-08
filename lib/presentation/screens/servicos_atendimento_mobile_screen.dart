import 'package:flutter/material.dart';

import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import 'atendimento_tecnico_mobile_screen.dart';
import 'atendimentos_tecnicos_mobile_screen.dart';

typedef ServicosAtendimentoMobileNavigate =
    void Function(BuildContext context, Widget page);

class ServicosAtendimentoMobileScreen extends StatelessWidget {
  const ServicosAtendimentoMobileScreen({super.key, this.onNavigate});

  final ServicosAtendimentoMobileNavigate? onNavigate;

  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = Color(0xFF7C3AED);
  static const Color _consultAccentColor = Color(0xFF0F766E);
  static const String _serviceAsset =
      'assets/images/servicos mobile/servico.webp';
  static const String _consultAsset =
      'assets/images/servicos mobile/consultar.webp';
  static const double _serviceCardMinHeight = 226;
  static const double _serviceCardGap = 14;

  String _t(BuildContext context, String key, String fallback) =>
      context.t(key, fallback: fallback);

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
        icon: const Icon(Icons.arrow_back_rounded),
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
              const double topPadding = 10;
              const double bottomPadding = 24;
              const int cardCount = 2;
              const double totalGaps = _serviceCardGap * (cardCount - 1);
              final double availableCardsHeight =
                  constraints.maxHeight -
                  topInset -
                  topPadding -
                  bottomPadding -
                  totalGaps;
              final double cardHeight =
                  availableCardsHeight > _serviceCardMinHeight * cardCount
                      ? availableCardsHeight / cardCount
                      : _serviceCardMinHeight;

              return ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topInset + topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                children: <Widget>[
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 40),
                    child: _buildServiceActionCard(
                      key: const ValueKey<String>(
                        'servicos-action-new-service',
                      ),
                      height: cardHeight,
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
                      assetPath: _serviceAsset,
                      badgeIcon: Icons.add_rounded,
                      accentColor: _accentColor,
                      onTap:
                          () => _go(
                            context,
                            const AtendimentoTecnicoMobileScreen(),
                          ),
                    ),
                  ),
                  const SizedBox(height: _serviceCardGap),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 95),
                    child: _buildServiceActionCard(
                      key: const ValueKey<String>(
                        'servicos-action-in-progress',
                      ),
                      height: cardHeight,
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
                      assetPath: _consultAsset,
                      badgeIcon: Icons.fact_check_rounded,
                      accentColor: _consultAccentColor,
                      onTap:
                          () => _go(
                            context,
                            const AtendimentosTecnicosMobileScreen(),
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceActionCard({
    required Key key,
    required double height,
    required String title,
    required String subtitle,
    required String assetPath,
    required IconData badgeIcon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      container: true,
      button: true,
      label: '$title. $subtitle',
      child: Container(
        key: key,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const <BoxShadow>[
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
              constraints: const BoxConstraints(
                minHeight: _serviceCardMinHeight,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accentColor.withAlpha(58)),
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
                        color: accentColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(22),
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
                      final double imageWidth = (constraints.maxWidth *
                              (tight ? 0.35 : 0.38))
                          .clamp(104.0, 148.0);
                      final double rightTextPadding = tight ? 52 : 58;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned(
                            left: tight ? 18 : 22,
                            top: tight ? 18 : 20,
                            bottom: tight ? 18 : 20,
                            width: imageWidth,
                            child: _buildServiceActionImage(
                              assetPath: assetPath,
                              badgeIcon: badgeIcon,
                              accentColor: accentColor,
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                imageWidth + (tight ? 34 : 42),
                                tight ? 20 : 22,
                                rightTextPadding,
                                tight ? 20 : 22,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: tight ? 18 : 20,
                                        height: 1.08,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: tight ? 7 : 8),
                                    Text(
                                      subtitle,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: SixMobilePalette.mutedText,
                                        fontSize: 12.5,
                                        height: 1.24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: tight ? 16 : 18,
                            bottom: tight ? 18 : 20,
                            child: _buildServiceActionArrow(accentColor),
                          ),
                        ],
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

  Widget _buildServiceActionImage({
    required String assetPath,
    required IconData badgeIcon,
    required Color accentColor,
  }) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double frameSize = constraints.biggest.shortestSide.clamp(
            104.0,
            168.0,
          );

          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: _buildServiceImageFrame(
                assetPath: assetPath,
                badgeIcon: badgeIcon,
                accentColor: accentColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceImageFrame({
    required String assetPath,
    required IconData badgeIcon,
    required Color accentColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(18),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Transform.scale(
              scale: 1.36,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Icon(
                    Icons.home_repair_service_rounded,
                    color: accentColor,
                    size: 42,
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: SixMobilePalette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withAlpha(78)),
            ),
            child: Icon(badgeIcon, color: accentColor, size: 18),
          ),
        ),
      ],
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
    final ServicosAtendimentoMobileNavigate? navigate = onNavigate;
    if (navigate != null) {
      navigate(context, page);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
