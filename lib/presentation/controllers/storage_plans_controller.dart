import 'package:flutter/foundation.dart';

import '../../data/models/storage_plan.dart';
import '../../data/services/storage/storage_usage_api_client.dart';

class StoragePlansController extends ChangeNotifier {
  StoragePlansController({StorageUsageApiClient? client, this.companyId})
    : _client = client ?? StorageUsageApiClient();
  final StorageUsageApiClient _client;
  final String? companyId;
  List<StoragePlan> plans = [];
  StorageEffectivePlan current = const StorageEffectivePlan();
  String? selectedPlanId;
  void selectPlan(String? id) {
    selectedPlanId = id;
    notifyListeners();
  }

  bool loading = false;
  bool saving = false;
  bool loaded = false;
  bool changed = false;
  bool _disposed = false;
  String? error;

  Future<void> load() async {
    if (loading || saving || _disposed) return;
    loading = true;
    loaded = false;
    error = null;
    notifyListeners();
    try {
      final list = await _client.listPlans();
      final selected = companyId == null
          ? const StorageEffectivePlan()
          : (await _client.load(adminCompanyId: companyId)).plan;
      if (_disposed) return;
      plans = list;
      current = selected;
      selectedPlanId = selected.planId;
      loaded = true;
    } catch (e) {
      _setError(e);
    }
    if (_disposed) return;
    loading = false;
    notifyListeners();
  }

  Future<bool> save(
    StoragePlan plan,
    String database,
    String files,
    String upload,
    String separator,
  ) async {
    if (saving || !loaded || _disposed) return false;
    saving = true;
    error = null;
    notifyListeners();
    bool success = false;
    try {
      final limits = StorageLimits(
        databaseLimitBytes: storageMegabytesToBytes(database, separator),
        fileLimitBytes: storageMegabytesToBytes(files, separator),
        maxUploadBytes: storageMegabytesToBytes(upload, separator),
        version: plan.limits.version,
      );
      if (limits.fileLimitBytes != null &&
          limits.maxUploadBytes != null &&
          limits.maxUploadBytes! > limits.fileLimitBytes!) {
        throw const FormatException('invalidLimits');
      }
      final updated = await _client.saveLimits(plan.id, limits);
      if (_disposed) return false;
      plans = plans.map((p) => p.id == updated.id ? updated : p).toList();
      changed = true;
      success = true;
    } catch (e) {
      _setError(e);
    }
    if (_disposed) return false;
    saving = false;
    notifyListeners();
    return success;
  }

  Future<void> assign(String? planId) async {
    if (companyId == null || saving || !loaded || _disposed) return;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final updated = await _client.assignPlan(companyId!, planId, current);
      if (_disposed) return;
      current = updated;
      selectedPlanId = updated.planId;
      changed = true;
    } catch (e) {
      _setError(e);
    }
    if (_disposed) return;
    saving = false;
    notifyListeners();
  }

  void _setError(Object error) {
    if (_disposed) return;
    this.error = error is StorageUsageException
        ? error.code
        : error is FormatException
        ? 'invalidLimits'
        : 'error';
    if (this.error == 'planConflict' ||
        this.error == 'forbidden' ||
        this.error == 'session')
      loaded = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }
}
