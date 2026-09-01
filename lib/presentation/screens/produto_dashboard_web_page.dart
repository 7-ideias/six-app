import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/di/catalog_health_module.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';
import 'package:sixpos/data/services/catalog_health/catalog_health_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/catalog_health_provider.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

/// Hub Web de produtos e do catálogo.
///
/// Saldos e movimentações permanecem na tela de estoque. Aqui ficam a
/// qualidade do cadastro, os pontos de entrada do catálogo e uma prévia de
/// disponibilidade somente para quem possui permissão de estoque.
class ProdutoDashboardWebPage extends StatelessWidget {
  const ProdutoDashboardWebPage({
    super.key,
    this.onBack,
    this.onNovoProduto,
    this.onNovoServico,
    this.onOpenListaCompleta,
    this.onOpenListaServicos,
    this.onOpenCategorias,
    this.onOpenEtiquetas,
    this.onOpenCatalogoOnline,
    this.onOpenEstoque,
    this.apiClient,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNovoProduto;
  final VoidCallback? onNovoServico;
  final VoidCallback? onOpenListaCompleta;
  final VoidCallback? onOpenListaServicos;
  final VoidCallback? onOpenCategorias;
  final VoidCallback? onOpenEtiquetas;
  final VoidCallback? onOpenCatalogoOnline;
  final VoidCallback? onOpenEstoque;
  final CatalogHealthApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CatalogHealthProvider>(
      create: (_) => CatalogHealthProvider(
        apiClient: apiClient ?? CatalogHealthModule.catalogHealthApiClient,
        visualizacao: 'WEB',
      )..load(),
      child: _ProdutoCatalogoWebView(
        onBack: onBack,
        onNovoProduto: onNovoProduto,
        onNovoServico: onNovoServico,
        onOpenListaCompleta: onOpenListaCompleta,
        onOpenListaServicos: onOpenListaServicos,
        onOpenCategorias: onOpenCategorias,
        onOpenEtiquetas: onOpenEtiquetas,
        onOpenCatalogoOnline: onOpenCatalogoOnline,
        onOpenEstoque: onOpenEstoque,
      ),
    );
  }
}

class _ProdutoCatalogoWebView extends StatelessWidget {
  const _ProdutoCatalogoWebView({
    required this.onBack,
    required this.onNovoProduto,
    required this.onNovoServico,
    required this.onOpenListaCompleta,
    required this.onOpenListaServicos,
    required this.onOpenCategorias,
    required this.onOpenEtiquetas,
    required this.onOpenCatalogoOnline,
    required this.onOpenEstoque,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNovoProduto;
  final VoidCallback? onNovoServico;
  final VoidCallback? onOpenListaCompleta;
  final VoidCallback? onOpenListaServicos;
  final VoidCallback? onOpenCategorias;
  final VoidCallback? onOpenEtiquetas;
  final VoidCallback? onOpenCatalogoOnline;
  final VoidCallback? onOpenEstoque;

  @override
  Widget build(BuildContext context) {
    final CatalogHealthProvider provider = context
        .watch<CatalogHealthProvider>();
    final ColaboradorAutorizacoesProvider permissions = context
        .watch<ColaboradorAutorizacoesProvider>();
    final bool canCreate = permissions.podeCadastrarProduto;
    final bool canManage =
        permissions.podeCadastrarProduto || permissions.podeEditarProduto;
    final bool canViewStock = permissions.podeVerEstoqueDeProduto;
    final bool canOpenLabels =
        permissions.podeAcessarEtiquetas && onOpenEtiquetas != null;

    return Material(
      color: WebThemeTokens.of(context).workspaceBackground,
      child: Column(
        children: <Widget>[
          SixWebDashboardHeader(
            icon: Icons.inventory_2_outlined,
            title: context.t('catalogHub.web.title', fallback: 'Produtos'),
            subtitle: context.t(
              'catalogHub.web.subtitle',
              fallback:
                  'Cuide da qualidade do catálogo e acesse cadastros, categorias e etiquetas.',
            ),
            onBack: onBack,
            actions: <Widget>[
              OutlinedButton.icon(
                onPressed: provider.isLoading ? null : provider.reload,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.t('common.refresh', fallback: 'Atualizar')),
              ),
              if (canCreate && (onNovoProduto != null || onNovoServico != null))
                PopupMenuButton<_CatalogCreateAction>(
                  onSelected: (_CatalogCreateAction action) {
                    switch (action) {
                      case _CatalogCreateAction.product:
                        onNovoProduto?.call();
                      case _CatalogCreateAction.service:
                        onNovoServico?.call();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<_CatalogCreateAction>>[
                        if (onNovoProduto != null)
                          PopupMenuItem<_CatalogCreateAction>(
                            value: _CatalogCreateAction.product,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(
                                context.t(
                                  'catalogHub.actions.newProduct',
                                  fallback: 'Novo produto',
                                ),
                              ),
                            ),
                          ),
                        if (onNovoServico != null)
                          PopupMenuItem<_CatalogCreateAction>(
                            value: _CatalogCreateAction.service,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.home_repair_service_outlined,
                              ),
                              title: Text(
                                context.t(
                                  'catalogHub.actions.newService',
                                  fallback: 'Novo serviço',
                                ),
                              ),
                            ),
                          ),
                      ],
                  child: IgnorePointer(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        context.t(
                          'catalogHub.actions.newItem',
                          fallback: 'Novo item',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                children: <Widget>[
                  if (!permissions.podeAcessarCatalogo)
                    _CatalogStatePanel(
                      icon: Icons.lock_outline_rounded,
                      title: context.t(
                        'catalogHub.states.noAccessTitle',
                        fallback: 'Acesso ao catálogo indisponível',
                      ),
                      description: context.t(
                        'catalogHub.states.noAccessDescription',
                        fallback:
                            'Seu perfil não permite visualizar produtos e serviços deste comércio.',
                      ),
                    )
                  else ...<Widget>[
                    _healthState(context, provider, canManage: canManage),
                    const SizedBox(height: 20),
                    SixWebEntry(
                      order: 2,
                      child: _CatalogManagementSection(
                        canManage: canManage,
                        canOpenLabels: canOpenLabels,
                        onOpenProducts: onOpenListaCompleta,
                        onOpenServices:
                            onOpenListaServicos ?? onOpenListaCompleta,
                        onOpenCategories: onOpenCategorias,
                        onOpenLabels: onOpenEtiquetas,
                        onOpenCatalog: onOpenCatalogoOnline,
                      ),
                    ),
                    if (canViewStock && onOpenEstoque != null) ...<Widget>[
                      const SizedBox(height: 20),
                      SixWebEntry(
                        order: 3,
                        child: _StockBoundaryCard(
                          summary: provider.summary,
                          onOpenStock: onOpenEstoque!,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthState(
    BuildContext context,
    CatalogHealthProvider provider, {
    required bool canManage,
  }) {
    if (provider.isLoading) {
      return const Column(
        children: <Widget>[
          SixWebLoadingBlock(height: 210, highlight: true),
          SizedBox(height: 16),
          SixWebLoadingBlock(height: 150),
        ],
      );
    }

    if (provider.hasError) {
      return _CatalogStatePanel(
        icon: Icons.cloud_off_outlined,
        title: context.t(
          'catalogHub.states.loadErrorTitle',
          fallback: 'Não foi possível carregar a saúde do catálogo',
        ),
        description: context.t(
          'catalogHub.states.loadErrorDescription',
          fallback:
              'Os acessos do catálogo continuam disponíveis. Tente atualizar o diagnóstico.',
        ),
        action: OutlinedButton.icon(
          onPressed: provider.reload,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            context.t('common.tryAgain', fallback: 'Tentar novamente'),
          ),
        ),
      );
    }

    final CatalogHealthSummary? summary = provider.summary;
    if (summary == null || summary.isEmpty) {
      return _CatalogStatePanel(
        icon: Icons.inventory_2_outlined,
        title: context.t(
          'catalogHub.states.emptyTitle',
          fallback: 'Comece seu catálogo',
        ),
        description: context.t(
          'catalogHub.states.emptyDescription',
          fallback:
              'Cadastre o primeiro produto ou serviço. A saúde do catálogo será calculada automaticamente.',
        ),
        action: onNovoProduto == null
            ? null
            : FilledButton.icon(
                onPressed: onNovoProduto,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  context.t(
                    'catalogHub.actions.newProduct',
                    fallback: 'Novo produto',
                  ),
                ),
              ),
      );
    }

    final List<CatalogHealthMetric> catalogPending = summary
        .pendingSection
        .items
        .where((CatalogHealthMetric metric) => !metric.requiresStockPermission)
        .toList(growable: false);

    return Column(
      children: <Widget>[
        SixWebEntry(
          child: _CatalogHealthOverview(
            summary: summary,
            onOpenProducts: canManage ? onOpenListaCompleta : null,
            onOpenServices:
                canManage
                    ? (onOpenListaServicos ?? onOpenListaCompleta)
                    : null,
          ),
        ),
        const SizedBox(height: 16),
        SixWebEntry(
          order: 1,
          child: _CatalogQualityIssues(
            metrics: catalogPending,
            onOpenItems: canManage ? onOpenListaCompleta : null,
          ),
        ),
      ],
    );
  }
}

enum _CatalogCreateAction { product, service }

class _CatalogHealthOverview extends StatelessWidget {
  const _CatalogHealthOverview({
    required this.summary,
    required this.onOpenProducts,
    required this.onOpenServices,
  });

  final CatalogHealthSummary summary;
  final VoidCallback? onOpenProducts;
  final VoidCallback? onOpenServices;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final CatalogHealthScore health = summary.health;
    final Color healthColor = _healthColor(tokens, health.situation);
    final int catalogIssues = summary.pendingSection.items
        .where((CatalogHealthMetric item) => !item.requiresStockPermission)
        .fold<int>(
          0,
          (int total, CatalogHealthMetric item) => total + item.value,
        );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 840;
          final Widget score = _CatalogScore(
            percentage: health.percentage,
            status: _healthStatus(context, health.situation),
            color: healthColor,
          );
          final Widget details = _CatalogHealthDetails(
            summary: summary,
            catalogIssues: catalogIssues,
            onOpenProducts: onOpenProducts,
            onOpenServices: onOpenServices,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(child: score),
                const SizedBox(height: 22),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(width: 220, child: score),
              const SizedBox(width: 28),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogScore extends StatelessWidget {
  const _CatalogScore({
    required this.percentage,
    required this.status,
    required this.color,
  });

  final int percentage;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final double progress = percentage.clamp(0, 100) / 100;
    return Semantics(
      label: '$percentage%. $status',
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 142,
            height: 142,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 720),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, Widget? child) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: tokens.surfaceMuted,
                    ),
                    Center(
                      child: Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogHealthDetails extends StatelessWidget {
  const _CatalogHealthDetails({
    required this.summary,
    required this.catalogIssues,
    required this.onOpenProducts,
    required this.onOpenServices,
  });

  final CatalogHealthSummary summary;
  final int catalogIssues;
  final VoidCallback? onOpenProducts;
  final VoidCallback? onOpenServices;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.monitor_heart_outlined, color: tokens.info),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.t(
                  'catalogHub.health.title',
                  fallback: 'Saúde do catálogo',
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          context.t(
            'catalogHub.health.description',
            fallback:
                'Qualidade dos cadastros e prontidão dos itens para venda.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.secondaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 620;
            final List<Widget> cards = <Widget>[
              _CatalogCountCard(
                icon: Icons.inventory_2_outlined,
                label: context.t(
                  'catalogHub.modules.products',
                  fallback: 'Produtos',
                ),
                value: summary.overview.products.quantity,
                onTap: onOpenProducts,
              ),
              _CatalogCountCard(
                icon: Icons.home_repair_service_outlined,
                label: context.t(
                  'catalogHub.modules.services',
                  fallback: 'Serviços',
                ),
                value: summary.overview.services.quantity,
                onTap: onOpenServices,
              ),
              _CatalogCountCard(
                icon: Icons.rule_folder_outlined,
                label: context.t(
                  'catalogHub.health.catalogIssues',
                  fallback: 'Pendências cadastrais',
                ),
                value: catalogIssues,
              ),
            ];
            if (compact) {
              return Column(
                children: <Widget>[
                  for (
                    int index = 0;
                    index < cards.length;
                    index++
                  ) ...<Widget>[
                    cards[index],
                    if (index != cards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return Row(
              children: <Widget>[
                for (int index = 0; index < cards.length; index++) ...<Widget>[
                  Expanded(child: cards[index]),
                  if (index != cards.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CatalogCountCard extends StatelessWidget {
  const _CatalogCountCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Icon(icon, color: tokens.info, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      value.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: tokens.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogQualityIssues extends StatelessWidget {
  const _CatalogQualityIssues({
    required this.metrics,
    required this.onOpenItems,
  });

  final List<CatalogHealthMetric> metrics;
  final VoidCallback? onOpenItems;

  @override
  Widget build(BuildContext context) {
    final bool healthy =
        metrics.isEmpty ||
        metrics.every((CatalogHealthMetric item) => item.value == 0);
    return SixWebSectionCard(
      title: context.t(
        'catalogHub.health.qualityTitle',
        fallback: 'Qualidade do cadastro',
      ),
      subtitle: context.t(
        'catalogHub.health.qualitySubtitle',
        fallback:
            'Fotos, categorias e informações que ajudam o cliente a decidir.',
      ),
      icon: Icons.fact_check_outlined,
      child: healthy
          ? const _HealthyCatalogMessage()
          : Column(
              children: <Widget>[
                for (
                  int index = 0;
                  index < metrics.length;
                  index++
                ) ...<Widget>[
                  _CatalogIssueRow(metric: metrics[index], onTap: onOpenItems),
                  if (index != metrics.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _HealthyCatalogMessage extends StatelessWidget {
  const _HealthyCatalogMessage();

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline_rounded, color: tokens.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(
                'catalogHub.health.noQualityIssues',
                fallback: 'Nenhuma pendência cadastral encontrada.',
              ),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogIssueRow extends StatelessWidget {
  const _CatalogIssueRow({required this.metric, this.onTap});

  final CatalogHealthMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color color = switch (metric.severity) {
      CatalogHealthMetricSeverity.critical => tokens.danger,
      CatalogHealthMetricSeverity.warning => tokens.warning,
      CatalogHealthMetricSeverity.informative => tokens.info,
      CatalogHealthMetricSeverity.neutral => tokens.statusNeutral,
    };
    final bool resolved = metric.value == 0;

    return Material(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: resolved ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_metricIcon(metric.type), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _metricTitle(context, metric),
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _metricSubtitle(context, metric),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                resolved
                    ? context.t('common.ok', fallback: 'OK')
                    : metric.value.toString(),
                style: TextStyle(
                  color: resolved ? tokens.success : color,
                  fontSize: resolved ? 13 : 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!resolved && onTap != null) ...<Widget>[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: tokens.mutedText),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogManagementSection extends StatelessWidget {
  const _CatalogManagementSection({
    required this.canManage,
    required this.canOpenLabels,
    required this.onOpenProducts,
    required this.onOpenServices,
    required this.onOpenCategories,
    required this.onOpenLabels,
    required this.onOpenCatalog,
  });

  final bool canManage;
  final bool canOpenLabels;
  final VoidCallback? onOpenProducts;
  final VoidCallback? onOpenServices;
  final VoidCallback? onOpenCategories;
  final VoidCallback? onOpenLabels;
  final VoidCallback? onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final List<_CatalogModuleData> modules = <_CatalogModuleData>[
      if (canManage) ...<_CatalogModuleData>[
        _CatalogModuleData(
          icon: Icons.inventory_2_outlined,
          title: context.t('catalogHub.modules.products', fallback: 'Produtos'),
          subtitle: context.t(
            'catalogHub.modules.productsDescription',
            fallback: 'Cadastre, revise e publique itens de venda.',
          ),
          onTap: onOpenProducts,
        ),
        _CatalogModuleData(
          icon: Icons.home_repair_service_outlined,
          title: context.t('catalogHub.modules.services', fallback: 'Serviços'),
          subtitle: context.t(
            'catalogHub.modules.servicesDescription',
            fallback: 'Organize serviços, preços e garantias.',
          ),
          onTap: onOpenServices,
        ),
        _CatalogModuleData(
          icon: Icons.category_outlined,
          title: context.t(
            'catalogHub.modules.categories',
            fallback: 'Categorias',
          ),
          subtitle: context.t(
            'catalogHub.modules.categoriesDescription',
            fallback: 'Agrupe produtos e serviços para facilitar a operação.',
          ),
          onTap: onOpenCategories,
        ),
      ],
      if (canOpenLabels)
        _CatalogModuleData(
          icon: Icons.local_offer_outlined,
          title: context.t('catalogHub.modules.labels', fallback: 'Etiquetas'),
          subtitle: context.t(
            'catalogHub.modules.labelsDescription',
            fallback: 'Crie modelos e imprima etiquetas de produtos.',
          ),
          onTap: onOpenLabels,
        ),
      if (canManage)
        _CatalogModuleData(
          icon: Icons.language_outlined,
          title: context.t(
            'catalogHub.modules.onlineCatalog',
            fallback: 'Catálogo online',
          ),
          subtitle: context.t(
            'catalogHub.modules.onlineCatalogDescription',
            fallback: 'Personalize a vitrine pública e compartilhe o link.',
          ),
          onTap: onOpenCatalog,
        ),
    ];

    return SixWebSectionCard(
      title: context.t(
        'catalogHub.management.title',
        fallback: 'Gestão do catálogo',
      ),
      subtitle: context.t(
        'catalogHub.management.subtitle',
        fallback:
            'Cadastros e ferramentas do catálogo ficam centralizados aqui.',
      ),
      icon: Icons.widgets_outlined,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = constraints.maxWidth >= 1180
              ? 4
              : constraints.maxWidth >= 720
              ? 2
              : 1;
          const double spacing = 12;
          final double width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: modules
                .map(
                  (_CatalogModuleData module) => SizedBox(
                    width: width,
                    child: _CatalogModuleCard(data: module),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _CatalogModuleData {
  const _CatalogModuleData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class _CatalogModuleCard extends StatelessWidget {
  const _CatalogModuleCard({required this.data});

  final _CatalogModuleData data;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tokens.info.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(data.icon, color: tokens.info, size: 21),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: tokens.mutedText),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                data.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.secondaryText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBoundaryCard extends StatelessWidget {
  const _StockBoundaryCard({required this.summary, required this.onOpenStock});

  final CatalogHealthSummary? summary;
  final VoidCallback onOpenStock;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<CatalogHealthMetric> stockMetrics =
        summary?.pendingSection.items
            .where((CatalogHealthMetric item) => item.requiresStockPermission)
            .toList(growable: false) ??
        const <CatalogHealthMetric>[];
    final int stockIssues = stockMetrics.fold<int>(
      0,
      (int total, CatalogHealthMetric item) => total + item.value,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.info.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.warehouse_outlined, color: tokens.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'catalogHub.stock.title',
                    fallback: 'Disponibilidade do estoque',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stockIssues == 0
                      ? context.t(
                          'catalogHub.stock.noIssues',
                          fallback: 'Nenhuma indisponibilidade exige atenção.',
                        )
                      : context
                            .t(
                              'catalogHub.stock.issues',
                              fallback:
                                  '{count} ocorrências precisam de atenção operacional.',
                            )
                            .replaceFirst('{count}', stockIssues.toString()),
                  style: TextStyle(color: tokens.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: onOpenStock,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              context.t(
                'catalogHub.stock.openManagement',
                fallback: 'Abrir estoque',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogStatePanel extends StatelessWidget {
  const _CatalogStatePanel({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tokens.info),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(color: tokens.secondaryText, height: 1.4),
                ),
              ],
            ),
          ),
          if (action != null) ...<Widget>[const SizedBox(width: 16), action!],
        ],
      ),
    );
  }
}

Color _healthColor(WebThemeTokens tokens, String situation) {
  switch (situation.trim().toUpperCase()) {
    case 'CRITICO':
    case 'CRITICA':
      return tokens.danger;
    case 'ATENCAO':
    case 'ALERTA':
      return tokens.warning;
    case 'SAUDAVEL':
    case 'SAUDE':
      return tokens.success;
    default:
      return tokens.info;
  }
}

String _healthStatus(BuildContext context, String situation) {
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
      return context.t('catalogHealth.status.default', fallback: 'Saúde');
  }
}

IconData _metricIcon(CatalogHealthMetricType type) {
  return switch (type) {
    CatalogHealthMetricType.missingPhoto => Icons.photo_library_outlined,
    CatalogHealthMetricType.incompleteRegistration => Icons.fact_check_outlined,
    CatalogHealthMetricType.missingCategory => Icons.category_outlined,
    CatalogHealthMetricType.withoutSales => Icons.history_toggle_off_rounded,
    CatalogHealthMetricType.outOfStock => Icons.remove_shopping_cart_outlined,
    CatalogHealthMetricType.lowStock =>
      Icons.production_quantity_limits_outlined,
    CatalogHealthMetricType.highStock => Icons.inventory_outlined,
    CatalogHealthMetricType.services => Icons.home_repair_service_outlined,
    CatalogHealthMetricType.products => Icons.inventory_2_outlined,
    CatalogHealthMetricType.unknown => Icons.info_outline_rounded,
  };
}

String _metricTitle(BuildContext context, CatalogHealthMetric metric) {
  return switch (metric.type) {
    CatalogHealthMetricType.missingPhoto => context.t(
      'catalogHealth.metric.missingPhoto',
      fallback: 'Sem foto',
    ),
    CatalogHealthMetricType.incompleteRegistration => context.t(
      'catalogHealth.metric.incompleteRegistration',
      fallback: 'Cadastro incompleto',
    ),
    CatalogHealthMetricType.missingCategory => context.t(
      'catalogHealth.metric.missingCategory',
      fallback: 'Sem categoria',
    ),
    CatalogHealthMetricType.withoutSales => context.t(
      'catalogHealth.metric.withoutSales',
      fallback: 'Sem vendas recentes',
    ),
    _ => metric.title,
  };
}

String _metricSubtitle(BuildContext context, CatalogHealthMetric metric) {
  return switch (metric.type) {
    CatalogHealthMetricType.missingPhoto => context.t(
      'catalogHealth.metric.missingPhotoDescription',
      fallback: 'Produtos que precisam de uma imagem.',
    ),
    CatalogHealthMetricType.incompleteRegistration => context.t(
      'catalogHealth.metric.incompleteRegistrationDescription',
      fallback: 'Itens com informações essenciais pendentes.',
    ),
    CatalogHealthMetricType.missingCategory => context.t(
      'catalogHealth.metric.missingCategoryDescription',
      fallback: 'Itens ainda sem organização definida.',
    ),
    CatalogHealthMetricType.withoutSales => context.t(
      'catalogHealth.metric.withoutSalesDescription',
      fallback: 'Produtos sem movimentação de saída recente.',
    ),
    _ => metric.subtitle,
  };
}
