import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../exceptions/registro_otp_exception.dart';
import 'http_client_factory.dart';

class RegistroOtpService {
  RegistroOtpService({http.Client? client})
      : _client = client ?? createHttpClient();

  final http.Client _client;

  Uri get _enviarCodigoUri =>
      Uri.parse('${AppConfig.baseUrl}/public/api/registro/enviar-codigo');

  Uri get _validarCodigoUri =>
      Uri.parse('${AppConfig.baseUrl}/public/api/registro/validar-codigo');

  /// Dispara o envio do código OTP de 6 dígitos para o e-mail informado.
  Future<void> enviarCodigo(String email) async {
    final response = await _client.post(
      _enviarCodigoUri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw RegistroOtpException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  /// Valida o código OTP. Em caso de sucesso o backend responde 204.
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

    throw RegistroOtpException.fromResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
