import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../exceptions/registro_otp_exception.dart';
import 'http_client_factory.dart';

class NovaEmpresaService {
  NovaEmpresaService({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Uri get _endpoint =>
      Uri.parse('${AppConfig.baseUrl}/public/api/login/nova-empresa');

  /// Cria a empresa. Pré-requisito: o e-mail precisa ter sido verificado
  /// via fluxo de OTP (validarCodigo retornou 204) dentro da janela de 15 min.
  Future<void> criarNovaEmpresa({
    required String nome,
    required String sobrenome,
    required String email,
    required String senha,
    required String celular,
    String? username,
    String? comercioId,
    List<String> permissoes = const ['TODAS'],
  }) async {
    final payload = <String, dynamic>{
      'nome': nome,
      'sobrenome': sobrenome,
      'celular': celular,
      'email': email,
      'username': username ?? _deriveUsername(email),
      'senhaInicial': senha,
      'senha': senha,
      'permissoes': permissoes,
    };

    final response = await _client.post(
      _endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    // Se for 403/OTP_003, propaga como exceção OTP para o chamador.
    if (response.statusCode == 403) {
      throw RegistroOtpException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    throw Exception(
      'Falha ao criar empresa (${response.statusCode}): ${response.body}',
    );
  }

  static String _deriveUsername(String email) {
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }
}
