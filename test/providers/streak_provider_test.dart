import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/streak_models.dart';
import 'package:sixpos/data/services/streak/streak_api_client.dart';
import 'package:sixpos/domain/services/streak/streak_service.dart';
import 'package:sixpos/providers/streak_provider.dart';

void main() {
  test('load expõe loading e estado de sucesso', () async {
    final completer = Completer<UserStreaksModel>();
    final provider = StreakProvider(
      service: StreakService(
        apiClient: _FakeStreakApiClient(getResult: completer.future),
      ),
    );
    addTearDown(provider.dispose);

    final future = provider.load(timezone: 'America/Sao_Paulo');

    expect(provider.loading, isTrue);
    expect(provider.hasError, isFalse);

    completer.complete(_loadedStreaks);
    await future;

    expect(provider.loading, isFalse);
    expect(provider.hasError, isFalse);
    expect(provider.streaks?.shared.currentDays, 12);
  });

  test('load guarda estado de erro sem lançar para a UI', () async {
    final provider = StreakProvider(
      service: StreakService(
        apiClient: _FakeStreakApiClient(
          getResult: Future<UserStreaksModel>.error(StateError('offline')),
        ),
      ),
    );
    addTearDown(provider.dispose);

    await provider.load();

    expect(provider.loading, isFalse);
    expect(provider.hasError, isTrue);
    expect(provider.streaks, isNull);
  });

  test('registerActivity atualiza estado sem exigir nova consulta', () async {
    final provider = StreakProvider(
      service: StreakService(
        apiClient: _FakeStreakApiClient(registerResult: _loadedStreaks),
      ),
    );
    addTearDown(provider.dispose);

    await provider.registerActivity(
      platform: StreakPlatform.web,
      timezone: 'Europe/Warsaw',
    );

    expect(provider.registering, isFalse);
    expect(provider.streaks?.web.currentDays, 8);
    expect(provider.hasError, isFalse);
  });
}

class _FakeStreakApiClient implements StreakApiClient {
  _FakeStreakApiClient({
    Future<UserStreaksModel>? getResult,
    UserStreaksModel? registerResult,
  }) : _getResult = getResult,
       _registerResult = registerResult;

  final Future<UserStreaksModel>? _getResult;
  final UserStreaksModel? _registerResult;

  @override
  Future<UserStreaksModel> getStreaks({String? timezone}) {
    return _getResult ?? Future<UserStreaksModel>.value(_loadedStreaks);
  }

  @override
  Future<UserStreaksModel> registerActivity(StreakActivityRequest request) {
    return Future<UserStreaksModel>.value(_registerResult ?? _loadedStreaks);
  }
}

const UserStreaksModel _loadedStreaks = UserStreaksModel(
  mobile: UserStreakScopeModel(
    currentDays: 5,
    longestDays: 18,
    activeToday: true,
  ),
  web: UserStreakScopeModel(currentDays: 8, longestDays: 9, activeToday: true),
  shared: UserStreakScopeModel(
    currentDays: 12,
    longestDays: 31,
    activeToday: true,
  ),
);
