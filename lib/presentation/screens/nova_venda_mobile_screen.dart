import 'package:flutter/material.dart';

import '../../data/models/operational_procedure_flow_models.dart';
import '../../data/models/operational_procedure_models.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import '../coordinators/operational_procedure_flow_coordinator.dart';
import 'pdv_mobile_screen.dart';
import 'vendas_nao_liquidadas_mobile_screen.dart';

typedef NovaVendaMobileNavigate =
    void Function(BuildContext context, Widget page);

class NovaVendaMobileScreen extends StatefulWidget {
  const NovaVendaMobileScreen({
    super.key,
    this.procedureCoordinator,
    this.onNavigate,
  });

  final OperationalProcedureFlowCoordinator? procedureCoordinator;
  final NovaVendaMobileNavigate? onNavigate;

  @override
  State<NovaVendaMobileScreen> createState() => _NovaVendaMobileScreenState();
}

class _NovaVendaMobileScreenState extends State<NovaVendaMobileScreen> {
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _receiveAccentColor = Color(0xFF16A34A);
  static const Color _disabledAccentColor = Color(0xFF8B85A6);
  static const String _saleAsset = 'assets/images/vendas mobile/vendas.webp';
  static const String _receiveAsset =
      'assets/images/vendas mobile/recebimento.webp';
  static const String _consultAsset =
      'assets/images/vendas mobile/consultar.webp';
  static const double _operationCardMinHeight = 158;
  static const double _operationCardGap = 12;

  late final OperationalProcedureFlowCoordinator _procedureCoordinator;
  bool _openingNewSale = false;

  @override
  void initState() {
    super.initState();
    _procedureCoordinator =
        widget.procedureCoordinator ?? OperationalProcedureFlowCoordinator();
  }

