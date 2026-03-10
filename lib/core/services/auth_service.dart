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

  Future<AuthResponseModel?> login(String login, String senha) async {

    var pathLogin;

    kIsWeb
        ? pathLogin = 'web'
        : pathLogin = 'mobile';

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/${pathLogin}/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'login': login,
        'senha': senha,
      }),
    );

    if (response.statusCode == 200) {
      final authData = AuthResponseModel.fromJson(jsonDecode(response.body));
      await _saveAuthData(authData);
      _startRefreshTimer();
      return authData;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Falha ao realizar login');
    }
  }

  Future<void> refreshToken() async {
    final String? refreshToken = await getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token found');

    String pathLogin = kIsWeb ? 'web' : 'mobile';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    dynamic body;

    if (pathLogin == 'mobile') {
      body = jsonEncode({
        'refreshToken': refreshToken,
      });
    } else {
      headers['Cookie'] = 'refresh_token=$refreshToken';
      body = '';
    }

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/$pathLogin/refresh'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final authData = AuthResponseModel.fromJson(jsonDecode(response.body));
      await _saveAuthData(authData);
      _startRefreshTimer();
    } else {
      await logout();
      throw Exception('Falha ao atualizar token');
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      try {
        await refreshToken();
        debugPrint('Sucesso no refresh automático');
      } catch (e) {
        debugPrint('Erro no refresh automático: $e');
      }
    });
  }

  Future<void> _saveAuthData(AuthResponseModel authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, authData.accessToken);
    await prefs.setString(_refreshTokenKey, authData.refreshToken);
    await prefs.setString(_userDataKey, jsonEncode(authData.usuario.toJson()));
    if (authData.idUnicoDaEmpresa.isNotEmpty) {
      await prefs.setString(_empresaIdKey, authData.idUnicoDaEmpresa.first);
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

  Future<UsuarioModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return UsuarioModel.fromJson(jsonDecode(userDataString));
    }
    return null;
  }

  Future<String?> getEmpresaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_empresaIdKey);
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_empresaIdKey);
  }
}
