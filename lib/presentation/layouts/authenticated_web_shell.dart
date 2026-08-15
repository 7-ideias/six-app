import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/navigation/web_navigation_destination_resolver.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/navigation/web_sidebar_navigation.dart';
import 'package:sixpos/presentation/screens/etiquetas_web_page.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

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
  WebNavigationDestination? _shellManagedDestination;

  @override
  void initState() {
    super.initState();
    _expandedGroupIds = _groupIdsForDestination(widget.activeDestination);
  }

  @override
  void didUpdateWidget(covariant AuthenticatedWebShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeDestination != widget.activeDestination) {
      _shellManagedDestination = null;
      _expandedGroupIds = <String>{
        ..._expandedGroupIds,
        ..._groupIdsForDestination(widget.activeDestination),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeData webTheme = WebThemeTokens.applyTo(theme);
    final WebThemeTokens tokens = WebThemeTokens.resolve(theme);
    final WebNavigationDestination? effectiveDestination =
        _shellManagedDestination ?? widget.activeDestination;
    final String activeTitle = _activeTitle(context, effectiveDestination);
    final Widget effectiveChild =
        effectiveDestination == WebNavigationDestination.catalogLabels
            ? const EtiquetasWebPage()
            : widget.child;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool forceCollapsed =
            constraints.maxWidth <= _compactSidebarBreakpoint;
        final bool expanded = _sidebarExpanded && !forceCollapsed;
        final double sidebarWidth = expanded
            ? WebSidebarNavigation.expandedWidth
            : WebSidebarNavigation.collapsedWidth;

        return AnimatedContainer(
          key: const Key('web-shell-workspace'),
          duration: WebThemeTokens.transitionDuration,
          curve: WebThemeTokens.transitionCurve,
          decoration: BoxDecoration(color: tokens.workspaceBackground),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: sidebarWidth,
                child: AnimatedTheme(
                  data: webTheme,
                  duration: WebThemeTokens.transitionDuration,
                  curve: WebThemeTokens.transitionCurve,
                  child: WebSidebarNavigation(
                    items: widget.navigationItems,
                    activeDestination: effectiveDestination,
                    expanded: expanded,
                    expandedGroupIds: _expandedGroupIds,
                    onToggleGroup: _toggleGroup,
                    onDestinationSelected: _resolveDestination,
                    appVersion: widget.appVersion,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    AnimatedTheme(
                      data: webTheme,
                      duration: WebThemeTokens.transitionDuration,
                      curve: WebThemeTokens.transitionCurve,
                      child: WebHeader(
                        title: activeTitle,
                        sidebarExpanded: expanded,
                        onToggleSidebar: _toggleSidebar,
                        currentCommerceName: widget.currentCommerceName,
                        actions: widget.headerActions,
                      ),
                    ),
                    Expanded(child: effectiveChild),
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
    setState(() => _sidebarExpanded = !_sidebarExpanded);
  }

  void _toggleGroup(String id) {
    setState(() {
      if (!_expandedGroupIds.remove(id)) _expandedGroupIds.add(id);
    });
  }

  void _resolveDestination(WebNavigationDestination destination) {
    if (destination == WebNavigationDestination.catalogLabels) {
      setState(() {
        _shellManagedDestination = destination;
        _expandedGroupIds.add('catalog');
      });
      return;
    }

    if (_shellManagedDestination != null) {
      setState(() => _shellManagedDestination = null);
    }
    final WebNavigationResolutionResult result = widget.resolver.resolve(destination);
    if (result.handled || !mounted) return;

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
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

  String _activeTitle(
    BuildContext context,
    WebNavigationDestination? destination,
  ) {
    final WebNavigationItem? activeItem = _findItemByDestination(destination);
    if (activeItem == null) {
      return _shellText(context, 'web.shell.workspace', 'Workspace operacional');
    }
    if (destination == WebNavigationDestination.catalogLabels) {
      final String language = Localizations.localeOf(context).languageCode;
      final String fallback = switch (language) {
        'en' => 'Labels',
        'es' => 'Etiquetas',
        _ => 'Etiquetas',
      };
      return _shellText(context, activeItem.labelKey, fallback);
    }
    return _shellText(context, activeItem.labelKey, activeItem.labelFallback);
  }

  WebNavigationItem? _findItemByDestination(
    WebNavigationDestination? destination,
  ) {
    if (destination == null) return null;
    for (final WebNavigationItem item in _flattenNavigationItems()) {
      if (item.destination == destination) return item;
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
    for (final WebNavigationItem item in widget.navigationItems) yield* item.flatten();
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
