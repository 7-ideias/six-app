import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../exceptions/recuperacao_senha_exception.dart';
import 'http_client_factory.dart';

class RecuperacaoSenhaService {
  RecuperacaoSenhaService({http.Client? client})
      : _client = client ?? createHttpClient();

  final http.Client _client;

  Uri get _enviarCodigoUri =>
      Uri.parse('${AppConfig.baseUrl}/public/api/esqueceu-senha/enviar-codigo');

  Uri get _validarCodigoUri =>
      Uri.parse('${AppConfig.baseUrl}/public/api/esqueceu-senha/validar-codigo');

  Uri get _redefinirSenhaUri =>
      Uri.parse('${AppConfig.baseUrl}/public/api/esqueceu-senha/redefinir-senha');

  Future<void> enviarCodigo(String email) async {
    final response = await _client.post(
      _enviarCodigoUri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw RecuperacaoSenhaException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Future<void> validarCodigo({
    required String email,
    required String codigo,
  }) async {
    final response = await _client.post(
      _validarCodigoUri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'codigo': codigo}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw RecuperacaoSenhaException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final response = await _client.post(
      _redefinirSenhaUri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'codigo': codigo,
        'novaSenha': novaSenha,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw RecuperacaoSenhaException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
