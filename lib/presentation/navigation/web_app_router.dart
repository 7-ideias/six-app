import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'web_destination_routes.dart';
import 'web_navigation_item.dart';

class WebAppRouteParser extends RouteInformationParser<Uri> {
  const WebAppRouteParser();

  @override
  Future<Uri> parseRouteInformation(
    RouteInformation routeInformation,
  ) => SynchronousFuture(
    Uri(
      path: routeInformation.uri.path.isEmpty ? '/' : routeInformation.uri.path,
      query: routeInformation.uri.hasQuery ? routeInformation.uri.query : null,
      fragment:
          routeInformation.uri.hasFragment
              ? routeInformation.uri.fragment
              : null,
    ),
  );

  @override
  RouteInformation restoreRouteInformation(Uri configuration) =>
      RouteInformation(uri: configuration);
}

typedef WebShellRouteHandler = Future<void> Function(WebNavigationDestination);

/// Owns browser history while retaining the existing Navigator for dialogs,
/// checkout and other standalone screens. Module changes reuse the live shell.
class WebAppRouter extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  WebAppRouter({required this.navigatorKey, required this.routeFactory}) {
    _observer = _WebRouteObserver(this);
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey;
  final RouteFactory routeFactory;
  late final _WebRouteObserver _observer;
  final _routes = <Route<dynamic>>[];
  final _locations = <Route<dynamic>, Uri>{};
  final _shells = <Route<dynamic>, WebShellRouteHandler>{};
  Uri _location = Uri(path: '/app');
  String? _initialLocation;
  bool _restoring = false;
  bool _notificationScheduled = false;
  bool _disposed = false;

  static WebAppRouter? maybeOf(BuildContext context) {
    final delegate = Router.maybeOf(context)?.routerDelegate;
    return delegate is WebAppRouter ? delegate : null;
  }

  @override
  Uri get currentConfiguration => _location;

  void registerShell(Route<dynamic> route, WebShellRouteHandler handler) {
    _shells[route] = handler;
  }

  void unregisterShell(Route<dynamic> route) => _shells.remove(route);

  void reportDestination(
    Route<dynamic> route,
    WebNavigationDestination destination,
  ) {
    final path = webDestinationRoutes[destination];
    if (path == null || !route.isCurrent || _restoring) return;
    // Preserve query parameters when staying in the same module.
    if (_location.path == path) return;
    _locations[route] = Uri(path: path);
    _location = _locations[route]!;
    _scheduleNotification();
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    _location = configuration;
    if (_initialLocation == null) {
      _initialLocation = configuration.toString();
      return;
    }
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    _restoring = true;
    try {
      final destination = webDestinationForUri(configuration);
      final shellRoutes = _routes.where(_shells.containsKey).toList();
      if (destination != null && shellRoutes.isNotEmpty) {
        final shell = shellRoutes.last;
        // Dismiss dialogs/standalone pages before restoring the module.
        navigator.popUntil((route) => identical(route, shell));
        _locations[shell] = configuration;
        await _shells[shell]!(destination);
      } else {
        final matches =
            _routes
                .where((route) => _locations[route] == configuration)
                .toList();
        if (matches.isNotEmpty) {
          navigator.popUntil((route) => identical(route, matches.last));
        } else {
          if (shellRoutes.isNotEmpty &&
              configuration.path.startsWith('/app/')) {
            unawaited(navigator.pushNamed(configuration.toString()));
          } else {
            unawaited(
              navigator.pushNamedAndRemoveUntil(
                configuration.toString(),
                (_) => false,
              ),
            );
          }
        }
      }
    } finally {
      _restoring = false;
      _scheduleNotification();
    }
  }

  void _navigationChanged() {
    if (_restoring) return;
    // Unnamed routes are dialogs/local workflows, not shareable page URLs.
    for (final route in _routes.reversed) {
      final uri = _locations[route];
      if (uri != null) {
        if (_location != uri) {
          _location = uri;
          _scheduleNotification();
        }
        return;
      }
    }
  }

  void _scheduleNotification() {
    if (_notificationScheduled || _disposed) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (!_disposed) notifyListeners();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    initialRoute: _initialLocation ?? _location.toString(),
    onGenerateInitialRoutes:
        (_, initialRoute) => [routeFactory(RouteSettings(name: initialRoute))!],
    onGenerateRoute: routeFactory,
    observers: [_observer],
    // Router is the only owner of browser history.
    reportsRouteUpdateToEngine: false,
  );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _WebRouteObserver extends NavigatorObserver {
  _WebRouteObserver(this.router);
  final WebAppRouter router;

  void _remember(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.startsWith('/')) {
      router._locations[route] = Uri.parse(name);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    router._routes.add(route);
    _remember(route);
    router._navigationChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    router._routes.remove(route);
    router._locations.remove(route);
    router._shells.remove(route);
    router._navigationChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    router._routes.remove(route);
    router._locations.remove(route);
    router._shells.remove(route);
    router._navigationChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : router._routes.indexOf(oldRoute);
    if (oldRoute != null) {
      router._routes.remove(oldRoute);
      router._locations.remove(oldRoute);
      router._shells.remove(oldRoute);
    }
    if (newRoute != null) {
      router._routes.insert(
        index < 0 ? router._routes.length : index,
        newRoute,
      );
      _remember(newRoute);
    }
    router._navigationChanged();
  }
}
