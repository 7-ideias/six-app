
import 'dart:convert';

import 'package:appplanilha/data/models/tela_inicial_models.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';

abstract class TelaInicialWebApiClient {
  Future<TelaInicialModel> getResumo();
}

class HttpResumoDaEmpresaApiClient implements TelaInicialWebApiClient {
  HttpResumoDaEmpresaApiClient({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<TelaInicialModel> getResumo() async {

    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/web/telainicial');

    final response = await _httpClient.get(
      uri,
      headers: {
        'idUnicoDaEmpresa': idUnicoDaEmpresa!,
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode != 200) {
      throw TelaInicialApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    return TelaInicialModel.fromJson(json);
  }
}

class TelaInicialApiException implements Exception {
  TelaInicialApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'TelaInicialApiException(statusCode: $statusCode, body: $body)';
  }
}
