import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/network/logging_interceptor.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/catalogo_reserva_model.dart';

class CatalogoReservaService {
  CatalogoReservaService({InterceptedClient? client})
    : _client =
          client ??
          InterceptedClient.build(interceptors: [LoggingInterceptor()]);

  final InterceptedClient _client;

  String get _endpoint =>
      '${AppConfig.baseUrl}/private/api/catalogo-publico/reservas';

  Future<CatalogoReservaPaginaModel> listar({
    CatalogoReservaStatus? status,
    int pagina = 0,
    int tamanho = 20,
  }) async {
    final Map<String, String> headers = await _headersAutenticados();
    final Uri uri = Uri.parse(_endpoint).replace(
      queryParameters: <String, String>{
        'pagina': pagina.toString(),
        'tamanho': tamanho.toString(),
        if (status != null) 'status': status.apiValue,
      },
    );
    final response = await _client.get(uri, headers: headers);
    final Map<String, dynamic> json = _decodeResponse(
      response.statusCode,
      response.body,
    );
    return CatalogoReservaPaginaModel.fromJson(json);
  }

  Future<CatalogoReservaDetalheModel> consultar(String idReserva) async {
    final Map<String, String> headers = await _headersAutenticados();
    final Uri uri = Uri.parse('$_endpoint/${Uri.encodeComponent(idReserva)}');
    final response = await _client.get(uri, headers: headers);
    final Map<String, dynamic> json = _decodeResponse(
      response.statusCode,
      response.body,
    );
    return CatalogoReservaDetalheModel.fromJson(json);
  }

  Future<CatalogoReservaDetalheModel> atualizarStatus({
    required String idReserva,
    required CatalogoReservaStatus status,
  }) async {
    final Map<String, String> headers = await _headersAutenticados();
    final Uri uri = Uri.parse(
      '$_endpoint/${Uri.encodeComponent(idReserva)}/status',
    );
    final response = await _client.patch(
      uri,
      headers: headers,
      body: jsonEncode(<String, String>{'status': status.apiValue}),
    );
    final Map<String, dynamic> json = _decodeResponse(
      response.statusCode,
      response.body,
    );
    return CatalogoReservaDetalheModel.fromJson(json);
  }

  Future<CatalogoReservaConversaoModel> converterEmVenda(
    String idReserva,
  ) async {
    final Map<String, String> headers = await _headersAutenticados();
    final Uri uri = Uri.parse(
      '$_endpoint/${Uri.encodeComponent(idReserva)}/converter-em-venda',
    );
    final response = await _client.post(uri, headers: headers);
    final Map<String, dynamic> json = _decodeResponse(
      response.statusCode,
      response.body,
      fallbackError: 'Não foi possível converter a reserva em venda.',
    );
    return CatalogoReservaConversaoModel.fromJson(json);
  }

  Future<Map<String, String>> _headersAutenticados() async {
    final AuthService authService = AuthService();
    final String? token = await authService.getAccessToken();
    final String? empresaId = await authService.getEmpresaId();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sessão inválida para consultar as reservas.');
    }
    if (empresaId == null || empresaId.trim().isEmpty) {
      throw Exception('Selecione um comércio para consultar as reservas.');
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'idUnicoDaEmpresa': empresaId,
    };
  }

  Map<String, dynamic> _decodeResponse(
    int statusCode,
    String body, {
    String fallbackError = 'Não foi possível consultar as reservas.',
  }) {
    if (statusCode < 200 || statusCode >= 300) {
      String? codigo;
      try {
        final dynamic errorBody = jsonDecode(body);
        if (errorBody is Map<String, dynamic>) {
          codigo =
              errorBody['detail']?.toString() ??
              errorBody['message']?.toString() ??
              errorBody['error']?.toString();
        }
      } catch (_) {
        codigo = null;
      }
      throw CatalogoReservaServiceException(
        statusCode: statusCode,
        codigo: codigo,
        fallbackMessage: fallbackError,
      );
    }
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao consultar as reservas.');
    }
    return decoded;
  }
}

class CatalogoReservaServiceException implements Exception {
  const CatalogoReservaServiceException({
    required this.statusCode,
    required this.fallbackMessage,
    this.codigo,
  });

  final int statusCode;
  final String fallbackMessage;
  final String? codigo;

  @override
  String toString() => codigo ?? '$fallbackMessage ($statusCode)';
}
