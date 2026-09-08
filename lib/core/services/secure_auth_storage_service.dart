import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureAuthStorageTemporarilyUnavailableException implements Exception {
  const SecureAuthStorageTemporarilyUnavailableException([this.cause]);

  final Object? cause;

  @override
  String toString() {
    final Object? currentCause = cause;
    return currentCause == null
        ? 'SecureAuthStorageTemporarilyUnavailableException'
        : 'SecureAuthStorageTemporarilyUnavailableException: $currentCause';
  }
}

/// Armazena credenciais de sessão do mobile em armazenamento protegido pelo SO.
///
/// No iOS os valores ficam no Keychain. O refresh token usa
/// `first_unlock_this_device`: depois do primeiro desbloqueio após reiniciar o
/// iPhone, o token continua acessível ao processo mesmo se o aparelho voltar a
/// bloquear. Isso é importante para renovação de sessão sem transformar uma
/// indisponibilidade transitória do Keychain em logout.
///
/// No Android o plugin usa chaves protegidas pelo Android Keystore. O Web
/// continua usando o fluxo atual de cookie/sessão do backend e não passa por
/// este serviço.
class SecureAuthStorageService {
  SecureAuthStorageService._internal();

  static final SecureAuthStorageService _instance =
      SecureAuthStorageService._internal();

  factory SecureAuthStorageService() => _instance;

  static const String legacyRefreshTokenKey = 'refreshToken';
  static const String _refreshTokenKey = 'sixo.auth.refreshToken';
  static const String _biometricEnabledKey = 'sixo.auth.biometric.enabled';
  static const String _biometricUserIdKey = 'sixo.auth.biometric.userId';
  static const String _refreshTokenExpectedKey =
      'sixo.auth.refreshToken.expected';
  static const String _accessTokenHintKey = 'accessToken';
  static const String _userDataHintKey = 'userData';

