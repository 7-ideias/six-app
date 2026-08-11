import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';

import 'web_navigation_item.dart';
import 'web_navigation_registry.dart';

class WebSidebarNavigation extends StatelessWidget {
  const WebSidebarNavigation({
    super.key,
    required this.items,
    required this.activeDestination,
    required this.expanded,
    required this.expandedGroupIds,
    required this.onToggleGroup,
    required this.onDestinationSelected,
    required this.appVersion,
  });

  final List<WebNavigationItem> items;
  final WebNavigationDestination? activeDestination;
  final bool expanded;
  final Set<String> expandedGroupIds;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<WebNavigationDestination> onDestinationSelected;
  final String appVersion;

  static const double expandedWidth = 248;
  static const double collapsedWidth = 72;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<WebNavigationItem> mainItems = _mainNavigationItems(items);
    final WebNavigationItem? settingsItem = _settingsNavigationItem(items);

    return Material(
      color: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _SidebarBrand(expanded: expanded),
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('web-sidebar-main-scroll'),
                  padding: EdgeInsets.fromLTRB(10, expanded ? 8 : 6, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final WebNavigationItem item
                          in mainItems) ...<Widget>[
                        _SidebarItem(
                          item: item,
                          activeDestination: activeDestination,
                          expanded: expanded,
                          expandedGroupIds: expandedGroupIds,
                          onToggleGroup: onToggleGroup,
                          onDestinationSelected: onDestinationSelected,
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ),
              _SidebarFooter(
                settingsItem: settingsItem,
                activeDestination: activeDestination,
                expanded: expanded,
                expandedGroupIds: expandedGroupIds,
                onToggleGroup: onToggleGroup,
                onDestinationSelected: onDestinationSelected,
                appVersion: appVersion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.settingsItem,
    required this.activeDestination,
    required this.expanded,
    required this.expandedGroupIds,
    required this.onToggleGroup,
    required this.onDestinationSelected,
    required this.appVersion,
  });

  final WebNavigationItem? settingsItem;
  final WebNavigationDestination? activeDestination;
  final bool expanded;
  final Set<String> expandedGroupIds;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<WebNavigationDestination> onDestinationSelected;
  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final WebNavigationItem? item = settingsItem;

    return Padding(
      key: const Key('web-sidebar-footer'),
      padding: EdgeInsets.fromLTRB(10, expanded ? 2 : 4, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Divider(height: 14, color: colorScheme.outlineVariant),
          if (item != null) ...<Widget>[
            _SidebarItem(
              item: item,
              activeDestination: activeDestination,
              expanded: expanded,
              expandedGroupIds: expandedGroupIds,
              onToggleGroup: onToggleGroup,
              onDestinationSelected: onDestinationSelected,
            ),
            const SizedBox(height: 8),
          ],
          _SidebarVersionPill(expanded: expanded, appVersion: appVersion),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment:
              expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                'S',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (expanded) ...<Widget>[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _navigationText(context, 'app.title', 'SixApp'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.activeDestination,
    required this.expanded,
    required this.expandedGroupIds,
    required this.onToggleGroup,
    required this.onDestinationSelected,
  });

  final WebNavigationItem item;
  final WebNavigationDestination? activeDestination;
  final bool expanded;
  final Set<String> expandedGroupIds;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<WebNavigationDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return _CollapsedSidebarItem(
        item: item,
        activeDestination: activeDestination,
        onDestinationSelected: onDestinationSelected,
      );
    }

    final bool active = _containsActiveDestination(item, activeDestination);
    final bool groupExpanded = active || expandedGroupIds.contains(item.id);
    final String label = _navigationLabel(context, item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SidebarTile(
          icon: item.icon,
          label: label,
          active: active && !item.hasChildren,
          groupActive: active && item.hasChildren,
          trailing:
              item.hasChildren
                  ? AnimatedRotation(
                    turns: groupExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(Icons.expand_more_rounded, size: 18),
                  )
                  : null,
          onTap: () {
            if (item.hasChildren) {
              onToggleGroup(item.id);
              return;
            }

            final WebNavigationDestination? destination = item.destination;
            if (destination != null) {
              onDestinationSelected(destination);
            }
          },
        ),
        if (item.hasChildren)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child:
                groupExpanded
                    ? Padding(
                      key: ValueKey<String>('${item.id}.expanded'),
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          for (final WebNavigationItem child in item.children)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _SidebarChildTile(
                                item: child,
                                active: _containsActiveDestination(
                                  child,
                                  activeDestination,
                                ),
                                onDestinationSelected: onDestinationSelected,
                              ),
                            ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(key: ValueKey<String>('collapsed')),
          ),
      ],
    );
  }
}

class _CollapsedSidebarItem extends StatelessWidget {
  const _CollapsedSidebarItem({
    required this.item,
    required this.activeDestination,
    required this.onDestinationSelected,
  });

