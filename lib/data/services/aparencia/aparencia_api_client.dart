import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/aparencia_models.dart';

abstract class AparenciaApiClient {
  Future<ConfiguracaoAparenciaResponse?> getAparencia();
  Future<void> salvarAparencia(SalvarConfiguracaoAparenciaRequest request);
}

class HttpAparenciaApiClient implements AparenciaApiClient {
  HttpAparenciaApiClient({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, String>> _getHeaders() async {
    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    return {
      'idUnicoDaEmpresa': idUnicoDaEmpresa ?? '',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwtToken',
    };
  }

  @override
  Future<ConfiguracaoAparenciaResponse?> getAparencia() async {
    // Para facilitar o desenvolvimento inicial, podemos retornar um mock se o endpoint ainda não existir.
    // Mas aqui implementaremos a chamada real conforme solicitado.
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/configuracoes/aparencia');
    
    try {
      final response = await _httpClient.get(uri, headers: await _getHeaders());

      if (response.statusCode == 404 || response.body.isEmpty) {
        return null;
      }

      if (response.statusCode != 200) {
        throw AparenciaApiException(statusCode: response.statusCode, body: response.body);
      }

      return ConfiguracaoAparenciaResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      // Em caso de erro de conexão ou outro, retornamos null para usar o default na tela
      return null;
    }
  }

  @override
  Future<void> salvarAparencia(SalvarConfiguracaoAparenciaRequest request) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/configuracoes/aparencia');
    final response = await _httpClient.put(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      throw AparenciaApiException(statusCode: response.statusCode, body: response.body);
    }
  }
}

class AparenciaApiException implements Exception {
  AparenciaApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'AparenciaApiException(statusCode: $statusCode, body: $body)';
  }
}
