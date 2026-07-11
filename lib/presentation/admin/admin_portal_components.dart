import 'package:flutter/material.dart';

import '../../core/services/admin_portal_service.dart';
import 'admin_dashboard_metrics.dart';
import 'admin_portal_texts.dart';

class AdminPortalUserInfo {
  const AdminPortalUserInfo({
    this.name,
    this.email,
    this.profileType,
  });

  final String? name;
  final String? email;
  final String? profileType;
}

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.texts,
    required this.userInfo,
    required this.onLogout,
    required this.onRefresh,
    required this.refreshing,
    required this.loggingOut,
    required this.child,
  });

  final AdminPortalTexts texts;
  final AdminPortalUserInfo userInfo;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final bool refreshing;
  final bool loggingOut;
  final Widget child;

  static const double sidebarWidth = 252;
  static const double compactBreakpoint = 900;
  static const double maxContentWidth = 1280;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < compactBreakpoint;
        final Widget sidebar = AdminSidebar(
          texts: texts,
          userInfo: userInfo,
          onLogout: onLogout,
          loggingOut: loggingOut,
        );

        if (compact) {
          return Scaffold(
            backgroundColor: AdminPalette.background,
            drawer: Drawer(width: sidebarWidth, child: sidebar),
            body: Builder(
              builder: (BuildContext scaffoldContext) {
                return _AdminMainArea(
                  texts: texts,
                  compact: true,
                  refreshing: refreshing,
                  loggingOut: loggingOut,
                  onOpenMenu: () => Scaffold.of(scaffoldContext).openDrawer(),
                  onRefresh: onRefresh,
                  onLogout: onLogout,
                  child: child,
                );
              },
            ),
          );
        }

        return Scaffold(
          backgroundColor: AdminPalette.background,
          body: Row(
            children: <Widget>[
              SizedBox(width: sidebarWidth, child: sidebar),
              Expanded(
                child: _AdminMainArea(
                  texts: texts,
                  compact: false,
                  refreshing: refreshing,
                  loggingOut: loggingOut,
                  onRefresh: onRefresh,
                  onLogout: onLogout,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminMainArea extends StatelessWidget {
  const _AdminMainArea({
    required this.texts,
    required this.compact,
    required this.refreshing,
    required this.loggingOut,
    required this.onRefresh,
    required this.onLogout,
    required this.child,
    this.onOpenMenu,
  });

  final AdminPortalTexts texts;
  final bool compact;
  final bool refreshing;
  final bool loggingOut;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback? onOpenMenu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          AdminTopBar(
            texts: texts,
            compact: compact,
            refreshing: refreshing,
            loggingOut: loggingOut,
            onOpenMenu: onOpenMenu,
            onRefresh: onRefresh,
            onLogout: onLogout,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? AdminSpacing.lg : AdminSpacing.xl,
                AdminSpacing.lg,
                compact ? AdminSpacing.lg : AdminSpacing.xl,
                AdminSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AdminShell.maxContentWidth),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.texts,
    required this.userInfo,
    required this.onLogout,
    required this.loggingOut,
  });

  final AdminPortalTexts texts;
  final AdminPortalUserInfo userInfo;
  final VoidCallback onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) {
    final String displayName = _firstNotEmpty(userInfo.name, texts.userFallback);
    final String displayEmail = _firstNotEmpty(userInfo.email, texts.userRole);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AdminPalette.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AdminPalette.dark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('6', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Six', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark)),
                        Text(texts.portalTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AdminPalette.mutedText, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AdminNavItem(
                icon: Icons.dashboard_rounded,
                label: texts.dashboard,
                selected: true,
                onTap: () {},
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminPalette.softSurface,
                  borderRadius: BorderRadius.circular(AdminRadius.lg),
                  border: Border.all(color: AdminPalette.border),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AdminPalette.dark,
                      child: Text(_initials(displayName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark)),
                          Text(displayEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AdminPalette.mutedText, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: loggingOut ? null : onLogout,
                icon: loggingOut
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.logout_rounded, size: 18),
                label: Text(texts.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminNavItem extends StatefulWidget {
  const AdminNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<AdminNavItem> createState() => _AdminNavItemState();
}

class _AdminNavItemState extends State<AdminNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.selected || _hovering;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: AdminMotion.fast,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.selected ? AdminPalette.activeGreen : (highlighted ? AdminPalette.hover : Colors.transparent),
          borderRadius: BorderRadius.circular(AdminRadius.md),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: <Widget>[
                  Icon(widget.icon, size: 20, color: AdminPalette.dark),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w800, color: AdminPalette.dark))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.texts,
    required this.compact,
    required this.refreshing,
    required this.loggingOut,
    required this.onRefresh,
    required this.onLogout,
    this.onOpenMenu,
  });

  final AdminPortalTexts texts;
  final bool compact;
  final bool refreshing;
  final bool loggingOut;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? AdminSpacing.lg : AdminSpacing.xl),
      decoration: const BoxDecoration(
        color: AdminPalette.background,
        border: Border(bottom: BorderSide(color: AdminPalette.border)),
      ),
      child: Row(
        children: <Widget>[
          if (compact) ...<Widget>[
            Tooltip(
              message: texts.menu,
              child: IconButton(onPressed: onOpenMenu, icon: const Icon(Icons.menu_rounded)),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(texts.currentPage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark, fontSize: 16)),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminPalette.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Flexible(child: Text(texts.online, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AdminPalette.mutedText, fontWeight: FontWeight.w700, fontSize: 12))),
                  ],
                ),
              ],
            ),
          ),
          Tooltip(
            message: texts.refresh,
            child: IconButton(
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: texts.logout,
            child: IconButton(
              onPressed: loggingOut ? null : onLogout,
              icon: loggingOut ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({
    super.key,
    required this.texts,
    required this.userName,
    required this.resumo,
    required this.metrics,
  });

  final AdminPortalTexts texts;
  final String? userName;
  final AdminPortalResumo resumo;
  final AdminCompaniesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return AdminStaggeredColumn(
      children: <Widget>[
        AdminDashboardHeader(texts: texts, userName: userName),
        AdminMetricsGrid(texts: texts, metrics: metrics),
        if (metrics.hasCompanies)
          AdminCompaniesOverview(texts: texts, metrics: metrics)
        else
          AdminEmptyState(texts: texts),
        if (resumo.bancosDeDados.isNotEmpty || resumo.actuator != null)
          AdminInfrastructureSection(texts: texts, resumo: resumo),
        AdminComingSoonCard(texts: texts),
      ],
    );
  }
}

class AdminDashboardHeader extends StatelessWidget {
  const AdminDashboardHeader({super.key, required this.texts, this.userName});

  final AdminPortalTexts texts;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(texts.greetingFor(DateTime.now(), userName), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AdminPalette.mutedText, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(texts.dashboardTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: AdminPalette.dark, letterSpacing: -0.8)),
                const SizedBox(height: 8),
                Text(texts.dashboardSubtitle, style: const TextStyle(color: AdminPalette.bodyText, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminMetricsGrid extends StatelessWidget {
  const AdminMetricsGrid({super.key, required this.texts, required this.metrics});

  final AdminPortalTexts texts;
  final AdminCompaniesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = constraints.maxWidth >= 1140 ? 4 : (constraints.maxWidth >= 680 ? 2 : 1);
          final double width = (constraints.maxWidth - ((columns - 1) * AdminSpacing.md)) / columns;
          return Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.md,
            children: <Widget>[
              SizedBox(width: width, child: AdminMetricCard.dark(icon: Icons.business_rounded, title: texts.totalCompanies, value: metrics.total.toDouble(), formatter: _formatInteger, subtitle: texts.totalCompaniesHint)),
              SizedBox(width: width, child: AdminMetricCard(icon: Icons.verified_rounded, title: texts.activeCompanies, value: metrics.active.toDouble(), formatter: _formatInteger, subtitle: texts.activeCompaniesHint)),
              SizedBox(width: width, child: AdminMetricCard(icon: Icons.pause_circle_outline_rounded, title: texts.inactiveCompanies, value: metrics.inactive.toDouble(), formatter: _formatInteger, subtitle: texts.inactiveCompaniesHint)),
              SizedBox(width: width, child: AdminMetricCard(icon: Icons.percent_rounded, title: texts.activePercent, value: metrics.activePercent, formatter: _formatPercent, subtitle: texts.activePercentHint)),
            ],
          );
        },
      ),
    );
  }
}

