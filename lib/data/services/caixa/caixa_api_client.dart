import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/caixa_completo_movimentos_models.dart';
import '../../models/caixa_models.dart';

abstract class CaixaApiClient {
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa();
  Future<CaixaSessao?> getSessaoAtual();
  Future<void> abrirCaixa(AbrirCaixaRequest request);
  Future<void> registrarMovimento(RegistrarMovimentoRequest request);
  Future<List<MovimentoCaixa>> getMovimentos(String idSessaoCaixa);
  Future<InformacoesCaixaComSomatorioResponse> getResumoDeMovimentosComSomatorio(String idSessaoCaixa);
  Future<ResumoCaixa> getResumo(String idSessaoCaixa);
  Future<void> cancelarMovimento(String id);
  Future<void> fecharCaixa(FecharCaixaRequest request);
  Future<void> encerrarSessao();
}

class HttpCaixaApiClient implements CaixaApiClient {
  HttpCaixaApiClient({
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
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/informacoes-basicas');
    final response = await _httpClient.get(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }

    return InformacoesBasicasCaixaResponse.fromJson(jsonDecode(response.body));
  }

  @override
  Future<CaixaSessao?> getSessaoAtual() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/sessao-atual');
    final response = await _httpClient.get(uri, headers: await _getHeaders());

    if (response.statusCode == 404 || response.body.isEmpty) {
      return null;
    }

    if (response.statusCode != 200) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }

    return CaixaSessao.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> abrirCaixa(AbrirCaixaRequest request) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/abrir');
    final response = await _httpClient.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }
  }

  @override
  Future<void> registrarMovimento(RegistrarMovimentoRequest request) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/movimentos');
    final response = await _httpClient.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }
  }

  @override
  Future<List<MovimentoCaixa>> getMovimentos(String idSessaoCaixa) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/movimentos?idSessaoCaixa=${idSessaoCaixa}');
    final response = await _httpClient.get(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }

    final List list = jsonDecode(response.body);
    return list.map((item) => MovimentoCaixa.fromJson(item)).toList();
  }

  @override
  Future<InformacoesCaixaComSomatorioResponse> getResumoDeMovimentosComSomatorio(String idSessaoCaixa) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/completo-movimentos?idSessaoCaixa=${idSessaoCaixa}');
    final response = await _httpClient.get(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return InformacoesCaixaComSomatorioResponse.fromJson(data);
  }

  @override
  Future<ResumoCaixa> getResumo(String idSessaoCaixa) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/resumo?idSessaoCaixa=${idSessaoCaixa}');
    final response = await _httpClient.get(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }

    return ResumoCaixa.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> cancelarMovimento(String id) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/movimentos/$id/cancelar');
    final response = await _httpClient.post(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }
  }

  @override
  Future<void> fecharCaixa(FecharCaixaRequest request) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/fechar');
    final response = await _httpClient.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }
  }

  @override
  Future<void> encerrarSessao() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/caixa/encerrar-sessao');
    final response = await _httpClient.post(uri, headers: await _getHeaders());

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw CaixaApiException(statusCode: response.statusCode, body: response.body);
    }
  }
}

class CaixaApiException implements Exception {
  CaixaApiException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'CaixaApiException(statusCode: $statusCode, body: $body)';
  }
}
