import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/network/logging_interceptor.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/catalogo_publico_link_model.dart';

class CatalogoPublicoService {
  CatalogoPublicoService({InterceptedClient? client})
    : _client =
          client ??
          InterceptedClient.build(interceptors: [LoggingInterceptor()]);

  final InterceptedClient _client;

  String get _endpoint =>
      '${AppConfig.baseUrl}/private/api/catalogo-publico/link';

  Future<CatalogoPublicoLinkModel> gerarOuObterLink({
    String? baseUrl,
  }) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getAccessToken();
    final String? empresaId = await authService.getEmpresaId();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Sessão inválida para gerar o link do catálogo.');
    }
    if (empresaId == null || empresaId.trim().isEmpty) {
      throw Exception('Selecione um comércio para gerar o link do catálogo.');
    }

    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId,
    };
    final String? baseUrlNormalizada = baseUrl?.trim();
    final String body = jsonEncode(<String, String>{
      if (baseUrlNormalizada != null && baseUrlNormalizada.isNotEmpty)
        'baseUrl': baseUrlNormalizada,
    });

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Não foi possível gerar o link do catálogo (${response.statusCode}).',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao gerar o link do catálogo.');
    }

    final CatalogoPublicoLinkModel link =
        CatalogoPublicoLinkModel.fromJson(decoded);
    final Uri? linkUri = Uri.tryParse(link.url);
    if (link.token.isEmpty ||
        linkUri == null ||
        !linkUri.hasScheme ||
        !<String>{'http', 'https'}.contains(linkUri.scheme)) {
      throw Exception('O backend retornou um link de catálogo inválido.');
    }
    return link;
  }
}
