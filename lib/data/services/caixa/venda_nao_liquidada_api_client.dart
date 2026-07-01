import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/venda_nao_liquidada_models.dart';

class VendaNaoLiquidadaApiClient {
  VendaNaoLiquidadaApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<List<VendaNaoLiquidadaModel>> listar() async {
    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/vendas-nao-liquidadas');
    final response = await _httpClient.get(
      uri,
      headers: {
        'idUnicoDaEmpresa': idUnicoDaEmpresa ?? '',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode != 200) {
      throw VendaNaoLiquidadaApiException(statusCode: response.statusCode, body: response.body);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <VendaNaoLiquidadaModel>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(VendaNaoLiquidadaModel.fromJson)
        .toList(growable: false);
  }

  Future<VendaNaoLiquidadaModel> liquidar({
    required String idRecebimento,
    required LiquidarVendaNaoLiquidadaInput input,
  }) async {
    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/vendas-nao-liquidadas/$idRecebimento/liquidar');
    final response = await _httpClient.post(
      uri,
      headers: {
        'idUnicoDaEmpresa': idUnicoDaEmpresa ?? '',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode != 200) {
      throw VendaNaoLiquidadaApiException(statusCode: response.statusCode, body: response.body);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw VendaNaoLiquidadaApiException(statusCode: response.statusCode, body: response.body);
    }
    return VendaNaoLiquidadaModel.fromJson(decoded);
  }
}

class VendaNaoLiquidadaApiException implements Exception {
  VendaNaoLiquidadaApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'VendaNaoLiquidadaApiException(statusCode: $statusCode, body: $body)';
}
