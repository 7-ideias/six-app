import 'package:flutter/widgets.dart';

/// Holds navigation until the authenticated mobile shell is ready.
class AgendaEmailLinkService extends ChangeNotifier
    with WidgetsBindingObserver {
  static final instance = AgendaEmailLinkService();
  static const path = '/mobile/agenda-financeira';
  bool _pending = false;
  bool get pending => _pending;

  static bool matches(Uri uri) {
    if (uri.userInfo.isNotEmpty || uri.hasPort || uri.hasFragment) return false;
    if (uri.scheme == 'com.sixoapp.app') {
      return uri.host == 'mobile' && uri.path == '/agenda-financeira';
    }
    if (uri.path != path) return false;
    return (!uri.hasScheme && !uri.hasAuthority) ||
        (uri.scheme == 'https' && uri.host == 'www.sixoapp.com');
  }

  void initialize() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _receive(Uri.tryParse(binding.platformDispatcher.defaultRouteName));
  }

  bool _receive(Uri? uri) {
    if (uri == null || !matches(uri)) return false;
    if (!_pending) {
      _pending = true;
      notifyListeners();
    }
    return true;
  }

  bool take() {
    final pending = _pending;
    _pending = false;
    return pending;
  }

  @override
  Future<bool> didPushRoute(String route) async =>
      _receive(Uri.tryParse(route));

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async => _receive(routeInformation.uri);
}
