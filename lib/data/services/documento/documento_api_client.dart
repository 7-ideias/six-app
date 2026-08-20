import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/documento_models.dart';

abstract interface class DocumentoApiClient {
  Future<bool> buscarAcesso();
  Future<List<ModeloDocumento>> listarModelos();
  Future<ModeloDocumento> criarModelo(ModeloDocumento modelo);
  Future<ModeloDocumento> atualizarModelo(ModeloDocumento modelo);
  Future<ModeloDocumento> duplicarModelo(String id);
  Future<void> excluirModelo(String id);
  Future<List<ModeloPadraoDocumento>> listarPadroes();
  Future<ModeloPadraoDocumento> definirPadrao(ModeloPadraoDocumento padrao);
  Future<DocumentoPdfResponse> gerarPrevia({
    required String idModelo,
    required TipoDocumentoPdf tipoDocumento,
  });
}

class HttpDocumentoApiClient implements DocumentoApiClient {
  HttpDocumentoApiClient({
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

  String get _base => '${AppConfig.baseUrl}/private/api/documentos';

  @override
  Future<bool> buscarAcesso() async {
    final http.Response response = await _httpClient.get(
      Uri.parse('$_base/acesso'),
      headers: await _headers(),
    );
    _esperar(response, const <int>{200}, operacao: 'GET $_base/acesso');
    return _decodificarMapa(
          response,
          operacao: 'GET $_base/acesso',
        )['permitido'] ==
        true;
  }

  @override
  Future<List<ModeloDocumento>> listarModelos() async {
    final http.Response response = await _httpClient.get(
      Uri.parse('$_base/modelos'),
      headers: await _headers(),
    );
    if (response.statusCode == 204) return const <ModeloDocumento>[];
    _esperar(response, const <int>{200}, operacao: 'GET $_base/modelos');
    final dynamic decoded = _decodificar(
      response,
      operacao: 'GET $_base/modelos',
    );
    if (decoded is! List) {
      throw DocumentoApiException.respostaInvalida(response.statusCode);
    }
    return decoded
        .whereType<Map>()
        .map(
          (Map item) => ModeloDocumento.fromJson(
            item.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ModeloDocumento> criarModelo(ModeloDocumento modelo) async {
    final http.Response response = await _httpClient.post(
      Uri.parse('$_base/modelos'),
      headers: await _headers(),
      body: jsonEncode(modelo.toJson(incluirCamposServidor: false)),
    );
    _esperar(response, const <int>{201}, operacao: 'POST $_base/modelos');
    return ModeloDocumento.fromJson(
      _decodificarMapa(response, operacao: 'POST $_base/modelos'),
    );
  }

  @override
  Future<ModeloDocumento> atualizarModelo(ModeloDocumento modelo) async {
    final String id = modelo.id?.trim() ?? '';
    if (id.isEmpty) {
      throw const DocumentoApiException(
        statusCode: 0,
        codigo: 'MODELO_DOCUMENTO_ID_OBRIGATORIO',
      );
    }
    final http.Response response = await _httpClient.put(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
      body: jsonEncode(modelo.toJson()),
    );
    _esperar(response, const <int>{
      200,
    }, operacao: 'PUT $_base/modelos/${Uri.encodeComponent(id)}');
    return ModeloDocumento.fromJson(
      _decodificarMapa(
        response,
        operacao: 'PUT $_base/modelos/${Uri.encodeComponent(id)}',
      ),
    );
  }

  @override
  Future<ModeloDocumento> duplicarModelo(String id) async {
    final http.Response response = await _httpClient.post(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}/duplicar'),
      headers: await _headers(),
    );
    _esperar(
      response,
      const <int>{201},
      operacao: 'POST $_base/modelos/${Uri.encodeComponent(id)}/duplicar',
    );
    return ModeloDocumento.fromJson(
      _decodificarMapa(
        response,
        operacao: 'POST $_base/modelos/${Uri.encodeComponent(id)}/duplicar',
      ),
    );
  }

  @override
  Future<void> excluirModelo(String id) async {
    final http.Response response = await _httpClient.delete(
      Uri.parse('$_base/modelos/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );
    _esperar(response, const <int>{
      200,
      204,
    }, operacao: 'DELETE $_base/modelos/${Uri.encodeComponent(id)}');
  }

  @override
  Future<List<ModeloPadraoDocumento>> listarPadroes() async {
    final http.Response response = await _httpClient.get(
      Uri.parse('$_base/padroes'),
      headers: await _headers(),
    );
    _esperar(response, const <int>{200}, operacao: 'GET $_base/padroes');
    final dynamic decoded = _decodificar(
      response,
      operacao: 'GET $_base/padroes',
    );
    if (decoded is! List) {
      throw DocumentoApiException.respostaInvalida(response.statusCode);
    }
    return decoded
        .whereType<Map>()
        .map(
          (Map item) => ModeloPadraoDocumento.fromJson(
            item.map(
              (dynamic key, dynamic value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ModeloPadraoDocumento> definirPadrao(
    ModeloPadraoDocumento padrao,
  ) async {
    final http.Response response = await _httpClient.put(
      Uri.parse('$_base/padroes'),
      headers: await _headers(),
      body: jsonEncode(padrao.toJson()),
    );
    _esperar(response, const <int>{200}, operacao: 'PUT $_base/padroes');
    return ModeloPadraoDocumento.fromJson(
      _decodificarMapa(response, operacao: 'PUT $_base/padroes'),
    );
  }

  @override
  Future<DocumentoPdfResponse> gerarPrevia({
    required String idModelo,
    required TipoDocumentoPdf tipoDocumento,
  }) async {
    final String rota =
        '$_base/modelos/${Uri.encodeComponent(idModelo)}/previa/pdf';
    final http.Response response = await _httpClient.post(
      Uri.parse(rota),
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{
        'tipoDocumento': tipoDocumento.codigoApi,
      }),
    );
    _esperar(response, const <int>{200}, operacao: 'POST $rota');
    return DocumentoPdfResponse.fromJson(
      _decodificarMapa(response, operacao: 'POST $rota'),
    );
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

  void _esperar(
    http.Response response,
    Set<int> esperados, {
    required String operacao,
  }) {
    if (esperados.contains(response.statusCode)) return;
    final String codigo = _extrairCodigo(response);
    debugPrint(
      '[DocumentoApiClient] $operacao falhou '
      'status=${response.statusCode} codigo=$codigo',
    );
    throw DocumentoApiException(
      statusCode: response.statusCode,
      codigo: codigo,
    );
  }

  dynamic _decodificar(http.Response response, {required String operacao}) {
    final String body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      debugPrint(
        '[DocumentoApiClient] Resposta inválida em $operacao '
        'status=${response.statusCode} tamanho=${body.length}',
      );
      throw DocumentoApiException.respostaInvalida(response.statusCode);
    }
  }

  Map<String, dynamic> _decodificarMapa(
    http.Response response, {
    required String operacao,
  }) {
    final dynamic decoded = _decodificar(response, operacao: operacao);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    throw DocumentoApiException.respostaInvalida(response.statusCode);
  }

  String _extrairCodigo(http.Response response) {
    final String body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return 'HTTP_${response.statusCode}';
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map) {
        for (final String campo in <String>[
          'code',
          'codigo',
          'message',
          'detail',
        ]) {
          final String valor = decoded[campo]?.toString() ?? '';
          final Match? match = RegExp(r'[A-Z][A-Z0-9_]{3,}').firstMatch(valor);
          if (match != null) return match.group(0)!;
        }
      }
    } catch (_) {
      // Proxies podem responder HTML. O conteúdo não é propagado para a UI.
    }
    return 'HTTP_${response.statusCode}';
  }
}

class DocumentoApiException implements Exception {
  const DocumentoApiException({required this.statusCode, required this.codigo});

  factory DocumentoApiException.respostaInvalida(int statusCode) =>
      DocumentoApiException(
        statusCode: statusCode,
        codigo: 'RESPOSTA_INVALIDA',
      );

  final int statusCode;
  final String codigo;

  @override
  String toString() =>
      'DocumentoApiException(statusCode: $statusCode, codigo: $codigo)';
}
