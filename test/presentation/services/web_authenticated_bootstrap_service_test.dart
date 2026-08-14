import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/services/web_authenticated_bootstrap_service.dart';

void main() {
  group('WebAuthenticatedBootstrapService', () {
    test('factory compartilha a mesma instancia em producao', () {
      final WebAuthenticatedBootstrapService first =
          WebAuthenticatedBootstrapService();
      final WebAuthenticatedBootstrapService second =
          WebAuthenticatedBootstrapService();

      addTearDown(first.reset);

      expect(identical(first, second), isTrue);
    });

    test('duas chamadas simultaneas compartilham uma operacao real', () async {
      final Completer<void> bootstrapCompleter = Completer<void>();
      final Completer<void> operationStarted = Completer<void>();
      int bootstrapCalls = 0;
      final WebAuthenticatedBootstrapService service =
          WebAuthenticatedBootstrapService.forTesting(
            sessionKeyResolver: () async => 'usuario-1|empresa-1',
            bootstrapOperation: () {
              bootstrapCalls += 1;
              if (!operationStarted.isCompleted) {
                operationStarted.complete();
              }
              return bootstrapCompleter.future;
            },
          );

      final Future<void> first = service.bootstrapForTesting();
      final Future<void> second = service.bootstrapForTesting();
      await operationStarted.future;
      await Future<void>.delayed(Duration.zero);

      bootstrapCompleter.complete();
      await Future.wait<void>(<Future<void>>[first, second]);
      expect(bootstrapCalls, 1);
    });

    test('mesma sessao nao repete bootstrap apos pos-login forcado', () async {
      int bootstrapCalls = 0;
      final WebAuthenticatedBootstrapService service =
          WebAuthenticatedBootstrapService.forTesting(
            sessionKeyResolver: () async => 'usuario-1|empresa-1',
            bootstrapOperation: () async {
              bootstrapCalls += 1;
            },
          );

      await service.bootstrapForTesting(force: true);
      await service.bootstrapForTesting();

      expect(bootstrapCalls, 1);
    });

    test('reset permite bootstrap novo para a mesma sessao', () async {
      int bootstrapCalls = 0;
      final WebAuthenticatedBootstrapService service =
          WebAuthenticatedBootstrapService.forTesting(
            sessionKeyResolver: () async => 'usuario-1|empresa-1',
            bootstrapOperation: () async {
              bootstrapCalls += 1;
            },
          );

      await service.bootstrapForTesting();
      service.reset();
      await service.bootstrapForTesting();

      expect(bootstrapCalls, 2);
    });

    test('troca de sessao permite novo bootstrap', () async {
      String sessionKey = 'usuario-1|empresa-1';
      int bootstrapCalls = 0;
      final WebAuthenticatedBootstrapService service =
          WebAuthenticatedBootstrapService.forTesting(
            sessionKeyResolver: () async => sessionKey,
            bootstrapOperation: () async {
              bootstrapCalls += 1;
            },
          );

      await service.bootstrapForTesting();
      sessionKey = 'usuario-2|empresa-2';
      await service.bootstrapForTesting();

      expect(bootstrapCalls, 2);
    });
  });
}
