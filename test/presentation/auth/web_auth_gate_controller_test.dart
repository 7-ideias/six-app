import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/presentation/auth/web_auth_gate_controller.dart';

void main() {
  group('WebAuthGateController', () {
    test('token valido nao chama refresh e executa bootstrap', () async {
      final _FakeSession session = _FakeSession(
        tokenStatus: WebAuthGateAccessTokenStatus.valid,
      );
      final _FakeBootstrap bootstrap = _FakeBootstrap();
      final WebAuthGateController controller = _controller(
        session: session,
        bootstrap: bootstrap,
      );

      await controller.start();

      expect(session.restoreCalls, 0);
      expect(session.clearCalls, 0);
      expect(bootstrap.calls, 1);
      expect(controller.status, WebAuthGateStatus.authenticated);
    });

    test('token ausente restaura sessao web e executa bootstrap', () async {
      final _FakeSession session = _FakeSession(
        tokenStatus: WebAuthGateAccessTokenStatus.absent,
      );
      final _FakeBootstrap bootstrap = _FakeBootstrap();
      final WebAuthGateController controller = _controller(
        session: session,
        bootstrap: bootstrap,
      );

      await controller.start();

      expect(session.restoreCalls, 1);
      expect(bootstrap.calls, 1);
      expect(controller.status, WebAuthGateStatus.authenticated);
    });

    test('token expirado restaura sessao web e executa bootstrap', () async {
      final _FakeSession session = _FakeSession(
        tokenStatus: WebAuthGateAccessTokenStatus.refreshRequired,
      );
      final _FakeBootstrap bootstrap = _FakeBootstrap();
      final WebAuthGateController controller = _controller(
        session: session,
        bootstrap: bootstrap,
      );

      await controller.start();

      expect(session.restoreCalls, 1);
      expect(bootstrap.calls, 1);
      expect(controller.status, WebAuthGateStatus.authenticated);
    });

    test(
      'refresh invalido limpa sessao local e redireciona para login',
      () async {
        final _FakeSession session = _FakeSession(
          tokenStatus: WebAuthGateAccessTokenStatus.absent,
          restoreError: const AuthRefreshException(
            type: AuthRefreshFailureType.invalidSession,
            statusCode: 401,
          ),
        );
        final _FakeBootstrap bootstrap = _FakeBootstrap();
        final WebAuthGateController controller = _controller(
          session: session,
          bootstrap: bootstrap,
        );

        await controller.start();

        expect(session.restoreCalls, 1);
        expect(session.clearCalls, 1);
        expect(bootstrap.calls, 0);
        expect(bootstrap.resets, 1);
        expect(controller.status, WebAuthGateStatus.unauthenticated);
        expect(controller.loginRoute, '/login?redirect=%2Fapp');
      },
    );

    test(
      'deep link com refresh valido abre child da rota solicitada',
      () async {
        final _FakeSession session = _FakeSession(
          tokenStatus: WebAuthGateAccessTokenStatus.absent,
        );
        final _FakeBootstrap bootstrap = _FakeBootstrap();
        final WebAuthGateController controller = _controller(
          requestedLocation: '/app/atendimentos-tecnicos?origem=agenda',
          session: session,
          bootstrap: bootstrap,
        );

        await controller.start();

        expect(controller.status, WebAuthGateStatus.authenticated);
        expect(
          controller.requestedLocation,
          '/app/atendimentos-tecnicos?origem=agenda',
        );
      },
    );

    test(
      'deep link sem sessao preserva destino no redirect para login',
      () async {
        final _FakeSession session = _FakeSession(
          tokenStatus: WebAuthGateAccessTokenStatus.absent,
          restoreError: const AuthRefreshException(
            type: AuthRefreshFailureType.invalidSession,
            statusCode: 403,
          ),
        );
        final WebAuthGateController controller = _controller(
          requestedLocation: '/app/atendimentos-tecnicos?tab=criados#lista',
          session: session,
          bootstrap: _FakeBootstrap(),
        );

        await controller.start();

        expect(controller.status, WebAuthGateStatus.unauthenticated);
        expect(
          controller.loginRoute,
          '/login?redirect=%2Fapp%2Fatendimentos-tecnicos%3Ftab%3Dcriados%23lista',
        );
      },
    );

    test(
      'backend indisponivel nao limpa sessao e exibe erro temporario',
      () async {
        final _FakeSession session = _FakeSession(
          tokenStatus: WebAuthGateAccessTokenStatus.absent,
          restoreError: const AuthRefreshException(
            type: AuthRefreshFailureType.temporaryFailure,
            statusCode: 503,
          ),
        );
        final _FakeBootstrap bootstrap = _FakeBootstrap();
        final WebAuthGateController controller = _controller(
          session: session,
          bootstrap: bootstrap,
        );

        await controller.start();

        expect(session.clearCalls, 0);
        expect(bootstrap.calls, 0);
        expect(controller.status, WebAuthGateStatus.temporaryError);
        expect(controller.failure?.statusCode, 503);
      },
    );

    test('falha de rede nao limpa sessao e permite retry', () async {
      final _FakeSession session = _FakeSession.sequence(
        tokenStatuses: <WebAuthGateAccessTokenStatus>[
          WebAuthGateAccessTokenStatus.absent,
          WebAuthGateAccessTokenStatus.absent,
        ],
        restoreResults: <Object?>[
          http.ClientException('Connection closed before full header'),
          null,
        ],
      );
      final _FakeBootstrap bootstrap = _FakeBootstrap();
      final WebAuthGateController controller = _controller(
        session: session,
        bootstrap: bootstrap,
      );

      await controller.start();

      expect(session.clearCalls, 0);
      expect(controller.status, WebAuthGateStatus.temporaryError);

      await controller.retry();

      expect(session.restoreCalls, 2);
      expect(bootstrap.calls, 1);
      expect(controller.status, WebAuthGateStatus.authenticated);
    });

    test('multiplos starts simultaneos nao duplicam refresh', () async {
      final Completer<void> restoreCompleter = Completer<void>();
      final _FakeSession session = _FakeSession(
        tokenStatus: WebAuthGateAccessTokenStatus.absent,
        restoreFuture: restoreCompleter.future,
      );
      final _FakeBootstrap bootstrap = _FakeBootstrap();
      final WebAuthGateController controller = _controller(
        session: session,
        bootstrap: bootstrap,
      );

      final Future<void> first = controller.start();
      final Future<void> second = controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(session.restoreCalls, 1);

      restoreCompleter.complete();
      await Future.wait<void>(<Future<void>>[first, second]);

      expect(bootstrap.calls, 1);
      expect(controller.status, WebAuthGateStatus.authenticated);
    });

    test('start apos autenticado nao executa bootstrap novamente', () async {
      final _FakeSession session = _FakeSession(
        tokenStatus: WebAuthGateAccessTokenStatus.valid,
      );
      final _FakeBootstrap bootstrap = _FakeBootstrap();
      final WebAuthGateController controller = _controller(
        session: session,
        bootstrap: bootstrap,
      );

      await controller.start();
      await controller.start();

      expect(session.statusCalls, 1);
      expect(session.restoreCalls, 0);
      expect(bootstrap.calls, 1);
      expect(controller.status, WebAuthGateStatus.authenticated);
    });

    test('bootstrap com 401 tenta refresh uma vez antes do login', () async {
      final _FakeSession session = _FakeSession(
        tokenStatus: WebAuthGateAccessTokenStatus.valid,
      );
      final _FakeBootstrap bootstrap = _FakeBootstrap.sequence(<Object?>[
        const WebAuthGateFailure(
          type: WebAuthGateFailureType.invalidSession,
          statusCode: 401,
        ),
        null,
      ]);
      final WebAuthGateController controller = _controller(
        session: session,
        bootstrap: bootstrap,
      );

      await controller.start();

      expect(session.restoreCalls, 1);
      expect(bootstrap.calls, 2);
      expect(controller.status, WebAuthGateStatus.authenticated);
    });
  });
}