  final WebNavigationItem item;
  final WebNavigationDestination? activeDestination;
  final ValueChanged<WebNavigationDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bool active = _containsActiveDestination(item, activeDestination);
    final String label = _navigationLabel(context, item);

    return Builder(
      builder:
          (BuildContext tileContext) => Tooltip(
            message: label,
            waitDuration: const Duration(milliseconds: 350),
            child: _SidebarIconButton(
              icon: item.icon,
              active: active,
              onTap: () {
                if (item.hasChildren) {
                  _showChildrenMenu(tileContext);
                  return;
                }

                final WebNavigationDestination? destination = item.destination;
                if (destination != null) {
                  onDestinationSelected(destination);
                }
              },
            ),
          ),
    );
  }

  Future<void> _showChildrenMenu(BuildContext context) async {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;
    final RenderObject? overlayObject =
        Navigator.of(context).overlay?.context.findRenderObject();
    if (overlayObject is! RenderBox) return;

    final Offset offset = renderObject.localToGlobal(Offset.zero);
    final Size size = renderObject.size;
    final WebNavigationItem? selected = await showMenu<WebNavigationItem>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(offset.dx + size.width + 6, offset.dy, 1, size.height),
        Offset.zero & overlayObject.size,
      ),
      items: <PopupMenuEntry<WebNavigationItem>>[
        for (final WebNavigationItem child in item.children)
          PopupMenuItem<WebNavigationItem>(
            value: child,
            child: _CollapsedChildMenuEntry(
              item: child,
              active: _containsActiveDestination(child, activeDestination),
            ),
          ),
      ],
    );

    final WebNavigationDestination? destination = selected?.destination;
    if (destination != null) {
      onDestinationSelected(destination);
    }
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.groupActive,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool groupActive;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool highlighted = active || groupActive;
    final Color foreground =
        highlighted ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color:
                active
                    ? colorScheme.primary.withValues(alpha: 0.10)
                    : groupActive
                    ? colorScheme.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  active
                      ? colorScheme.primary.withValues(alpha: 0.28)
                      : Colors.transparent,
            ),
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 3,
                height: active ? 24 : 0,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 9),
              Icon(icon, size: 19, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color:
                        highlighted
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                    fontWeight: highlighted ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 6),
                IconTheme(
                  data: IconThemeData(color: foreground),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarChildTile extends StatelessWidget {
  const _SidebarChildTile({
    required this.item,
    required this.active,
    required this.onDestinationSelected,
  });

  final WebNavigationItem item;
  final bool active;
  final ValueChanged<WebNavigationDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return _SidebarTile(
      icon: item.icon,
      label: _navigationLabel(context, item),
      active: active,
      groupActive: false,
      onTap: () {
        final WebNavigationDestination? destination = item.destination;
        if (destination != null) {
          onDestinationSelected(destination);
        }
      },
    );
  }
}

class _SidebarIconButton extends StatelessWidget {
  const _SidebarIconButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 46,
          decoration: BoxDecoration(
            color:
                active
                    ? colorScheme.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  active
                      ? colorScheme.primary.withValues(alpha: 0.26)
                      : Colors.transparent,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 21,
                color:
                    active ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              Positioned(
                left: 4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 3,
                  height: active ? 24 : 0,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsedChildMenuEntry extends StatelessWidget {
  const _CollapsedChildMenuEntry({required this.item, required this.active});

  final WebNavigationItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(
          item.icon,
          size: 18,
          color: active ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _navigationLabel(context, item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: active ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarVersionPill extends StatelessWidget {
  const _SidebarVersionPill({required this.expanded, required this.appVersion});

  final bool expanded;
  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String label = _navigationText(
      context,
      'web.shell.version',
      'Versão',
    );
    final String versionText = 'v$appVersion';

    return Padding(
      padding: EdgeInsets.zero,
      child: Tooltip(
        message: '$label $versionText',
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 7,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child:
              expanded
                  ? Text(
                    '$label $versionText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                  : Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
        ),
      ),
    );
  }
}

String _navigationLabel(BuildContext context, WebNavigationItem item) {
  return _navigationText(context, item.labelKey, item.labelFallback);
}

String _navigationText(BuildContext context, String key, String fallback) {
  final String resolved = context.t(key);
  return resolved == key ? fallback : resolved;
}

List<WebNavigationItem> _mainNavigationItems(List<WebNavigationItem> items) {
  return <WebNavigationItem>[
    for (final WebNavigationItem item in items)
      if (item.id != WebNavigationIds.settings) item,
  ];
}

WebNavigationItem? _settingsNavigationItem(List<WebNavigationItem> items) {
  for (final WebNavigationItem item in items) {
    if (item.id == WebNavigationIds.settings) {
      return item;
    }
  }

  return null;
}

bool _containsActiveDestination(
  WebNavigationItem item,
  WebNavigationDestination? activeDestination,
) {
  if (activeDestination == null) return false;
  if (item.destination == activeDestination) return true;
  return item.children.any(
    (WebNavigationItem child) =>
        _containsActiveDestination(child, activeDestination),
  );
}
