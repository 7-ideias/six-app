import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../data/models/atendimento_mobile_assets_model.dart';
import '../../data/models/perfil_negocio_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class PerfilNegocioException implements Exception {
  const PerfilNegocioException(this.statusCode, [this.code]);
  final int statusCode;
  final String? code;
}

class PerfilNegocioService {
  PerfilNegocioService({AuthService? authService, http.Client? client})
    : _auth = authService ?? AuthService(),
      _client = client ?? createHttpClient();
  final AuthService _auth;
  final http.Client _client;

  Future<String> empresaAtual() async {
    final id = await _auth.getEmpresaId();
    if (id == null || id.trim().isEmpty) {
      throw const PerfilNegocioException(401);
    }
    return id;
  }

  Future<PerfilNegocioEmpresaModel> buscar(String empresaId) async =>
      PerfilNegocioEmpresaModel.fromJson(
        await _request('GET', '/perfil-negocio', empresaId),
      );

  Future<CatalogoPerfilNegocioModel> catalogo(String empresaId) async =>
      CatalogoPerfilNegocioModel.fromJson(
        await _request('GET', '/perfil-negocio/catalogo', empresaId),
      );

  Future<HomeBannersModel> banners(String empresaId) async =>
      HomeBannersModel.fromJson(
        await _request('GET', '/home/banners', empresaId),
      );

  Future<AtendimentoMobileAssetsModel> atendimentoMobileAssets(
    String empresaId,
  ) async => AtendimentoMobileAssetsModel.fromJson(
    await _request('GET', '/atendimento-mobile/assets', empresaId),
  );

  Future<PerfilNegocioEmpresaModel> salvar(
    String empresaId,
    AtualizarPerfilNegocioRequest request,
  ) async => PerfilNegocioEmpresaModel.fromJson(
    await _request('PUT', '/perfil-negocio', empresaId, request.toJson()),
  );

  Future<Map<String, dynamic>> _request(
    String method,
    String path,
    String empresaId, [
    Map<String, dynamic>? body,
  ]) async {
    if (await empresaAtual() != empresaId) {
      throw const PerfilNegocioException(409, 'CONTEXTO_EMPRESA_ALTERADO');
    }
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) throw const PerfilNegocioException(401);
    final headers = <String, String>{
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
      'idUnicoDaEmpresa': empresaId,
      if (body != null) 'Content-Type': 'application/json',
    };
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api$path');
    final http.Response response;
    try {
      response = await (method == 'PUT'
              ? _client.put(uri, headers: headers, body: jsonEncode(body))
              : _client.get(uri, headers: headers))
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const PerfilNegocioException(0, 'TIMEOUT');
    }
    // Uma resposta da empresa anterior nunca substitui o contexto atualmente selecionado.
    if (await empresaAtual() != empresaId)
      throw const PerfilNegocioException(409, 'CONTEXTO_EMPRESA_ALTERADO');
    if (response.statusCode != 200) {
      String? code;
      try {
        final dynamic error = jsonDecode(utf8.decode(response.bodyBytes));
        if (error is Map) {
          code =
              (error['codigo'] ?? error['code'] ?? error['reason'])?.toString();
        }
      } catch (_) {
        // Não exibir HTML, stacktrace ou texto cru do servidor ao usuário.
      }
      throw PerfilNegocioException(response.statusCode, code);
    }
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const PerfilNegocioException(0, 'RESPOSTA_INVALIDA');
    }
    return decoded;
  }

  void dispose() => _client.close();
}
