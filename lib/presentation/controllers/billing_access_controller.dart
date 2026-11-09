import 'package:flutter/foundation.dart';

import '../../data/models/billing_access.dart';
import '../../data/services/billing_access_api.dart';

class BillingAccessController extends ChangeNotifier {
  BillingAccessController(
    this.company, {
    this.admin = false,
    BillingAccessApi? api,
  }) : _api = api ?? BillingAccessApi();
  final String company;
  final bool admin;
  final BillingAccessApi _api;
  BillingAccess? value;
  String? error;
  bool busy = false;
  bool _disposed = false;
  Future<void> load() => _run(() async {
    value = await _api.load(company, admin: admin);
  });
  Future<void> release(String reason) async {
    if (!admin || value == null || busy) return;
    if (reason.trim().length < 3 || reason.length > 500) {
      error = 'reasonError';
      notifyListeners();
      return;
    }
    await _run(() async {
      value = await _api.release(value!, !value!.manualRelease, reason);
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await operation();
    } on BillingAccessException catch (e) {
      error = e.code;
      if (e.code == 'conflict') value = null;
    } catch (_) {
      error = 'error';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _api.close();
    super.dispose();
  }
}
