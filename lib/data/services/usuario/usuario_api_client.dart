
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/auth_response_model.dart';

abstract class UsuarioApiClient {
  Future<UsuarioModel> getUsuario();
}

class HttpUsuarioApiClient implements UsuarioApiClient {
  HttpUsuarioApiClient({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<UsuarioModel> getUsuario() async {

    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-pessoais');

    final response = await _httpClient.get(
      uri,
      headers: {
        'idUnicoDaEmpresa': idUnicoDaEmpresa!,
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode != 200) {
      throw UsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    return UsuarioModel.fromJson(json);
  }
}

class UsuarioApiException implements Exception {
UsuarioApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'UsuarioApiException(statusCode: $statusCode, body: $body)';
  }
}
