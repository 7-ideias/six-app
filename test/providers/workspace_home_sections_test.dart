import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/domain/services/workspace_home/workspace_home_service.dart';
import 'package:sixpos/providers/workspace_home_provider.dart';

void main() {
  test(
    'renders a finished block while another is slow; at most three calls',
    () async {
      final service = _Sections();
      final provider = WorkspaceHomeProvider(service: service);
      addTearDown(provider.dispose);
      final pending = provider.load();
      await _tick();
      expect(service.calls.length, 3);
      service.finish(WorkspaceHomeSection.cash);
      await _tick();
      expect(provider.block(WorkspaceHomeSection.cash).data, isNotNull);
      expect(provider.block(WorkspaceHomeSection.financial).loading, isTrue);
      expect(
        provider.home,
        isNull,
      ); // Legacy summary waits for the initial batch.
      service.finish(WorkspaceHomeSection.stock);
      await _tick();
      service.finish(WorkspaceHomeSection.reservations);
      service.finish(WorkspaceHomeSection.financial);
      service.finish(WorkspaceHomeSection.technicalServices);
      await pending;
      expect(service.peak, 3);
      expect(provider.home, isNotNull);
      expect(provider.loading, isFalse);
    },
  );

  test('isolates errors and retries only the failed block', () async {
    final service = _Sections()..automatic = true;
    final provider = WorkspaceHomeProvider(service: service);
    addTearDown(provider.dispose);
    service.failures.add(WorkspaceHomeSection.stock);
    await provider.load();
    expect(provider.block(WorkspaceHomeSection.stock).failed, isTrue);
    expect(provider.block(WorkspaceHomeSection.financial).failed, isFalse);
    final calls = service.calls.length;
    service.failures.clear();
    await provider.reloadSection(WorkspaceHomeSection.stock);
    expect(service.calls.length, calls + 1);
    expect(provider.block(WorkspaceHomeSection.stock).failed, isFalse);
  });

  test('retains values during refresh and marks a failed refresh', () async {
    final service = _Sections()..automatic = true;
    final provider = WorkspaceHomeProvider(service: service);
    addTearDown(provider.dispose);
    await provider.load();
    final old = provider.block(WorkspaceHomeSection.cash).data;
    service.automatic = false;
    final pending = provider.reloadSection(WorkspaceHomeSection.cash);
    await _tick();
    expect(provider.block(WorkspaceHomeSection.cash).data, same(old));
    expect(provider.block(WorkspaceHomeSection.cash).loading, isTrue);
    service.completers[WorkspaceHomeSection.cash]!.completeError(
      StateError('offline'),
    );
    await pending;
    expect(provider.block(WorkspaceHomeSection.cash).data, same(old));
    expect(provider.block(WorkspaceHomeSection.cash).failed, isTrue);
  });

  test(
    'discards late results when context changes or provider is disposed',
    () async {
      final service = _Sections();
      final provider = WorkspaceHomeProvider(service: service);
      final pending = provider.load();
      await _tick();
      service.scope = 'user|company-b';
      service.finish(WorkspaceHomeSection.cash);
      service.finish(WorkspaceHomeSection.financial);
      service.finish(WorkspaceHomeSection.technicalServices);
      await pending;
      expect(provider.home, isNull);
      expect(provider.block(WorkspaceHomeSection.cash).data, isNull);
      service.automatic = true;
      await provider.reload();
      expect(provider.home, isNotNull);
      service.automatic = false;
      final next = provider.reloadSection(WorkspaceHomeSection.cash);
      await _tick();
      provider.dispose();
      service.finish(WorkspaceHomeSection.cash);
      await next;
    },
  );

  test(
    'clear invalidates an old batch without clobbering a newer one',
    () async {
      final service = _Sections();
      final provider = WorkspaceHomeProvider(service: service);
      addTearDown(provider.dispose);
      final old = provider.load();
      await _tick();
      final stale = Map.of(service.completers);
      provider.clear();
      service.automatic = true;
      service.scope = 'user|company-b';
      await provider.load();
      final current = provider.home;
      for (final entry in stale.entries) {
        entry.value.complete(_response(entry.key));
      }
      await old;
      expect(provider.home, same(current));
      expect(provider.loading, isFalse);
    },
  );
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);
WorkspaceHomeModel _response(WorkspaceHomeSection section) =>
    WorkspaceHomeModel.fromJson({
      'date': '2026-11-16',
      'timeZone': 'America/Sao_Paulo',
      section.jsonKey: {
        'available': true,
        'open': true,
        'received': 2,
        'belowMinimum': 3,
      },
    });

class _Sections implements WorkspaceHomeService, WorkspaceHomeSectionsService {
  @override
  bool get supportsSections => true;
  String scope = 'user|company-a';
  bool automatic = false;
  int active = 0;
  int peak = 0;
  final calls = <WorkspaceHomeSection>[];
  final failures = <WorkspaceHomeSection>{};
  final completers = <WorkspaceHomeSection, Completer<WorkspaceHomeModel>>{};
  @override
  Future<String> currentScope() async => scope;
  @override
  Future<WorkspaceHomeModel> buscarHome() =>
      throw StateError('Aggregate must not be used');
  @override
  Future<WorkspaceHomeModel> buscarSecao(
    WorkspaceHomeSection section,
    String scope,
  ) async {
    calls.add(section);
    active++;
    if (active > peak) peak = active;
    try {
      if (failures.contains(section)) throw StateError('offline');
      if (automatic) return _response(section);
      final completer = Completer<WorkspaceHomeModel>();
      completers[section] = completer;
      return await completer.future;
    } finally {
      active--;
    }
  }

  void finish(WorkspaceHomeSection section) =>
      completers[section]!.complete(_response(section));
}