  String _t(BuildContext context, String key, String fallback) =>
      context.t(key, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: _t(context, 'atendimento.mobile.newSaleTitle', 'Nova venda'),
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
              const double topPadding = 8;
              const double bottomPadding = 24;
              const int cardCount = 3;
              const double totalGaps = _operationCardGap * (cardCount - 1);
              final double availableCardsHeight =
                  constraints.maxHeight -
                  topInset -
                  topPadding -
                  bottomPadding -
                  totalGaps;
              final double cardHeight =
                  availableCardsHeight > _operationCardMinHeight * cardCount
                      ? availableCardsHeight / cardCount
                      : _operationCardMinHeight;

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
                    child: _OperationActionCard(
                      key: const ValueKey<String>('nova-venda-action-new-sale'),
                      height: cardHeight,
                      title: _t(
                        context,
                        'atendimento.mobile.newSaleTitle',
                        'Nova venda',
                      ),
                      subtitle: _t(
                        context,
                        'atendimento.mobile.newSaleSubtitle',
                        'Vender produtos',
                      ),
                      accentColor: _accentColor,
                      illustration: const _OperationAssetIllustration(
                        assetPath: _saleAsset,
                        accentColor: _accentColor,
                      ),
                      loading: _openingNewSale,
                      onTap: _startNewSale,
                    ),
                  ),
                  const SizedBox(height: _operationCardGap),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 95),
                    child: _OperationActionCard(
                      key: const ValueKey<String>('nova-venda-action-receive'),
                      height: cardHeight,
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
                      accentColor: _receiveAccentColor,
                      illustration: const _OperationAssetIllustration(
                        assetPath: _receiveAsset,
                        accentColor: _receiveAccentColor,
                      ),
                      onTap: () => _go(const VendasNaoLiquidadasMobileScreen()),
                    ),
                  ),
                  const SizedBox(height: _operationCardGap),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 140),
                    child: _OperationActionCard(
                      key: const ValueKey<String>('nova-venda-action-history'),
                      height: cardHeight,
                      title: _t(
                        context,
                        'atendimento.mobile.consultSalesTitle',
                        'Consultar vendas',
                      ),
                      subtitle: _t(
                        context,
                        'atendimento.mobile.consultSalesSubtitle',
                        'Consultar histórico de vendas',
                      ),
                      badge: _t(
                        context,
                        'operacao.mobile.returnUnavailable',
                        'Em breve',
                      ),
                      accentColor: _disabledAccentColor,
                      illustration: const _OperationAssetIllustration(
                        assetPath: _consultAsset,
                        accentColor: _disabledAccentColor,
                      ),
                      enabled: false,
                      onTap: null,
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

  Future<void> _startNewSale() async {
    if (_openingNewSale) return;
    setState(() => _openingNewSale = true);
    try {
      final ProcedureFlowResult result = await _procedureCoordinator.execute(
        context: context,
        operationPoint: ProcedureOperationPoint.saleStartBefore,
      );
      if (!mounted) return;
      if (result.shouldContinue) _go(const PdvMobileScreen());
    } finally {
      if (mounted) setState(() => _openingNewSale = false);
    }
  }

  void _go(Widget page) {
    final NovaVendaMobileNavigate? navigate = widget.onNavigate;
    if (navigate != null) {
      navigate(context, page);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _OperationActionCard extends StatelessWidget {
  const _OperationActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.illustration,
    required this.onTap,
    this.enabled = true,
    this.badge,
    this.loading = false,
    this.height,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget illustration;
  final VoidCallback? onTap;
  final bool enabled;
  final String? badge;
  final bool loading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final bool available = enabled && !loading && onTap != null;
    final VoidCallback? effectiveTap = available ? onTap : null;
    final Color titleColor =
        enabled ? accentColor : SixMobilePalette.secondary.withAlpha(205);
    final Color subtitleColor =
        enabled
            ? SixMobilePalette.mutedText
            : SixMobilePalette.mutedText.withAlpha(215);
    final Color borderColor =
        enabled
            ? accentColor.withAlpha(58)
            : SixMobilePalette.border.withAlpha(170);
    final Color surfaceColor =
        enabled
            ? SixMobilePalette.surface
            : SixMobilePalette.softNeutralSurface;
    final String? badgeText = badge?.trim();

    return Semantics(
      container: true,
      button: enabled,
      enabled: available,
      label:
          badgeText == null || badgeText.isEmpty
              ? '$title. $subtitle'
              : '$title. $subtitle. $badgeText',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color:
                  enabled
                      ? SixMobilePalette.navigationShadow
                      : SixMobilePalette.navigationShadow.withAlpha(10),
              blurRadius: enabled ? 16 : 10,
              offset: Offset(0, enabled ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: effectiveTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(
                minHeight: _NovaVendaMobileScreenState._operationCardMinHeight,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
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
                        color: enabled ? accentColor : SixMobilePalette.border,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(24),
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
                      final double illustrationWidth = (constraints.maxWidth *
                              (tight ? 0.46 : 0.48))
                          .clamp(126.0, 184.0);
                      final double textRightPadding = (illustrationWidth -
                              (tight ? 20 : 28))
                          .clamp(104.0, 158.0);

                      return Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned(
                            right: tight ? -26 : -30,
                            top: tight ? 4 : 0,
                            bottom: tight ? 4 : 0,
                            width: illustrationWidth,
                            child: _OperationIllustrationPane(
                              accentColor: accentColor,
                              enabled: enabled,
                              child: illustration,
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                tight ? 18 : 21,
                                tight ? 14 : 16,
                                textRightPadding,
                                tight ? 14 : 16,
                              ),
                              child: Stack(
                                children: <Widget>[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: tight ? 24 : 28,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: titleColor,
                                              fontSize: tight ? 17 : 19,
                                              height: 1.06,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(height: tight ? 6 : 7),
                                          Text(
                                            subtitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: subtitleColor,
                                              fontSize: tight ? 11.4 : 12.2,
                                              height: 1.18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (badgeText != null &&
                                              badgeText.isNotEmpty) ...<Widget>[
                                            SizedBox(height: tight ? 6 : 7),
                                            _OperationStatusBadge(
                                              label: badgeText,
                                              accentColor: accentColor,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: _OperationActionTrailing(
                                      accentColor: accentColor,
                                      loading: loading,
                                      enabled: enabled,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}

class _OperationIllustrationPane extends StatelessWidget {
  const _OperationIllustrationPane({
    required this.accentColor,
    required this.enabled,
    required this.child,
  });

  final Color accentColor;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Opacity(
        opacity: enabled ? 1 : 0.50,
        child: Align(
          alignment: Alignment.centerRight,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color:
                    enabled
                        ? accentColor.withAlpha(13)
                        : SixMobilePalette.border.withAlpha(32),
                shape: BoxShape.circle,
              ),
              child: Padding(padding: const EdgeInsets.all(4), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationAssetIllustration extends StatelessWidget {
  const _OperationAssetIllustration({
    required this.assetPath,
    required this.accentColor,
  });

  final String assetPath;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.34,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Icon(Icons.storefront_outlined, color: accentColor, size: 42);
        },
      ),
    );
  }
}

class _OperationStatusBadge extends StatelessWidget {
  const _OperationStatusBadge({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withAlpha(38)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accentColor,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OperationActionTrailing extends StatelessWidget {
  const _OperationActionTrailing({
    required this.accentColor,
    required this.loading,
    required this.enabled,
  });

  final Color accentColor;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor =
        enabled ? accentColor : SixMobilePalette.mutedText;

    return ExcludeSemantics(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              enabled
                  ? accentColor.withAlpha(20)
                  : SixMobilePalette.border.withAlpha(42),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                enabled ? accentColor.withAlpha(58) : SixMobilePalette.border,
          ),
        ),
        child:
            loading
                ? Padding(
                  padding: const EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: effectiveColor,
                  ),
                )
                : Icon(
                  enabled
                      ? Icons.arrow_forward_rounded
                      : Icons.lock_outline_rounded,
                  color: effectiveColor,
                  size: 16,
                ),
      ),
    );
  }
}
