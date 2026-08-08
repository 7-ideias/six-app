import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/di/catalog_health_module.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/catalog_health_score_indicator.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/produto_cadastrar_mobile_screen.dart';
import 'package:sixpos/presentation/screens/produto_list_mobile_screen.dart';
import 'package:sixpos/providers/catalog_health_provider.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

class CatalogHealthMobileScreen extends StatelessWidget {
  const CatalogHealthMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CatalogHealthProvider>(
      create:
          (_) => CatalogHealthProvider(
            apiClient: CatalogHealthModule.catalogHealthApiClient,
          )..load(),
      child: const _CatalogHealthMobileView(),
    );
  }
}

class _CatalogHealthMobileView extends StatelessWidget {
  const _CatalogHealthMobileView();

  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: 'Saúde do catálogo',
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child:
              Consumer2<CatalogHealthProvider, ColaboradorAutorizacoesProvider>(
                builder: (
                  BuildContext context,
                  CatalogHealthProvider provider,
                  ColaboradorAutorizacoesProvider permissions,
                  _,
                ) {
                  final bool reduceMotion =
                      MediaQuery.disableAnimationsOf(context) ||
                      MediaQuery.accessibleNavigationOf(context);

                  return RefreshIndicator(
                    onRefresh: provider.reload,
                    child: ListView(
                      controller: scrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
                      children: <Widget>[
                        AnimatedSwitcher(
                          duration:
                              reduceMotion
                                  ? Duration.zero
                                  : Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _buildState(
                            context,
                            provider,
                            permissions,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        );
      },
    );
  }

  Widget _buildState(
    BuildContext context,
    CatalogHealthProvider provider,
    ColaboradorAutorizacoesProvider permissions, {
    required bool reduceMotion,
  }) {
    if (!permissions.podeAcessarCatalogo) {
      return const _CatalogPermissionState(
        key: ValueKey<String>('catalog-health-permission'),
      );
    }

    if (provider.isLoading) {
      return const _CatalogLoadingState(
        key: ValueKey<String>('catalog-health-loading'),
      );
    }

    if (provider.hasError) {
      return _CatalogErrorState(
        key: ValueKey<String>('catalog-health-error'),
        onRetry: provider.reload,
      );
    }

    final CatalogHealthSummary? summary = provider.summary;
    if (summary == null || summary.isEmpty) {
      return _CatalogEmptyState(
        key: ValueKey<String>('catalog-health-empty'),
        canCreate: permissions.podeCadastrarProduto,
        onNewProduct: () => _openCreate(context, 'PRODUTO'),
        onNewService: () => _openCreate(context, 'SERVICO'),
      );
    }

    return _CatalogSuccessState(
      key: ValueKey<String>('catalog-health-success'),
      summary: summary,
      animationRevision: provider.loadRevision,
      canCreate: permissions.podeCadastrarProduto,
      canViewStock: permissions.podeVerEstoqueDeProduto,
      reduceMotion: reduceMotion,
      onOpenProducts: () => _openProducts(context),
      onOpenServices: () => _openServices(context),
      onNewProduct: () => _openCreate(context, 'PRODUTO'),
      onNewService: () => _openCreate(context, 'SERVICO'),
      onPendingMetric:
          (CatalogHealthMetric metric) =>
              _showPendingFilterMessage(context, metric),
    );
  }

  void _openProducts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProdutolistMobileScreen(tipoInicial: 'PRODUTO'),
      ),
    );
  }

