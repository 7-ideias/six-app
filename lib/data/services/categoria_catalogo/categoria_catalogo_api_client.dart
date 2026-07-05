import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/categoria_catalogo_model.dart';

abstract class CategoriaCatalogoApiClient {
  Future<CategoriaCatalogoListResponse> listarCategorias();
  Future<CategoriaCatalogoModel> cadastrarCategoria(
    CategoriaCatalogoRequest request,
  );
  Future<CategoriaCatalogoModel> atualizarCategoria(
    String idCategoria,
    CategoriaCatalogoRequest request,
  );
  Future<void> apagarCategoria(String idCategoria);
}

class HttpCategoriaCatalogoApiClient implements CategoriaCatalogoApiClient {
  HttpCategoriaCatalogoApiClient({
    http.Client? httpClient,
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? empresaIdProvider,
  }) : _httpClient = httpClient ?? http.Client(),
       _accessTokenProvider =
           accessTokenProvider ?? AuthService().getAccessToken,
       _empresaIdProvider = empresaIdProvider ?? AuthService().getEmpresaId;
  final http.Client _httpClient;
  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _empresaIdProvider;
  Future<Map<String, String>> _headers() async {
    final String token = (await _accessTokenProvider())?.trim() ?? '';
    final String empresaId = (await _empresaIdProvider())?.trim() ?? '';
    return <String, String>{
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId,
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<CategoriaCatalogoListResponse> listarCategorias() async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/categoria-produto-servico/lista',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw CategoriaCatalogoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    if (response.body.trim().isEmpty) {
      return const CategoriaCatalogoListResponse(
        idUnicoDaEmpresa: '',
        total: 0,
        categorias: <CategoriaCatalogoModel>[],
      );
    }
    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw CategoriaCatalogoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return CategoriaCatalogoListResponse.fromJson(data);
  }

  @override
  Future<CategoriaCatalogoModel> cadastrarCategoria(
    CategoriaCatalogoRequest request,
  ) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/categoria-produto-servico/cadastro',
    );
    final http.Response response = await _httpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );
    return _parseCategoriaResponse(response);
  }

  @override
  Future<CategoriaCatalogoModel> atualizarCategoria(
    String idCategoria,
    CategoriaCatalogoRequest request,
  ) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/categoria-produto-servico/atualizacao/$idCategoria',
    );
    final http.Response response = await _httpClient.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );
    return _parseCategoriaResponse(response);
  }

  @override
  Future<void> apagarCategoria(String idCategoria) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/categoria-produto-servico/apagar/$idCategoria',
    );
    final http.Response response = await _httpClient.delete(
      uri,
      headers: await _headers(),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw CategoriaCatalogoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  CategoriaCatalogoModel _parseCategoriaResponse(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CategoriaCatalogoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw CategoriaCatalogoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return CategoriaCatalogoModel.fromJson(data);
  }
}

class CategoriaCatalogoApiException implements Exception {
  const CategoriaCatalogoApiException({
    required this.statusCode,
    required this.body,
  });
  final int statusCode;
  final String body;
  @override
  String toString() {
    return 'CategoriaCatalogoApiException(statusCode: $statusCode, body: $body)';
  }
}
