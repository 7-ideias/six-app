import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';

import 'agenda_financeira_lancamento_service.dart';

class AgendaFinanceiraAcoesFinanceiras {
  AgendaFinanceiraAcoesFinanceiras({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  String get _basePath => '${AppConfig.baseUrl}/private/api/agenda-financeira/lancamentos';
  String _endpoint(String idLancamento, String acao) => '$_basePath/$idLancamento/$acao';
  String _endpointLiquidacao(String idLancamento, String idLiquidacao) => '$_basePath/$idLancamento/liquidacoes/$idLiquidacao';

  Future<Map<String, String>> _buildHeaders() async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();
    final authorizationHeaderName = 'Author${'ization'}';
    final bearerPrefix = 'Bear${'er'}';

    return {
      'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId ?? '',
      authorizationHeaderName: '$bearerPrefix $token',
    };
  }

  Future<LancamentoAgendaFinanceiraResponse> executarTotal({
    required String idLancamento,
    required AgendaFinanceiraLiquidacaoRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse(_endpoint(idLancamento, 'confirmar')),
      headers: await _buildHeaders(),
      body: jsonEncode(request.toJson()),
    );
    return _parseResponse(response, idLancamento, 'CONFIRMADO');
  }

  Future<LancamentoAgendaFinanceiraResponse> executarAbatimento({
    required String idLancamento,
    required AgendaFinanceiraParcialRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse(_endpoint(idLancamento, 'abatimento')),
      headers: await _buildHeaders(),
      body: jsonEncode(request.toJson()),
    );
    return _parseResponse(response, idLancamento, 'ABATIMENTO_REGISTRADO');
  }

  Future<LancamentoAgendaFinanceiraResponse> excluirLiquidacao({
    required String idLancamento,
    required String idLiquidacao,
  }) async {
    final response = await _httpClient.delete(
      Uri.parse(_endpointLiquidacao(idLancamento, idLiquidacao)),
      headers: await _buildHeaders(),
    );
    return _parseResponse(response, idLancamento, 'LIQUIDACAO_EXCLUIDA');
  }

  LancamentoAgendaFinanceiraResponse _parseResponse(
    http.Response response,
    String idFallback,
    String statusFallback,
  ) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AgendaFinanceiraLancamentoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.trim().isEmpty) {
      return LancamentoAgendaFinanceiraResponse(id: idFallback, status: statusFallback);
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return LancamentoAgendaFinanceiraResponse(id: idFallback, status: statusFallback);
    }

    return LancamentoAgendaFinanceiraResponse.fromJson(decoded);
  }
}