  void _openServices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProdutolistMobileScreen(tipoInicial: 'SERVICO'),
      ),
    );
  }

  void _openCreate(BuildContext context, String tipoInicial) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CadastroProdutoMobileScreen(tipoInicial: tipoInicial),
      ),
    );
  }

  void _showPendingFilterMessage(
    BuildContext context,
    CatalogHealthMetric metric,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A lista filtrada de ${metric.title.toLowerCase()} será integrada em uma próxima etapa.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CatalogSuccessState extends StatelessWidget {
  const _CatalogSuccessState({
    super.key,
    required this.summary,
    required this.animationRevision,
    required this.canCreate,
    required this.canViewStock,
    required this.reduceMotion,
    required this.onOpenProducts,
    required this.onOpenServices,
    required this.onNewProduct,
    required this.onNewService,
    required this.onPendingMetric,
  });

  final CatalogHealthSummary summary;
  final int animationRevision;
  final bool canCreate;
  final bool canViewStock;
  final bool reduceMotion;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenServices;
  final VoidCallback onNewProduct;
  final VoidCallback onNewService;
  final ValueChanged<CatalogHealthMetric> onPendingMetric;

  @override
  Widget build(BuildContext context) {
    final CatalogHealthMetric products =
        summary.metric(CatalogHealthMetricType.products) ??
        summary.overview.products.toMetric(
          type: CatalogHealthMetricType.products,
          code: 'PRODUTOS',
        );
    final CatalogHealthMetric services =
        summary.metric(CatalogHealthMetricType.services) ??
        summary.overview.services.toMetric(
          type: CatalogHealthMetricType.services,
          code: 'SERVICOS',
        );
    final List<CatalogHealthMetric> pendingMetrics = summary
        .pendingSection
        .items
        .where(
          (CatalogHealthMetric metric) =>
              canViewStock || !metric.requiresStockPermission,
        )
        .toList(growable: false);
    final CatalogHealthAction? newProductAction = summary.action(
      'NOVO_PRODUTO',
    );
    final CatalogHealthAction? newServiceAction = summary.action(
      'NOVO_SERVICO',
    );

    final List<Widget> children = <Widget>[
      _entry(
        reduceMotion: reduceMotion,
        child: _CatalogHealthHero(
          summary: summary,
          animationRevision: animationRevision,
          reduceMotion: reduceMotion,
        ),
      ),
      SizedBox(height: 16),
      _entry(
        reduceMotion: reduceMotion,
        delay: Duration(milliseconds: 120),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _CatalogEntryCard(
                metric: products,
                semanticsLabel:
                    '${products.value} produtos cadastrados. Abrir produtos.',
                onTap: onOpenProducts,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _CatalogEntryCard(
                metric: services,
                semanticsLabel:
                    '${services.value} serviços cadastrados. Abrir serviços.',
                onTap: onOpenServices,
              ),
            ),
          ],
        ),
      ),
      if (canCreate) ...<Widget>[
        SizedBox(height: 12),
        _entry(
          reduceMotion: reduceMotion,
          delay: Duration(milliseconds: 170),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _CatalogActionButton(
                  label: newProductAction?.title ?? 'Novo produto',
                  icon: _catalogIcon(newProductAction?.iconCode ?? 'ADICIONAR'),
                  onTap: onNewProduct,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _CatalogActionButton(
                  label: newServiceAction?.title ?? 'Novo serviço',
                  icon: _catalogIcon(newServiceAction?.iconCode ?? 'SERVICO'),
                  onTap: onNewService,
                ),
              ),
            ],
          ),
        ),
      ],
      SizedBox(height: 22),
      _entry(
        reduceMotion: reduceMotion,
        delay: Duration(milliseconds: 220),
        child: _SectionTitle(
          title: summary.pendingSection.title,
          subtitle: summary.pendingSection.description,
        ),
      ),
      SizedBox(height: 10),
      ...pendingMetrics.asMap().entries.map((
        MapEntry<int, CatalogHealthMetric> entry,
      ) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _entry(
            reduceMotion: reduceMotion,
            delay: Duration(milliseconds: 260 + (entry.key * 40)),
            child: _CatalogPendingCard(
              metric: entry.value,
              onTap: () => onPendingMetric(entry.value),
            ),
          ),
        );
      }),
      if (!canViewStock) ...<Widget>[
        SizedBox(height: 2),
        _entry(
          reduceMotion: reduceMotion,
          delay: Duration(milliseconds: 320),
          child: const _RestrictedStockNotice(),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _entry({
    required bool reduceMotion,
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    if (reduceMotion) return child;
    return SixStaggeredEntry(delay: delay, child: child);
  }
}

class _CatalogHealthHero extends StatelessWidget {
  const _CatalogHealthHero({
    required this.summary,
    required this.animationRevision,
    required this.reduceMotion,
  });

  final CatalogHealthSummary summary;
  final int animationRevision;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final CatalogHealthScore health = summary.health;
    final String statusLabel = _catalogHealthStatusLabel(
      context,
      health.situation,
    );
    final String attentionTemplate = context.t(
      'catalogHealth.mobile.attentionItems',
      fallback: '{count} itens precisam de atenção',
    );
    final String attentionLabel =
        attentionTemplate.contains('{count}')
            ? attentionTemplate.replaceFirst(
              '{count}',
              summary.attentionItems.toString(),
            )
            : '${summary.attentionItems} $attentionTemplate';

    return Semantics(
      container: true,
      label: '${health.title}. ${health.description}. $attentionLabel.',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.heroShadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              summary.header.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              health.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SixMobilePalette.mutedText,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 14),
            Center(
              child: CatalogHealthScoreIndicator(
                percentage: health.percentage,
                statusLabel: statusLabel,
                semanticColorCode:
                    health.semanticColor.isNotEmpty
                        ? health.semanticColor
                        : health.situation,
                attentionLabel: attentionLabel,
                reduceMotion: reduceMotion,
                animationKey: animationRevision,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _catalogHealthStatusLabel(BuildContext context, String situation) {
  switch (situation.trim().toUpperCase()) {
    case 'CRITICO':
    case 'CRITICA':
      return context.t('catalogHealth.status.critical', fallback: 'Crítico');
    case 'ATENCAO':
    case 'ALERTA':
      return context.t('catalogHealth.status.warning', fallback: 'Atenção');
    case 'SAUDAVEL':
    case 'SAUDE':
      return context.t('catalogHealth.status.healthy', fallback: 'Saudável');
    default:
      if (situation.trim().isNotEmpty) {
        return situation;
      }
      return context.t('catalogHealth.status.default', fallback: 'Saúde');
  }
}

IconData _catalogIcon(String code) {
  switch (code) {
    case 'ADICIONAR':
      return Icons.add_rounded;
    case 'SERVICO':
      return Icons.design_services_outlined;
    case 'IMAGEM':
      return Icons.photo_library_outlined;
    case 'ESTOQUE_ZERADO':
      return Icons.remove_shopping_cart_outlined;
    case 'CARRINHO_ALERTA':
      return Icons.production_quantity_limits_outlined;
    case 'CADASTRO':
      return Icons.fact_check_outlined;
    case 'CATEGORIA':
      return Icons.category_outlined;
    case 'PRODUTO':
    default:
      return Icons.inventory_2_outlined;
  }
}

Color _catalogSemanticColor(String code) {
  switch (code) {
    case 'VERMELHO':
      return SixMobilePalette.error;
    case 'AMARELO':
      return Color(0xFFFBBF24);
    case 'VERDE':
      return Color(0xFF14B8A6);
    case 'AZUL':
      return SixMobilePalette.accent;
    default:
      return SixMobilePalette.primary;
  }
}

class _CatalogEntryCard extends StatelessWidget {
  const _CatalogEntryCard({
    required this.metric,
    required this.semanticsLabel,
    required this.onTap,
  });

  final CatalogHealthMetric metric;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 112),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: SixMobilePalette.softNeutralSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _catalogIcon(metric.iconCode),
                        color: SixMobilePalette.primary,
                        size: 20,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: SixMobilePalette.mutedText,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SixAnimatedNumberText(
                  value: metric.value.toString(),
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  metric.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogActionButton extends StatelessWidget {
  const _CatalogActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: SixMobilePalette.accent,
          foregroundColor: SixMobilePalette.onPrimary,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: SixMobilePalette.titleText,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: SixMobilePalette.mutedText,
            height: 1.3,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CatalogPendingCard extends StatelessWidget {
  const _CatalogPendingCard({required this.metric, required this.onTap});

  final CatalogHealthMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        metric.semanticColor.isNotEmpty
            ? _catalogSemanticColor(metric.semanticColor)
            : switch (metric.severity) {
              CatalogHealthMetricSeverity.critical => SixMobilePalette.error,
              CatalogHealthMetricSeverity.warning => SixMobilePalette.error,
              CatalogHealthMetricSeverity.informative =>
                SixMobilePalette.accent,
              CatalogHealthMetricSeverity.neutral => SixMobilePalette.primary,
            };
    final String stateText = metric.isPositive ? 'Em dia' : '${metric.value}';

    return Semantics(
      button: true,
      label:
          metric.isPositive
              ? '${metric.title}, nenhum item pendente.'
              : '${metric.value} itens em ${metric.title.toLowerCase()}.',
      child: Material(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 72),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.softNeutralSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _catalogIcon(metric.iconCode),
                    color: accent,
                    size: 21,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        metric.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        metric.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  stateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: metric.isPositive ? 12 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SixMobilePalette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestrictedStockNotice extends StatelessWidget {
  const _RestrictedStockNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Indicadores de estoque ocultos pelo seu acesso.',
      child: Container(
        padding: EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              color: SixMobilePalette.mutedText,
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Indicadores de estoque ocultos pelo seu acesso.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SixMobilePalette.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogLoadingState extends StatelessWidget {
  const _CatalogLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Carregando saúde do catálogo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SkeletonLine(width: 260),
          SizedBox(height: 10),
          const _SkeletonLine(width: 132),
          SizedBox(height: 16),
          const _SkeletonCard(height: 132),
          SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(child: _SkeletonCard(height: 112)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonCard(height: 112)),
            ],
          ),
          SizedBox(height: 22),
          const _SkeletonLine(width: 120),
          SizedBox(height: 10),
          const _SkeletonCard(height: 72),
          SizedBox(height: 10),
          const _SkeletonCard(height: 72),
          SizedBox(height: 10),
          const _SkeletonCard(height: 72),
        ],
      ),
    );
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState({
    super.key,
    required this.canCreate,
    required this.onNewProduct,
    required this.onNewService,
  });

  final bool canCreate;
  final VoidCallback onNewProduct;
  final VoidCallback onNewService;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.inventory_2_outlined,
      title: 'Catálogo ainda não iniciado',
      subtitle:
          'Quando produtos e serviços forem cadastrados, as pendências aparecerão aqui.',
      actions:
          canCreate
              ? <Widget>[
                _CatalogActionButton(
                  label: 'Novo produto',
                  icon: Icons.add_rounded,
                  onTap: onNewProduct,
                ),
                SizedBox(height: 10),
                _CatalogActionButton(
                  label: 'Novo serviço',
                  icon: Icons.design_services_outlined,
                  onTap: onNewService,
                ),
              ]
              : <Widget>[],
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  const _CatalogErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.cloud_off_outlined,
      title: 'Não foi possível carregar',
      subtitle: 'Tente novamente para ver a saúde do catálogo.',
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: Icon(Icons.refresh_rounded),
          label: Text('Tentar novamente'),
        ),
      ],
    );
  }
}

class _CatalogPermissionState extends StatelessWidget {
  const _CatalogPermissionState({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icons.lock_outline_rounded,
      title: 'Acesso ao catálogo indisponível',
      subtitle:
          'Seu acesso atual não permite visualizar a gestão de produtos e serviços.',
      actions: <Widget>[],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: SixMobilePalette.softNeutralSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: SixMobilePalette.primary),
            ),
            SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: SixMobilePalette.mutedText, height: 1.35),
            ),
            if (actions.isNotEmpty) ...<Widget>[
              SizedBox(height: 16),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: SixMobilePalette.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: SixMobilePalette.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
