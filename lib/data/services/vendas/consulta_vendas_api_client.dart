import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';
import '../../models/consulta_vendas_models.dart';

abstract interface class ConsultaVendasApiClient {
  Future<ConsultaVendasResponse> consultar(ConsultaVendasFiltro filtro);

  Future<VendaDetalheResponse> detalhar(String identificador);
}

class HttpConsultaVendasApiClient implements ConsultaVendasApiClient {
  HttpConsultaVendasApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? createHttpClient();

  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final AuthService authService = AuthService();
    final String? token = await authService.getAccessToken();
    final String? empresaId = await authService.getEmpresaId();

    return <String, String>{
      'Authorization': 'Bearer ${token ?? ''}',
      'idUnicoDaEmpresa': empresaId ?? '',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  @override
  Future<ConsultaVendasResponse> consultar(ConsultaVendasFiltro filtro) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/vendas')
        .replace(queryParameters: filtro.toQueryParameters());

    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );
    final dynamic decoded = _decode(response);
    if (response.statusCode != 200 || decoded is! Map) {
      throw _exception(response, decoded);
    }

    return ConsultaVendasResponse.fromJson(decoded.cast<String, dynamic>());
  }

  @override
  Future<VendaDetalheResponse> detalhar(String identificador) async {
    final String normalized = identificador.trim();
    if (normalized.isEmpty) {
      throw const ConsultaVendasApiException(
        codigo: 'VENDA_CONSULTA_LOCAL_001',
        mensagem: 'Informe o código ou identificador da venda.',
      );
    }

    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/vendas/${Uri.encodeComponent(normalized)}',
    );
    final http.Response response = await _httpClient.get(
      uri,
      headers: await _headers(),
    );
    final dynamic decoded = _decode(response);
    if (response.statusCode != 200 || decoded is! Map) {
      throw _exception(response, decoded);
    }

    return VendaDetalheResponse.fromJson(decoded.cast<String, dynamic>());
  }

  dynamic _decode(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return response.body;
    }
  }

  ConsultaVendasApiException _exception(
    http.Response response,
    dynamic decoded,
  ) {
    if (decoded is Map) {
      final Map<String, dynamic> json = decoded.cast<String, dynamic>();
      final String mensagem =
          <dynamic>[
                json['mensagemUsuario'],
                json['detail'],
                json['message'],
                json['titulo'],
              ]
              .map((dynamic value) => value?.toString().trim() ?? '')
              .firstWhere(
                (String value) => value.isNotEmpty,
                orElse: () => 'Não foi possível consultar as vendas.',
              );
      return ConsultaVendasApiException(
        codigo: json['codigo']?.toString() ?? 'HTTP_${response.statusCode}',
        mensagem: mensagem,
        statusCode: response.statusCode,
      );
    }

    final String body = decoded?.toString().trim() ?? '';
    return ConsultaVendasApiException(
      codigo: 'HTTP_${response.statusCode}',
      mensagem: body.isNotEmpty
          ? body
          : 'Não foi possível consultar as vendas.',
      statusCode: response.statusCode,
    );
  }
}

class ConsultaVendasApiException implements Exception {
  const ConsultaVendasApiException({
    required this.codigo,
    required this.mensagem,
    this.statusCode,
  });

  final String codigo;
  final String mensagem;
  final int? statusCode;

  @override
  String toString() => mensagem;
}
