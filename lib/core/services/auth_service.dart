import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'google_auth_service.dart';
import 'http_client_factory.dart';
import 'empresa_service.dart';
import '../config/app_config.dart';
import '../../data/models/auth_response_model.dart';

enum AuthAccessTokenStatus { absent, valid, refreshRequired }

enum AuthRefreshFailureType { invalidSession, temporaryFailure }

class AuthRefreshException implements Exception {
  const AuthRefreshException({
    required this.type,
    this.statusCode,
    this.message,
  });

  final AuthRefreshFailureType type;
  final int? statusCode;
  final String? message;

  bool get isInvalidSession => type == AuthRefreshFailureType.invalidSession;

  @override
  String toString() {
    final String status = statusCode == null ? '' : ', statusCode: $statusCode';
    final String detail = message == null ? '' : ', message: $message';
    return 'AuthRefreshException(type: $type$status$detail)';
  }
}

class AuthService {
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _userDataKey = 'userData';
  static const String _empresaIdKey = 'idUnicoDaEmpresa';
  static const String _accessTokenExpiresAtKey = 'accessTokenExpiresAt';
  static const Duration _refreshSafetyWindow = Duration(seconds: 30);
  static const Duration _refreshRetryDelay = Duration(seconds: 30);
  static const Duration _fallbackRefreshDelay = Duration(minutes: 4);
  static const Duration _authRequestTimeout = Duration(seconds: 20);

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    registerUnauthorizedTokenRefreshHandler(_recoverFromUnauthorized);
  }

  Timer? _refreshTimer;
  Future<void>? _refreshFuture;

  http.Client _client() => createHttpClient();

  Future<AuthResponseModel?> login(String login, String senha) async {
    final String pathLogin = kIsWeb ? 'web' : 'mobile';
    final baseUrl = AppConfig.baseUrl;
    if (baseUrl.isEmpty) {
      throw Exception(
        'API_BASE_URL não configurado. Rode com --dart-define=API_BASE_URL=http://localhost:8082.',
      );
    }
    final uri = Uri.parse('$baseUrl/auth/$pathLogin/login');

    final requestBody = jsonEncode({'login': login, 'senha': senha});

    debugPrint('[AuthService] POST $uri');

    final client = _client();
    final http.Response response;
    try {
      response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(_authRequestTimeout);
    } on http.ClientException catch (e) {
      debugPrint('[AuthService] ClientException no POST $uri: $e');
      throw Exception(
        'Não foi possível contatar o servidor em $baseUrl. '
        'Verifique CORS, se o backend está no ar e se o endereço está correto.',
      );
    } catch (e) {
      debugPrint('[AuthService] Erro inesperado no POST $uri: $e');
      rethrow;
    }

    debugPrint(
      '[AuthService] resposta ${response.statusCode} de $uri '
      '(${response.body.length} bytes)',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final authData = AuthResponseModel.fromJson(decoded);
      await _saveAuthData(authData);
      _scheduleRefreshTimer(authData);

      try {
        await EmpresaService().buscarDadosDaEmpresa();
        debugPrint('Dados da empresa buscados e armazenados com sucesso');
      } catch (e) {
        debugPrint('Erro ao buscar dados da empresa: $e');
      }

      return authData;
    }

    throw Exception(
      'Falha ao realizar login (${response.statusCode}): ${response.body}',
    );
  }

  Future<AuthResponseModel> loginWithGoogle() async {
    final authData = await GoogleAuthService().signIn();
    await _saveAuthData(authData);
    _scheduleRefreshTimer(authData);

    try {
      await EmpresaService().buscarDadosDaEmpresa();
    } catch (e) {
      debugPrint('Erro ao buscar dados da empresa: $e');
    }

    return authData;
  }

  void cancelPendingWebGoogleLogin() {
    GoogleAuthService().cancelWebSignIn();
  }

  /// Web-only entry point. Awaits the result of the rendered Google button
  /// and persists the backend auth response.
  Future<AuthResponseModel> awaitWebGoogleLogin() async {
    final authData = await GoogleAuthService().awaitWebSignIn();
    await _saveAuthData(authData);
    _scheduleRefreshTimer(authData);

    try {
      await EmpresaService().buscarDadosDaEmpresa();
    } catch (e) {
      debugPrint('Erro ao buscar dados da empresa: $e');
    }

    return authData;
  }

  Future<void> refreshToken() async {
    final Future<void>? currentRefresh = _refreshFuture;
    if (currentRefresh != null) {
      return currentRefresh;
    }

    final Future<void> refreshFuture = _refreshTokenInternal();
    _refreshFuture = refreshFuture;

    try {
      await refreshFuture;
    } finally {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }
  }

  Future<void> _refreshTokenInternal() async {
    final String pathLogin = kIsWeb ? 'web' : 'mobile';
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/$pathLogin/refresh');

    final client = _client();
    http.Response response;

    try {
      if (kIsWeb) {
        response = await client
            .post(uri, headers: {'Content-Type': 'application/json'})
            .timeout(_authRequestTimeout);
      } else {
        final String? refreshTokenStr = await getRefreshToken();

        if (refreshTokenStr == null || refreshTokenStr.isEmpty) {
          throw const AuthRefreshException(
            type: AuthRefreshFailureType.invalidSession,
            message: 'No refresh token found',
          );
        }

        response = await client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refreshToken': refreshTokenStr}),
            )
            .timeout(_authRequestTimeout);
      }
    } on AuthRefreshException {
      rethrow;
    } on http.ClientException catch (e) {
      throw AuthRefreshException(
        type: AuthRefreshFailureType.temporaryFailure,
        message: e.message,
      );
    } on TimeoutException catch (e) {
      throw AuthRefreshException(
        type: AuthRefreshFailureType.temporaryFailure,
        message: e.message,
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException catch (e) {
        throw AuthRefreshException(
          type: AuthRefreshFailureType.temporaryFailure,
          statusCode: response.statusCode,
          message: e.message,
        );
      }
      final AuthResponseModel authData;
      try {
        authData = AuthResponseModel.fromJson(decoded);
      } catch (error) {
        throw AuthRefreshException(
          type: AuthRefreshFailureType.temporaryFailure,
          statusCode: response.statusCode,
          message: error.toString(),
        );
      }
      await _saveAuthData(authData);
      _scheduleRefreshTimer(authData);
      return;
    }

    if (response.statusCode == 401) {
      throw AuthRefreshException(
        type: AuthRefreshFailureType.invalidSession,
        statusCode: response.statusCode,
      );
    }

    throw AuthRefreshException(
      type: AuthRefreshFailureType.temporaryFailure,
      statusCode: response.statusCode,
    );
  }

  void _scheduleRefreshTimer(AuthResponseModel authData) {
    _refreshTimer?.cancel();

    if (!kIsWeb && authData.refreshToken.trim().isEmpty) {
      return;
    }

    final DateTime? expiresAt = _resolveAccessTokenExpiresAt(
      authData.accessToken,
      authData.expiresIn,
    );
    final Duration delay = _nextRefreshDelay(expiresAt);

    _refreshTimer = Timer(delay, () async {
      try {
        await refreshToken();
      } catch (error) {
        debugPrint('[AuthService] Refresh agendado falhou: $error');
        if (error is AuthRefreshException && error.isInvalidSession) {
          return;
        }
        await _scheduleRefreshRetryIfPossible();
      }
    });
  }

  Future<void> _saveAuthData(AuthResponseModel authData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, authData.accessToken);
    await prefs.setString(_userDataKey, jsonEncode(authData.usuario.toJson()));

    final DateTime? expiresAt = _resolveAccessTokenExpiresAt(
      authData.accessToken,
      authData.expiresIn,
    );
    if (expiresAt == null) {
      await prefs.remove(_accessTokenExpiresAtKey);
    } else {
      await prefs.setString(
        _accessTokenExpiresAtKey,
        expiresAt.toUtc().toIso8601String(),
      );
    }

    if (authData.idUnicoDaEmpresa.isNotEmpty) {
      await prefs.setString(_empresaIdKey, authData.idUnicoDaEmpresa.first);
    }

    if (!kIsWeb && authData.refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, authData.refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString(_accessTokenKey);
    if (accessToken == null || accessToken.trim().isEmpty) {
      if (!kIsWeb) {
        final String storedRefreshToken =
            prefs.getString(_refreshTokenKey)?.trim() ?? '';
        if (storedRefreshToken.isEmpty) {
          return accessToken;
        }
      }

      try {
        await refreshToken();
      } catch (error) {
        debugPrint(
          '[AuthService] Recuperação de access token ausente falhou: $error',
        );
        if (error is AuthRefreshException && error.isInvalidSession) {
          rethrow;
        }
        await _scheduleRefreshRetryIfPossible();
      }

      return prefs.getString(_accessTokenKey);
    }

    if (await _shouldRefreshAccessToken(prefs, accessToken)) {
      try {
        await refreshToken();
      } catch (error) {
        debugPrint('[AuthService] Refresh sob demanda falhou: $error');
        if (error is AuthRefreshException && error.isInvalidSession) {
          rethrow;
        }
        await _scheduleRefreshRetryIfPossible();
      }

      return prefs.getString(_accessTokenKey);
    }

    return accessToken;
  }

  Future<AuthAccessTokenStatus> getCurrentWebAccessTokenStatus() async {
    if (!kIsWeb) {
      return AuthAccessTokenStatus.absent;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString(_accessTokenKey);
    if (accessToken == null || accessToken.trim().isEmpty) {
      return AuthAccessTokenStatus.absent;
    }

    if (await _shouldRefreshAccessToken(prefs, accessToken)) {
      return AuthAccessTokenStatus.refreshRequired;
    }

    return AuthAccessTokenStatus.valid;
  }

  Future<void> restoreWebSession() async {
    if (!kIsWeb) {
      throw UnsupportedError('restoreWebSession é exclusivo do Flutter Web.');
    }

    await refreshToken();
  }

  Future<void> clearLocalWebSession() async {
    if (!kIsWeb) {
      return;
    }

    await _clearLocalAuthData();
  }

  Future<void> clearLocalSession() {
    return _clearLocalAuthData();
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    final String? refreshToken = await getRefreshToken();

    final baseUrl = AppConfig.baseUrl;
    if (baseUrl.isNotEmpty) {
      final pathLogout = kIsWeb ? 'web' : 'mobile';
      final uri = Uri.parse('$baseUrl/auth/$pathLogout/logout');
      try {
        if (kIsWeb) {
          await _client()
              .post(uri, headers: const {'Content-Type': 'application/json'})
              .timeout(_authRequestTimeout);
        } else if (refreshToken != null && refreshToken.trim().isNotEmpty) {
          await _client()
              .post(
                uri,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode({'refreshToken': refreshToken}),
              )
              .timeout(_authRequestTimeout);
        }
      } catch (e) {
        debugPrint('[AuthService] logout remoto falhou: $e');
      }
    }

    await _clearLocalAuthData();
  }

  Future<void> _clearLocalAuthData() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_empresaIdKey);
    await prefs.remove(_accessTokenExpiresAtKey);

    try {
      await GoogleAuthService().signOut();
    } catch (_) {}
  }

  Future<String?> getEmpresaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_empresaIdKey);
  }

  Future<void> setEmpresaId(String empresaId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String normalized = empresaId.trim();

    if (normalized.isEmpty) {
      await prefs.remove(_empresaIdKey);
      return;
    }

    await prefs.setString(_empresaIdKey, normalized);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString(_accessTokenKey);
    final String? idUnicoDoUsuario = _extrairSubjectDoJwt(token);
    if (idUnicoDoUsuario != null && idUnicoDoUsuario.trim().isNotEmpty) {
      return idUnicoDoUsuario;
    }

    final String? raw = prefs.getString(_userDataKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final String keycloakId = decoded['keycloakId']?.toString().trim() ?? '';
      if (keycloakId.isNotEmpty) {
        return keycloakId;
      }

      return decoded['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  String? _extrairSubjectDoJwt(String? token) {
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final List<String> parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final String normalized = base64Url.normalize(parts[1]);
      final String payload = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final String subject = decoded['sub']?.toString().trim() ?? '';
      return subject.isEmpty ? null : subject;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _shouldRefreshAccessToken(
    SharedPreferences prefs,
    String accessToken,
  ) async {
    final DateTime? expiresAt =
        _readStoredAccessTokenExpiresAt(prefs) ??
        _readJwtExpiresAt(accessToken);
    if (expiresAt == null) {
      return false;
    }

    final DateTime refreshAt = expiresAt.subtract(_refreshSafetyWindow);
    return !DateTime.now().isBefore(refreshAt);
  }

  DateTime? _readStoredAccessTokenExpiresAt(SharedPreferences prefs) {
    final String? raw = prefs.getString(_accessTokenExpiresAtKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  DateTime? _resolveAccessTokenExpiresAt(String token, int expiresIn) {
    final DateTime? jwtExpiresAt = _readJwtExpiresAt(token);
    if (jwtExpiresAt != null) {
      return jwtExpiresAt;
    }
    if (expiresIn <= 0) {
      return null;
    }
    return DateTime.now().add(Duration(seconds: expiresIn));
  }

  DateTime? _readJwtExpiresAt(String? token) {
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final List<String> parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final String normalized = base64Url.normalize(parts[1]);
      final String payload = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final dynamic exp = decoded['exp'];
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          exp.toInt() * 1000,
          isUtc: true,
        ).toLocal();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Duration _nextRefreshDelay(DateTime? expiresAt) {
    if (expiresAt == null) {
      return _fallbackRefreshDelay;
    }

    final Duration remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return Duration.zero;
    }

    final Duration delay = remaining - _refreshSafetyWindow;
    if (delay <= Duration.zero) {
      return const Duration(seconds: 1);
    }

    return delay;
  }

  Future<void> _scheduleRefreshRetryIfPossible() async {
    if (!kIsWeb) {
      final String? refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        return;
      }
    }

    _refreshTimer?.cancel();
    _refreshTimer = Timer(_refreshRetryDelay, () async {
      try {
        await refreshToken();
      } catch (error) {
        debugPrint('[AuthService] Nova tentativa de refresh falhou: $error');
        if (error is AuthRefreshException && error.isInvalidSession) {
          return;
        }
        await _scheduleRefreshRetryIfPossible();
      }
    });
  }

  Future<String?> _recoverFromUnauthorized(String rejectedAccessToken) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String currentAccessToken =
        prefs.getString(_accessTokenKey)?.trim() ?? '';

    if (currentAccessToken.isNotEmpty &&
        currentAccessToken != rejectedAccessToken) {
      return currentAccessToken;
    }

    await refreshToken();
    final String renewedAccessToken =
        prefs.getString(_accessTokenKey)?.trim() ?? '';
    return renewedAccessToken.isEmpty ? null : renewedAccessToken;
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_userDataKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final String email = decoded['email']?.toString().trim() ?? '';
      return email.isEmpty ? null : email.toLowerCase();
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> getRealmRoles() async {
    final String accessToken = (await getAccessToken())?.trim() ?? '';
    if (accessToken.isEmpty) {
      return <String>{};
    }

    final List<String> parts = accessToken.split('.');
    if (parts.length < 2) {
      return <String>{};
    }

    try {
      final String normalized = base64Url.normalize(parts[1]);
      final String payload = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return <String>{};
      }

      final dynamic realmAccess = decoded['realm_access'];
      if (realmAccess is! Map<String, dynamic>) {
        return <String>{};
      }

      final dynamic roles = realmAccess['roles'];
      if (roles is! List) {
        return <String>{};
      }

      return roles
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<bool> hasRealmRole(String role) async {
    final String normalizedRole = role.trim();
    if (normalizedRole.isEmpty) {
      return false;
    }

    final Set<String> roles = await getRealmRoles();
    return roles.contains(normalizedRole);
  }

  Future<List<String>> getUserPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_userDataKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String>[];
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String>[];
      }

      final dynamic permissoes = decoded['permissoes'];
      if (permissoes is! List) {
        return <String>[];
      }

      return permissoes
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    } catch (_) {
      return <String>[];
    }
  }

  Future<String> getUserProfileType() async {
    final List<String> permissions = await getUserPermissions();
    final Set<String> normalized =
        permissions
            .map(
              (String item) =>
                  item
                      .trim()
                      .replaceAll('-', '_')
                      .replaceAll(' ', '_')
                      .toUpperCase(),
            )
            .toSet();

    if (normalized.contains('ADMINISTRADOR') || normalized.contains('TODAS')) {
      return 'ADMIN';
    }

    if (normalized.isNotEmpty) {
      return 'COLABORADOR';
    }

    return 'DESCONHECIDO';
  }
}
