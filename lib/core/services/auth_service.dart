import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  void _log(String message) {
    debugPrint('[AuthService] $message');
  }

  String _truncate(String? value, {int max = 300}) {
    if (value == null) return 'null';
    if (value.length <= max) return value;
    return '${value.substring(0, max)}... [truncado]';
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'vazio/null';
    if (token.length <= 20) return '***';
    return '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
  }

  Future<AuthResponseModel?> login(String login, String senha) async {
    final String pathLogin = kIsWeb ? 'web' : 'mobile';
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/$pathLogin/login');

    _log('========================================');
    _log('LOGIN INICIADO');
    _log('Plataforma: ${kIsWeb ? "WEB" : "MOBILE"}');
    _log('URL: $uri');
    _log('Login enviado: $login');

    final requestBody = jsonEncode({
      'login': login,
      'senha': senha,
    });

    _log('Body enviado: ${_truncate(requestBody)}');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      _log('LOGIN RESPONSE STATUS: ${response.statusCode}');
      _log('LOGIN RESPONSE HEADERS: ${response.headers}');
      if (kIsWeb && response.headers.containsKey('set-cookie')) {
        _log('LOGIN SET-COOKIE (WEB): ${response.headers['set-cookie']}');
      }
      _log('LOGIN RESPONSE BODY: ${_truncate(response.body, max: 1000)}');

      // Se na Web o refresh_token veio no Set-Cookie no login, vamos extrair também
      if (kIsWeb && response.headers.containsKey('set-cookie')) {
        final setCookie = response.headers['set-cookie']!;
        _log('Analisando Set-Cookie (LOGIN) para extrair refresh_token...');
        final regExp = RegExp(r'refresh_token=([^;]+)');
        final match = regExp.firstMatch(setCookie);
        if (match != null) {
          final extractedToken = match.group(1);
          if (extractedToken != null && extractedToken.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_refreshTokenKey, extractedToken);
            _log('RefreshToken EXTRAÍDO do Set-Cookie (LOGIN) e salvo no storage');
          }
        }
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _log('LOGIN JSON DECODED: $decoded');

        final authData = AuthResponseModel.fromJson(decoded);

        _log('LOGIN PARSEADO COM SUCESSO');
        _log('accessToken recebido? ${authData.accessToken.isNotEmpty}');
        _log('accessToken(masked): ${_maskToken(authData.accessToken)}');
        _log('refreshToken recebido? ${authData.refreshToken.isNotEmpty}');
        _log('refreshToken(masked): ${_maskToken(authData.refreshToken)}');
        _log('empresaIds: ${authData.idUnicoDaEmpresa}');
        _log('usuario id: ${authData.usuario.id}');
        _log('usuario keycloakId: ${authData.usuario.keycloakId}');

        await _saveAuthData(authData);
        _startRefreshTimer();

        _log('LOGIN FINALIZADO COM SUCESSO');
        _log('========================================');

        return authData;
      } else {
        _log('LOGIN FALHOU COM STATUS != 200');
        _log('========================================');

        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Falha ao realizar login',
        );
      }
    } catch (e, stack) {
      _log('EXCEÇÃO NO LOGIN: $e');
      _log('STACK: $stack');
      _log('========================================');
      rethrow;
    }
  }

  Future<void> refreshToken() async {
    final String pathLogin = kIsWeb ? 'web' : 'mobile';
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/$pathLogin/refresh');

    _log('----------------------------------------');
    _log('REFRESH INICIADO');
    _log('Plataforma: ${kIsWeb ? "WEB" : "MOBILE"}');
    _log('URL: $uri');

    http.Response response;

    try {
      final String? refreshTokenStr = await getRefreshToken();

      if (kIsWeb) {
        _log('Modo WEB: enviando refreshToken no header Cookie');

        final Map<String, String> headers = {
          'Content-Type': 'application/json',
        };

        if (refreshTokenStr != null && refreshTokenStr.isNotEmpty) {
          headers['Cookie'] = 'refresh_token=$refreshTokenStr';
          _log('Modo WEB: Cookie refresh_token adicionado');
        } else {
          _log('Modo WEB: AVISO: refresh_token não encontrado no storage');
        }

        response = await http.post(
          uri,
          headers: headers,
        );
      } else {
        _log('Modo MOBILE: refreshToken recuperado do storage? ${refreshTokenStr != null && refreshTokenStr.isNotEmpty}');
        _log('Modo MOBILE: refreshToken(masked): ${_maskToken(refreshTokenStr)}');

        if (refreshTokenStr == null || refreshTokenStr.isEmpty) {
          _log('REFRESH ABORTADO: refresh token não encontrado no mobile');
          throw Exception('No refresh token found');
        }

        final requestBody = jsonEncode({
          'refreshToken': refreshTokenStr,
        });

        _log('Modo MOBILE: body enviado no refresh: ${_truncate(requestBody)}');

        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: requestBody,
        );
      }

      _log('REFRESH RESPONSE STATUS: ${response.statusCode}');
      _log('REFRESH RESPONSE HEADERS: ${response.headers}');
      if (kIsWeb && response.headers.containsKey('set-cookie')) {
        _log('REFRESH SET-COOKIE (WEB): ${response.headers['set-cookie']}');
      }
      _log('REFRESH RESPONSE BODY: ${_truncate(response.body, max: 1000)}');

      // Se na Web o refresh_token veio no Set-Cookie, vamos tentar extrair o valor
      // para garantir que tenhamos ele no storage para a próxima chamada,
      // caso o backend não envie no body JSON.
      if (kIsWeb && response.headers.containsKey('set-cookie')) {
        final setCookie = response.headers['set-cookie']!;
        _log('Analisando Set-Cookie para extrair refresh_token...');
        final regExp = RegExp(r'refresh_token=([^;]+)');
        final match = regExp.firstMatch(setCookie);
        if (match != null) {
          final extractedToken = match.group(1);
          if (extractedToken != null && extractedToken.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_refreshTokenKey, extractedToken);
            _log('RefreshToken EXTRAÍDO do Set-Cookie e salvo no storage');
          }
        }
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _log('REFRESH JSON DECODED: $decoded');

        final authData = AuthResponseModel.fromJson(decoded);

        _log('REFRESH PARSEADO COM SUCESSO');
        _log('novo accessToken recebido? ${authData.accessToken.isNotEmpty}');
        _log('novo accessToken(masked): ${_maskToken(authData.accessToken)}');
        _log('novo refreshToken recebido? ${authData.refreshToken.isNotEmpty}');
        _log('novo refreshToken(masked): ${_maskToken(authData.refreshToken)}');

        await _saveAuthData(authData);
        _startRefreshTimer();

        _log('REFRESH FINALIZADO COM SUCESSO');
        _log('----------------------------------------');
      } else {
        _log('REFRESH FALHOU. VOU EXECUTAR LOGOUT.');
        await logout();
        _log('----------------------------------------');
        throw Exception('Falha ao atualizar token');
      }
    } catch (e, stack) {
      _log('EXCEÇÃO NO REFRESH: $e');
      _log('STACK: $stack');
      _log('----------------------------------------');
      rethrow;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();

    _log('Configurando timer de refresh automático para 4 minutos');

    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      _log('TIMER DISPARADO: iniciando refresh automático');
      try {
        await refreshToken();
        _log('Sucesso no refresh automático');
      } catch (e) {
        _log('Erro no refresh automático: $e');
      }
    });
  }

  Future<void> _saveAuthData(AuthResponseModel authData) async {
    final prefs = await SharedPreferences.getInstance();

    _log('SALVANDO DADOS DE AUTENTICAÇÃO');
    _log('Plataforma ao salvar: ${kIsWeb ? "WEB" : "MOBILE"}');
    _log('Salvando accessToken(masked): ${_maskToken(authData.accessToken)}');

    await prefs.setString(_accessTokenKey, authData.accessToken);
    await prefs.setString(_userDataKey, jsonEncode(authData.usuario.toJson()));

    if (authData.idUnicoDaEmpresa.isNotEmpty) {
      await prefs.setString(_empresaIdKey, authData.idUnicoDaEmpresa.first);
      _log('EmpresaId salvo: ${authData.idUnicoDaEmpresa.first}');
    } else {
      _log('Nenhum idUnicoDaEmpresa recebido para salvar');
    }

    if (authData.refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, authData.refreshToken);
      _log('RefreshToken novo salvo no storage');
    } else {
      final existingRefreshToken = prefs.getString(_refreshTokenKey);
      if (existingRefreshToken != null && existingRefreshToken.isNotEmpty) {
        _log('RefreshToken NÃO recebido no body, mantendo o anterior no storage');
      } else {
        _log('RefreshToken NÃO salvo no storage (vazio e nenhum anterior encontrado)');
      }
    }

    final savedAccessToken = prefs.getString(_accessTokenKey);
    final savedRefreshToken = prefs.getString(_refreshTokenKey);
    final savedEmpresaId = prefs.getString(_empresaIdKey);
    final savedUserData = prefs.getString(_userDataKey);

    _log('VALIDAÇÃO PÓS-SAVE');
    _log('accessToken salvo? ${savedAccessToken != null && savedAccessToken.isNotEmpty}');
    _log('refreshToken salvo? ${savedRefreshToken != null && savedRefreshToken.isNotEmpty}');
    _log('empresaId salvo? ${savedEmpresaId != null && savedEmpresaId.isNotEmpty}');
    _log('userData salvo? ${savedUserData != null && savedUserData.isNotEmpty}');
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    _log('getAccessToken -> ${_maskToken(token)}');
    return token;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_refreshTokenKey);
    _log('getRefreshToken -> ${_maskToken(token)}');
    return token;
  }

  Future<UsuarioModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(_userDataKey);

    _log('getUserData -> existe? ${userDataString != null}');

    if (userDataString != null) {
      final user = UsuarioModel.fromJson(jsonDecode(userDataString));
      _log('getUserData -> usuario id: ${user.id}');
      return user;
    }
    return null;
  }

  Future<String?> getEmpresaId() async {
    final prefs = await SharedPreferences.getInstance();
    final empresaId = prefs.getString(_empresaIdKey);
    _log('getEmpresaId -> $empresaId');
    return empresaId;
  }

  Future<void> logout() async {
    _log('LOGOUT INICIADO');
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_empresaIdKey);

    _log('LOGOUT FINALIZADO. STORAGE LIMPO.');
  }
}