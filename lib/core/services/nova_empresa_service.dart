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

  /// Cria a empresa e o usuário administrador.
  ///
  /// Fluxo temporariamente simplificado: apenas [login] e [senha] são
  /// obrigatórios. Campos adicionais continuam opcionais para manter
  /// compatibilidade com chamadas antigas.
  Future<void> criarNovaEmpresa({
    String? login,
    String? email,
    required String senha,
    String? nome,
    String? sobrenome,
    String? celular,
    String? username,
    String? comercioId,
    List<String> permissoes = const ['ADMINISTRADOR'],
  }) async {
    final identificador = (login ?? username ?? email ?? celular ?? '').trim();
    if (identificador.isEmpty) {
      throw Exception('Informe o login para criar a conta.');
    }

    final emailNormalizado = (email ?? '').trim();
    final payload = <String, dynamic>{
      'login': identificador,
      'username': (username == null || username.trim().isEmpty)
          ? identificador
          : username.trim(),
      'senha': senha,
      'senhaInicial': senha,
      'permissoes': permissoes,
      if (emailNormalizado.isNotEmpty) 'email': emailNormalizado,
      if (emailNormalizado.isEmpty && identificador.contains('@'))
        'email': identificador,
      if (nome != null && nome.isNotEmpty) 'nome': nome,
      if (sobrenome != null && sobrenome.isNotEmpty) 'sobrenome': sobrenome,
      if (celular != null && celular.isNotEmpty) 'celular': celular,
      if (comercioId != null && comercioId.isNotEmpty) 'comercioId': comercioId,
    };

    final response = await _client.post(
      _endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    // Mantém compatibilidade com fluxos antigos enquanto o backend ainda pode
    // responder erros de OTP em ambientes não atualizados.
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
}
