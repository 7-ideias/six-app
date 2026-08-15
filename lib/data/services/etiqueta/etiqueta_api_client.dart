import 'dart:convert';

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
  })  : _httpClient = httpClient ?? createHttpClient(),
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
    _expect(response, const <int>{200});
    final Map<String, dynamic> json = _decodeMap(response);
    return json['podeAcessar'] == true;
  }

  @override
  Future<List<EtiquetaModelo>> listarModelos() async {
    final http.Response response = await _httpClient.get(
      Uri.parse('$_base/modelos'),
      headers: await _headers(),
    );
    if (response.statusCode == 204) return const <EtiquetaModelo>[];
    _expect(response, const <int>{200});
    final dynamic decoded = _decode(response);
    if (decoded is! List) {
      throw EtiquetaApiException.invalidResponse(response.statusCode);
    }
    return decoded
        .whereType<Map>()
        .map((Map value) => EtiquetaModelo.fromJson(
              value.map((dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value)),
            ))
        .toList(growable: false);
  }

  @override
  Future<EtiquetaModelo> buscarModelo(String id) async {
    final http.Response response = await _httpClient.get(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );
    _expect(response, const <int>{200});
    return EtiquetaModelo.fromJson(_decodeMap(response));
  }

  @override
  Future<EtiquetaModelo> criarModelo(EtiquetaModelo modelo) async {
    final http.Response response = await _httpClient.post(
      Uri.parse('$_base/modelos'),
      headers: await _headers(),
      body: jsonEncode(modelo.toJson(includeServerFields: false)),
    );
    _expect(response, const <int>{201});
    return EtiquetaModelo.fromJson(_decodeMap(response));
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
    _expect(response, const <int>{200});
    return EtiquetaModelo.fromJson(_decodeMap(response));
  }

  @override
  Future<EtiquetaModelo> duplicarModelo(String id) async {
    final http.Response response = await _httpClient.post(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}/duplicar'),
      headers: await _headers(),
    );
    _expect(response, const <int>{201});
    return EtiquetaModelo.fromJson(_decodeMap(response));
  }

  @override
  Future<void> excluirModelo(String id) async {
    final http.Response response = await _httpClient.delete(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );
    _expect(response, const <int>{200, 204});
  }

  @override
  Future<EtiquetaPdfResponse> gerarPdf({
    required String templateId,
    required List<EtiquetaImpressaoItem> items,
  }) async {
    final http.Response response = await _httpClient.post(
      Uri.parse('$_base/impressao/pdf'),
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{
        'templateId': templateId,
        'sourceType': 'PRODUCT',
        'items': items.map((EtiquetaImpressaoItem item) => item.toJson()).toList(),
      }),
    );
    _expect(response, const <int>{200});
    return EtiquetaPdfResponse.fromJson(_decodeMap(response));
  }

  @override
  Future<bool> buscarPermissaoColaborador(String idUnicoDoUsuario) async {
    final http.Response response = await _httpClient.get(
      Uri.parse(
        '$_base/permissoes/colaboradores/${Uri.encodeComponent(idUnicoDoUsuario)}',
      ),
      headers: await _headers(),
    );
    _expect(response, const <int>{200});
    return _decodeMap(response)['permitido'] == true;
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
    _expect(response, const <int>{200});
    return _decodeMap(response)['permitido'] == true;
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

  void _expect(http.Response response, Set<int> expected) {
    if (!expected.contains(response.statusCode)) {
      throw EtiquetaApiException(
        statusCode: response.statusCode,
        code: _extractCode(response),
      );
    }
  }

  dynamic _decode(http.Response response) {
    final String body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      throw EtiquetaApiException.invalidResponse(response.statusCode);
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final dynamic decoded = _decode(response);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value));
    }
    throw EtiquetaApiException.invalidResponse(response.statusCode);
  }

  String _extractCode(http.Response response) {
    final String body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return 'HTTP_${response.statusCode}';
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map) {
        final dynamic message = decoded['message'] ?? decoded['detail'] ?? decoded['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          final RegExp codePattern = RegExp(r'[A-Z][A-Z0-9_]{3,}');
          final Match? match = codePattern.firstMatch(message.toString());
          if (match != null) return match.group(0)!;
        }
      }
    } catch (_) {
      // O corpo pode ser HTML/texto em proxies. Não o propagamos para a UI.
    }
    return 'HTTP_${response.statusCode}';
  }
}

class EtiquetaApiException implements Exception {
  const EtiquetaApiException({required this.statusCode, required this.code});

  factory EtiquetaApiException.invalidResponse(int statusCode) =>
      EtiquetaApiException(statusCode: statusCode, code: 'RESPOSTA_INVALIDA');

  final int statusCode;
  final String code;

  @override
  String toString() => 'EtiquetaApiException(statusCode: $statusCode, code: $code)';
}
