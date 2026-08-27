import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/mobile_session_restoration_service.dart';

void main() {
  group('MobileSessionRestorationService', () {
    test('não tenta renovar quando não há sessão armazenada', () async {
      final _FakeMobileSessionAuthGateway gateway =
          _FakeMobileSessionAuthGateway(refreshToken: null);
      final MobileSessionRestorationService service =
          MobileSessionRestorationService(gateway: gateway);

      final MobileSessionRestorationResult result = await service.restore();

      expect(result.status, MobileSessionRestorationStatus.noStoredSession);
      expect(gateway.refreshCalls, 0);
      expect(gateway.clearCalls, 0);
    });

    test('restaura uma sessão válida', () async {
      final _FakeMobileSessionAuthGateway gateway =
          _FakeMobileSessionAuthGateway(refreshToken: 'refresh-token');
      final MobileSessionRestorationService service =
          MobileSessionRestorationService(gateway: gateway);

      final MobileSessionRestorationResult result = await service.restore();

      expect(result.status, MobileSessionRestorationStatus.restored);
      expect(gateway.refreshCalls, 1);
      expect(gateway.clearCalls, 0);
    });

    test('limpa os dados somente após invalidação confirmada', () async {
      final _FakeMobileSessionAuthGateway gateway =
          _FakeMobileSessionAuthGateway(
            refreshToken: 'refresh-token',
            refreshError: const AuthRefreshException(
              type: AuthRefreshFailureType.invalidSession,
              statusCode: 401,
            ),
          );
      final MobileSessionRestorationService service =
          MobileSessionRestorationService(gateway: gateway);

      final MobileSessionRestorationResult result = await service.restore();

      expect(result.status, MobileSessionRestorationStatus.invalidSession);
      expect(gateway.clearCalls, 1);
    });

    test('preserva os dados em falha temporária', () async {
      final _FakeMobileSessionAuthGateway gateway =
          _FakeMobileSessionAuthGateway(
            refreshToken: 'refresh-token',
            refreshError: const AuthRefreshException(
              type: AuthRefreshFailureType.temporaryFailure,
              statusCode: 503,
            ),
          );
      final MobileSessionRestorationService service =
          MobileSessionRestorationService(gateway: gateway);

      final MobileSessionRestorationResult result = await service.restore();

      expect(result.status, MobileSessionRestorationStatus.temporaryFailure);
      expect(gateway.clearCalls, 0);
    });

    test('compartilha uma restauração concorrente', () async {
      final _FakeMobileSessionAuthGateway gateway =
          _FakeMobileSessionAuthGateway(
            refreshToken: 'refresh-token',
            refreshCompleter: Completer<void>(),
          );
      final MobileSessionRestorationService service =
          MobileSessionRestorationService(gateway: gateway);

      final Future<MobileSessionRestorationResult> first = service.restore();
      final Future<MobileSessionRestorationResult> second = service.restore();
      gateway.refreshCompleter!.complete();

      expect((await first).status, MobileSessionRestorationStatus.restored);
      expect((await second).status, MobileSessionRestorationStatus.restored);
      expect(gateway.refreshCalls, 1);
    });
  });
}

class _FakeMobileSessionAuthGateway implements MobileSessionAuthGateway {
  _FakeMobileSessionAuthGateway({
    required String? refreshToken,
    this.refreshError,
    this.refreshCompleter,
  }) : _storedRefreshToken = refreshToken;

  final String? _storedRefreshToken;
  final Object? refreshError;
  final Completer<void>? refreshCompleter;
  int refreshCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> clearLocalSession() async {
    clearCalls += 1;
  }

  @override
  Future<String?> getRefreshToken() async => _storedRefreshToken;

  @override
  Future<void> refreshToken() async {
    refreshCalls += 1;
    if (refreshCompleter != null) {
      await refreshCompleter!.future;
    }
    if (refreshError != null) {
      throw refreshError!;
    }
  }
}
