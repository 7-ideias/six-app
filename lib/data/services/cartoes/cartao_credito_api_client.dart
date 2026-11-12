import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/http_client_factory.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';

class CartaoCreditoApiException implements Exception {
  const CartaoCreditoApiException(this.kind, {this.statusCode});
  final String kind;
  final int? statusCode;

  String get messageKey => 'cards.error.$kind';
}

/// Shared transport for Web and future Mobile; no UI or local persistence.
class CartaoCreditoApiClient {
  CartaoCreditoApiClient({
    required this.espaco,
    http.Client? client,
    Future<String?> Function()? tokenProvider,
    Future<String?> Function()? empresaProvider,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? createHttpClient(),
       _tokenProvider = tokenProvider ?? AuthService().getAccessToken,
       _empresaProvider = empresaProvider ?? AuthService().getEmpresaId;

  final String espaco;
  final Duration timeout;
  final http.Client _client;
  final Future<String?> Function() _tokenProvider, _empresaProvider;
  String? _empresa;

  void dispose() => _client.close();

  Future<Map<String, dynamic>> _request(String method, [CartaoCreditoRequest? input]) async {
    try {
      final token = await _tokenProvider().timeout(timeout);
      if (token == null || token.isEmpty) {
        throw const CartaoCreditoApiException('session', statusCode: 401);
      }
      final empresa = espaco == 'PESSOAL'
          ? null
          : (_empresa ??= await _empresaProvider().timeout(timeout));
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'espacoFinanceiro': espaco,
        if (empresa != null) 'idUnicoDaEmpresa': empresa,
      };
      final suffix = method == 'PUT' ? '/${Uri.encodeComponent(input!.id)}' : '';
      final uri = Uri.parse('${AppConfig.baseUrl}/private/api/agenda-financeira/cartoes$suffix');
      final http.Response response;
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      } else {
        final body = jsonEncode(input!.toJson());
        response = await (method == 'POST'
            ? _client.post(uri, headers: headers, body: body)
            : _client.put(uri, headers: headers, body: body)).timeout(timeout);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final kind = switch (response.statusCode) {
          401 => 'session',
          403 => 'permission',
          404 || 405 || 501 => 'unavailable',
          409 => 'conflict',
          400 || 422 => 'validation',
          _ => 'server',
        };
        throw CartaoCreditoApiException(kind, statusCode: response.statusCode);
      }
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(response.bodyBytes)) as Map);
    } on CartaoCreditoApiException {
      rethrow;
    } on TimeoutException {
      throw const CartaoCreditoApiException('connection');
    } on http.ClientException {
      throw const CartaoCreditoApiException('connection');
    } on FormatException {
      throw const CartaoCreditoApiException('invalidResponse');
    } on TypeError {
      throw const CartaoCreditoApiException('invalidResponse');
    }
  }

  Future<CartoesCreditoResponse> listar() async {
    final data = await _request('GET');
    try {
      return CartoesCreditoResponse.fromJson(data);
    } catch (_) {
      throw const CartaoCreditoApiException('invalidResponse');
    }
  }

  Future<CartaoCredito> salvar(CartaoCreditoRequest input) async {
    final data = await _request(input.versao == null ? 'POST' : 'PUT', input);
    try {
      return CartaoCredito.fromJson(data);
    } catch (_) {
      throw const CartaoCreditoApiException('invalidResponse');
    }
  }
}
