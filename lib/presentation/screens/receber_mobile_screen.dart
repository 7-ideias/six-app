import 'package:flutter/material.dart';

import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import 'atendimentos_tecnicos_pendentes_pagamento_mobile_screen.dart';
import 'vendas_nao_liquidadas_mobile_screen.dart';

typedef ReceberMobileNavigate =
    void Function(BuildContext context, Widget page);

class ReceberMobileScreen extends StatelessWidget {
  const ReceberMobileScreen({super.key, this.onNavigate});

  final ReceberMobileNavigate? onNavigate;

  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = Color(0xFF16A34A);
  static const Color _serviceAccentColor = Color(0xFF0F766E);

  String _t(BuildContext context, String key, String fallback) =>
      context.t(key, fallback: fallback);

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
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 24),
            children: <Widget>[
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 40),
                child: _ReceiveActionButton(
                  key: const ValueKey<String>('receber-action-sales'),
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
                  icon: Icons.point_of_sale_outlined,
                  badgeIcon: Icons.payments_rounded,
                  accentColor: _accentColor,
                  onTap:
                      () =>
                          _go(context, const VendasNaoLiquidadasMobileScreen()),
                ),
              ),
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 95),
                child: _ReceiveActionButton(
                  key: const ValueKey<String>('receber-action-services'),
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
                  icon: Icons.home_repair_service_outlined,
                  badgeIcon: Icons.request_quote_rounded,
                  accentColor: _serviceAccentColor,
                  onTap:
                      () => _go(
                        context,
                        const AtendimentosTecnicosPendentesPagamentoMobileScreen(),
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _go(BuildContext context, Widget page) {
    final ReceberMobileNavigate? navigate = onNavigate;
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
    required this.icon,
    required this.badgeIcon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final IconData badgeIcon;
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
              constraints: const BoxConstraints(minHeight: 118),
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accentColor.withAlpha(58)),
              ),
              child: Row(
                children: <Widget>[
                  _ReceiveActionIcon(
                    icon: icon,
                    badgeIcon: badgeIcon,
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 14),
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
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          maxLines: 2,
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
                  const SizedBox(width: 10),
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
    required this.icon,
    required this.badgeIcon,
    required this.accentColor,
  });

  final IconData icon;
  final IconData badgeIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: accentColor, size: 34),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: SixMobilePalette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withAlpha(78)),
                ),
                child: Icon(badgeIcon, color: accentColor, size: 17),
              ),
            ),
          ],
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
