import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/datasources/catalog_health_mock_data_source.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
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
            dataSource: const CatalogHealthMockDataSource(),
          )..load(),
      child: const _CatalogHealthMobileView(),
    );
  }
}

class _CatalogHealthMobileView extends StatelessWidget {
  const _CatalogHealthMobileView();

  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;

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
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
                      children: <Widget>[
                        AnimatedSwitcher(
                          duration:
                              reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
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
        key: const ValueKey<String>('catalog-health-error'),
        onRetry: provider.reload,
      );
    }

    final CatalogHealthSummary? summary = provider.summary;
    if (summary == null || summary.isEmpty) {
      return _CatalogEmptyState(
        key: const ValueKey<String>('catalog-health-empty'),
        canCreate: permissions.podeCadastrarProduto,
        onNewProduct: () => _openCreate(context, 'PRODUTO'),
        onNewService: () => _openCreate(context, 'SERVICO'),
      );
    }

    return _CatalogSuccessState(
      key: const ValueKey<String>('catalog-health-success'),
      summary: summary,
      canCreate: permissions.podeCadastrarProduto,
      canViewStock: permissions.podeVerEstoqueDeProduto,
      reduceMotion: reduceMotion,
      onOpenProducts: () => _openProducts(context),
      onOpenServices: () => _openServices(context),
      onNewProduct: () => _openCreate(context, 'PRODUTO'),
      onNewService: () => _openCreate(context, 'SERVICO'),
      onDemoMetric: () => _showDemoFilterMessage(context),
    );
  }

  void _openProducts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProdutolistMobileScreen(tipoInicial: 'PRODUTO'),
      ),
    );
  }

  void _openServices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProdutolistMobileScreen(tipoInicial: 'SERVICO'),
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

  void _showDemoFilterMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Este indicador ainda utiliza dados demonstrativos. O filtro será integrado em uma próxima etapa.',
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
    required this.canCreate,
    required this.canViewStock,
    required this.reduceMotion,
    required this.onOpenProducts,
    required this.onOpenServices,
    required this.onNewProduct,
    required this.onNewService,
    required this.onDemoMetric,
  });

  final CatalogHealthSummary summary;
  final bool canCreate;
  final bool canViewStock;
  final bool reduceMotion;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenServices;
  final VoidCallback onNewProduct;
  final VoidCallback onNewService;
  final VoidCallback onDemoMetric;

  @override
  Widget build(BuildContext context) {
    final CatalogHealthMetric products =
        summary.metric(CatalogHealthMetricType.products)!;
    final CatalogHealthMetric services =
        summary.metric(CatalogHealthMetricType.services)!;
    final List<CatalogHealthMetric> pendingMetrics = summary.metrics
        .where((CatalogHealthMetric metric) => metric.countsAsAttention)
        .where(
          (CatalogHealthMetric metric) =>
              canViewStock || !metric.requiresStockPermission,
        )
        .toList(growable: false);

    final List<Widget> children = <Widget>[
      _entry(reduceMotion: reduceMotion, child: const _CatalogIntro()),
      const SizedBox(height: 14),
      _entry(
        reduceMotion: reduceMotion,
        delay: const Duration(milliseconds: 70),
        child: _CatalogAttentionHero(total: summary.attentionItems),
      ),
      const SizedBox(height: 16),
      _entry(
        reduceMotion: reduceMotion,
        delay: const Duration(milliseconds: 120),
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
            const SizedBox(width: 10),
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
        const SizedBox(height: 12),
        _entry(
          reduceMotion: reduceMotion,
          delay: const Duration(milliseconds: 170),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _CatalogActionButton(
                  label: 'Novo produto',
                  icon: Icons.add_rounded,
                  onTap: onNewProduct,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CatalogActionButton(
                  label: 'Novo serviço',
                  icon: Icons.design_services_outlined,
                  onTap: onNewService,
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 22),
      _entry(
        reduceMotion: reduceMotion,
        delay: const Duration(milliseconds: 220),
        child: _SectionTitle(
          title: 'Pendências',
          subtitle: 'Tarefas de revisão para manter o catálogo pronto.',
        ),
      ),
      const SizedBox(height: 10),
      ...pendingMetrics.asMap().entries.map((
        MapEntry<int, CatalogHealthMetric> entry,
      ) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _entry(
            reduceMotion: reduceMotion,
            delay: Duration(milliseconds: 260 + (entry.key * 40)),
            child: _CatalogPendingCard(
              metric: entry.value,
              onTap: onDemoMetric,
            ),
          ),
        );
      }),
      if (!canViewStock) ...<Widget>[
        const SizedBox(height: 2),
        _entry(
          reduceMotion: reduceMotion,
          delay: const Duration(milliseconds: 320),
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

class _CatalogIntro extends StatelessWidget {
  const _CatalogIntro();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Saúde do catálogo. Revise produtos e serviços que precisam de atenção. Dados demonstrativos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Revise produtos e serviços que precisam de atenção.',
            style: TextStyle(
              color: SixMobilePalette.heroSupportingText,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SixMobilePalette.surface.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: SixMobilePalette.surface.withValues(alpha: 0.22),
                ),
              ),
              child: const Text(
                'Dados demonstrativos',
                style: TextStyle(
                  color: SixMobilePalette.heroLabelText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogAttentionHero extends StatelessWidget {
  const _CatalogAttentionHero({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '$total itens precisam de atenção. Corrija pendências para manter o catálogo pronto para vendas.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.heroShadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SixMobilePalette.softAccentSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: SixMobilePalette.accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      SixAnimatedNumberText(
                        value: total.toString(),
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'itens precisam de atenção',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.titleText,
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Corrija pendências para manter o catálogo pronto para vendas.',
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
              ),
            ),
          ],
        ),
      ),
    );
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
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(14),
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
                        metric.icon,
                        color: SixMobilePalette.primary,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SixMobilePalette.mutedText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SixAnimatedNumberText(
                  value: metric.value.toString(),
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metric.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
          style: const TextStyle(
            color: SixMobilePalette.titleText,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
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
        metric.severity == CatalogHealthMetricSeverity.restricted
            ? SixMobilePalette.error
            : SixMobilePalette.accent;
    final String stateText = metric.isPositive ? 'Em dia' : '${metric.value}';

    return Semantics(
      button: true,
      label:
          metric.isPositive
              ? '${metric.title}, nenhum item pendente, indicador demonstrativo.'
              : '${metric.value} ${metric.title.toLowerCase()}, indicador demonstrativo.',
      child: Material(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  child: Icon(metric.icon, color: accent, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        metric.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
                const SizedBox(width: 6),
                const Icon(
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
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: const Row(
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
      label: 'Carregando dados demonstrativos da saúde do catálogo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SkeletonLine(width: 260),
          const SizedBox(height: 10),
          const _SkeletonLine(width: 132),
          const SizedBox(height: 16),
          const _SkeletonCard(height: 104),
          const SizedBox(height: 14),
          Row(
            children: const <Widget>[
              Expanded(child: _SkeletonCard(height: 112)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonCard(height: 112)),
            ],
          ),
          const SizedBox(height: 22),
          const _SkeletonLine(width: 120),
          const SizedBox(height: 10),
          const _SkeletonCard(height: 72),
          const SizedBox(height: 10),
          const _SkeletonCard(height: 72),
          const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                _CatalogActionButton(
                  label: 'Novo serviço',
                  icon: Icons.design_services_outlined,
                  onTap: onNewService,
                ),
              ]
              : const <Widget>[],
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
      subtitle: 'Tente novamente para ver os dados demonstrativos do catálogo.',
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: SixMobilePalette.mutedText,
                height: 1.35,
              ),
            ),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
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