WebAuthGateController _controller({
  String requestedLocation = '/app',
  required _FakeSession session,
  required _FakeBootstrap bootstrap,
}) {
  return WebAuthGateController(
    session: session,
    bootstrap: bootstrap,
    requestedLocation: requestedLocation,
  );
}

class _FakeSession implements WebAuthGateSession {
  _FakeSession({
    required WebAuthGateAccessTokenStatus tokenStatus,
    Object? restoreError,
    Future<void>? restoreFuture,
  }) : _tokenStatuses = <WebAuthGateAccessTokenStatus>[tokenStatus],
       _restoreResults = <Object?>[restoreFuture ?? restoreError];

  _FakeSession.sequence({
    required List<WebAuthGateAccessTokenStatus> tokenStatuses,
    required List<Object?> restoreResults,
  }) : _tokenStatuses = List<WebAuthGateAccessTokenStatus>.from(tokenStatuses),
       _restoreResults = List<Object?>.from(restoreResults);

  final List<WebAuthGateAccessTokenStatus> _tokenStatuses;
  final List<Object?> _restoreResults;

  int statusCalls = 0;
  int restoreCalls = 0;
  int clearCalls = 0;

  @override
  Future<WebAuthGateAccessTokenStatus> currentAccessTokenStatus() async {
    statusCalls += 1;
    if (_tokenStatuses.length <= 1) {
      return _tokenStatuses.first;
    }
    return _tokenStatuses.removeAt(0);
  }

  @override
  Future<void> restoreSession() async {
    restoreCalls += 1;
    final Object? result =
        _restoreResults.length <= 1
            ? (_restoreResults.isEmpty ? null : _restoreResults.first)
            : _restoreResults.removeAt(0);
    if (result == null) {
      return;
    }
    if (result is Future<void>) {
      await result;
      return;
    }
    throw result;
  }

  @override
  Future<void> clearLocalSession() async {
    clearCalls += 1;
  }
}

class _FakeBootstrap implements WebAuthGateBootstrap {
  _FakeBootstrap() : _results = <Object?>[null];

  _FakeBootstrap.sequence(List<Object?> results)
    : _results = List<Object?>.from(results);

  final List<Object?> _results;
  int calls = 0;
  int resets = 0;

  @override
  Future<void> bootstrap({bool force = false}) async {
    calls += 1;
    final Object? result =
        _results.length <= 1
            ? (_results.isEmpty ? null : _results.first)
            : _results.removeAt(0);
    if (result == null) {
      return;
    }
    if (result is Future<void>) {
      await result;
      return;
    }
    throw result;
  }

  @override
  void reset() {
    resets += 1;
  }
}
