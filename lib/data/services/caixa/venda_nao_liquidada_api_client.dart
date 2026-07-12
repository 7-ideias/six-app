import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/loading_do_mobile_comunicando_com_backend_controller.dart';
import '../../models/venda_nao_liquidada_models.dart';

class VendaNaoLiquidadaApiClient {
  VendaNaoLiquidadaApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

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

  Future<List<VendaNaoLiquidadaModel>> listar() async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/caixa/vendas-nao-liquidadas',
    );
    final response = await _httpClient.get(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw VendaNaoLiquidadaApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
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
  }) {
    return LoadingDoMobileComunicandoComBackendController.track(() async {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/private/api/caixa/vendas-nao-liquidadas/$idRecebimento/liquidar',
      );
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(input.toJson()),
      );

      if (response.statusCode != 200) {
        throw VendaNaoLiquidadaApiException(
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VendaNaoLiquidadaApiException(
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      return VendaNaoLiquidadaModel.fromJson(decoded);
    });
  }

  Future<void> cancelar({required String idRecebimento}) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/caixa/vendas-nao-liquidadas/$idRecebimento/cancelar',
    );
    final response = await _httpClient.post(uri, headers: await _getHeaders());

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw VendaNaoLiquidadaApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

class VendaNaoLiquidadaApiException implements Exception {
  VendaNaoLiquidadaApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'VendaNaoLiquidadaApiException(statusCode: $statusCode, body: $body)';
  }
}
