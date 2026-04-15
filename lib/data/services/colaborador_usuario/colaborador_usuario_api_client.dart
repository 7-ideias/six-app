import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/colaborador_usuario_model.dart';

abstract class ColaboradorUsuarioApiClient {
  Future<List<ColaboradorUsuarioResumo>> listarColaboradores();
  Future<ColaboradorUsuarioDetalhe> buscarColaborador(String idUnicoDoUsuario);
  Future<void> editarColaborador(Map<String, dynamic> payload);
}

class HttpColaboradorUsuarioApiClient implements ColaboradorUsuarioApiClient {
  HttpColaboradorUsuarioApiClient({
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

  Future<Map<String, String>> _getHeaders() async {
    final String token = (await _accessTokenProvider())?.trim() ?? '';
    final String empresaId = (await _empresaIdProvider())?.trim() ?? '';

    return <String, String>{
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId,
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<ColaboradorUsuarioResumo>> listarColaboradores() async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/colaborador/listar',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.trim().isEmpty) {
      return const <ColaboradorUsuarioResumo>[];
    }

    final dynamic data = jsonDecode(response.body);
    final List<dynamic> rawList;
    if (data is List<dynamic>) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      rawList = (data['colaboradores'] as List<dynamic>?) ?? <dynamic>[];
    } else {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ColaboradorUsuarioResumo.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ColaboradorUsuarioDetalhe> buscarColaborador(
    String idUnicoDoUsuario,
  ) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/colaborador/buscar',
    ).replace(
      queryParameters: <String, String>{'idUnicoDoUsuario': idUnicoDoUsuario},
    );

    final http.Response response = await _httpClient.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return ColaboradorUsuarioDetalhe.fromJson(data);
  }

  @override
  Future<void> editarColaborador(Map<String, dynamic> payload) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/colaborador/editar',
    );

    final http.Response response = await _httpClient.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ColaboradorUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

class ColaboradorUsuarioApiException implements Exception {
  ColaboradorUsuarioApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'ColaboradorUsuarioApiException(statusCode: $statusCode, body: $body)';
  }
}
