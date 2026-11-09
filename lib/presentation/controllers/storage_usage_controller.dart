import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/storage_usage.dart';
import '../../data/services/storage/storage_usage_api_client.dart';

class StorageUsageController extends ChangeNotifier {
  StorageUsageController({StorageUsageApiClient? client, this.adminCompanyId})
    : _client = client ?? StorageUsageApiClient();
  final StorageUsageApiClient _client;
  final String? adminCompanyId;
  StorageUsage? usage;
  String? error;
  bool loading = false;
  bool _disposed = false;
  int _generation = 0;
  int _polls = 0;
  Timer? _timer;

  Future<void> load({bool reset = false, bool automatic = false}) async {
    final generation = ++_generation;
    _timer?.cancel();
    if (!automatic) _polls = 0;
    if (reset) usage = null;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _client.load(adminCompanyId: adminCompanyId);
      if (_disposed || generation != _generation) return;
      usage = result;
    } on StorageUsageException catch (failure) {
      if (_disposed || generation != _generation) return;
      error = failure.code;
      usage = null;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error = 'error';
    }
    if (_disposed || generation != _generation) return;
    loading = false;
    notifyListeners();
    if (error == null && usage?.pending == true && _polls++ < 12) {
      _timer = Timer(const Duration(seconds: 10), () => load(automatic: true));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
