import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/navigation/web_navigation_destination_resolver.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/navigation/web_sidebar_navigation.dart';

import 'web_header.dart';

class AuthenticatedWebShell extends StatefulWidget {
  const AuthenticatedWebShell({
    super.key,
    required this.navigationItems,
    required this.resolver,
    required this.activeDestination,
    required this.child,
    required this.appVersion,
    this.currentCommerceName,
    this.headerActions = const <Widget>[],
  });

  final List<WebNavigationItem> navigationItems;
  final WebNavigationDestinationResolver resolver;
  final WebNavigationDestination? activeDestination;
  final Widget child;
  final String appVersion;
  final String? currentCommerceName;
  final List<Widget> headerActions;

  @override
  State<AuthenticatedWebShell> createState() => _AuthenticatedWebShellState();
}

class _AuthenticatedWebShellState extends State<AuthenticatedWebShell> {
  static const double _compactSidebarBreakpoint = 1024;

  bool _sidebarExpanded = true;
  late Set<String> _expandedGroupIds;

  @override
  void initState() {
    super.initState();
    _expandedGroupIds = _groupIdsForDestination(widget.activeDestination);
  }

  @override
  void didUpdateWidget(covariant AuthenticatedWebShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeDestination != widget.activeDestination) {
      _expandedGroupIds = <String>{
        ..._expandedGroupIds,
        ..._groupIdsForDestination(widget.activeDestination),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String activeTitle = _activeTitle(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool forceCollapsed =
            constraints.maxWidth <= _compactSidebarBreakpoint;
        final bool expanded = _sidebarExpanded && !forceCollapsed;
        final double sidebarWidth =
            expanded
                ? WebSidebarNavigation.expandedWidth
                : WebSidebarNavigation.collapsedWidth;

        return DecoratedBox(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerLowest),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: sidebarWidth,
                child: WebSidebarNavigation(
                  items: widget.navigationItems,
                  activeDestination: widget.activeDestination,
                  expanded: expanded,
                  expandedGroupIds: _expandedGroupIds,
                  onToggleGroup: _toggleGroup,
                  onDestinationSelected: _resolveDestination,
                  appVersion: widget.appVersion,
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    WebHeader(
                      title: activeTitle,
                      sidebarExpanded: expanded,
                      onToggleSidebar: _toggleSidebar,
                      currentCommerceName: widget.currentCommerceName,
                      actions: widget.headerActions,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarExpanded = !_sidebarExpanded;
    });
  }

  void _toggleGroup(String id) {
    setState(() {
      if (!_expandedGroupIds.remove(id)) {
        _expandedGroupIds.add(id);
      }
    });
  }

  void _resolveDestination(WebNavigationDestination destination) {
    final WebNavigationResolutionResult result = widget.resolver.resolve(
      destination,
    );

    if (result.handled || !mounted) {
      return;
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          _shellText(
            context,
            'web.navigation.unavailable',
            'Destino indisponível nesta versão.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _activeTitle(BuildContext context) {
    final WebNavigationItem? activeItem = _findItemByDestination(
      widget.activeDestination,
    );
    if (activeItem == null) {
      return _shellText(
        context,
        'web.shell.workspace',
        'Workspace operacional',
      );
    }

    return _shellText(context, activeItem.labelKey, activeItem.labelFallback);
  }

  WebNavigationItem? _findItemByDestination(
    WebNavigationDestination? destination,
  ) {
    if (destination == null) return null;

    for (final WebNavigationItem item in _flattenNavigationItems()) {
      if (item.destination == destination) {
        return item;
      }
    }

    return null;
  }

  Set<String> _groupIdsForDestination(WebNavigationDestination? destination) {
    if (destination == null) return <String>{};

    return <String>{
      for (final WebNavigationItem item in widget.navigationItems)
        if (item.children.isNotEmpty && _containsDestination(item, destination))
          item.id,
    };
  }

  Iterable<WebNavigationItem> _flattenNavigationItems() sync* {
    for (final WebNavigationItem item in widget.navigationItems) {
      yield* item.flatten();
    }
  }

  bool _containsDestination(
    WebNavigationItem item,
    WebNavigationDestination destination,
  ) {
    if (item.destination == destination) return true;
    return item.children.any(
      (WebNavigationItem child) => _containsDestination(child, destination),
    );
  }
}

String _shellText(BuildContext context, String key, String fallback) {
  final String resolved = context.t(key);
  return resolved == key ? fallback : resolved;
}
