import 'package:flutter/widgets.dart';
import '../../data/models/billing_return.dart';
export '../../data/models/billing_return.dart';

class BillingReturnService extends ChangeNotifier with WidgetsBindingObserver {
  BillingReturnService._();
  static final instance = BillingReturnService._();
  BillingReturn? pending;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _receive(WidgetsBinding.instance.platformDispatcher.defaultRouteName);
  }

  bool _receive(String location) {
    final uri = Uri.tryParse(location);
    final value = uri == null ? null : BillingReturn.parse(uri);
    // Consume malformed billing links too, avoiding an unknown Navigator route.
    if (value == null)
      return uri != null && BillingReturn.isReturnLocation(uri);
    pending = value;
    notifyListeners();
    return true;
  }

  BillingReturn? take() {
    final value = pending;
    pending = null;
    return value;
  }

  @override
  Future<bool> didPushRoute(String route) async => _receive(route);

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async => _receive(routeInformation.uri.toString());
}
