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

class AuthService {
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _userDataKey = 'userData';
  static const String _empresaIdKey = 'idUnicoDaEmpresa';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Timer? _refreshTimer;

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

    final requestBody = jsonEncode({
      'login': login,
      'senha': senha,
    });

    debugPrint('[AuthService] POST $uri');

    final client = _client();
    final http.Response response;
    try {
      response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
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
      _startRefreshTimer();

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
    _startRefreshTimer();

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
    _startRefreshTimer();

    try {
      await EmpresaService().buscarDadosDaEmpresa();
    } catch (e) {
      debugPrint('Erro ao buscar dados da empresa: $e');
    }

    return authData;
  }

  Future<void> refreshToken() async {
    final String pathLogin = kIsWeb ? 'web' : 'mobile';
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/$pathLogin/refresh');

    final client = _client();
    http.Response response;

    if (kIsWeb) {
      response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );
    } else {
      final String? refreshTokenStr = await getRefreshToken();

      if (refreshTokenStr == null || refreshTokenStr.isEmpty) {
        throw Exception('No refresh token found');
      }

      response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshTokenStr,
        }),
      );
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final authData = AuthResponseModel.fromJson(decoded);
      await _saveAuthData(authData);
      _startRefreshTimer();
      return;
    }

    await logout();
    throw Exception('Falha ao atualizar token');
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        await refreshToken();
      } catch (_) {}
    });
  }

  Future<void> _saveAuthData(AuthResponseModel authData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, authData.accessToken);
    await prefs.setString(_userDataKey, jsonEncode(authData.usuario.toJson()));

    if (authData.idUnicoDaEmpresa.isNotEmpty) {
      await prefs.setString(_empresaIdKey, authData.idUnicoDaEmpresa.first);
    }

    if (!kIsWeb && authData.refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, authData.refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final baseUrl = AppConfig.baseUrl;
    if (baseUrl.isNotEmpty) {
      final pathLogout = kIsWeb ? 'web' : 'mobile';
      final uri = Uri.parse('$baseUrl/auth/$pathLogout/logout');
      try {
        await _client().post(
          uri,
          headers: const {'Content-Type': 'application/json'},
        );
      } catch (e) {
        debugPrint('[AuthService] logout remoto falhou: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_empresaIdKey);

    try {
      await GoogleAuthService().signOut();
    } catch (_) {}
  }

  Future<String?> getEmpresaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_empresaIdKey);
  }
}