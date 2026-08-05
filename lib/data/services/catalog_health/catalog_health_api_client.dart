import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/http_client_factory.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';

abstract class CatalogHealthApiClient {
  Future<CatalogHealthSummary> buscarSaudeCatalogo({
    String visualizacao = 'MOBILE',
  });
}

class HttpCatalogHealthApiClient implements CatalogHealthApiClient {
  HttpCatalogHealthApiClient({
    http.Client? httpClient,
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? empresaIdProvider,
  }) : _httpClient = httpClient ?? createHttpClient(),
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
  Future<CatalogHealthSummary> buscarSaudeCatalogo({
    String visualizacao = 'MOBILE',
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/catalogo/saude',
    ).replace(queryParameters: <String, String>{'visualizacao': visualizacao});

    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );

    if (response.statusCode == 204) {
      return CatalogHealthSummary.empty();
    }

    if (response.statusCode != 200) {
      throw CatalogHealthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.trim().isEmpty) {
      return CatalogHealthSummary.empty();
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw CatalogHealthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return CatalogHealthSummary.fromJson(data);
  }
}

class CatalogHealthApiException implements Exception {
  const CatalogHealthApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'CatalogHealthApiException(statusCode: $statusCode, body: $body)';
  }
}
