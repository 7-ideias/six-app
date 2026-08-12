import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/domain/services/workspace_home/workspace_home_service.dart';
import 'package:sixpos/providers/workspace_home_provider.dart';

void main() {
  test('load expõe loading e estado de sucesso', () async {
    final completer = Completer<WorkspaceHomeModel>();
    final provider = WorkspaceHomeProvider(
      service: _FakeWorkspaceHomeService(result: completer.future),
    );
    addTearDown(provider.dispose);

    final future = provider.load();

    expect(provider.loading, isTrue);
    expect(provider.hasError, isFalse);

    completer.complete(_workspaceHome);
    await future;

    expect(provider.loading, isFalse);
    expect(provider.hasError, isFalse);
    expect(provider.home?.stock.negative, 1);
    expect(provider.loadRevision, 1);
  });

  test('load guarda código de erro sem lançar para a UI', () async {
    final provider = WorkspaceHomeProvider(
      service: _FakeWorkspaceHomeService(
        result: Future<WorkspaceHomeModel>.error(StateError('offline')),
      ),
    );
    addTearDown(provider.dispose);

    await provider.load();

    expect(provider.loading, isFalse);
    expect(provider.hasError, isTrue);
    expect(provider.errorCode, 'workspace.home.error.load');
    expect(provider.home, isNull);
  });

  test('reload com erro preserva dados carregados anteriormente', () async {
    final provider = WorkspaceHomeProvider(
      service: _SequencedWorkspaceHomeService(<Future<WorkspaceHomeModel>>[
        Future<WorkspaceHomeModel>.value(_workspaceHome),
        Future<WorkspaceHomeModel>.error(StateError('offline')),
      ]),
    );
    addTearDown(provider.dispose);

    await provider.load();
    expect(provider.home, isNotNull);

    await provider.reload();

    expect(provider.loading, isFalse);
    expect(provider.hasError, isTrue);
    expect(provider.home, same(_workspaceHome));
    expect(provider.loadRevision, 1);
  });
}

class _FakeWorkspaceHomeService implements WorkspaceHomeService {
  const _FakeWorkspaceHomeService({required Future<WorkspaceHomeModel> result})
    : _result = result;

  final Future<WorkspaceHomeModel> _result;

  @override
  Future<WorkspaceHomeModel> buscarHome() {
    return _result;
  }
}

class _SequencedWorkspaceHomeService implements WorkspaceHomeService {
  _SequencedWorkspaceHomeService(this._results);

  final List<Future<WorkspaceHomeModel>> _results;
  int _index = 0;

  @override
  Future<WorkspaceHomeModel> buscarHome() {
    final Future<WorkspaceHomeModel> result = _results[_index];
    if (_index < _results.length - 1) {
      _index += 1;
    }
    return result;
  }
}

final WorkspaceHomeModel _workspaceHome = WorkspaceHomeModel.fromJson(
  const <String, dynamic>{
    'date': '2026-08-10',
    'timeZone': 'America/Sao_Paulo',
    'cash': <String, dynamic>{'available': true, 'open': false},
    'technicalServices': <String, dynamic>{
      'available': true,
      'active': 8,
      'waitingApproval': 5,
      'late': 3,
      'readyForPickup': 4,
    },
    'financial': <String, dynamic>{'available': false},
    'stock': <String, dynamic>{
      'available': true,
      'belowMinimum': 6,
      'withoutStock': 2,
      'negative': 1,
    },
  },
);
