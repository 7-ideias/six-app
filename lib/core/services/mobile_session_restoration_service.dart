import 'auth_service.dart';

enum MobileSessionRestorationStatus {
  restored,
  noStoredSession,
  invalidSession,
  temporaryFailure,
}

class MobileSessionRestorationResult {
  const MobileSessionRestorationResult(this.status, {this.error});

  final MobileSessionRestorationStatus status;
  final Object? error;
}

abstract interface class MobileSessionAuthGateway {
  Future<String?> getRefreshToken();

  Future<void> refreshToken();

  Future<void> clearLocalSession();
}

class AuthServiceMobileSessionAuthGateway implements MobileSessionAuthGateway {
  AuthServiceMobileSessionAuthGateway({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  Future<void> clearLocalSession() => _authService.clearLocalSession();

  @override
  Future<String?> getRefreshToken() => _authService.getRefreshToken();

  @override
  Future<void> refreshToken() => _authService.refreshToken();
}

class MobileSessionRestorationService {
  MobileSessionRestorationService({MobileSessionAuthGateway? gateway})
    : _gateway = gateway ?? AuthServiceMobileSessionAuthGateway();

  final MobileSessionAuthGateway _gateway;
  Future<MobileSessionRestorationResult>? _restoration;

  Future<MobileSessionRestorationResult> restore() async {
    final Future<MobileSessionRestorationResult>? current = _restoration;
    if (current != null) {
      return current;
    }

    final Future<MobileSessionRestorationResult> restoration =
        _restoreInternal();
    _restoration = restoration;
    try {
      return await restoration;
    } finally {
      if (identical(_restoration, restoration)) {
        _restoration = null;
      }
    }
  }

  Future<MobileSessionRestorationResult> _restoreInternal() async {
    try {
      final String refreshToken =
          (await _gateway.getRefreshToken())?.trim() ?? '';
      if (refreshToken.isEmpty) {
        return const MobileSessionRestorationResult(
          MobileSessionRestorationStatus.noStoredSession,
        );
      }

      await _gateway.refreshToken();
      return const MobileSessionRestorationResult(
        MobileSessionRestorationStatus.restored,
      );
    } on AuthRefreshException catch (error) {
      if (error.isInvalidSession) {
        await _gateway.clearLocalSession();
        return MobileSessionRestorationResult(
          MobileSessionRestorationStatus.invalidSession,
          error: error,
        );
      }

      return MobileSessionRestorationResult(
        MobileSessionRestorationStatus.temporaryFailure,
        error: error,
      );
    } catch (error) {
      return MobileSessionRestorationResult(
        MobileSessionRestorationStatus.temporaryFailure,
        error: error,
      );
    }
  }
}
