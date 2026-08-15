import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/etiqueta_models.dart';

abstract interface class EtiquetaApiClient {
  Future<bool> buscarAcesso();
  Future<List<EtiquetaModelo>> listarModelos();
  Future<EtiquetaModelo> buscarModelo(String id);
  Future<EtiquetaModelo> criarModelo(EtiquetaModelo modelo);
  Future<EtiquetaModelo> atualizarModelo(EtiquetaModelo modelo);
  Future<EtiquetaModelo> duplicarModelo(String id);
  Future<void> excluirModelo(String id);
  Future<EtiquetaPdfResponse> gerarPdf({
    required String templateId,
    required List<EtiquetaImpressaoItem> items,
  });
  Future<bool> buscarPermissaoColaborador(String idUnicoDoUsuario);
  Future<bool> atualizarPermissaoColaborador(
    String idUnicoDoUsuario, {
    required bool permitido,
  });
}

class HttpEtiquetaApiClient implements EtiquetaApiClient {
  HttpEtiquetaApiClient({
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

  String get _base => '${AppConfig.baseUrl}/private/api/etiquetas';

  @override
  Future<bool> buscarAcesso() async {
    final http.Response response = await _httpClient.get(
      Uri.parse('$_base/acesso'),
      headers: await _headers(),
    );
    _expect(response, const <int>{200}, operation: 'GET $_base/acesso');
    final Map<String, dynamic> json = _decodeMap(
      response,
      operation: 'GET $_base/acesso',
    );
    return json['podeAcessar'] == true;
  }

  @override
  Future<List<EtiquetaModelo>> listarModelos() async {
    final http.Response response = await _httpClient.get(
      Uri.parse('$_base/modelos'),
      headers: await _headers(),
    );
    if (response.statusCode == 204) return const <EtiquetaModelo>[];
    _expect(response, const <int>{200}, operation: 'GET $_base/modelos');
    final dynamic decoded = _decode(response, operation: 'GET $_base/modelos');
    if (decoded is! List) {
      throw EtiquetaApiException.invalidResponse(response.statusCode);
    }
    return decoded
        .whereType<Map>()
        .map(
          (Map value) => EtiquetaModelo.fromJson(
            value.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<EtiquetaModelo> buscarModelo(String id) async {
    final http.Response response = await _httpClient.get(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );
    _expect(response, const <int>{
      200,
    }, operation: 'GET $_base/modelos/${Uri.encodeComponent(id)}');
    return EtiquetaModelo.fromJson(
      _decodeMap(
        response,
        operation: 'GET $_base/modelos/${Uri.encodeComponent(id)}',
      ),
    );
  }

  @override
  Future<EtiquetaModelo> criarModelo(EtiquetaModelo modelo) async {
    final http.Response response = await _httpClient.post(
      Uri.parse('$_base/modelos'),
      headers: await _headers(),
      body: jsonEncode(modelo.toJson(includeServerFields: false)),
    );
    _expect(response, const <int>{201}, operation: 'POST $_base/modelos');
    return EtiquetaModelo.fromJson(
      _decodeMap(response, operation: 'POST $_base/modelos'),
    );
  }

  @override
  Future<EtiquetaModelo> atualizarModelo(EtiquetaModelo modelo) async {
    final String id = modelo.id?.trim() ?? '';
    if (id.isEmpty) {
      throw const EtiquetaApiException(
        statusCode: 0,
        code: 'ETIQUETA_ID_OBRIGATORIO',
      );
    }
    final http.Response response = await _httpClient.put(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
      body: jsonEncode(modelo.toJson(includeServerFields: false)),
    );
    _expect(response, const <int>{
      200,
    }, operation: 'PUT $_base/modelos/${Uri.encodeComponent(id)}');
    return EtiquetaModelo.fromJson(
      _decodeMap(
        response,
        operation: 'PUT $_base/modelos/${Uri.encodeComponent(id)}',
      ),
    );
  }

  @override
  Future<EtiquetaModelo> duplicarModelo(String id) async {
    final http.Response response = await _httpClient.post(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}/duplicar'),
      headers: await _headers(),
    );
    _expect(
      response,
      const <int>{201},
      operation: 'POST $_base/modelos/${Uri.encodeComponent(id)}/duplicar',
    );
    return EtiquetaModelo.fromJson(
      _decodeMap(
        response,
        operation: 'POST $_base/modelos/${Uri.encodeComponent(id)}/duplicar',
      ),
    );
  }

  @override
  Future<void> excluirModelo(String id) async {
    final http.Response response = await _httpClient.delete(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );
    _expect(response, const <int>{
      200,
      204,
    }, operation: 'DELETE $_base/modelos/${Uri.encodeComponent(id)}');
  }

  @override
  Future<EtiquetaPdfResponse> gerarPdf({
    required String templateId,
    required List<EtiquetaImpressaoItem> items,
  }) async {
    final int totalEtiquetas = items.fold<int>(
      0,
      (int total, EtiquetaImpressaoItem item) => total + item.quantidade,
    );
    debugPrint(
      '[EtiquetaApiClient] POST $_base/impressao/pdf '
      'templateId=$templateId itens=${items.length} totalEtiquetas=$totalEtiquetas',
    );
    final http.Response response = await _httpClient.post(
      Uri.parse('$_base/impressao/pdf'),
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{
        'templateId': templateId,
        'sourceType': 'PRODUCT',
        'items':
            items.map((EtiquetaImpressaoItem item) => item.toJson()).toList(),
      }),
    );
    _expect(response, const <int>{200}, operation: 'POST $_base/impressao/pdf');
    final EtiquetaPdfResponse pdf = EtiquetaPdfResponse.fromJson(
      _decodeMap(response, operation: 'POST $_base/impressao/pdf'),
    );
    debugPrint(
      '[EtiquetaApiClient] PDF gerado com sucesso '
      'templateId=$templateId paginas=${pdf.totalPaginas} '
      'etiquetas=${pdf.totalEtiquetas} arquivo=${pdf.nomeArquivo}',
    );
    return pdf;
  }

  @override
  Future<bool> buscarPermissaoColaborador(String idUnicoDoUsuario) async {
    final http.Response response = await _httpClient.get(
      Uri.parse(
        '$_base/permissoes/colaboradores/${Uri.encodeComponent(idUnicoDoUsuario)}',
      ),
      headers: await _headers(),
    );
    _expect(
      response,
      const <int>{200},
      operation:
          'GET $_base/permissoes/colaboradores/${Uri.encodeComponent(idUnicoDoUsuario)}',
    );
    return _decodeMap(
          response,
          operation:
              'GET $_base/permissoes/colaboradores/${Uri.encodeComponent(idUnicoDoUsuario)}',
        )['permitido'] ==
        true;
  }

  @override
  Future<bool> atualizarPermissaoColaborador(
    String idUnicoDoUsuario, {
    required bool permitido,
  }) async {
    final http.Response response = await _httpClient.put(
      Uri.parse(
        '$_base/permissoes/colaboradores/${Uri.encodeComponent(idUnicoDoUsuario)}',
      ),
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{'permitido': permitido}),
    );
    _expect(
      response,
      const <int>{200},
      operation:
          'PUT $_base/permissoes/colaboradores/${Uri.encodeComponent(idUnicoDoUsuario)}',
    );
    return _decodeMap(
          response,
          operation:
              'PUT $_base/permissoes/colaboradores/${Uri.encodeComponent(idUnicoDoUsuario)}',
        )['permitido'] ==
        true;
  }

  Future<Map<String, String>> _headers() async {
    final String token = (await _accessTokenProvider())?.trim() ?? '';
    final String empresa = (await _empresaIdProvider())?.trim() ?? '';
    return <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json; charset=utf-8',
      'idUnicoDaEmpresa': empresa,
      'Authorization': 'Bearer $token',
    };
  }

  void _expect(
    http.Response response,
    Set<int> expected, {
    required String operation,
  }) {
    if (!expected.contains(response.statusCode)) {
      final _EtiquetaErrorData errorData = _extractErrorData(response);
      debugPrint(
        '[EtiquetaApiClient] $operation falhou '
        'status=${response.statusCode} code=${errorData.code} '
        'message=${errorData.message ?? '-'} '
        'detail=${errorData.detail ?? '-'} '
        'path=${errorData.path ?? '-'}',
      );
      throw EtiquetaApiException(
        statusCode: response.statusCode,
        code: errorData.code,
        message: errorData.message,
        detail: errorData.detail,
        path: errorData.path,
      );
    }
  }

  dynamic _decode(http.Response response, {String? operation}) {
    final String body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      debugPrint(
        '[EtiquetaApiClient] Resposta invalida '
        '${operation == null ? '' : 'em $operation '}'
        'status=${response.statusCode} '
        'contentType=${response.headers['content-type'] ?? '-'} '
        'bodyLength=${body.length}',
      );
      throw EtiquetaApiException.invalidResponse(
        response.statusCode,
        detail:
            'contentType=${response.headers['content-type'] ?? '-'} bodyLength=${body.length}',
      );
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response, {String? operation}) {
    final dynamic decoded = _decode(response, operation: operation);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    debugPrint(
      '[EtiquetaApiClient] Resposta JSON inesperada '
      '${operation == null ? '' : 'em $operation '}'
      'status=${response.statusCode} tipo=${decoded.runtimeType}',
    );
    throw EtiquetaApiException.invalidResponse(
      response.statusCode,
      detail: 'tipo=${decoded.runtimeType}',
    );
  }

  _EtiquetaErrorData _extractErrorData(http.Response response) {
    final String body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) {
      return _EtiquetaErrorData(code: 'HTTP_${response.statusCode}');
    }
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map) {
        final String? explicitCode = _firstNonEmpty(
          decoded['code'],
          decoded['codigo'],
        );
        final String? message = _firstNonEmpty(
          decoded['message'],
          decoded['mensagem'],
          decoded['detail'],
          decoded['error'],
        );
        final String? detail = _firstNonEmpty(
          decoded['detail'],
          decoded['mensagemDetalhada'],
          decoded['details'],
        );
        final String? path = _firstNonEmpty(decoded['path']);
        if ((explicitCode ?? '').isNotEmpty) {
          return _EtiquetaErrorData(
            code: explicitCode!,
            message: message,
            detail: detail,
            path: path,
          );
        }
        if (message != null && message.trim().isNotEmpty) {
          final RegExp codePattern = RegExp(r'[A-Z][A-Z0-9_]{3,}');
          final Match? match = codePattern.firstMatch(message);
          if (match != null) {
            return _EtiquetaErrorData(
              code: match.group(0)!,
              message: message,
              detail: detail,
              path: path,
            );
          }
          return _EtiquetaErrorData(
            code: 'HTTP_${response.statusCode}',
            message: message,
            detail: detail,
            path: path,
          );
        }
      }
    } catch (_) {
      // O corpo pode ser HTML/texto em proxies. Não o propagamos para a UI.
    }
    return _EtiquetaErrorData(code: 'HTTP_${response.statusCode}');
  }
}

class EtiquetaApiException implements Exception {
  const EtiquetaApiException({
    required this.statusCode,
    required this.code,
    this.message,
    this.detail,
    this.path,
  });

  factory EtiquetaApiException.invalidResponse(
    int statusCode, {
    String? detail,
  }) => EtiquetaApiException(
    statusCode: statusCode,
    code: 'RESPOSTA_INVALIDA',
    detail: detail,
  );

  final int statusCode;
  final String code;
  final String? message;
  final String? detail;
  final String? path;

  @override
  String toString() {
    return 'EtiquetaApiException('
        'statusCode: $statusCode, '
        'code: $code, '
        'message: ${message ?? '-'}, '
        'detail: ${detail ?? '-'}, '
        'path: ${path ?? '-'}'
        ')';
  }
}

class _EtiquetaErrorData {
  const _EtiquetaErrorData({
    required this.code,
    this.message,
    this.detail,
    this.path,
  });

  final String code;
  final String? message;
  final String? detail;
  final String? path;
}

String? _firstNonEmpty(
  dynamic first, [
  dynamic second,
  dynamic third,
  dynamic fourth,
]) {
  for (final dynamic value in <dynamic>[first, second, third, fourth]) {
    final String text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return null;
}
