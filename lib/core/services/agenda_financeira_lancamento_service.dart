import 'dart:convert';

import 'package:appplanilha/core/config/app_config.dart';
import 'package:appplanilha/core/services/auth_service.dart';
import 'package:appplanilha/data/models/agenda_financeira_lancamento_model.dart';
import 'package:http/http.dart' as http;

class AgendaFinanceiraLancamentoService {
  final http.Client _httpClient;

  AgendaFinanceiraLancamentoService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  String get _endpointCadastro =>
      '${AppConfig.baseUrl}/private/api/agenda-financeira/lancamentos2';

  Future<Map<String, String>> _buildHeaders() async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    return {
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId ?? '',
      'Authorization': 'Bearer $token',
    };
  }

  Future<LancamentoAgendaFinanceiraResponse> cadastrarLancamento(
    LancamentoAgendaFinanceiraRequest request,
  ) async {
    final uri = Uri.parse(_endpointCadastro);

    final response = await _httpClient.post(
      uri,
      headers: await _buildHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AgendaFinanceiraLancamentoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.trim().isEmpty) {
      return LancamentoAgendaFinanceiraResponse(
        id: request.uuidOperacaoApp ?? '',
        status: 'CRIADO',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return LancamentoAgendaFinanceiraResponse(
        id: request.uuidOperacaoApp ?? '',
        status: 'CRIADO',
      );
    }

    return LancamentoAgendaFinanceiraResponse.fromJson(decoded);
  }
}

class AgendaFinanceiraLancamentoApiException implements Exception {
  AgendaFinanceiraLancamentoApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'AgendaFinanceiraLancamentoApiException(statusCode: $statusCode, body: $body)';
  }
}
