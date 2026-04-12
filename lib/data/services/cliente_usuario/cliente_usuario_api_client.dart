import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/cliente_usuario_model.dart';

abstract class ClienteUsuarioApiClient {
  Future<ClienteUsuarioListResponse> listarClientesUsuario();
}

class HttpClienteUsuarioApiClient implements ClienteUsuarioApiClient {
  HttpClienteUsuarioApiClient({
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
  Future<ClienteUsuarioListResponse> listarClientesUsuario() async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/cliente-usuario/lista',
    );
    final response = await _httpClient.get(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw ClienteUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.trim().isEmpty) {
      return ClienteUsuarioListResponse(
        idUnicoDaEmpresa: '',
        total: 0,
        clientes: const <ClienteUsuario>[],
      );
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw ClienteUsuarioApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return ClienteUsuarioListResponse.fromJson(data);
  }
}

class ClienteUsuarioApiException implements Exception {
  ClienteUsuarioApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'ClienteUsuarioApiException(statusCode: $statusCode, body: $body)';
  }
}
