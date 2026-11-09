import 'auth_service.dart';

/// Etapas obrigatorias para liberar o aplicativo apos restaurar a sessao.
/// Servicos complementares (push, locale, analytics) nao pertencem a esse fluxo.
enum MobileSessionBootstrapStep { company, permissions, onboarding }

class MobileSessionBootstrapFailure implements Exception {
  const MobileSessionBootstrapFailure({
    required this.step,
    required this.cause,
  });

  final MobileSessionBootstrapStep step;
  final Object cause;

  @override
  String toString() => 'MobileSessionBootstrapFailure(step: $step, cause: $cause)';
}

class MobileSessionBootstrapService {
  const MobileSessionBootstrapService({
    this.stepTimeout = const Duration(seconds: 15),
  });

  final Duration stepTimeout;

  Future<void> prepare({
    required Future<void> Function() loadCompany,
    required Future<void> Function() loadPermissions,
    required Future<void> Function() loadOnboarding,
  }) async {
    await _run(MobileSessionBootstrapStep.company, loadCompany);
    await _run(MobileSessionBootstrapStep.permissions, loadPermissions);
    await _run(MobileSessionBootstrapStep.onboarding, loadOnboarding);
  }

  Future<void> _run(
    MobileSessionBootstrapStep step,
    Future<void> Function() operation,
  ) async {
    try {
      await operation().timeout(stepTimeout);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        MobileSessionBootstrapFailure(step: step, cause: error),
        stackTrace,
      );
    }
  }
}

/// Backoff progressivo: usuario pode retentar manualmente a qualquer momento.
/// Nunca limpar o token por timeouts, falhas de rede ou HTTP 5xx.
class MobileSessionRecoveryPolicy {
  const MobileSessionRecoveryPolicy();

  static const List<Duration> _delays = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(minutes: 1),
  ];

  Duration delayForFailure(int consecutiveFailures) {
    final int index = consecutiveFailures <= 1 ? 0 : consecutiveFailures - 1;
    return _delays[index >= _delays.length ? _delays.length - 1 : index];
  }

  bool isInvalidSession(Object error) {
    if (error is MobileSessionBootstrapFailure) {
      return isInvalidSession(error.cause);
    }
    return error is AuthRefreshException && error.isInvalidSession;
  }
}
