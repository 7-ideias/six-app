import 'package:flutter/foundation.dart';

import '../data/models/streak_models.dart';
import '../domain/services/streak/streak_service.dart';

class StreakProvider extends ChangeNotifier {
  StreakProvider({StreakService? service})
    : _service = service ?? StreakService();

  final StreakService _service;

  UserStreaksModel? _streaks;
  bool _loading = false;
  bool _registering = false;
  Object? _lastError;

  UserStreaksModel? get streaks => _streaks;

  bool get loading => _loading;

  bool get registering => _registering;

  bool get hasError => _lastError != null;

  Object? get lastError => _lastError;

  Future<void> load({String? timezone}) async {
    _loading = true;
    _lastError = null;
    notifyListeners();

    try {
      _streaks = await _service.getStreaks(timezone: timezone);
    } catch (error, stackTrace) {
      _lastError = error;
      debugPrint('[StreakProvider] Falha ao consultar ofensiva: $error');
      debugPrint('[StreakProvider] Stack trace: $stackTrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> registerActivity({
    required StreakPlatform platform,
    String? timezone,
  }) async {
    _registering = true;
    _lastError = null;
    notifyListeners();

    try {
      _streaks = await _service.registerActivity(
        platform: platform,
        timezone: timezone,
      );
    } catch (error, stackTrace) {
      _lastError = error;
      debugPrint('[StreakProvider] Falha ao registrar ofensiva: $error');
      debugPrint('[StreakProvider] Stack trace: $stackTrace');
    } finally {
      _registering = false;
      notifyListeners();
    }
  }
}
