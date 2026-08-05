import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/usuario_model.dart';

abstract class UsuarioApiClient {
  Future<UsuarioModel> buscarDadosPessoais();

  Future<UsuarioModel?> atualizarDadosPessoais(UsuarioModel usuario);

  Future<void> atualizarPreferenciasIndividuais(Map<String, dynamic> body);
}

class HttpUsuarioApiClient implements UsuarioApiClient {
  HttpUsuarioApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? createHttpClient();

  final http.Client _httpClient;
  final AuthService _authService = AuthService();

  static final Uri _dadosPessoaisUri = Uri.parse(
    '${AppConfig.baseUrl}/private/api/dados-pessoais',
  );

  static final Uri _preferenciasUri = Uri.parse(
    '${AppConfig.baseUrl}/private/api/dados-pessoais/preferencias',
  );

  @override
  Future<UsuarioModel> buscarDadosPessoais() async {
    final http.Response response = await _httpClient.get(
      _dadosPessoaisUri,
      headers: await _headers(acceptOnly: true),
    );

    if (response.statusCode != 200) {
      throw UsuarioApiException(statusCode: response.statusCode);
    }

    return _decodeUsuario(response.body);
  }

  @override
  Future<UsuarioModel?> atualizarDadosPessoais(UsuarioModel usuario) async {
    final http.Response response = await _httpClient.put(
      _dadosPessoaisUri,
      headers: await _headers(),
      body: jsonEncode(usuario.toJson()),
    );

    if (response.statusCode == 204) {
      return null;
    }

    if (response.statusCode != 200) {
      throw UsuarioApiException(statusCode: response.statusCode);
    }

    return _decodeUsuario(response.body);
  }

  @override
  Future<void> atualizarPreferenciasIndividuais(
    Map<String, dynamic> body,
  ) async {
    final http.Response response = await _httpClient.patch(
      _preferenciasUri,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw UsuarioApiException(statusCode: response.statusCode);
    }
  }

  Future<Map<String, String>> _headers({bool acceptOnly = false}) async {
    final String? token = await _authService.getAccessToken();
    final String? empresaId = await _authService.getEmpresaId();

    if (token == null ||
        token.trim().isEmpty ||
        empresaId == null ||
        empresaId.trim().isEmpty) {
      throw const UsuarioApiException(statusCode: 401);
    }

    return <String, String>{
      if (!acceptOnly) 'Content-Type': 'application/json',
      'accept': 'application/json',
      'idUnicoDaEmpresa': empresaId,
      'Authorization': 'Bearer $token',
    };
  }

  UsuarioModel _decodeUsuario(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const UsuarioApiException(statusCode: 0);
    }

    return UsuarioModel.fromJson(decoded);
  }
}

class UsuarioApiException implements Exception {
  const UsuarioApiException({required this.statusCode});

  final int statusCode;

  @override
  String toString() => 'UsuarioApiException(statusCode: $statusCode)';
}
