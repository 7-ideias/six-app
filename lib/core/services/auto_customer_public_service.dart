import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'http_client_factory.dart';

class AutoCustomerPublicResponse {
  const AutoCustomerPublicResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

class AutoCustomerPublicService {
  AutoCustomerPublicService({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Uri get _endpoint =>
      Uri.parse('${AppConfig.baseUrl}/public/api/auto-customer');

  Future<AutoCustomerPublicResponse> enviarAutoCadastro({
    required String idUnicoDaEmpresa,
    required String token,
    required String tipoPessoa,
    required String documento,
    required String nome,
    required String telefone,
    required String email,
    required String enderecoCompleto,
    required String observacoes,
    required Uri origem,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'idUnicoDaEmpresa': idUnicoDaEmpresa,
      'token': token,
      'tipoPessoa': tipoPessoa,
      'documento': documento,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'enderecoCompleto': enderecoCompleto,
      'observacoes': observacoes,
      'origem': origem.toString(),
      'enviadoEm': DateTime.now().toUtc().toIso8601String(),
    };

    final http.Response response = await _client.post(
      _endpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'idUnicoDaEmpresa': idUnicoDaEmpresa,
      },
      body: jsonEncode(payload),
    );

    return AutoCustomerPublicResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
