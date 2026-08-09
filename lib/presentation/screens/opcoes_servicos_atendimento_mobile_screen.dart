import 'package:flutter/material.dart';

import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import 'atendimento_tecnico_mobile_screen.dart';
import 'atendimentos_tecnicos_mobile_screen.dart';

typedef ServicosAtendimentoMobileNavigate =
    void Function(BuildContext context, Widget page);

class OpcoesServicosAtendimentoMobileScreen extends StatelessWidget {
  const OpcoesServicosAtendimentoMobileScreen({super.key, this.onNavigate});

  final ServicosAtendimentoMobileNavigate? onNavigate;

  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static const Color _accentColor = Color(0xFF7C3AED);
  static const Color _consultAccentColor = Color(0xFF0F766E);
  static const String _serviceAsset =
      'assets/images/servicos mobile/servico.webp';
  static const String _consultAsset =
      'assets/images/servicos mobile/consultar.webp';
  static const double _serviceCardHeight = 136;
  static const double _serviceCardGap = 10;

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
                  SixStaggeredEntry(
                    delay: Duration(milliseconds: 40),
                    child: _buildServiceActionCard(
                      key: ValueKey<String>('servicos-action-new-service'),
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
                          () => _go(context, AtendimentoTecnicoMobileScreen()),
                    ),
                  ),
                  SizedBox(height: _serviceCardGap),
                  SixStaggeredEntry(
                    delay: Duration(milliseconds: 95),
                    child: _buildServiceActionCard(
                      key: ValueKey<String>('servicos-action-in-progress'),
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
                          () =>
                              _go(context, AtendimentosTecnicosMobileScreen()),
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
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(minHeight: height),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
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
                              child: _buildServiceActionImage(
                                assetPath: assetPath,
                                badgeIcon: badgeIcon,
                                accentColor: accentColor,
                              ),
                            ),
                            SizedBox(width: tight ? 14 : 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: tight ? 16.5 : 17.5,
                                      height: 1.08,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: tight ? 7 : 8),
                                  Text(
                                    subtitle,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: SixMobilePalette.mutedText,
                                      fontSize: tight ? 11.2 : 12,
                                      height: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: tight ? 8 : 10),
                            _buildServiceActionArrow(accentColor),
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

  Widget _buildServiceActionImage({
    required String assetPath,
    required IconData badgeIcon,
    required Color accentColor,
  }) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double frameSize = constraints.biggest.shortestSide.clamp(
            76.0,
            98.0,
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
              borderRadius: BorderRadius.circular(24),
            ),
            child: Transform.scale(
              scale: 1.12,
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
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: SixMobilePalette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withAlpha(78)),
            ),
            child: Icon(badgeIcon, color: accentColor, size: 16),
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
