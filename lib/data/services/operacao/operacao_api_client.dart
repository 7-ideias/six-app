import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/documento_models.dart';
import '../../models/operacao_models.dart';

abstract class OperacaoApiClient {
  Future<OperacaoInserirResponse> inserirOperacao({
    required OperacaoInserirRequest request,
  });
  Future<DocumentoPdfResponse> imprimirComprovanteOperacao({
    required String idOperacao,
    required FormatoImpressaoOperacao formato,
  });
}

class HttpOperacaoApiClient implements OperacaoApiClient {
  HttpOperacaoApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? createHttpClient();

  final http.Client _httpClient;

  @override
  Future<OperacaoInserirResponse> inserirOperacao({
    required OperacaoInserirRequest request,
  }) async {
    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    final uri = Uri.parse('${AppConfig.baseUrl}/operacao/inserir');

    final response = await _httpClient.post(
      uri,
      headers: {
        'idUnicoDaEmpresa': idUnicoDaEmpresa ?? '',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 201) {
      throw OperacaoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    return OperacaoInserirResponse.fromJson(json);
  }

  @override
  Future<DocumentoPdfResponse> imprimirComprovanteOperacao({
    required String idOperacao,
    required FormatoImpressaoOperacao formato,
  }) async {
    final authService = AuthService();
    final jwtToken = await authService.getAccessToken();
    final idUnicoDaEmpresa = await authService.getEmpresaId();

    final uri = Uri.parse(
      '${AppConfig.baseUrl}/operacao/impressao/comprovante/$idOperacao?formato=${formato.apiValue}',
    );

    final response = await _httpClient.get(
      uri,
      headers: {
        'idUnicoDaEmpresa': idUnicoDaEmpresa ?? '',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw OperacaoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw OperacaoApiException(
        statusCode: response.statusCode,
        body: 'RESPOSTA_PDF_INVALIDA',
      );
    }
    return DocumentoPdfResponse.fromJson(
      decoded.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      ),
    );
  }
}

class OperacaoApiException implements Exception {
  OperacaoApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'OperacaoApiException(statusCode: $statusCode, body: $body)';
  }
}
