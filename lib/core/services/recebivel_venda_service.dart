import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class RecebivelVenda {
  RecebivelVenda.fromJson(Map<String, dynamic> j)
    : id = j['id'].toString(),
      codigoOperacao = j['codigoOperacao']?.toString() ?? '',
      descricao = j['descricao']?.toString() ?? '',
      conta = j['contaNome']?.toString() ?? '',
      maquininha = j['maquininhaNome']?.toString() ?? '',
      status = j['status'].toString(),
      bruto = (j['bruto'] as num).toDouble(),
      taxa = (j['taxa'] as num).toDouble(),
      liquido = (j['liquido'] as num).toDouble(),
      data = DateTime.parse(j['dataPrevista']),
      valorRecebido = (j['valorRecebido'] as num?)?.toDouble(),
      dataRecebimento = DateTime.tryParse(
        j['dataRecebimento']?.toString() ?? '',
      );
  final String id, codigoOperacao, descricao, conta, maquininha, status;
  final double bruto, taxa, liquido;
  final DateTime data;
  final double? valorRecebido;
  final DateTime? dataRecebimento;
}

class RecebivelVendaService {
  final http.Client _client = createHttpClient();
  void dispose() => _client.close();
  Future<Map<String, String>> _headers() async {
    final auth = AuthService();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await auth.getAccessToken()}',
      'idUnicoDaEmpresa': await auth.getEmpresaId() ?? '',
    };
  }

  Uri _uri([String path = '']) => Uri.parse(
    '${AppConfig.baseUrl}/private/api/agenda-financeira/recebiveis-vendas$path',
  );
  Future<List<RecebivelVenda>> listar() async {
    final r = await _client.get(_uri(), headers: await _headers());
    _check(r);
    return (jsonDecode(r.body) as List)
        .map((j) => RecebivelVenda.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<void> confirmar(String id, DateTime data, double valor) async {
    _check(
      await _client.post(
        _uri('/$id/confirmar'),
        headers: await _headers(),
        body: jsonEncode({
          'dataRecebimento': data.toIso8601String().split('T').first,
          'valorRecebido': valor,
        }),
      ),
    );
  }

  Future<void> estornar(String id) async {
    _check(
      await _client.post(_uri('/$id/estornar'), headers: await _headers()),
    );
  }

  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception('RECEBIVEL_REQUEST_FAILED');
  }
}
