import 'package:flutter/material.dart';

typedef SixWebMetricFormatter = String Function(double value);

class SixWebDashboardHeader extends StatelessWidget {
  const SixWebDashboardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.onBack,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ...actions,
              if (onBack != null)
                IconButton.filledTonal(
                  onPressed: onBack,
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SixWebEntry extends StatelessWidget {
  const SixWebEntry({
    super.key,
    required this.child,
    this.order = 0,
    this.duration = const Duration(milliseconds: 680),
  });

  final Widget child;
  final num order;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      // Cada ordem adiciona 60ms de atraso ao início (máx 480ms extra),
      // criando uma cascata top-down visível entre blocos.
      duration: duration + Duration(milliseconds: (order * 60).clamp(0, 480).toInt()),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
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
    final ThemeData theme = Theme.of(context);
    final Color background = highlight ? theme.colorScheme.primary : theme.colorScheme.surface;
    final Color foreground = highlight ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final Color muted = highlight ? theme.colorScheme.onPrimary.withOpacity(0.80) : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: highlight ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: highlight ? theme.colorScheme.onPrimary.withOpacity(0.14) : theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: highlight ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
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
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>('$label:${value.toStringAsFixed(4)}'),
                  tween: Tween<double>(begin: 0, end: value),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double currentValue, Widget? child) {
                    return Text(
                      formatter(currentValue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: foreground, fontWeight: FontWeight.w900, fontSize: 22),
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
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
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
  const SixWebNoData({super.key, this.text = 'Sem dados suficientes para exibir esta informação.', this.height = 180});

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SixWebLoadingBlock extends StatelessWidget {
  const SixWebLoadingBlock({super.key, required this.height, this.highlight = false});

  final double height;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: highlight ? theme.colorScheme.primary.withOpacity(0.92) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: highlight ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color: highlight ? theme.colorScheme.onPrimary.withOpacity(0.20) : theme.colorScheme.surfaceVariant.withOpacity(0.80),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> sixWebResponsiveChildren({required bool compact, required List<Widget> children}) {
  final List<Widget> spaced = <Widget>[];
  for (int index = 0; index < children.length; index++) {
    if (index > 0) {
      spaced.add(SizedBox(width: compact ? 0 : 18, height: compact ? 18 : 0));
    }
    spaced.add(compact ? children[index] : Expanded(child: children[index]));
  }
  return spaced;
}

Widget sixWebResponsiveGroup({required bool compact, required List<Widget> children}) {
  if (compact) {
    return Column(children: sixWebResponsiveChildren(compact: true, children: children));
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: sixWebResponsiveChildren(compact: false, children: children),
  );
}
