import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/http_client_factory.dart';
import 'package:sixpos/data/datasources/operational_procedure_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/data/models/operational_procedure_persistence_models.dart';

class HttpOperationalProcedureApiClient
    implements OperationalProcedureDataSource {
  HttpOperationalProcedureApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? createHttpClient();

  final http.Client _httpClient;

  @override
  Future<OperationalProcedureSummary> fetchProcedures({
    String idioma = 'pt-BR',
    bool somenteAtivos = false,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/procedimentos')
        .replace(
          queryParameters: <String, String>{
            'idioma': idioma,
            'somenteAtivos': somenteAtivos.toString(),
          },
        );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );
    _ensureSuccess(response, const <int>{200});
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const OperationalProcedureApiException(
        statusCode: 200,
        body: 'PROCEDIMENTO_RESPOSTA_INVALIDA',
      );
    }
    return OperationalProcedureSummary(
      procedures: decoded
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                OperationalProcedure.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      isDemonstrationData: false,
    );
  }

  @override
  Future<OperationalProcedure> saveProcedure({
    required OperationalProcedure procedure,
    required String idioma,
    required bool isCreating,
  }) async {
    final Uri uri = Uri.parse(
      isCreating
          ? '${AppConfig.baseUrl}/private/api/procedimentos'
          : '${AppConfig.baseUrl}/private/api/procedimentos/${procedure.id}',
    ).replace(queryParameters: <String, String>{'idioma': idioma});
    final String body = jsonEncode(procedure.toApiJson(idioma));
    final http.Response response = isCreating
        ? await _httpClient.post(uri, headers: await _headers(), body: body)
        : await _httpClient.put(uri, headers: await _headers(), body: body);
    _ensureSuccess(response, const <int>{200, 201});
    return OperationalProcedure.fromJson(
      (jsonDecode(utf8.decode(response.bodyBytes)) as Map)
          .cast<String, dynamic>(),
    );
  }

  Future<OperationalProcedureExecutionResult> registerExecution(
    Map<String, dynamic> request,
  ) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/procedimentos/execucoes',
    );
    final http.Response response = await _httpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(request),
    );
    _ensureSuccess(response, const <int>{201});
    return OperationalProcedureExecutionResult.fromJson(
      (jsonDecode(utf8.decode(response.bodyBytes)) as Map)
          .cast<String, dynamic>(),
    );
  }

  Future<void> linkExecutionsToSale({
    required List<String> executionIds,
    required String saleId,
  }) async {
    if (executionIds.isEmpty || saleId.trim().isEmpty) return;
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/procedimentos/execucoes/vincular-venda',
    );
    final http.Response response = await _httpClient.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{
        'execucaoIds': executionIds,
        'idVenda': saleId,
      }),
    );
    _ensureSuccess(response, const <int>{200});
  }

  Future<OperationalProcedureAnalytics> fetchAnalytics({
    required String idioma,
    int days = 30,
  }) async {
    final Uri uri =
        Uri.parse(
          '${AppConfig.baseUrl}/private/api/procedimentos/analise',
        ).replace(
          queryParameters: <String, String>{
            'idioma': idioma,
            'dias': days.toString(),
          },
        );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );
    _ensureSuccess(response, const <int>{200});
    return OperationalProcedureAnalytics.fromJson(
      (jsonDecode(utf8.decode(response.bodyBytes)) as Map)
          .cast<String, dynamic>(),
    );
  }

  Future<Map<String, String>> _headers() async {
    final AuthService authService = AuthService();
    final String? token = await authService.getAccessToken();
    final String? companyId = await authService.getEmpresaId();
    return <String, String>{
      'idUnicoDaEmpresa': companyId ?? '',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _ensureSuccess(http.Response response, Set<int> expected) {
    if (expected.contains(response.statusCode)) return;
    throw OperationalProcedureApiException(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}

class OperationalProcedureApiException implements Exception {
  const OperationalProcedureApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'OperationalProcedureApiException('
        'statusCode: $statusCode, body: $body)';
  }
}
