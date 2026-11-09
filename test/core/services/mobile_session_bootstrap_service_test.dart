import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/mobile_session_bootstrap_service.dart';

void main() {
  group('MobileSessionBootstrapService', () {
    test('executa apenas as etapas obrigatorias em ordem', () async {
      final List<String> steps = <String>[];
      const MobileSessionBootstrapService service =
          MobileSessionBootstrapService();

      await service.prepare(
        loadCompany: () async => steps.add('company'),
        loadPermissions: () async => steps.add('permissions'),
        loadOnboarding: () async => steps.add('onboarding'),
      );

      expect(steps, <String>['company', 'permissions', 'onboarding']);
    });

    test('falha de empresa impede as demais etapas', () async {
      final List<String> steps = <String>[];
      const MobileSessionBootstrapService service =
          MobileSessionBootstrapService();

      await expectLater(
        service.prepare(
          loadCompany: () async {
            steps.add('company');
            throw StateError('offline');
          },
          loadPermissions: () async => steps.add('permissions'),
          loadOnboarding: () async => steps.add('onboarding'),
        ),
        throwsA(
          isA<MobileSessionBootstrapFailure>().having(
            (MobileSessionBootstrapFailure error) => error.step,
            'step',
            MobileSessionBootstrapStep.company,
          ),
        ),
      );
      expect(steps, <String>['company']);
    });

    test('nao libera a conta quando permissoes falham', () async {
      bool onboardingCalled = false;
      const MobileSessionBootstrapService service =
          MobileSessionBootstrapService();

      await expectLater(
        service.prepare(
          loadCompany: () async {},
          loadPermissions: () async => throw StateError('permissions offline'),
          loadOnboarding: () async {
            onboardingCalled = true;
          },
        ),
        throwsA(
          isA<MobileSessionBootstrapFailure>().having(
            (MobileSessionBootstrapFailure error) => error.step,
            'step',
            MobileSessionBootstrapStep.permissions,
          ),
        ),
      );
      expect(onboardingCalled, isFalse);
    });

    test('timeout e transitorio e nao e invalidez da sessao', () async {
      final Completer<void> stalled = Completer<void>();
      const MobileSessionBootstrapService service =
          MobileSessionBootstrapService(
            stepTimeout: Duration(milliseconds: 5),
          );
      const MobileSessionRecoveryPolicy policy = MobileSessionRecoveryPolicy();

      try {
        await service.prepare(
          loadCompany: () => stalled.future,
          loadPermissions: () async {},
          loadOnboarding: () async {},
        );
        fail('Deveria ter encerrado a tentativa por timeout');
      } on MobileSessionBootstrapFailure catch (error) {
        expect(error.step, MobileSessionBootstrapStep.company);
        expect(error.cause, isA<TimeoutException>());
        expect(policy.isInvalidSession(error), isFalse);
      } finally {
        stalled.complete();
      }
    });
  });

  group('MobileSessionRecoveryPolicy', () {
    const MobileSessionRecoveryPolicy policy = MobileSessionRecoveryPolicy();

    test('usa backoff com teto de um minuto', () {
      expect(policy.delayForFailure(1), const Duration(seconds: 5));
      expect(policy.delayForFailure(2), const Duration(seconds: 10));
      expect(policy.delayForFailure(3), const Duration(seconds: 20));
      expect(policy.delayForFailure(4), const Duration(seconds: 30));
      expect(policy.delayForFailure(5), const Duration(minutes: 1));
      expect(policy.delayForFailure(99), const Duration(minutes: 1));
    });

    test('somente refresh invalidado deve forcar novo login', () {
      const AuthRefreshException invalid = AuthRefreshException(
        type: AuthRefreshFailureType.invalidSession,
        statusCode: 401,
      );
      const AuthRefreshException unavailable = AuthRefreshException(
        type: AuthRefreshFailureType.temporaryFailure,
        statusCode: 503,
      );

      expect(policy.isInvalidSession(invalid), isTrue);
      expect(policy.isInvalidSession(unavailable), isFalse);
      expect(
        policy.isInvalidSession(
          const MobileSessionBootstrapFailure(
            step: MobileSessionBootstrapStep.company,
            cause: invalid,
          ),
        ),
        isTrue,
      );
      expect(
        policy.isInvalidSession(
          const MobileSessionBootstrapFailure(
            step: MobileSessionBootstrapStep.onboarding,
            cause: unavailable,
          ),
        ),
        isFalse,
      );
    });
  });
}
