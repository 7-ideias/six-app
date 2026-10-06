import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';
import 'agenda_financeira_lancamento_service.dart';

class ConfiguracaoFinanceira {
  const ConfiguracaoFinanceira({
    required this.id,
    required this.nome,
    required this.tipo,
    this.instituicao = '',
    this.ativo = true,
    this.codigo,
    this.centroPaiId,
  });
  final String id, nome, tipo, instituicao;
  final bool ativo;
  final String? codigo;
  final String? centroPaiId;
  factory ConfiguracaoFinanceira.fromJson(Map<String, dynamic> json) =>
      ConfiguracaoFinanceira(
        id: json['id'].toString(),
        nome: json['nome'] as String,
        tipo: json['tipo'] as String,
        instituicao: json['instituicao']?.toString() ?? '',
        ativo: json['ativo'] == true,
        codigo: json['codigo']?.toString(),
        centroPaiId: json['centroPaiId']?.toString(),
      );
}

class ConfiguracaoFinanceiraService {
  ConfiguracaoFinanceiraService(this.espaco, {http.Client? client})
    : _client = client ?? createHttpClient();
  final String espaco;
  final http.Client _client;
  void dispose() => _client.close();
  Future<Map<String, String>> _headers() async {
    final auth = AuthService();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await auth.getAccessToken()}',
      'idUnicoDaEmpresa': await auth.getEmpresaId() ?? '',
      'espacoFinanceiro': espaco,
    };
  }

  Uri _uri(String grupo, [String? id]) => Uri.parse(
    '${AppConfig.baseUrl}/private/api/agenda-financeira/${grupo == 'CENTROS' ? 'centros-custo' : 'configuracoes/$grupo'}${id == null ? '' : '/$id'}',
  );
  Future<List<ConfiguracaoFinanceira>> listar(String grupo) async {
    final uri =
        grupo == 'CENTROS'
            ? _uri(grupo).replace(queryParameters: {'incluirInativos': 'true'})
            : _uri(grupo);
    final response = await _client.get(uri, headers: await _headers());
    _check(response);
    return (jsonDecode(response.body) as List)
        .map(
          (e) => ConfiguracaoFinanceira.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<void> salvar(
    String grupo, {
    ConfiguracaoFinanceira? original,
    required String nome,
    required String tipo,
    required String instituicao,
    required bool ativo,
  }) async {
    final payload = {
      'nome': nome.trim(),
      'tipo': tipo,
      'instituicao': instituicao.trim(),
      'ativo': ativo,
      if (grupo == 'CENTROS') 'codigo': original?.codigo,
      if (grupo == 'CENTROS') 'centroPaiId': original?.centroPaiId,
    };
    final headers = await _headers();
    final response =
        original == null
            ? await _client.post(
              _uri(grupo),
              headers: headers,
              body: jsonEncode(payload),
            )
            : await _client.put(
              _uri(grupo, original.id),
              headers: headers,
              body: jsonEncode(payload),
            );
    _check(response);
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw AgendaFinanceiraLancamentoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
  }
}
