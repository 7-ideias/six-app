import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/regionalizacao_models.dart';

abstract class RegionalizacaoApiClient {
  Future<void> salvarRegionalizacao(
      SalvarConfiguracaoRegionalizacaoRequest request,
      );
}

class HttpRegionalizacaoApiClient implements RegionalizacaoApiClient {
  HttpRegionalizacaoApiClient({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, String>> _getHeaders() async {
    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    return {
      'idUnicoDaEmpresa': idUnicoDaEmpresa ?? '',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwtToken',
    };
  }

  @override
  Future<void> salvarRegionalizacao(
      SalvarConfiguracaoRegionalizacaoRequest request,
      ) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/caixa/configuracoes/regionalizacao',
    );

    final response = await _httpClient.put(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw RegionalizacaoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

class RegionalizacaoApiException implements Exception {
  RegionalizacaoApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'RegionalizacaoApiException(statusCode: $statusCode, body: $body)';
  }
}
