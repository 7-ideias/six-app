import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class AutoCustomerTokenApiResponse {
  const AutoCustomerTokenApiResponse({
    required this.statusCode,
    required this.body,
    required this.message,
    required this.code,
    required this.token,
    required this.link,
    required this.expiracao,
  });

  final int statusCode;
  final String body;
  final String message;
  final String code;
  final String token;
  final String link;
  final String expiracao;

  bool get isSuccess => statusCode == 201;
}

class AutoCustomerTokenService {
  AutoCustomerTokenService({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Uri get _endpoint =>
      Uri.parse('${AppConfig.baseUrl}/private/api/auto-customer/token');

  Future<AutoCustomerTokenApiResponse> gerarToken({
    required String idUnicoDaEmpresa,
    required String tipoPessoa,
    String? documento,
    int? validadeMinutos,
    String? baseUrl,
  }) async {
    final String empresaId = idUnicoDaEmpresa.trim();
    if (empresaId.isEmpty) {
      throw Exception('idUnicoDaEmpresa não informado.');
    }

    final AuthService authService = AuthService();
    final String? accessToken = await authService.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw Exception('Token de autenticação não encontrado.');
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'tipoPessoa': tipoPessoa.trim().toUpperCase(),
    };

    final String documentoLimpo = (documento ?? '').trim();
    if (documentoLimpo.isNotEmpty) {
      body['documento'] = documentoLimpo;
    }

    if (validadeMinutos != null) {
      body['validadeMinutos'] = validadeMinutos;
    }

    final String baseUrlLimpa = (baseUrl ?? '').trim();
    if (baseUrlLimpa.isNotEmpty) {
      body['baseUrl'] = baseUrlLimpa;
    }

    final http.Response response = await _client.post(
      _endpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'idUnicoDaEmpresa': empresaId,
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      try {
        final Object json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          decoded = json;
        }
      } catch (_) {}
    }

    return AutoCustomerTokenApiResponse(
      statusCode: response.statusCode,
      body: response.body,
      message: (decoded['message'] ?? decoded['mensagem'] ?? '').toString(),
      code: (decoded['code'] ?? '').toString(),
      token: (decoded['token'] ?? '').toString(),
      link: (decoded['link'] ?? '').toString(),
      expiracao: (decoded['expiracao'] ?? '').toString(),
    );
  }
}
