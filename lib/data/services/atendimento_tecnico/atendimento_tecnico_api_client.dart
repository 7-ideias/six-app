import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../models/atendimento_tecnico_models.dart';
import '../../models/dominio_models.dart';

class AtendimentoTecnicoApiClient {
  AtendimentoTecnicoApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<AtendimentoTecnicoDominiosBaseModel> buscarDominiosBase() async {
    final response = await _httpClient.get(
      Uri.parse('${AppConfig.baseUrl}/dominios/atendimento-tecnico/base'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    return AtendimentoTecnicoDominiosBaseModel.fromJson(jsonDecode(_decodeBody(response)) as Map<String, dynamic>);
  }

  Future<List<DominioStatusAtendimentoCustomizacaoModel>> listarCustomizacoesStatusAtendimento() async {
    final response = await _httpClient.get(
      Uri.parse('${AppConfig.baseUrl}/dominios/atendimento-tecnico/status/customizacoes'),
      headers: await _headers(),
    );
    if (response.statusCode == 204) return <DominioStatusAtendimentoCustomizacaoModel>[];
    if (response.statusCode != 200) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    final decoded = jsonDecode(_decodeBody(response));
    if (decoded is! List) return <DominioStatusAtendimentoCustomizacaoModel>[];
    return decoded.whereType<Map<String, dynamic>>().map(DominioStatusAtendimentoCustomizacaoModel.fromJson).toList(growable: false);
  }

  Future<List<DominioStatusAtendimentoCustomizacaoModel>> salvarCustomizacoesStatusAtendimento(List<Map<String, dynamic>> customizacoes) async {
    final response = await _httpClient.put(
      Uri.parse('${AppConfig.baseUrl}/dominios/atendimento-tecnico/status/customizacoes'),
      headers: await _headers(),
      body: jsonEncode(customizacoes),
    );
    if (response.statusCode != 200) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    final decoded = jsonDecode(_decodeBody(response));
    if (decoded is! List) return <DominioStatusAtendimentoCustomizacaoModel>[];
    return decoded.whereType<Map<String, dynamic>>().map(DominioStatusAtendimentoCustomizacaoModel.fromJson).toList(growable: false);
  }

  Future<List<AtendimentoTecnicoModel>> listar() async {
    final response = await _httpClient.get(Uri.parse('${AppConfig.baseUrl}/atendimentos-tecnicos'), headers: await _headers());
    if (response.statusCode == 204) return <AtendimentoTecnicoModel>[];
    if (response.statusCode != 200) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    final decoded = jsonDecode(_decodeBody(response));
    if (decoded is! List) return <AtendimentoTecnicoModel>[];
    return decoded.whereType<Map<String, dynamic>>().map(AtendimentoTecnicoModel.fromJson).toList(growable: false);
  }

  Future<AtendimentoTecnicoModel> criar(AtendimentoTecnicoCreateInput input) async {
    final response = await _httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/atendimentos-tecnicos'),
      headers: await _headers(),
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 201) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    return AtendimentoTecnicoModel.fromJson(jsonDecode(_decodeBody(response)) as Map<String, dynamic>);
  }

  Future<AtendimentoTecnicoModel> atualizar({required String id, required AtendimentoTecnicoUpdateInput input}) async {
    final response = await _httpClient.put(
      Uri.parse('${AppConfig.baseUrl}/atendimentos-tecnicos/' + id),
      headers: await _headers(),
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 200) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    return AtendimentoTecnicoModel.fromJson(jsonDecode(_decodeBody(response)) as Map<String, dynamic>);
  }

  Future<AtendimentoTecnicoModel> receber({required String id, required AtendimentoTecnicoRecebimentoInput input}) async {
    final response = await _httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/atendimentos-tecnicos/' + id + '/recebimentos'),
      headers: await _headers(),
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode != 200) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    return AtendimentoTecnicoModel.fromJson(jsonDecode(_decodeBody(response)) as Map<String, dynamic>);
  }

  Future<AtendimentoTecnicoModel> alterarStatus({required String id, required int statusId, required String statusCodigo, required String statusI18nKey, String? observacao}) async {
    final response = await _httpClient.patch(
      Uri.parse('${AppConfig.baseUrl}/atendimentos-tecnicos/' + id + '/status'),
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{'statusId': statusId, 'statusCodigo': statusCodigo, 'statusI18nKey': statusI18nKey, 'observacao': observacao}),
    );
    if (response.statusCode != 200) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    return AtendimentoTecnicoModel.fromJson(jsonDecode(_decodeBody(response)) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> gerarLinkAssinatura({required String id, required String baseUrl}) async {
    final response = await _httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/atendimentos-tecnicos/' + id + '/assinatura/link'),
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{'baseUrl': baseUrl, 'validadeMinutos': 1440}),
    );
    if (response.statusCode != 201) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    return jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> consultarAssinaturaPublica({required String idUnicoDaEmpresa, required String token}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/public/api/atendimentos-tecnicos/assinatura').replace(queryParameters: <String, String>{'idUnicoDaEmpresa': idUnicoDaEmpresa, 'token': token});
    final response = await _httpClient.get(uri, headers: _publicHeaders());
    if (response.statusCode != 200) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    return jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> aprovarAssinaturaPublica({required String idUnicoDaEmpresa, required String token, required String nomeAssinante, required String? documentoAssinante, required String assinaturaDataUrl, required String? observacao}) async {
    final response = await _httpClient.post(
      Uri.parse('${AppConfig.baseUrl}/public/api/atendimentos-tecnicos/assinatura/aprovar'),
      headers: _publicHeaders(),
      body: jsonEncode(<String, dynamic>{'idUnicoDaEmpresa': idUnicoDaEmpresa, 'token': token, 'nomeAssinante': nomeAssinante, 'documentoAssinante': documentoAssinante, 'assinaturaDataUrl': assinaturaDataUrl, 'aceitouTermos': true, 'observacao': observacao}),
    );
    if (response.statusCode != 201) throw AtendimentoTecnicoApiException(statusCode: response.statusCode, body: _decodeBody(response));
    return jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
  }

  Future<Map<String, String>> _headers() async {
    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();
    return <String, String>{'idUnicoDaEmpresa': idUnicoDaEmpresa ?? '', 'Content-Type': 'application/json; charset=utf-8', 'Accept': 'application/json; charset=utf-8', 'Authorization': 'Bearer ' + (jwtToken ?? '')};
  }

  Map<String, String> _publicHeaders() => const <String, String>{'Content-Type': 'application/json; charset=utf-8', 'Accept': 'application/json; charset=utf-8'};

  String _decodeBody(http.Response response) => utf8.decode(response.bodyBytes);
}

class AtendimentoTecnicoApiException implements Exception {
  AtendimentoTecnicoApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'AtendimentoTecnicoApiException(statusCode: $statusCode, body: $body)';
}
