
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/operacao_models.dart';

abstract class OperacaoApiClient {
  Future<OperacaoInserirResponse> inserirOperacao({
    required OperacaoInserirRequest request,
  });
}

class HttpOperacaoApiClient implements OperacaoApiClient {
  HttpOperacaoApiClient({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<OperacaoInserirResponse> inserirOperacao({
    required OperacaoInserirRequest request,
  }) async {

    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    final uri = Uri.parse('${AppConfig.baseUrl}/operacao/inserir');

    final response = await _httpClient.post(
      uri,
      headers: {
        'idUnicoDaEmpresa': idUnicoDaEmpresa!!,
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 201) {
      throw OperacaoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    return OperacaoInserirResponse.fromJson(json);
  }
}

class OperacaoApiException implements Exception {
  OperacaoApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'OperacaoApiException(statusCode: $statusCode, body: $body)';
  }
}
