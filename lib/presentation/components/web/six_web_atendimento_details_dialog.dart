import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

class SixWebAtendimentoDetailsMetric {
  const SixWebAtendimentoDetailsMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasisColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? emphasisColor;
}

Future<void> showSixWebAtendimentoDetailsDialog({
  required BuildContext context,
  required String equipmentTitle,
  required String attendanceNumber,
  required String customerLabel,
  required String technicianLabel,
  required Color accentColor,
  required IconData accentIcon,
  required List<SixWebAtendimentoDetailsMetric> summaryMetrics,
  required List<Widget> statusChips,
  required Widget actionContent,
  required Widget progressContent,
  required Widget detailsContent,
}) {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: context.t(
      'atendimentoTecnico.lista.detailsDialog.barrierLabel',
      fallback: 'Fechar detalhes do atendimento',
    ),
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _AtendimentoDetailsRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: SixWebAtendimentoDetailsDialog(
          equipmentTitle: equipmentTitle,
          attendanceNumber: attendanceNumber,
          customerLabel: customerLabel,
          technicianLabel: technicianLabel,
          accentColor: accentColor,
          accentIcon: accentIcon,
          summaryMetrics: summaryMetrics,
          statusChips: statusChips,
          actionContent: actionContent,
          progressContent: progressContent,
          detailsContent: detailsContent,
        ),
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => child,
  );
}

class SixWebAtendimentoDetailsDialog extends StatefulWidget {
  const SixWebAtendimentoDetailsDialog({
    super.key,
    required this.equipmentTitle,
    required this.attendanceNumber,
    required this.customerLabel,
    required this.technicianLabel,
    required this.accentColor,
    required this.accentIcon,
    required this.summaryMetrics,
    required this.statusChips,
    required this.actionContent,
    required this.progressContent,
    required this.detailsContent,
  });

  final String equipmentTitle;
  final String attendanceNumber;
  final String customerLabel;
  final String technicianLabel;
  final Color accentColor;
  final IconData accentIcon;
  final List<SixWebAtendimentoDetailsMetric> summaryMetrics;
  final List<Widget> statusChips;
  final Widget actionContent;
  final Widget progressContent;
  final Widget detailsContent;

  @override
  State<SixWebAtendimentoDetailsDialog> createState() =>
      _SixWebAtendimentoDetailsDialogState();
}

class _SixWebAtendimentoDetailsDialogState
    extends State<SixWebAtendimentoDetailsDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  final ScrollController _scrollController = ScrollController();

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _iconController.value = 1;
      } else {
        _iconController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Size size = MediaQuery.sizeOf(context);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (DismissIntent intent) {
              _close();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: PopScope(
            canPop: true,
            child: Semantics(
              namesRoute: true,
              label: context.t(
                'atendimentoTecnico.lista.detailsDialog.title',
                fallback: 'Detalhes do atendimento',
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1140,
                  maxHeight: size.height * 0.92,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.34),
                        blurRadius: 42,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: tokens.surfaceElevated,
                      surfaceTintColor: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  widget.accentColor.withValues(alpha: 0.84),
                                  widget.accentColor,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 24, 20, 18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _AnimatedDetailIcon(
                                  animation: _iconController,
                                  accentColor: widget.accentColor,
                                  surfaceColor: tokens.surfaceElevated,
                                  icon: widget.accentIcon,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        context.t(
                                          'atendimentoTecnico.lista.detailsDialog.title',
                                          fallback: 'Detalhes do atendimento',
                                        ),
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: tokens.primaryText,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.t(
                                          'atendimentoTecnico.lista.detailsDialog.subtitle',
                                          fallback:
                                              'Revise financeiro, andamento e histórico completos antes de seguir para outra ação.',
                                        ),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: tokens.secondaryText,
                                              height: 1.45,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: tokens.surfaceMuted,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: tokens.cardBorder,
                                    ),
                                  ),
                                  child: IconButton(
                                    tooltip: context.t(
                                      'common.close',
                                      fallback: 'Fechar',
                                    ),
                                    onPressed: _close,
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: tokens.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  0,
                                  28,
                                  28,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    _buildSubjectCard(theme, tokens),
                                    const SizedBox(height: 18),
                                    _buildMetrics(theme, tokens),
                                    if (widget
                                        .statusChips
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 18),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: widget.statusChips,
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    widget.actionContent,
                                    const SizedBox(height: 18),
                                    widget.progressContent,
                                    const SizedBox(height: 18),
                                    widget.detailsContent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.equipmentTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _subjectPill(
                context,
                icon: Icons.confirmation_number_outlined,
                label: widget.attendanceNumber,
              ),
              _subjectPill(
                context,
                icon: Icons.person_outline_rounded,
                label: widget.customerLabel,
              ),
              _subjectPill(
                context,
                icon: Icons.engineering_outlined,
                label: widget.technicianLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(ThemeData theme, WebThemeTokens tokens) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 920;
        final double width =
            compact
                ? constraints.maxWidth
                : ((constraints.maxWidth - 24) / 3).clamp(
                  220.0,
                  constraints.maxWidth,
                );
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.summaryMetrics
              .map((SixWebAtendimentoDetailsMetric metric) {
                return SizedBox(
                  width: width,
                  child: _MetricCard(metric: metric, tokens: tokens),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.tokens});

  final SixWebAtendimentoDetailsMetric metric;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = metric.emphasisColor ?? tokens.info;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(metric.icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: metric.emphasisColor ?? tokens.primaryText,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDetailIcon extends StatelessWidget {
  const _AnimatedDetailIcon({
    required this.animation,
    required this.accentColor,
    required this.surfaceColor,
    required this.icon,
  });

  final Animation<double> animation;
  final Color accentColor;
  final Color surfaceColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double progress = animation.value;
        final double ringScale = 0.84 + (0.16 * progress);
        final double iconScale = 0.92 + (0.08 * progress);
        return SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        accentColor.withValues(alpha: 0.24 * progress),
                        accentColor.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: iconScale,
                    child: Icon(icon, color: accentColor, size: 26),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: 0.9 + (0.1 * progress),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.18 * progress),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.46),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _subjectPill(
  BuildContext context, {
  required IconData icon,
  required String label,
}) {
  final ThemeData theme = Theme.of(context);
  final WebThemeTokens tokens = WebThemeTokens.of(context);
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 300),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: tokens.secondaryText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AtendimentoDetailsRouteSurface extends StatelessWidget {
  const _AtendimentoDetailsRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: curvedAnimation,
        child: child,
        builder: (BuildContext context, Widget? dialogChild) {
          final double progress = reduceMotion ? 1 : curvedAnimation.value;
          final Color overlayColor =
              Color.lerp(
                Colors.transparent,
                const Color(0xC40B1324),
                progress,
              )!;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: reduceMotion ? 0 : 12 * progress,
                        sigmaY: reduceMotion ? 0 : 12 * progress,
                      ),
                      child: ColoredBox(color: overlayColor),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, (1 - progress) * 24),
                        child: Transform.scale(
                          scale: 0.965 + (0.035 * progress),
                          child: dialogChild,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
