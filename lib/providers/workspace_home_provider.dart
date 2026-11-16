import 'package:flutter/foundation.dart';
import 'package:sixpos/data/services/workspace_home/workspace_home_api_client.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/domain/services/workspace_home/workspace_home_service.dart';

@immutable
class WorkspaceHomeBlock {
  const WorkspaceHomeBlock({
    this.data,
    this.loading = false,
    this.failed = false,
    this.updatedAt,
  });
  final WorkspaceHomeModel? data;
  final bool loading;
  final bool failed;
  final DateTime? updatedAt;
  bool available(WorkspaceHomeSection section) =>
      data?.toJson()[section.jsonKey]?['available'] == true;
}

class WorkspaceHomeProvider extends ChangeNotifier {
  WorkspaceHomeProvider({WorkspaceHomeService? service, this.segmented = true})
    : _service = service ?? DefaultWorkspaceHomeService();
  final WorkspaceHomeService _service;
  final bool segmented;
  final Map<WorkspaceHomeSection, WorkspaceHomeBlock> _blocks = {};
  WorkspaceHomeModel? _home;
  bool _loading = false;
  bool _disposed = false;
  String? _errorCode;
  String? _scope;
  int _loadRevision = 0;
  int _generation = 0;
  Future<void>? _pending;

  WorkspaceHomeModel? get home => _home;
  bool get loading => _loading;
  String? get errorCode => _errorCode;
  bool get hasError => _errorCode != null;
  int get loadRevision => _loadRevision;
  WorkspaceHomeBlock block(WorkspaceHomeSection section) =>
      _blocks[section] ??
      WorkspaceHomeBlock(data: _home, loading: _loading, failed: hasError);

  Future<void> load({Set<WorkspaceHomeSection>? sections}) {
    if (_disposed) return Future.value();
    return _pending ??= _load(sections ?? WorkspaceHomeSection.values.toSet());
  }

  Future<void> _load(Set<WorkspaceHomeSection> sections) async {
    final generation = _generation;
    bool active() => !_disposed && generation == _generation;
    _loading = true;
    _errorCode = null;
    for (final section in sections) {
      final previous = block(section);
      _blocks[section] = WorkspaceHomeBlock(
        data: previous.data,
        loading: true,
        updatedAt: previous.updatedAt,
      );
    }
    _notify();
    try {
      final service = _service;
      if (!segmented ||
          service is! WorkspaceHomeSectionsService ||
          !(service as WorkspaceHomeSectionsService).supportsSections) {
        final result = await service.buscarHome();
        if (!active()) return;
        _home = result;
        for (final section in sections) {
          _blocks[section] = WorkspaceHomeBlock(
            data: result,
            updatedAt: DateTime.now(),
          );
        }
      } else {
        final sectionsService = service as WorkspaceHomeSectionsService;
        final scope = await sectionsService.currentScope();
        if (!active()) return;
        if (_scope != scope) {
          _home = null;
          _blocks.clear();
          // A new account/company must load every block, including on single-block retry.
          sections = WorkspaceHomeSection.values.toSet();
          for (final section in sections) {
            _blocks[section] = const WorkspaceHomeBlock(loading: true);
          }
          _scope = scope;
          _notify();
        }
        final queue = sections.toList();
        int next = 0;
        Future<void> worker() async {
          while (active() && next < queue.length) {
            final section = queue[next++];
            final previous = _blocks[section]!;
            try {
              final result = await sectionsService.buscarSecao(section, scope);
              final currentScope = await sectionsService.currentScope();
              if (!active()) return;
              if (scope != currentScope) {
                clear();
                return;
              }
              _blocks[section] = WorkspaceHomeBlock(
                data: result,
                updatedAt: DateTime.now(),
              );
            } catch (error) {
              if (!active()) return;
              // Never keep data from a session/company that changed mid-request.
              try {
                if (await sectionsService.currentScope() != scope) {
                  if (active()) clear();
                  return;
                }
              } catch (_) {
                if (active()) clear();
                return;
              }
              if (!active()) return;
              _blocks[section] = WorkspaceHomeBlock(
                data:
                    error is WorkspaceHomeApiException &&
                            (error.statusCode == 401 || error.statusCode == 403)
                        ? null
                        : previous.data,
                failed: true,
                updatedAt: previous.updatedAt,
              );
            }
            _notify();
          }
        }

        await Future.wait(
          List.generate(queue.length.clamp(0, 3), (_) => worker()),
        );
        if (!active()) return;
        final data = <String, dynamic>{};
        for (final section in WorkspaceHomeSection.values) {
          final result = _blocks[section]?.data?.toJson();
          if (result != null) {
            data['date'] = result['date'];
            data['timeZone'] = result['timeZone'];
            data[section.jsonKey] = result[section.jsonKey];
          }
        }
        if (data.isNotEmpty) _home = WorkspaceHomeModel.fromJson(data);
        if (_blocks.values.any((block) => block.failed)) {
          _errorCode = 'workspace.home.error.load';
        }
      }
      _loadRevision++;
    } catch (_) {
      if (active()) {
        _errorCode = 'workspace.home.error.load';
        if (_service is WorkspaceHomeSectionsService && segmented) {
          _home = null;
          _scope = null;
          _blocks.clear();
        }
        for (final section in sections) {
          final previous = _blocks[section];
          _blocks[section] = WorkspaceHomeBlock(
            data: previous?.data,
            failed: true,
            updatedAt: previous?.updatedAt,
          );
        }
      }
    } finally {
      if (active()) {
        _loading = false;
        _pending = null;
        _notify();
      }
    }
  }

  Future<void> reload() => load();
  Future<void> reloadSection(WorkspaceHomeSection section) =>
      load(sections: {section});

  void clear() {
    _generation++;
    _pending = null;
    _home = null;
    _scope = null;
    _blocks.clear();
    _errorCode = null;
    _loading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
