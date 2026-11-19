import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../exceptions/recuperacao_senha_exception.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class RecuperacaoSenhaService {
  RecuperacaoSenhaService({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Uri get _enviarCodigoUri =>
      Uri.parse('${AppConfig.baseUrl}/public/api/esqueceu-senha/enviar-codigo');

  Uri get _validarCodigoUri => Uri.parse(
    '${AppConfig.baseUrl}/public/api/esqueceu-senha/validar-codigo',
  );

  Uri get _redefinirSenhaUri => Uri.parse(
    '${AppConfig.baseUrl}/public/api/esqueceu-senha/redefinir-senha',
  );

  Future<void> enviarCodigo(
    String email, {
    String languageCode = 'pt',
    bool contaAutenticada = false,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept-Language': languageCode,
    };
    Uri destino = _enviarCodigoUri;
    if (contaAutenticada) {
      final token = await AuthService().getAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw const RecuperacaoSenhaException(
          code: RecuperacaoSenhaErrorCode.emailDaContaIndisponivel,
          message: 'Sessão indisponível.',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
      destino = Uri.parse(
        '${AppConfig.baseUrl}/private/api/usuario/troca-senha/enviar-codigo',
      );
    }

    final response = await _client
        .post(destino, headers: headers, body: jsonEncode({'email': email}))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (contaAutenticada && response.statusCode == 401) {
      throw const RecuperacaoSenhaException(
        code: RecuperacaoSenhaErrorCode.emailDaContaIndisponivel,
        message: 'Sessão indisponível.',
        statusCode: 401,
      );
    }

    throw RecuperacaoSenhaException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Future<void> validarCodigo({
    required String email,
    required String codigo,
  }) async {
    final response = await _client
        .post(
          _validarCodigoUri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'codigo': codigo}),
        )
        .timeout(const Duration(seconds: 30));

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
    String languageCode = 'pt',
  }) async {
    final response = await _client
        .post(
          _redefinirSenhaUri,
          headers: {
            'Content-Type': 'application/json',
            'Accept-Language': languageCode,
          },
          body: jsonEncode({
            'email': email,
            'codigo': codigo,
            'novaSenha': novaSenha,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw RecuperacaoSenhaException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
