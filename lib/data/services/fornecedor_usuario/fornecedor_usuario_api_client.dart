import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/http_client_factory.dart';
import 'package:sixpos/data/models/fornecedor_usuario_model.dart';

abstract class FornecedorUsuarioApiClient {
  Future<List<FornecedorUsuario>> listar();
  Future<FornecedorUsuario> buscar(String id);
  Future<FornecedorUsuario> cadastrar(FornecedorUsuarioDraft fornecedor);
  Future<FornecedorUsuario> atualizar(String id, FornecedorUsuarioDraft fornecedor);
}

class HttpFornecedorUsuarioApiClient implements FornecedorUsuarioApiClient {
  HttpFornecedorUsuarioApiClient({
    http.Client? httpClient,
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? empresaIdProvider,
  }) : _httpClient = httpClient ?? createHttpClient(),
       _accessTokenProvider = accessTokenProvider ?? AuthService().getAccessToken,
       _empresaIdProvider = empresaIdProvider ?? AuthService().getEmpresaId;

  final http.Client _httpClient;
  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _empresaIdProvider;

  Future<Map<String, String>> _headers() async {
    final token = (await _accessTokenProvider())?.trim() ?? '';
    final empresa = (await _empresaIdProvider())?.trim() ?? '';
    if (token.isEmpty || empresa.isEmpty) {
      throw StateError('Selecione um comércio e entre na sua conta.');
    }
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'idUnicoDaEmpresa': empresa,
    };
  }

  Uri _uri([String path = '']) =>
      Uri.parse('${AppConfig.baseUrl}/private/api/fornecedores$path');

  @override
  Future<List<FornecedorUsuario>> listar() async {
    final response = await _httpClient.get(_uri(), headers: await _headers());
    _validar(response);
    final data = jsonDecode(response.body);
    if (data is! List) throw FormatException('Resposta de fornecedores inválida.');
    return data
        .whereType<Map<String, dynamic>>()
        .map(FornecedorUsuario.fromJson)
        .toList(growable: false);
  }

  @override
  Future<FornecedorUsuario> buscar(String id) async =>
      _lerFornecedor(await _httpClient.get(_uri('/${Uri.encodeComponent(id)}'),
          headers: await _headers()));

  @override
  Future<FornecedorUsuario> cadastrar(FornecedorUsuarioDraft fornecedor) async =>
      _lerFornecedor(await _httpClient.post(_uri(),
          headers: await _headers(), body: jsonEncode(fornecedor.toJson())));

  @override
  Future<FornecedorUsuario> atualizar(String id, FornecedorUsuarioDraft fornecedor) async =>
      _lerFornecedor(await _httpClient.put(_uri('/${Uri.encodeComponent(id)}'),
          headers: await _headers(), body: jsonEncode(fornecedor.toJson())));

  FornecedorUsuario _lerFornecedor(http.Response response) {
    _validar(response);
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) throw FormatException('Fornecedor inválido.');
    return FornecedorUsuario.fromJson(data);
  }

  void _validar(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FornecedorUsuarioApiException(response.statusCode, response.body);
    }
  }
}

class FornecedorUsuarioApiException implements Exception {
  const FornecedorUsuarioApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => switch (statusCode) {
    400 => 'Verifique os campos obrigatórios do fornecedor.',
    401 => 'Sua sessão expirou. Entre novamente.',
    403 => 'Você não tem acesso a este comércio.',
    404 => 'Fornecedor não encontrado neste comércio.',
    409 => 'Já existe um fornecedor com este documento neste comércio.',
    _ => 'Não foi possível concluir a operação (HTTP $statusCode).',
  };
}
