import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/chat_suporte_models.dart';

class ChatSuporteApiClient {
  ChatSuporteApiClient({http.Client? httpClient, AuthService? authService})
    : _ownsHttpClient = httpClient == null,
      _httpClient = httpClient ?? createHttpClient(),
      _authService = authService ?? AuthService();

  static const String _base = '/private/api/suporte/chat';

  final http.Client _httpClient;
  final AuthService _authService;
  final bool _ownsHttpClient;

  Future<ChatSuporteConversaModel> buscarMinhaConversa() async {
    final http.Response response = await _httpClient.get(
      _uri('$_base/minha-conversa'),
      headers: await _headers(),
    );
    _validar(response, const <int>{200});
    return ChatSuporteConversaModel.fromJson(_jsonObject(response));
  }

  Future<ChatSuporteConversaModel> buscarConversa(
    String idConversa, {
    String? idUnicoDaEmpresa,
  }) async {
    final http.Response response = await _httpClient.get(
      _uri('$_base/conversas/${Uri.encodeComponent(idConversa)}'),
      headers: await _headers(idUnicoDaEmpresa: idUnicoDaEmpresa),
    );
    _validar(response, const <int>{200});
    return ChatSuporteConversaModel.fromJson(_jsonObject(response));
  }

  Future<List<ChatSuporteConversaModel>> listarConversas({
    ChatSuporteStatus? status,
    bool somenteMinhas = false,
  }) async {
    final Map<String, String> query = <String, String>{
      if (status != null) 'status': status.apiValue,
      if (somenteMinhas) 'somenteMinhas': 'true',
    };
    final http.Response response = await _httpClient.get(
      _uri('$_base/conversas', query: query),
      headers: await _headers(includeCompany: false),
    );
    _validar(response, const <int>{200});
    final dynamic decoded = jsonDecode(_body(response));
    if (decoded is! List) return const <ChatSuporteConversaModel>[];
    return decoded
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> value) => ChatSuporteConversaModel.fromJson(
            Map<String, dynamic>.from(value),
          ),
        )
        .toList(growable: false);
  }

  Future<ChatSuporteMensagensPageModel> listarMensagens({
    required String idConversa,
    String? idUnicoDaEmpresa,
    DateTime? antesDe,
    int limite = 80,
  }) async {
    final http.Response response = await _httpClient.get(
      _uri(
        '$_base/conversas/${Uri.encodeComponent(idConversa)}/mensagens',
        query: <String, String>{
          'limite': limite.toString(),
          if (antesDe != null) 'antesDe': antesDe.toUtc().toIso8601String(),
        },
      ),
      headers: await _headers(idUnicoDaEmpresa: idUnicoDaEmpresa),
    );
    _validar(response, const <int>{200});
    return ChatSuporteMensagensPageModel.fromJson(_jsonObject(response));
  }

  Future<ChatSuporteEnvioMensagemModel> enviarMensagem({
    required String idConversa,
    String? idUnicoDaEmpresa,
    String? texto,
    List<ChatSuporteImagemUpload> imagens = const <ChatSuporteImagemUpload>[],
  }) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      _uri('$_base/conversas/${Uri.encodeComponent(idConversa)}/mensagens'),
    );
    request.headers.addAll(
      await _headers(
        idUnicoDaEmpresa: idUnicoDaEmpresa,
        includeContentType: false,
      ),
    );
    final String textoNormalizado = texto?.trim() ?? '';
    if (textoNormalizado.isNotEmpty) {
      request.fields['texto'] = textoNormalizado;
    }
    for (final ChatSuporteImagemUpload imagem in imagens) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivos',
          imagem.dados,
          filename: imagem.nomeArquivo,
        ),
      );
    }
    final http.StreamedResponse streamed = await _httpClient.send(request);
    final http.Response response = await http.Response.fromStream(streamed);
    _validar(response, const <int>{201});
    return ChatSuporteEnvioMensagemModel.fromJson(_jsonObject(response));
  }

  Future<ChatSuporteConversaModel> assumir(String idConversa) {
    return _acao(idConversa, 'assumir');
  }

  Future<ChatSuporteConversaModel> liberar(String idConversa) {
    return _acao(idConversa, 'liberar');
  }

  Future<ChatSuporteConversaModel> encerrar(String idConversa) {
    return _acao(idConversa, 'encerrar');
  }

  Future<void> marcarComoLida({
    required String idConversa,
    String? idUnicoDaEmpresa,
  }) async {
    final http.Response response = await _httpClient.post(
      _uri('$_base/conversas/${Uri.encodeComponent(idConversa)}/leitura'),
      headers: await _headers(idUnicoDaEmpresa: idUnicoDaEmpresa),
    );
    _validar(response, const <int>{204});
  }

  Future<Uint8List> buscarArquivo({
    required String idArquivo,
    String? idUnicoDaEmpresa,
  }) async {
    final http.Response response = await _httpClient.get(
      _uri('$_base/arquivos/${Uri.encodeComponent(idArquivo)}'),
      headers: await _headers(idUnicoDaEmpresa: idUnicoDaEmpresa),
    );
    _validar(response, const <int>{200});
    return response.bodyBytes;
  }

  Future<ChatSuporteConversaModel> _acao(String idConversa, String acao) async {
    final http.Response response = await _httpClient.post(
      _uri('$_base/conversas/${Uri.encodeComponent(idConversa)}/$acao'),
      headers: await _headers(includeCompany: false),
    );
    _validar(response, const <int>{200});
    return ChatSuporteConversaModel.fromJson(_jsonObject(response));
  }

  Future<Map<String, String>> _headers({
    String? idUnicoDaEmpresa,
    bool includeCompany = true,
    bool includeContentType = true,
  }) async {
    final String accessToken =
        (await _authService.getAccessToken())?.trim() ?? '';
    final String empresa =
        idUnicoDaEmpresa?.trim() ??
        (includeCompany
            ? (await _authService.getEmpresaId())?.trim() ?? ''
            : '');
    return <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json; charset=utf-8',
      if (includeContentType) 'Content-Type': 'application/json; charset=utf-8',
      if (empresa.isNotEmpty) 'idUnicoDaEmpresa': empresa,
    };
  }

  Uri _uri(String path, {Map<String, String>? query}) {
    return Uri.parse(
      '${AppConfig.baseUrl}$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
  }

  Map<String, dynamic> _jsonObject(http.Response response) {
    final dynamic decoded = jsonDecode(_body(response));
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw ChatSuporteApiException(
      statusCode: response.statusCode,
      codigo: 'CHAT_SUPORTE_RESPOSTA_INVALIDA',
    );
  }

  void _validar(http.Response response, Set<int> statusEsperados) {
    if (statusEsperados.contains(response.statusCode)) return;
    String codigo = 'CHAT_SUPORTE_ERRO_INESPERADO';
    try {
      final dynamic decoded = jsonDecode(_body(response));
      if (decoded is Map && decoded['codigo'] != null) {
        codigo = decoded['codigo'].toString();
      }
    } catch (_) {
      final String body = _body(response).trim();
      if (body.startsWith('CHAT_SUPORTE_')) codigo = body;
    }
    throw ChatSuporteApiException(
      statusCode: response.statusCode,
      codigo: codigo,
    );
  }

  String _body(http.Response response) => utf8.decode(response.bodyBytes);

  void dispose() {
    if (_ownsHttpClient) _httpClient.close();
  }
}

class ChatSuporteApiException implements Exception {
  const ChatSuporteApiException({
    required this.statusCode,
    required this.codigo,
  });

  final int statusCode;
  final String codigo;

  @override
  String toString() => codigo;
}
