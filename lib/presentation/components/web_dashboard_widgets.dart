import 'package:flutter/material.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

typedef SixWebMetricFormatter = String Function(double value);

class SixWebDashboardHeader extends StatelessWidget {
  const SixWebDashboardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.onBack,
    this.backgroundImageUrl,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final String? backgroundImageUrl;

  bool get _hasBackgroundImage =>
      backgroundImageUrl != null && backgroundImageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    if (!_hasBackgroundImage) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          border: Border(bottom: BorderSide(color: tokens.cardBorder)),
        ),
        child: _content(context, theme, tokens),
      );
    }

    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.network(
            backgroundImageUrl!,
            fit: BoxFit.cover,
            alignment: const Alignment(0.18, -0.52),
            filterQuality: FilterQuality.high,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              debugPrint(
                '[SixWebDashboardHeader] falha ao carregar imagem '
                'url=$backgroundImageUrl error=$error',
              );
              return ColoredBox(color: tokens.surfaceMuted);
            },
            loadingBuilder: (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              return loadingProgress == null
                  ? child
                  : ColoredBox(color: tokens.surfaceMuted);
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const <double>[0, 0.36, 0.67, 0.86, 1],
                colors: <Color>[
                  tokens.surfaceMuted.withValues(alpha: isDark ? 0.98 : 0.96),
                  tokens.surfaceMuted.withValues(alpha: isDark ? 0.92 : 0.87),
                  tokens.surfaceMuted.withValues(alpha: isDark ? 0.32 : 0.20),
                  tokens.surfaceMuted.withValues(alpha: isDark ? 0.18 : 0.12),
                  tokens.surfaceMuted.withValues(alpha: isDark ? 0.92 : 0.86),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: _content(context, theme, tokens, contextual: true),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ThemeData theme,
    WebThemeTokens tokens, {
    bool contextual = false,
  }) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color titleColor =
        contextual
            ? (isDark ? Colors.white : tokens.primaryText)
            : tokens.primaryText;
    final Color subtitleColor =
        contextual
            ? (isDark
                ? Colors.white.withValues(alpha: 0.84)
                : tokens.secondaryText)
            : tokens.secondaryText;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 780;
        final Widget leading = Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color:
                contextual
                    ? (isDark
                        ? Colors.black.withValues(alpha: 0.24)
                        : Colors.white.withValues(alpha: 0.72))
                    : tokens.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border:
                contextual
                    ? Border.all(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : tokens.cardBorder,
                    )
                    : null,
          ),
          child: Icon(
            icon,
            color:
                contextual
                    ? (isDark ? Colors.white : tokens.info)
                    : tokens.info,
            size: 28,
          ),
        );

        final Widget texts = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
                shadows:
                    contextual
                        ? const <Shadow>[
                          Shadow(color: Color(0x99000000), blurRadius: 10),
                        ]
                        : const <Shadow>[],
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subtitleColor,
                  height: 1.35,
                  fontWeight: contextual ? FontWeight.w600 : null,
                  shadows:
                      contextual
                          ? const <Shadow>[
                            Shadow(color: Color(0x8A000000), blurRadius: 8),
                          ]
                          : const <Shadow>[],
                ),
              ),
            ),
          ],
        );

        final Widget actionWrap = Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ...actions,
            if (onBack != null)
              IconButton.filledTonal(
                tooltip: 'Fechar',
                onPressed: onBack,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  leading,
                  const SizedBox(width: 16),
                  Expanded(child: texts),
                ],
              ),
              if (actions.isNotEmpty || onBack != null) ...<Widget>[
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerRight, child: actionWrap),
              ],
            ],
          );
        }

        return Row(
          children: <Widget>[
            leading,
            const SizedBox(width: 16),
            Expanded(child: texts),
            const SizedBox(width: 20),
            Flexible(child: actionWrap),
          ],
        );
      },
    );
  }
}

class SixWebEntry extends StatelessWidget {
  const SixWebEntry({
    super.key,
    required this.child,
    this.order = 0,
    this.duration = const Duration(milliseconds: 520),
  });

  final Widget child;
  final num order;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration:
          duration + Duration(milliseconds: (order * 30).clamp(0, 300).toInt()),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class SixWebKpiCard extends StatelessWidget {
  const SixWebKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.formatter,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final double value;
  final SixWebMetricFormatter formatter;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color background =
        highlight ? tokens.surfaceElevated : tokens.cardBackground;
    final Color foreground = tokens.primaryText;
    final Color muted = tokens.secondaryText;
    final Color accent = tokens.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlight ? tokens.selectedBorder : tokens.cardBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: highlight ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>('$label:${value.toStringAsFixed(4)}'),
                  tween: Tween<double>(begin: 0, end: value),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (
                    BuildContext context,
                    double currentValue,
                    Widget? child,
                  ) {
                    return Text(
                      formatter(currentValue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SixWebSectionCard extends StatelessWidget {
  const SixWebSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: tokens.info),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class SixWebNoData extends StatelessWidget {
  const SixWebNoData({
    super.key,
    this.text = 'Sem dados suficientes para exibir esta informação.',
    this.height = 180,
  });

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: tokens.secondaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SixWebLoadingBlock extends StatelessWidget {
  const SixWebLoadingBlock({
    super.key,
    required this.height,
    this.highlight = false,
  });

  final double height;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: highlight ? tokens.surfaceElevated : tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlight ? tokens.selectedBorder : tokens.cardBorder,
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color:
                  highlight
                      ? accent.withValues(alpha: 0.20)
                      : tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> sixWebResponsiveChildren({
  required bool compact,
  required List<Widget> children,
}) {
  final List<Widget> spaced = <Widget>[];
  for (int index = 0; index < children.length; index++) {
    if (index > 0) {
      spaced.add(SizedBox(width: compact ? 0 : 18, height: compact ? 18 : 0));
    }
    spaced.add(compact ? children[index] : Expanded(child: children[index]));
  }
  return spaced;
}

Widget sixWebResponsiveGroup({
  required bool compact,
  required List<Widget> children,
}) {
  if (compact) {
    return Column(
      children: sixWebResponsiveChildren(compact: true, children: children),
    );
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: sixWebResponsiveChildren(compact: false, children: children),
  );
}