  static const IOSOptions _iosSessionOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: _iosSessionOptions,
  );

  // Instância apenas para migrar itens gravados pela primeira versão da
  // biometria, que usava o padrão `unlocked` do Keychain.
  final FlutterSecureStorage _legacyIosStorage = const FlutterSecureStorage();

  String? _cachedRefreshToken;

  bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> writeRefreshToken(String value) async {
    if (kIsWeb) return;

    final String normalized = value.trim();
    if (normalized.isEmpty) {
      await deleteRefreshToken();
      return;
    }

    // Mantém a credencial mais nova em memória antes da persistência. Isso
    // evita perder um refresh token rotacionado caso o SO interrompa uma
    // operação de Keychain exatamente entre a resposta HTTP e a gravação.
    _cachedRefreshToken = normalized;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_refreshTokenExpectedKey, true);

    await _writeSecureValueWithRetry(_refreshTokenKey, normalized);

    // Remove o legado somente depois de persistir com sucesso no storage seguro.
    await prefs.remove(legacyRefreshTokenKey);
  }

  /// Lê o refresh token seguro e migra silenciosamente instalações antigas.
  ///
  /// Se há indícios locais de uma sessão existente, uma leitura vazia do
  /// Keychain não é interpretada como logout. Nesse cenário lançamos uma falha
  /// transitória para que a camada de restauração preserve a sessão e tente de
  /// novo.
  Future<String?> readRefreshToken() async {
    if (kIsWeb) return null;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String cached = _cachedRefreshToken?.trim() ?? '';
    if (cached.isNotEmpty) {
      // Se uma gravação anterior falhou depois de o backend rotacionar o token,
      // o valor mais novo ficou preservado em memória. Reaproveitamos esse
      // valor imediatamente e tentamos repersisti-lo sem derrubar a sessão.
      try {
        await _writeSecureValueWithRetry(_refreshTokenKey, cached);
        await prefs.setBool(_refreshTokenExpectedKey, true);
        await prefs.remove(legacyRefreshTokenKey);
      } catch (error) {
        debugPrint(
          '[SecureAuthStorageService] Refresh token em memória preservado; '
          'repersistência será tentada novamente: $error',
        );
      }
      return cached;
    }

    Object? secureReadError;

    try {
      final String secureValue =
          (await _readSecureValueWithIosMigration(_refreshTokenKey))?.trim() ??
          '';
      if (secureValue.isNotEmpty) {
        _cachedRefreshToken = secureValue;
        await prefs.setBool(_refreshTokenExpectedKey, true);
        return secureValue;
      }
    } catch (error) {
      secureReadError = error;
      debugPrint(
        '[SecureAuthStorageService] Keychain/Keystore temporariamente '
        'indisponível ao ler refresh token: $error',
      );
    }

    // Compatibilidade com instalações anteriores à migração para secure storage.
    final String legacyValue =
        prefs.getString(legacyRefreshTokenKey)?.trim() ?? '';
    if (legacyValue.isNotEmpty) {
      _cachedRefreshToken = legacyValue;
      await prefs.setBool(_refreshTokenExpectedKey, true);

      try {
        await _writeSecureValueWithRetry(_refreshTokenKey, legacyValue);
        await prefs.remove(legacyRefreshTokenKey);
      } catch (error) {
        // Não elimina a sessão antiga se a migração segura falhar. O token
        // legado permanece disponível apenas até uma migração futura ter êxito.
        debugPrint(
          '[SecureAuthStorageService] Migração do refresh token legado será '
          'tentada novamente: $error',
        );
      }

      return legacyValue;
    }

    if (_hasStoredSessionHint(prefs)) {
      // Uma pequena segunda tentativa cobre a janela de retomada do iOS em que
      // o app já recebeu `resumed`, mas o protected data ainda está sendo
      // disponibilizado pelo sistema.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      try {
        final String retryValue =
            (await _readSecureValueWithIosMigration(_refreshTokenKey))?.trim() ??
            '';
        if (retryValue.isNotEmpty) {
          _cachedRefreshToken = retryValue;
          await prefs.setBool(_refreshTokenExpectedKey, true);
          return retryValue;
        }
      } catch (error) {
        secureReadError ??= error;
      }

      throw SecureAuthStorageTemporarilyUnavailableException(secureReadError);
    }

    return null;
  }

  Future<void> deleteRefreshToken() async {
    _cachedRefreshToken = null;

    if (!kIsWeb) {
      await _deleteSecureValueAcrossIosAccessibility(_refreshTokenKey);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyRefreshTokenKey);
    await prefs.remove(_refreshTokenExpectedKey);
  }

  Future<bool> isBiometricEnabled() async {
    if (kIsWeb) return false;
    return await _readSecureValueWithIosMigration(_biometricEnabledKey) == '1';
  }

  Future<String?> readBiometricUserId() async {
    if (kIsWeb) return null;
    final String value =
        (await _readSecureValueWithIosMigration(_biometricUserIdKey))?.trim() ??
        '';
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

    await _writeSecureValueWithRetry(
      _biometricUserIdKey,
      normalizedUserId,
    );
    await _writeSecureValueWithRetry(_biometricEnabledKey, '1');
  }

  Future<void> disableBiometric() async {
    if (kIsWeb) return;
    await _deleteSecureValueAcrossIosAccessibility(_biometricEnabledKey);
    await _deleteSecureValueAcrossIosAccessibility(_biometricUserIdKey);
  }

  bool _hasStoredSessionHint(SharedPreferences prefs) {
    if (prefs.getBool(_refreshTokenExpectedKey) == true) {
      return true;
    }

    final String accessToken = prefs.getString(_accessTokenHintKey)?.trim() ?? '';
    final String userData = prefs.getString(_userDataHintKey)?.trim() ?? '';
    return accessToken.isNotEmpty || userData.isNotEmpty;
  }

  Future<String?> _readSecureValueWithIosMigration(String key) async {
    Object? primaryError;

    try {
      final String? value = await _secureStorage.read(key: key);
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    } catch (error) {
      primaryError = error;
    }

    if (!_isIOS) {
      if (primaryError != null) throw primaryError;
      return null;
    }

    // A primeira implementação foi gravada com `unlocked` (default). Como a
    // acessibilidade faz parte da consulta ao Keychain, tentamos esse formato
    // antigo e, encontrando valor, regravamos no novo formato.
    try {
      final String? legacyValue = await _legacyIosStorage.read(key: key);
      if (legacyValue == null || legacyValue.trim().isEmpty) {
        if (primaryError != null) throw primaryError;
        return null;
      }

      await _writeSecureValueWithRetry(key, legacyValue);
      return legacyValue;
    } catch (legacyError) {
      throw primaryError ?? legacyError;
    }
  }

  Future<void> _writeSecureValueWithRetry(String key, String value) async {
    Object? lastError;

    for (int attempt = 0; attempt < 3; attempt += 1) {
      try {
        await _secureStorage.write(key: key, value: value);
        return;
      } catch (error) {
        lastError = error;
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 120 * (attempt + 1)),
          );
        }
      }
    }

    throw SecureAuthStorageTemporarilyUnavailableException(lastError);
  }

  Future<void> _deleteSecureValueAcrossIosAccessibility(String key) async {
    Object? primaryError;

    try {
      await _secureStorage.delete(key: key);
    } catch (error) {
      primaryError = error;
    }

    if (_isIOS) {
      try {
        await _legacyIosStorage.delete(key: key);
      } catch (error) {
        primaryError ??= error;
      }
    }

    if (primaryError != null) {
      // Limpeza explícita deve continuar sinalizando falha. Não usamos esse
      // caminho durante restauração automática de sessão.
      throw primaryError;
    }
  }
}
