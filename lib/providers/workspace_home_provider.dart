import 'package:flutter/foundation.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/domain/services/workspace_home/workspace_home_service.dart';

class WorkspaceHomeProvider extends ChangeNotifier {
  WorkspaceHomeProvider({WorkspaceHomeService? service})
    : _service = service ?? DefaultWorkspaceHomeService();

  final WorkspaceHomeService _service;

  WorkspaceHomeModel? _home;
  bool _loading = false;
  String? _errorCode;
  int _loadRevision = 0;

  WorkspaceHomeModel? get home => _home;
  bool get loading => _loading;
  String? get errorCode => _errorCode;
  bool get hasError => _errorCode != null;
  int get loadRevision => _loadRevision;

  Future<void> load() async {
    if (_loading) {
      return;
    }

    _loading = true;
    _errorCode = null;
    notifyListeners();

    try {
      _home = await _service.buscarHome();
      _loadRevision += 1;
    } catch (_) {
      _errorCode = 'workspace.home.error.load';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  void clear() {
    _home = null;
    _errorCode = null;
    _loading = false;
    notifyListeners();
  }
}
