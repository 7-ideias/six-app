import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';
import 'agenda_financeira_lancamento_service.dart';
import '../../data/services/cartoes/cartao_credito_api_client.dart';
import '../../data/models/instituicao_open_finance_model.dart';

class ConfiguracaoFinanceira {
  const ConfiguracaoFinanceira({
    required this.id,
    required this.nome,
    required this.tipo,
    this.instituicao = '',
    this.ativo = true,
    this.codigo,
    this.centroPaiId,
    this.contaDestinoId,
    this.marcaId,
  });
  final String id, nome, tipo, instituicao;
  final bool ativo;
  final String? codigo;
  final String? contaDestinoId;
  final String? centroPaiId;
  final String? marcaId;
  factory ConfiguracaoFinanceira.fromJson(Map<String, dynamic> json) =>
      ConfiguracaoFinanceira(
        id: json['id'].toString(),
        nome: json['nome'] as String,
        tipo: json['tipo'] as String,
        instituicao: json['instituicao']?.toString() ?? '',
        ativo: json['ativo'] == true,
        codigo: json['codigo']?.toString(),
        contaDestinoId: json['contaDestinoId']?.toString(),
        marcaId: json['marcaId']?.toString(),
        centroPaiId: json['centroPaiId']?.toString(),
      );
}

class ConfiguracaoFinanceiraService {
  ConfiguracaoFinanceiraService(this.espaco, {http.Client? client})
    : _client = client ?? createHttpClient();
  final String espaco;
  final http.Client _client;
  late final CartaoCreditoApiClient _catalogo = CartaoCreditoApiClient(
    espaco: espaco,
  );

  /// Reutiliza exatamente o endpoint de catálogo de cartões, validando no
  /// backend o país canônico da empresa ativa (inclusive no espaço PESSOAL).
  Future<CatalogoInstituicoesBrasil> catalogoBrasileiro() =>
      _catalogo.listarInstituicoesBrasileiras();

  void dispose() {
    _client.close();
    _catalogo.dispose();
  }
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
    String? contaDestinoId,
    String? marcaId,
  }) async {
    await _persistir(
      grupo,
      original: original,
      nome: nome,
      tipo: tipo,
      instituicao: instituicao,
      ativo: ativo,
      contaDestinoId: contaDestinoId,
      marcaId: marcaId,
    );
  }

  /// Retorna o ID persistido, sem procurar por nome (nomes podem se repetir).
  Future<ConfiguracaoFinanceira> criarConta({
    required String nome,
    required String tipo,
    required String instituicao,
    String? marcaId,
  }) async {
    final response = await _persistir(
      'CONTAS',
      nome: nome,
      tipo: tipo,
      instituicao: instituicao,
      ativo: true,
      marcaId: marcaId,
    );
    final conta = ConfiguracaoFinanceira.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
    if (conta.id.trim().isEmpty || conta.id == 'null') {
      throw const FormatException('Conta sem identificador');
    }
    return conta;
  }

  Future<http.Response> _persistir(
    String grupo, {
    ConfiguracaoFinanceira? original,
    required String nome,
    required String tipo,
    required String instituicao,
    required bool ativo,
    String? contaDestinoId,
    String? marcaId,
  }) async {
    final payload = {
      'nome': nome.trim(),
      'tipo': tipo,
      'instituicao': instituicao.trim(),
      'ativo': ativo,
      'contaDestinoId': contaDestinoId,
      'marcaId': marcaId,
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
    return response;
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw AgendaFinanceiraLancamentoApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
  }
}
