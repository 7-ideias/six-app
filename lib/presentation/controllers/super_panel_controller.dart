import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/admin_portal_service.dart';

/// Owns monitoring data only while an authorized SUPER panel is open.
class SuperPanelController extends ChangeNotifier {
  SuperPanelController({AdminPortalService? service})
    : _service = service ?? AdminPortalService();

  final AdminPortalService _service;
  bool _authorized = false;
  bool _disposed = false;
  int _generation = 0;
  bool loading = false;
  bool hasError = false;
  AdminPortalResumo? resumo;
  int windowValue = 15;
  AdminRequestWindowUnit windowUnit = AdminRequestWindowUnit.minutes;

  void setAuthorized(bool authorized) {
    if (_disposed || authorized == _authorized) return;
    _authorized = authorized;
    _generation++;
    resumo = null;
    hasError = false;
    loading = false;
    if (authorized) {
      unawaited(reload());
    } else {
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (_disposed || !_authorized || loading) return;
    final generation = ++_generation;
    loading = true;
    hasError = false;
    notifyListeners();
    try {
      final result = await _service.buscarResumo(
        janelaValor: windowValue,
        janelaUnidade: windowUnit,
      );
      if (!_accepts(generation)) return;
      resumo = result;
      final requests = result.requestsHttp;
      if (requests != null && requests.janelaValor > 0) {
        windowValue = requests.janelaValor;
        windowUnit = requests.janelaUnidade;
      }
    } catch (_) {
      if (!_accepts(generation)) return;
      resumo = null;
      hasError = true;
    } finally {
      if (_accepts(generation)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> changeWindow(int value, AdminRequestWindowUnit unit) async {
    if (_disposed || !_authorized || loading) return;
    windowValue = value.clamp(
      1,
      unit == AdminRequestWindowUnit.hours ? 72 : 4320,
    );
    windowUnit = unit;
    await reload();
  }

  bool _accepts(int generation) =>
      !_disposed && _authorized && _generation == generation;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
