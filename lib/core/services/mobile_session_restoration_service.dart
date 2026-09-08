import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  Future<String?> getStoredAccessToken();

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
  Future<String?> getStoredAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  @override
  Future<void> refreshToken() => _authService.refreshToken();
}

class MobileSessionRestorationService {
  MobileSessionRestorationService({MobileSessionAuthGateway? gateway})
    : _gateway = gateway ?? AuthServiceMobileSessionAuthGateway();

  static const Duration _refreshSafetyWindow = Duration(seconds: 30);

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

      // Retomar o app (inclusive após o prompt de Face ID) não deve consumir um
      // refresh token se o access token atual ainda é válido. O refresh continua
      // acontecendo normalmente quando o token estiver próximo de expirar.
      final String accessToken =
          (await _gateway.getStoredAccessToken())?.trim() ?? '';
      if (_isAccessTokenUsable(accessToken)) {
        return const MobileSessionRestorationResult(
          MobileSessionRestorationStatus.restored,
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

  bool _isAccessTokenUsable(String token) {
    if (token.isEmpty) return false;

    final List<String> parts = token.split('.');
    if (parts.length < 2) return false;

    try {
      final String normalized = base64Url.normalize(parts[1]);
      final String payload = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return false;

      final dynamic exp = decoded['exp'];
      if (exp is! num) return false;

      final DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
      final DateTime refreshAt = expiresAt.subtract(_refreshSafetyWindow);
      return DateTime.now().toUtc().isBefore(refreshAt);
    } catch (_) {
      return false;
    }
  }
}