class AdminMetricCard extends StatefulWidget {
  const AdminMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.formatter,
    required this.subtitle,
  }) : dark = false;

  const AdminMetricCard.dark({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.formatter,
    required this.subtitle,
  }) : dark = true;

  final IconData icon;
  final String title;
  final double value;
  final String Function(double) formatter;
  final String subtitle;
  final bool dark;

  @override
  State<AdminMetricCard> createState() => _AdminMetricCardState();
}

class _AdminMetricCardState extends State<AdminMetricCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color background = widget.dark ? AdminPalette.dark : Colors.white;
    final Color foreground = widget.dark ? Colors.white : AdminPalette.dark;
    final Color muted = widget.dark ? Colors.white.withOpacity(0.68) : AdminPalette.mutedText;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: AdminMotion.fast,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovering ? -3 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AdminRadius.xl),
          border: Border.all(color: widget.dark ? Colors.transparent : AdminPalette.border),
          boxShadow: <BoxShadow>[
            BoxShadow(color: AdminPalette.shadow.withOpacity(_hovering ? 0.13 : 0.07), blurRadius: _hovering ? 24 : 18, offset: Offset(0, _hovering ? 12 : 8)),
          ],
        ),
        child: TweenAnimationBuilder<double>(
          key: ValueKey<String>('${widget.title}-${widget.value}'),
          tween: Tween<double>(begin: 0, end: widget.value),
          duration: AdminMotion.number,
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double animatedValue, Widget? child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: widget.dark ? Colors.white.withOpacity(0.10) : AdminPalette.activeGreen, borderRadius: BorderRadius.circular(AdminRadius.md)),
                      child: Icon(widget.icon, color: foreground, size: 20),
                    ),
                    const Spacer(),
                    Icon(Icons.trending_flat_rounded, color: muted, size: 20),
                  ],
                ),
                const SizedBox(height: 18),
                Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 8),
                Text(widget.formatter(animatedValue), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: foreground, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                const SizedBox(height: 8),
                Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, height: 1.25)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AdminCompaniesOverview extends StatelessWidget {
  const AdminCompaniesOverview({super.key, required this.texts, required this.metrics});

  final AdminPortalTexts texts;
  final AdminCompaniesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 820;
          return Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.md,
            children: <Widget>[
              SizedBox(
                width: compact ? constraints.maxWidth : (constraints.maxWidth - AdminSpacing.md) * 0.62,
                child: _DistributionPanel(texts: texts, metrics: metrics),
              ),
              SizedBox(
                width: compact ? constraints.maxWidth : (constraints.maxWidth - AdminSpacing.md) * 0.38,
                child: _SummaryPanel(texts: texts, metrics: metrics),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DistributionPanel extends StatelessWidget {
  const _DistributionPanel({required this.texts, required this.metrics});

  final AdminPortalTexts texts;
  final AdminCompaniesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final double activeRatio = metrics.total == 0 ? 0 : (metrics.active.clamp(0, metrics.total) / metrics.total);
    final double inactiveRatio = metrics.total == 0 ? 0 : (metrics.inactive / metrics.total);

    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(texts.overviewTitle, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark, fontSize: 18)),
          const SizedBox(height: 6),
          Text(texts.overviewSubtitle, style: const TextStyle(color: AdminPalette.mutedText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 26),
          _DistributionBar(label: texts.activeLabel, value: metrics.active, ratio: activeRatio, color: AdminPalette.success),
          const SizedBox(height: 18),
          _DistributionBar(label: texts.inactiveLabel, value: metrics.inactive, ratio: inactiveRatio, color: AdminPalette.warning),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatefulWidget {
  const _DistributionBar({required this.label, required this.value, required this.ratio, required this.color});

  final String label;
  final int value;
  final double ratio;
  final Color color;

  @override
  State<_DistributionBar> createState() => _DistributionBarState();
}

class _DistributionBarState extends State<_DistributionBar> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final double safeRatio = widget.ratio.clamp(0, 1).toDouble();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w800, color: AdminPalette.dark))),
              Text(widget.value.toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: _hovering ? 13 : 11,
              color: AdminPalette.softSurface,
              child: TweenAnimationBuilder<double>(
                key: ValueKey<String>('bar-${widget.label}-$safeRatio'),
                tween: Tween<double>(begin: 0, end: safeRatio),
                duration: AdminMotion.medium,
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double progress, Widget? child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: DecoratedBox(decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(999))),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.texts, required this.metrics});

  final AdminPortalTexts texts;
  final AdminCompaniesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(texts.statusSummaryTitle, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark, fontSize: 18)),
          const SizedBox(height: 18),
          _SummaryRow(label: texts.totalLabel, value: metrics.total.toString()),
          _SummaryRow(label: texts.activeLabel, value: metrics.active.toString()),
          _SummaryRow(label: texts.inactiveLabel, value: metrics.inactive.toString()),
          _SummaryRow(label: texts.activePercent, value: _formatPercent(metrics.activePercent)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: const TextStyle(color: AdminPalette.mutedText, fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(color: AdminPalette.dark, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class AdminInfrastructureSection extends StatelessWidget {
  const AdminInfrastructureSection({super.key, required this.texts, required this.resumo});

  final AdminPortalTexts texts;
  final AdminPortalResumo resumo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
      child: AdminSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(texts.infrastructureTitle, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark, fontSize: 18)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 860;
                return Wrap(
                  spacing: AdminSpacing.md,
                  runSpacing: AdminSpacing.md,
                  children: <Widget>[
                    if (resumo.bancosDeDados.isNotEmpty)
                      SizedBox(width: compact ? constraints.maxWidth : (constraints.maxWidth - AdminSpacing.md) / 2, child: AdminDatabasePanel(texts: texts, bancos: resumo.bancosDeDados)),
                    if (resumo.actuator != null)
                      SizedBox(width: compact ? constraints.maxWidth : (constraints.maxWidth - AdminSpacing.md) / 2, child: AdminActuatorPanel(texts: texts, actuator: resumo.actuator!)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDatabasePanel extends StatelessWidget {
  const AdminDatabasePanel({super.key, required this.texts, required this.bancos});

  final AdminPortalTexts texts;
  final List<AdminBancoDadosResumo> bancos;

  @override
  Widget build(BuildContext context) {
    return _SubPanel(
      icon: Icons.storage_rounded,
      title: texts.databasesTitle,
      child: Column(
        children: bancos.map((AdminBancoDadosResumo banco) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(banco.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    AdminInfoPill(label: 'Dados', value: _formatBytes(banco.tamanhoDadosBytes)),
                    AdminInfoPill(label: 'Storage', value: _formatBytes(banco.tamanhoArmazenadoBytes)),
                    AdminInfoPill(label: 'Índices', value: _formatBytes(banco.tamanhoIndicesBytes)),
                    AdminInfoPill(label: 'Total', value: _formatBytes(banco.tamanhoTotalBytes)),
                  ],
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class AdminActuatorPanel extends StatelessWidget {
  const AdminActuatorPanel({super.key, required this.texts, required this.actuator});

  final AdminPortalTexts texts;
  final AdminActuatorResumo actuator;

  @override
  Widget build(BuildContext context) {
    final bool ok = actuator.status.toUpperCase() == 'UP';
    return _SubPanel(
      icon: Icons.monitor_heart_rounded,
      title: texts.actuatorTitle,
      trailing: AdminStatusBadge(status: actuator.status, ok: ok),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          AdminInfoPill(label: 'Uptime', value: _formatDuration(actuator.uptimeSegundos)),
          AdminInfoPill(label: 'Heap', value: '${_formatBytes(actuator.memoriaHeapUsadaBytes)} / ${_formatBytes(actuator.memoriaHeapMaxBytes)}'),
          AdminInfoPill(label: 'Threads', value: actuator.threadsAtivas.toString()),
          AdminInfoPill(label: 'CPU', value: actuator.processadoresDisponiveis.toString()),
          AdminInfoPill(label: 'Carga', value: _formatLoad(actuator.cargaSistema)),
          AdminInfoPill(label: 'Java', value: actuator.versaoJava),
        ],
      ),
    );
  }
}

class _SubPanel extends StatelessWidget {
  const _SubPanel({required this.icon, required this.title, required this.child, this.trailing});

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminPalette.softSurface,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: AdminPalette.dark, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.status, required this.ok});

  final String status;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final Color color = ok ? AdminPalette.success : AdminPalette.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class AdminInfoPill extends StatelessWidget {
  const AdminInfoPill({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w800, color: AdminPalette.dark, fontSize: 12)),
    );
  }
}

class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({super.key, required this.texts});

  final AdminPortalTexts texts;

  @override
  Widget build(BuildContext context) {
    return AdminStaggeredColumn(
      children: <Widget>[
        AdminDashboardHeader(texts: texts),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns = constraints.maxWidth >= 1140 ? 4 : (constraints.maxWidth >= 680 ? 2 : 1);
            final double width = (constraints.maxWidth - ((columns - 1) * AdminSpacing.md)) / columns;
            return Wrap(
              spacing: AdminSpacing.md,
              runSpacing: AdminSpacing.md,
              children: List<Widget>.generate(4, (int index) => SizedBox(width: width, child: const AdminSkeletonCard(height: 178))),
            );
          },
        ),
        const AdminSkeletonCard(height: 260),
      ],
    );
  }
}

class AdminErrorState extends StatelessWidget {
  const AdminErrorState({super.key, required this.texts, required this.message, required this.onRetry});

  final AdminPortalTexts texts;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: AdminPalette.danger, size: 42),
          const SizedBox(height: 12),
          Text(texts.errorTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AdminPalette.dark)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AdminPalette.bodyText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(texts.errorAction)),
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({super.key, required this.texts});

  final AdminPortalTexts texts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
      child: AdminSurfaceCard(
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: AdminPalette.activeGreen, borderRadius: BorderRadius.circular(AdminRadius.lg)),
              child: const Icon(Icons.apartment_rounded, color: AdminPalette.dark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(texts.emptyTitle, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(texts.emptySubtitle, style: const TextStyle(color: AdminPalette.mutedText, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminComingSoonCard extends StatelessWidget {
  const AdminComingSoonCard({super.key, required this.texts});

  final AdminPortalTexts texts;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      compact: true,
      child: Row(
        children: <Widget>[
          const Icon(Icons.construction_rounded, color: AdminPalette.dark),
          const SizedBox(width: 12),
          Expanded(child: Text(texts.comingSoon, style: const TextStyle(fontWeight: FontWeight.w700, color: AdminPalette.bodyText))),
        ],
      ),
    );
  }
}

class AdminSurfaceCard extends StatelessWidget {
  const AdminSurfaceCard({super.key, required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminPalette.border),
        boxShadow: <BoxShadow>[BoxShadow(color: AdminPalette.shadow.withOpacity(0.05), blurRadius: 22, offset: const Offset(0, 12))],
      ),
      child: Padding(padding: EdgeInsets.all(compact ? 16 : 22), child: child),
    );
  }
}

class AdminSkeletonCard extends StatefulWidget {
  const AdminSkeletonCard({super.key, required this.height});

  final double height;

  @override
  State<AdminSkeletonCard> createState() => _AdminSkeletonCardState();
}

class _AdminSkeletonCardState extends State<AdminSkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double opacity = 0.45 + (_controller.value * 0.20);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(AdminRadius.xl),
            border: Border.all(color: AdminPalette.border),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SkeletonLine(width: 92),
                SizedBox(height: 18),
                _SkeletonLine(width: 150, height: 26),
                Spacer(),
                _SkeletonLine(width: double.infinity),
                SizedBox(height: 8),
                _SkeletonLine(width: 180),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, this.height = 12});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AdminPalette.skeleton, borderRadius: BorderRadius.circular(999)),
    );
  }
}

