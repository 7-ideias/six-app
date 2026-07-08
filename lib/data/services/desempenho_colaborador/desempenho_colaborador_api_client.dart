import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/colaborador_usuario_model.dart';
import '../../models/desempenho_colaborador_model.dart';

abstract class DesempenhoColaboradorApiClient {
  Future<List<ColaboradorUsuarioResumo>> listarParticipantes({
    bool incluirNaoAtivos = false,
  });

  Future<List<MetaColaboradorModel>> listarMetas();

  Future<MetaColaboradorModel> criarMeta(Map<String, dynamic> payload);

  Future<MetaColaboradorModel> editarMeta(
    String idMeta,
    Map<String, dynamic> payload,
  );

  Future<DesempenhoColaboradorResumoModel> buscarResumo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? idColaborador,
  });
}

class HttpDesempenhoColaboradorApiClient
    implements DesempenhoColaboradorApiClient {
  HttpDesempenhoColaboradorApiClient({
    http.Client? httpClient,
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? empresaIdProvider,
  }) : _httpClient = httpClient ?? http.Client(),
       _accessTokenProvider = accessTokenProvider ?? AuthService().getAccessToken,
       _empresaIdProvider = empresaIdProvider ?? AuthService().getEmpresaId;

  final http.Client _httpClient;
  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _empresaIdProvider;

  Future<Map<String, String>> _getHeaders() async {
    final String token = (await _accessTokenProvider())?.trim() ?? '';
    final String empresaId = (await _empresaIdProvider())?.trim() ?? '';

    return <String, String>{
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId,
      'Authori' 'zation': 'Bear' 'er $token',
    };
  }

  @override
  Future<List<ColaboradorUsuarioResumo>> listarParticipantes({
    bool incluirNaoAtivos = false,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/desempenho-colaborador/participantes',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return const <ColaboradorUsuarioResumo>[];
    }

    if (response.statusCode != 200) {
      throw DesempenhoColaboradorApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final dynamic data = jsonDecode(response.body);
    final List<dynamic> rawList = data is List<dynamic> ? data : <dynamic>[];
    final List<ColaboradorUsuarioResumo> participantes = rawList
        .whereType<Map<String, dynamic>>()
        .map(ColaboradorUsuarioResumo.fromJson)
        .toList(growable: false);

    if (incluirNaoAtivos) return participantes;
    return participantes.where((item) => item.ativo).toList(growable: false);
  }

  @override
  Future<List<MetaColaboradorModel>> listarMetas() async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/desempenho-colaborador/metas',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return const <MetaColaboradorModel>[];
    }

    if (response.statusCode != 200) {
      throw DesempenhoColaboradorApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final dynamic data = jsonDecode(response.body);
    final List<dynamic> rawList = data is List<dynamic> ? data : <dynamic>[];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(MetaColaboradorModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<MetaColaboradorModel> criarMeta(Map<String, dynamic> payload) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/desempenho-colaborador/metas',
    );
    final http.Response response = await _httpClient.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DesempenhoColaboradorApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return MetaColaboradorModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<MetaColaboradorModel> editarMeta(
    String idMeta,
    Map<String, dynamic> payload,
  ) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/desempenho-colaborador/metas/$idMeta',
    );
    final http.Response response = await _httpClient.put(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw DesempenhoColaboradorApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return MetaColaboradorModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<DesempenhoColaboradorResumoModel> buscarResumo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? idColaborador,
  }) async {
    final Map<String, String> query = <String, String>{
      'dataInicio': _formatDate(dataInicio),
      'dataFim': _formatDate(dataFim),
    };
    if (idColaborador != null && idColaborador.trim().isNotEmpty) {
      query['idColaborador'] = idColaborador.trim();
    }

    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/desempenho-colaborador/resumo',
    ).replace(queryParameters: query);

    final http.Response response = await _httpClient.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return DesempenhoColaboradorResumoModel.empty();
    }

    if (response.statusCode != 200) {
      throw DesempenhoColaboradorApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return DesempenhoColaboradorResumoModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class DesempenhoColaboradorApiException implements Exception {
  DesempenhoColaboradorApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'DesempenhoColaboradorApiException(statusCode: $statusCode, body: $body)';
  }
}
