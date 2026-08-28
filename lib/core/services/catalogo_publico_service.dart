import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/http_client_factory.dart';
import 'package:sixpos/data/models/catalogo_publico_configuracao_model.dart';
import 'package:sixpos/data/models/catalogo_publico_link_model.dart';

class CatalogoPublicoService {
  CatalogoPublicoService({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  String get _endpoint =>
      '${AppConfig.baseUrl}/private/api/catalogo-publico/link';

  String get _configurationEndpoint =>
      '${AppConfig.baseUrl}/private/api/catalogo-publico/configuracao';

  Future<Map<String, String>> _authenticatedHeaders() async {
    final AuthService authService = AuthService();
    final String? token = await authService.getAccessToken();
    final String? empresaId = await authService.getEmpresaId();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Sessão inválida para acessar o catálogo.');
    }
    if (empresaId == null || empresaId.trim().isEmpty) {
      throw Exception('Selecione um comércio para acessar o catálogo.');
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId,
    };
  }

  Future<CatalogoPublicoConfiguracaoModel> buscarConfiguracao({
    String? baseUrl,
  }) async {
    final Map<String, String> headers = await _authenticatedHeaders();
    final Uri uri = Uri.parse(_configurationEndpoint).replace(
      queryParameters: <String, String>{
        if (baseUrl?.trim().isNotEmpty == true) 'baseUrl': baseUrl!.trim(),
      },
    );
    final response = await _client.get(uri, headers: headers);
    return _parseConfigurationResponse(response);
  }

  Future<CatalogoPublicoConfiguracaoModel> atualizarConfiguracao({
    required bool ativo,
    required CatalogoPublicoPersonalizacaoModel personalizacao,
    String? baseUrl,
  }) async {
    final Map<String, String> headers = await _authenticatedHeaders();
    final response = await _client.patch(
      Uri.parse(_configurationEndpoint),
      headers: headers,
      body: jsonEncode(<String, dynamic>{
        if (baseUrl?.trim().isNotEmpty == true) 'baseUrl': baseUrl!.trim(),
        'ativo': ativo,
        'personalizacao': personalizacao.toJson(),
      }),
    );
    return _parseConfigurationResponse(response);
  }

  CatalogoPublicoConfiguracaoModel _parseConfigurationResponse(
    http.Response response,
  ) {
    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível salvar a página pública do catálogo '
        '(${response.statusCode}).',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida da configuração do catálogo.');
    }
    final CatalogoPublicoConfiguracaoModel configuration =
        CatalogoPublicoConfiguracaoModel.fromJson(decoded);
    final Uri? linkUri = Uri.tryParse(configuration.url);
    if (configuration.token.isEmpty ||
        linkUri == null ||
        !linkUri.hasScheme ||
        !<String>{'http', 'https'}.contains(linkUri.scheme)) {
      throw Exception('O backend retornou uma configuração inválida.');
    }
    return configuration;
  }

  Future<CatalogoPublicoLinkModel> gerarOuObterLink({String? baseUrl}) async {
    final Map<String, String> headers = await _authenticatedHeaders();
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

    final CatalogoPublicoLinkModel link = CatalogoPublicoLinkModel.fromJson(
      decoded,
    );
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
