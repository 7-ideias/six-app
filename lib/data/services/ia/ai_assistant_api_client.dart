import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/ai_assistant_models.dart';

class AiAssistantApiClient {
  AiAssistantApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<AiAssistantResponseModel> perguntar(
    AiAssistantRequestModel request,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/private/api/ia/assistente/perguntar'),
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw AiAssistantApiException(
        statusCode: response.statusCode,
        body: _decodeBody(response),
      );
    }

    return AiAssistantResponseModel.fromJson(
      jsonDecode(_decodeBody(response)) as Map<String, dynamic>,
    );
  }

  Future<void> enviarFeedback(AiAssistantFeedbackRequestModel request) async {
    final response = await _httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/private/api/ia/assistente/feedback'),
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw AiAssistantApiException(
        statusCode: response.statusCode,
        body: _decodeBody(response),
      );
    }
  }

  Future<void> enviarSugestao(AiAssistantSuggestionRequestModel request) async {
    final response = await _httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/private/api/ia/assistente/sugestoes'),
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AiAssistantApiException(
        statusCode: response.statusCode,
        body: _decodeBody(response),
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final AuthService authService = AuthService();
    final String? jwtToken = await authService.getAccessToken();
    final String? idUnicoDaEmpresa = await authService.getEmpresaId();
    return <String, String>{
      'idUnicoDaEmpresa': idUnicoDaEmpresa ?? '',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json; charset=utf-8',
      'Authorization': 'Bearer ${jwtToken ?? ''}',
    };
  }

  String _decodeBody(http.Response response) => utf8.decode(response.bodyBytes);
}

class AiAssistantApiException implements Exception {
  AiAssistantApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'AiAssistantApiException(statusCode: $statusCode, body: $body)';
  }
}
