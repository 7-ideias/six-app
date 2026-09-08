import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_auth_storage_service.dart';

enum MobileBiometricKind {
  faceId,
  touchId,
  face,
  fingerprint,
  generic,
}

class MobileBiometricAvailability {
  const MobileBiometricAvailability({
    required this.deviceSupported,
    required this.enrolled,
    required this.kind,
  });

  const MobileBiometricAvailability.unavailable()
    : deviceSupported = false,
      enrolled = false,
      kind = MobileBiometricKind.generic;

  final bool deviceSupported;
  final bool enrolled;
  final MobileBiometricKind kind;

  bool get canAuthenticate => deviceSupported && enrolled;
}

/// Fachada única para autenticação biométrica local do SixoApp.
///
/// A biometria nunca é enviada ao backend. O sistema operacional apenas
/// informa ao app se a autenticação local foi aprovada. O Keycloak continua
/// sendo a autoridade da sessão por meio do refresh token.
class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuthentication,
    SecureAuthStorageService? secureStorage,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? SecureAuthStorageService();

  final LocalAuthentication _localAuthentication;
  final SecureAuthStorageService _secureStorage;

  Future<MobileBiometricAvailability> availability() async {
    if (kIsWeb) {
      return const MobileBiometricAvailability.unavailable();
    }

    try {
      final bool supported = await _localAuthentication.isDeviceSupported();
      if (!supported) {
        return const MobileBiometricAvailability.unavailable();
      }

      final bool canCheck = await _localAuthentication.canCheckBiometrics;
      if (!canCheck) {
        return const MobileBiometricAvailability(
          deviceSupported: true,
          enrolled: false,
          kind: MobileBiometricKind.generic,
        );
      }

      final List<BiometricType> available =
          await _localAuthentication.getAvailableBiometrics();
      return MobileBiometricAvailability(
        deviceSupported: true,
        enrolled: available.isNotEmpty,
        kind: _resolveKind(available),
      );
    } catch (error) {
      debugPrint('[BiometricAuthService] Falha ao consultar biometria: $error');
      return const MobileBiometricAvailability.unavailable();
    }
  }

  Future<bool> authenticate({required String localizedReason}) async {
    if (kIsWeb) return false;

    final MobileBiometricAvailability current = await availability();
    if (!current.canAuthenticate) {
      return false;
    }

    try {
      return await _localAuthentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } catch (error) {
      debugPrint('[BiometricAuthService] Autenticação biométrica falhou: $error');
      return false;
    }
  }

  Future<bool> isEnabled() async {
    if (!await _secureStorage.isBiometricEnabled()) {
      return false;
    }

    final String owner = (await _secureStorage.readBiometricUserId())?.trim() ?? '';
    if (owner.isEmpty) {
      await _disableInconsistentBiometric(
        'Biometria sem usuário proprietário',
      );
      return false;
    }

    final String currentSessionUserId = await _currentStoredSessionUserId();
    if (currentSessionUserId.isNotEmpty && owner != currentSessionUserId) {
      await _disableInconsistentBiometric(
        'Biometria pertence a outro usuário local',
      );
      return false;
    }

    return true;
  }

  Future<String?> enabledUserId() => _secureStorage.readBiometricUserId();

  Future<bool> hasProtectedSessionForUser(String? userId) async {
    final String normalizedUserId = userId?.trim() ?? '';
    if (normalizedUserId.isEmpty || !await isEnabled()) {
      return false;
    }

    final String owner = (await enabledUserId())?.trim() ?? '';
    if (owner.isEmpty || owner != normalizedUserId) {
      return false;
    }

    final String refreshToken =
        (await _secureStorage.readRefreshToken())?.trim() ?? '';
    return refreshToken.isNotEmpty;
  }

  /// Evita herdar a biometria de outro usuário no mesmo aparelho.
  Future<void> reconcileAuthenticatedUser(String? userId) async {
    if (!await isEnabled()) return;

    final String normalizedUserId = userId?.trim() ?? '';
    final String owner = (await enabledUserId())?.trim() ?? '';
    if (normalizedUserId.isEmpty || owner.isEmpty || owner != normalizedUserId) {
      await disable();
    }
  }

  Future<bool> enableForUser({
    required String userId,
    required String localizedReason,
  }) async {
    final String normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return false;
    }

    final String refreshToken =
        (await _secureStorage.readRefreshToken())?.trim() ?? '';
    if (refreshToken.isEmpty) {
      return false;
    }

    final bool authenticated = await authenticate(
      localizedReason: localizedReason,
    );
    if (!authenticated) {
      return false;
    }

    await _secureStorage.enableBiometricForUser(normalizedUserId);
    return true;
  }

  Future<void> disable() => _secureStorage.disableBiometric();

  Future<void> _disableInconsistentBiometric(String reason) async {
    debugPrint(
      '[BiometricAuthService] $reason; desabilitando somente a biometria '
      'e preservando a sessão Keycloak.',
    );
    await _secureStorage.disableBiometric();
  }

  Future<String> _currentStoredSessionUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String accessToken = prefs.getString('accessToken')?.trim() ?? '';
    final String subject = _subjectFromJwt(accessToken);
    if (subject.isNotEmpty) {
      return subject;
    }

    final String rawUserData = prefs.getString('userData')?.trim() ?? '';
    if (rawUserData.isEmpty) {
      return '';
    }

    try {
      final dynamic decoded = jsonDecode(rawUserData);
      if (decoded is! Map<String, dynamic>) {
        return '';
      }

      final String keycloakId = decoded['keycloakId']?.toString().trim() ?? '';
      if (keycloakId.isNotEmpty) {
        return keycloakId;
      }

      return decoded['id']?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _subjectFromJwt(String token) {
    if (token.isEmpty) return '';

    final List<String> parts = token.split('.');
    if (parts.length < 2) return '';

    try {
      final String normalized = base64Url.normalize(parts[1]);
      final String payload = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return '';
      return decoded['sub']?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  MobileBiometricKind _resolveKind(List<BiometricType> available) {
    if (available.contains(BiometricType.face)) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? MobileBiometricKind.faceId
          : MobileBiometricKind.face;
    }

    if (available.contains(BiometricType.fingerprint)) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? MobileBiometricKind.touchId
          : MobileBiometricKind.fingerprint;
    }

    return MobileBiometricKind.generic;
  }
}
