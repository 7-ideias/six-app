import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Armazena credenciais de sessão do mobile em armazenamento protegido pelo SO.
///
/// No iOS os valores ficam no Keychain. No Android, o plugin usa chaves
/// protegidas pelo Android Keystore. O Web continua usando o fluxo atual de
/// cookie/sessão do backend e não passa por este serviço.
class SecureAuthStorageService {
  SecureAuthStorageService._internal();

  static final SecureAuthStorageService _instance =
      SecureAuthStorageService._internal();

  factory SecureAuthStorageService() => _instance;

  static const String legacyRefreshTokenKey = 'refreshToken';
  static const String _refreshTokenKey = 'sixo.auth.refreshToken';
  static const String _biometricEnabledKey = 'sixo.auth.biometric.enabled';
  static const String _biometricUserIdKey = 'sixo.auth.biometric.userId';

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> writeRefreshToken(String value) async {
    if (kIsWeb) return;

    final String normalized = value.trim();
    if (normalized.isEmpty) {
      await deleteRefreshToken();
      return;
    }

    await _secureStorage.write(key: _refreshTokenKey, value: normalized);

    // Remove o legado somente depois de persistir com sucesso no storage seguro.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyRefreshTokenKey);
  }

  /// Lê o refresh token seguro e migra silenciosamente instalações antigas que
  /// ainda possuam o token em SharedPreferences.
  Future<String?> readRefreshToken() async {
    if (kIsWeb) return null;

    final String secureValue =
        (await _secureStorage.read(key: _refreshTokenKey))?.trim() ?? '';
    if (secureValue.isNotEmpty) {
      return secureValue;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String legacyValue =
        prefs.getString(legacyRefreshTokenKey)?.trim() ?? '';
    if (legacyValue.isEmpty) {
      return null;
    }

    await _secureStorage.write(key: _refreshTokenKey, value: legacyValue);
    await prefs.remove(legacyRefreshTokenKey);
    return legacyValue;
  }

  Future<void> deleteRefreshToken() async {
    if (!kIsWeb) {
      await _secureStorage.delete(key: _refreshTokenKey);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyRefreshTokenKey);
  }

  Future<bool> isBiometricEnabled() async {
    if (kIsWeb) return false;
    return await _secureStorage.read(key: _biometricEnabledKey) == '1';
  }

  Future<String?> readBiometricUserId() async {
    if (kIsWeb) return null;
    final String value =
        (await _secureStorage.read(key: _biometricUserIdKey))?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  Future<void> enableBiometricForUser(String userId) async {
    if (kIsWeb) return;

    final String normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'Usuário obrigatório para habilitar biometria.',
      );
    }

    await _secureStorage.write(key: _biometricUserIdKey, value: normalizedUserId);
    await _secureStorage.write(key: _biometricEnabledKey, value: '1');
  }

  Future<void> disableBiometric() async {
    if (kIsWeb) return;
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _biometricUserIdKey);
  }
}
