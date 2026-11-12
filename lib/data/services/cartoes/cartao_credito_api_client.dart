import 'package:sixpos/data/models/fatura_cartao_model.dart';
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

  Future<Map<String, dynamic>> _request(String method, {Map<String,dynamic>? input, String path = '', String resource = 'cartoes'}) async {
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
      final uri = Uri.parse('${AppConfig.baseUrl}/private/api/agenda-financeira/$resource$path');
      final http.Response response;
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      } else {
        final body = jsonEncode(input!);
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
    final data = await _request(input.versao == null ? 'POST' : 'PUT', input: input.toJson(), path: input.versao == null ? '' : '/${Uri.encodeComponent(input.id)}');
    try {
      return CartaoCredito.fromJson(data);
    } catch (_) {
      throw const CartaoCreditoApiException('invalidResponse');
    }
  }

  Future<T> _decode<T>(Future<Map<String,dynamic>> response,T Function(Map<String,dynamic>) parser) async {
    final json = await response;
    try { return parser(json); } catch (_) { throw const CartaoCreditoApiException('invalidResponse'); }
  }
  Future<List<FaturaCartao>> faturas(String cartaoId) => _decode(
    _request('GET',path:'/${Uri.encodeComponent(cartaoId)}/faturas'),
    (j) => (j['faturas'] as List).map((e) => FaturaCartao.fromJson(Map<String,dynamic>.from(e as Map))).toList());
  Future<FaturaCartao> fatura(String id) => _decode(_request('GET',path:'/faturas/${Uri.encodeComponent(id)}'),FaturaCartao.fromJson);
  Future<PreviaFaturaCartao> previa(String cartaoId,DateTime data) => _decode(
    _request('GET',path:'/${Uri.encodeComponent(cartaoId)}/previa?dataCompra=${dataCartaoIso(data)}'),PreviaFaturaCartao.fromJson);
  Future<FaturaCartao> comprar(CompraCartaoRequest input) => _decode(
    _request('POST',path:'/${Uri.encodeComponent(input.cartaoId)}/compras',input:input.toJson()),FaturaCartao.fromJson);
  Future<FaturaCartao> pagar(PagarFaturaCartaoRequest input) => _decode(
    _request('POST',path:'/faturas/${Uri.encodeComponent(input.faturaId)}/pagamento',input:input.toJson()),FaturaCartao.fromJson);
  Future<List<FormaPagamentoFatura>> formasFatura() => _decode(
    _request('GET',resource:'formas-recebimento'), (j) => (j['tiposRecebimento'] as List)
      .map((e) => Map<String,dynamic>.from(e as Map))
      .where((e) => e['ativo'] == true && const ['tipo1','tipo2','tipo4','tipo5','tipo10'].contains(e['codigoTipo']))
      .map((e) => FormaPagamentoFatura(e['codigoTipo'] as String,e['descricaoExibicao'] as String)).toList());
}