class AdminStaggeredColumn extends StatelessWidget {
  const AdminStaggeredColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(children.length, (int index) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 220 + (index * 36)),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double value, Widget? child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child),
            );
          },
          child: children[index],
        );
      }),
    );
  }
}

class AdminPalette {
  const AdminPalette._();

  static const Color background = Color(0xFFF6F7F4);
  static const Color dark = Color(0xFF16231C);
  static const Color bodyText = Color(0xFF334155);
  static const Color mutedText = Color(0xFF6B756E);
  static const Color border = Color(0xFFE5E9E2);
  static const Color softSurface = Color(0xFFF2F5EF);
  static const Color activeGreen = Color(0xFFE8F2E4);
  static const Color hover = Color(0xFFF3F6F0);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEAB308);
  static const Color danger = Color(0xFFDC2626);
  static const Color skeleton = Color(0xFFE5E9E2);
  static const Color shadow = Color(0xFF0F172A);
}

class AdminSpacing {
  const AdminSpacing._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AdminRadius {
  const AdminRadius._();

  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

class AdminMotion {
  const AdminMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration number = Duration(milliseconds: 520);
}

String _formatInteger(double value) => value.round().toString();
String _formatPercent(double value) => '${value.toStringAsFixed(value >= 10 ? 0 : 1)}%';

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value = value / 1024;
    unit++;
  }
  final String text = value >= 10 || unit == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0s';
  final int days = seconds ~/ 86400;
  final int hours = (seconds % 86400) ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

String _formatLoad(double value) {
  if (value < 0) return '-';
  return value.toStringAsFixed(2);
}

String _firstNotEmpty(String? primary, String fallback) {
  final String normalized = primary?.trim() ?? '';
  return normalized.isEmpty ? fallback : normalized;
}

String _initials(String value) {
  final List<String> parts = value.trim().split(RegExp(r'\s+')).where((String item) => item.isNotEmpty).toList();
  if (parts.isEmpty) return 'S';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}
