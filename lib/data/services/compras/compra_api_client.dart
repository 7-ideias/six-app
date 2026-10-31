import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/http_client_factory.dart';

class CompraAcesso {
  const CompraAcesso({
    required this.consultar, required this.criar, required this.editar,
    required this.confirmar, required this.cancelar, required this.receber,
  });
  final bool consultar, criar, editar, confirmar, cancelar, receber;
  static const negado = CompraAcesso(
    consultar: false, criar: false, editar: false,
    confirmar: false, cancelar: false, receber: false,
  );
  factory CompraAcesso.fromJson(Map<String,dynamic> json) => CompraAcesso(
    consultar: json['consultar'] == true,
    criar: json['criar'] == true,
    editar: json['editar'] == true,
    confirmar: json['confirmar'] == true,
    cancelar: json['cancelar'] == true,
    receber: json['receber'] == true,
  );
}

class CompraColaboradorPermissoes {
  const CompraColaboradorPermissoes({
    required this.vinculoId, required this.email, required this.permissoes,
  });
  final String vinculoId, email;
  final List<String> permissoes;
  factory CompraColaboradorPermissoes.fromJson(Map<String,dynamic> json) =>
      CompraColaboradorPermissoes(
        vinculoId: json['vinculoId']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        permissoes: (json['permissoes'] as List<dynamic>? ?? [])
            .map((e) => e.toString()).toList(growable: false),
      );
}

/// Compras: confirmacao gera titulos a pagar; recebimentos parciais movimentam estoque.
class CompraApiClient {
  CompraApiClient({
    http.Client? httpClient,
    Future<String?> Function()? accessTokenProvider,
    Future<String?> Function()? empresaIdProvider,
  }) : _http = httpClient ?? createHttpClient(),
       _token = accessTokenProvider ?? AuthService().getAccessToken,
       _empresa = empresaIdProvider ?? AuthService().getEmpresaId;

  final http.Client _http;
  final Future<String?> Function() _token;
  final Future<String?> Function() _empresa;

  Uri _uri([String tail = '']) =>
      Uri.parse('${AppConfig.baseUrl}/private/api/compras$tail');

  Future<Map<String,String>> _headers() async {
    final token = (await _token())?.trim() ?? '';
    final company = (await _empresa())?.trim() ?? '';
    if (token.isEmpty || company.isEmpty) {
      throw const CompraApiException(401, 'Selecione um comércio e entre na sua conta.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'idUnicoDaEmpresa': company,
    };
  }

  Map<String,dynamic> _object(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CompraApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String,dynamic>) {
      throw const FormatException('Resposta da API de compras inválida.');
    }
    return decoded;
  }

  Future<CompraAcesso> consultarAcesso() async {
    final data = _object(await _http.get(_uri('/acesso'), headers: await _headers()));
    return CompraAcesso.fromJson(data);
  }

  Future<List<CompraColaboradorPermissoes>> listarPermissoesColaboradores() async {
    final response = await _http.get(_uri('/permissoes-colaboradores'),
        headers: await _headers());
    if (response.statusCode != 200) {
      throw CompraApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const FormatException('Permissões inválidas.');
    return decoded.whereType<Map<String,dynamic>>()
        .map(CompraColaboradorPermissoes.fromJson).toList(growable: false);
  }

  Future<CompraColaboradorPermissoes> atualizarPermissoesColaborador(
      String vinculoId, List<String> permissoes) async {
    final data = _object(await _http.put(
      _uri('/permissoes-colaboradores/${Uri.encodeComponent(vinculoId)}'),
      headers: await _headers(), body: jsonEncode(permissoes)));
    return CompraColaboradorPermissoes.fromJson(data);
  }

  Future<List<Map<String,dynamic>>> listarFornecedores() async {
    final response = await _http.get(_uri('/fornecedores'), headers: await _headers());
    if (response.statusCode != 200) {
      throw CompraApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const FormatException('Fornecedores inválidos.');
    return decoded.whereType<Map<String,dynamic>>().toList(growable: false);
  }

  Future<List<Map<String,dynamic>>> listar() async {
    final response = await _http.get(_uri(), headers: await _headers());
    if (response.statusCode != 200) {
      throw CompraApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const FormatException('Lista de compras inválida.');
    return decoded.whereType<Map<String,dynamic>>().toList(growable: false);
  }

  Future<Map<String,dynamic>> criar(Map<String,dynamic> compra) async =>
      _object(await _http.post(_uri(),
          headers: await _headers(), body: jsonEncode(compra)));

  Future<Map<String,dynamic>> atualizar(String id, Map<String,dynamic> compra) async =>
      _object(await _http.put(_uri('/${Uri.encodeComponent(id)}'),
          headers: await _headers(), body: jsonEncode(compra)));

  Future<Map<String,dynamic>> buscar(String id) async =>
      _object(await _http.get(_uri('/${Uri.encodeComponent(id)}'),
          headers: await _headers()));

  Future<Map<String,dynamic>> receber(
      String id, String chaveIdempotencia, List<Map<String,dynamic>> itens,
      {String observacoes = ''}) async =>
      _object(await _http.post(_uri('/${Uri.encodeComponent(id)}/recebimentos'),
          headers: await _headers(),
          body: jsonEncode({
            'chaveIdempotencia': chaveIdempotencia,
            'itens': itens,
            'observacoes': observacoes,
          })));

  Future<Map<String,dynamic>> reconciliarFinanceiro(String id) async =>
      _object(await _http.post(_uri('/${Uri.encodeComponent(id)}/reconciliar-financeiro'),
          headers: await _headers()));

  Future<Map<String,dynamic>> confirmar(String id) async =>
      _object(await _http.post(_uri('/${Uri.encodeComponent(id)}/confirmar'),
          headers: await _headers()));

  Future<Map<String,dynamic>> cancelar(String id, String motivo) async =>
      _object(await _http.post(_uri('/${Uri.encodeComponent(id)}/cancelar'),
          headers: await _headers(), body: jsonEncode({'motivo': motivo})));
}

class CompraApiException implements Exception {
  const CompraApiException(this.statusCode, this.details);
  final int statusCode;
  final String details;
  @override
  String toString() => switch (statusCode) {
    400 => 'Dados da compra inválidos: $details',
    401 => 'Sessão encerrada. Entre novamente.',
    403 => 'Permissão insuficiente para esta operação.',
    404 => 'Compra não encontrada neste comércio.',
    409 => 'Conflito na compra: atualize os dados ou regularize pagamentos/recebimentos.',
    422 => 'Verifique os itens e os campos obrigatórios.',
    _ => 'Não foi possível concluir a operação (HTTP $statusCode).',
  };
}
