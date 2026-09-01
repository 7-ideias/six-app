import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/procedimentos',
    ).replace(
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
    final Map<String, String> headers = await _headers();
    final Map<String, dynamic> payload = procedure.toApiJson(idioma);
    final String body = jsonEncode(payload);
    debugPrint(
      '[OperationalProcedureApi] save start '
      'mode=${isCreating ? 'create' : 'update'} '
      'path=${uri.path} idioma=$idioma '
      'hasToken=${_hasAuthorizationToken(headers)} '
      'hasCompanyId=${_hasCompanyId(headers)} '
      'summary=${_procedureDebugSummary(procedure)}',
    );
    http.Response response;
    try {
      response =
          isCreating
              ? await _httpClient.post(uri, headers: headers, body: body)
              : await _httpClient.put(uri, headers: headers, body: body);
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[OperationalProcedureApi] save transport failure '
        'mode=${isCreating ? 'create' : 'update'} '
        'path=${uri.path} error=$error',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
    if (!const <int>{200, 201}.contains(response.statusCode)) {
      debugPrint(
        '[OperationalProcedureApi] save rejected '
        'mode=${isCreating ? 'create' : 'update'} '
        'path=${uri.path} status=${response.statusCode} '
        'detail=${_safeResponseDetail(response.body)}',
      );
    }
    _ensureSuccess(response, const <int>{200, 201});
    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error, stackTrace) {
      debugPrint(
        '[OperationalProcedureApi] save invalid json response '
        'mode=${isCreating ? 'create' : 'update'} '
        'path=${uri.path} status=${response.statusCode} '
        'detail=${_safeResponseDetail(response.body)} error=$error',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
    if (decoded is! Map) {
      debugPrint(
        '[OperationalProcedureApi] save unexpected response type '
        'mode=${isCreating ? 'create' : 'update'} '
        'path=${uri.path} status=${response.statusCode} '
        'runtimeType=${decoded.runtimeType}',
      );
      throw const OperationalProcedureApiException(
        statusCode: 200,
        body: 'PROCEDIMENTO_RESPOSTA_INVALIDA',
      );
    }
    try {
      return OperationalProcedure.fromJson(decoded.cast<String, dynamic>());
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[OperationalProcedureApi] save response parse failure '
        'mode=${isCreating ? 'create' : 'update'} '
        'path=${uri.path} status=${response.statusCode} error=$error',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
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
    final Uri uri = Uri.parse(
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

bool _hasAuthorizationToken(Map<String, String> headers) {
  final String? authorization = headers['Authorization'];
  return authorization != null &&
      authorization.trim().isNotEmpty &&
      authorization.trim() != 'Bearer null';
}

bool _hasCompanyId(Map<String, String> headers) {
  return (headers['idUnicoDaEmpresa'] ?? '').trim().isNotEmpty;
}

String _procedureDebugSummary(OperationalProcedure procedure) {
  final int itemCount = procedure.stages.fold<int>(
    0,
    (int total, ProcedureStage stage) => total + stage.items.length,
  );
  final Map<String, int> responseTypes = <String, int>{};
  for (final ProcedureStage stage in procedure.stages) {
    for (final ProcedureItem item in stage.items) {
      responseTypes.update(
        item.responseType.name,
        (int current) => current + 1,
        ifAbsent: () => 1,
      );
    }
  }
  final String triggerMoments =
      procedure.triggers.isEmpty
          ? 'none'
          : procedure.triggers
              .map((ProcedureTrigger trigger) => trigger.triggerMoment.name)
              .toSet()
              .join('|');
  final String triggerModes =
      procedure.triggers.isEmpty
          ? 'none'
          : procedure.triggers
              .map((ProcedureTrigger trigger) => trigger.activationMode.name)
              .toSet()
              .join('|');
  return 'id=${procedure.id} '
      'status=${procedure.status.name} '
      'operationType=${procedure.operationType.name} '
      'procedureMoment=${procedure.moment.name} '
      'triggerMoments=$triggerMoments '
      'triggerModes=$triggerModes '
      'triggers=${procedure.triggers.length} '
      'activeTriggers=${procedure.activeTriggerCount} '
      'stages=${procedure.stages.length} '
      'items=$itemCount '
      'responseTypes=${_formatCounts(responseTypes)} '
      'requiredProcedure=${procedure.required} '
      'notifyAdmin=${procedure.adminNotification.enabled}';
}

String _formatCounts(Map<String, int> counts) {
  if (counts.isEmpty) return 'none';
  final List<String> entries = counts.entries
    .map((MapEntry<String, int> entry) => '${entry.key}:${entry.value}')
    .toList(growable: false)..sort();
  return entries.join('|');
}

String _safeResponseDetail(String body) {
  final String trimmed = body.trim();
  if (trimmed.isEmpty) return 'empty';
  try {
    final dynamic decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      final String? value = _firstNonEmptyField(decoded, const <String>[
        'codigo',
        'code',
        'erro',
        'error',
        'mensagem',
        'message',
        'tipo',
      ]);
      if (value != null) return 'json:$value';
      return 'json-map(keys=${decoded.keys.join('|')})';
    }
    if (decoded is List) {
      return 'json-list(length=${decoded.length})';
    }
  } catch (_) {
    // Best-effort summary only.
  }
  return 'text(length=${trimmed.length})';
}

String? _firstNonEmptyField(Map<dynamic, dynamic> source, List<String> keys) {
  for (final String key in keys) {
    final String value = source[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
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
