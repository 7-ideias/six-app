import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

class WebHeader extends StatelessWidget {
  const WebHeader({
    super.key,
    required this.title,
    required this.sidebarExpanded,
    required this.onToggleSidebar,
    this.currentCommerceName,
    this.actions = const <Widget>[],
  });

  final String title;
  final bool sidebarExpanded;
  final VoidCallback onToggleSidebar;
  final String? currentCommerceName;
  final List<Widget> actions;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return AnimatedContainer(
      key: const Key('web-header-container'),
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.headerBackground,
        border: Border(bottom: BorderSide(color: tokens.headerBorder)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 900;

          return Row(
            children: <Widget>[
              IconButton(
                style: IconButton.styleFrom(
                  foregroundColor: tokens.secondaryText,
                  hoverColor: tokens.hoverBackground,
                  focusColor: tokens.hoverBackground,
                  highlightColor: tokens.selectedBackground,
                ),
                tooltip: _headerText(
                  context,
                  sidebarExpanded
                      ? 'web.shell.collapseSidebar'
                      : 'web.shell.expandSidebar',
                  sidebarExpanded ? 'Recolher navegação' : 'Expandir navegação',
                ),
                onPressed: onToggleSidebar,
                icon: Icon(
                  sidebarExpanded
                      ? Icons.menu_open_rounded
                      : Icons.menu_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...<Widget>[
                const SizedBox(width: 16),
                _CommerceContextPill(currentCommerceName: currentCommerceName),
              ],
              if (actions.isNotEmpty) ...<Widget>[
                const SizedBox(width: 12),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (int index = 0; index < actions.length; index++)
                          Padding(
                            padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                            child: actions[index],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CommerceContextPill extends StatelessWidget {
  const _CommerceContextPill({this.currentCommerceName});

  final String? currentCommerceName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String commerceName = currentCommerceName?.trim() ?? '';
    final String value =
        commerceName.isEmpty
            ? _headerText(
              context,
              'web.shell.sessionContext',
              'Contexto da sessão',
            )
            : commerceName;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.storefront_outlined,
            size: 16,
            color: tokens.secondaryText,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _headerText(
                    context,
                    'web.shell.currentCommerce',
                    'Comércio atual',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
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

String _headerText(BuildContext context, String key, String fallback) {
  final String resolved = context.t(key);
  return resolved == key ? fallback : resolved;
}
