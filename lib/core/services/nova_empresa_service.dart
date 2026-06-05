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

  /// Cria a empresa.
  ///
  /// Pré-requisito: o e-mail precisa ter sido verificado via fluxo de OTP
  /// (validarCodigo retornou 204) dentro da janela de 15 min.
  ///
  /// Fluxo simplificado: apenas [email] e [senha] são obrigatórios.
  /// Demais campos são opcionais; quando omitidos, o backend deriva defaults
  /// a partir do e-mail (nome=prefixo, celular=email).
  Future<void> criarNovaEmpresa({
    required String email,
    required String senha,
    String? nome,
    String? sobrenome,
    String? celular,
    String? username,
    String? comercioId,
    List<String> permissoes = const ['TODAS'],
  }) async {
    // Payload mínimo: email + senha. Campos opcionais só vão se preenchidos —
    // o backend (LoginService.normalizarParaCadastroSimplificado) aplica
    // defaults derivados do e-mail para os que vierem ausentes.
    final payload = <String, dynamic>{
      'email': email,
      'senha': senha,
      'senhaInicial': senha,
      'permissoes': permissoes,
      if (nome != null && nome.isNotEmpty) 'nome': nome,
      if (sobrenome != null && sobrenome.isNotEmpty) 'sobrenome': sobrenome,
      if (celular != null && celular.isNotEmpty) 'celular': celular,
      if (username != null && username.isNotEmpty) 'username': username,
      if (comercioId != null && comercioId.isNotEmpty)
        'comercioId': comercioId,
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
}
