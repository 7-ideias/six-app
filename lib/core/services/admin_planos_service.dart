import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class AdminPlanoPreco {
  const AdminPlanoPreco({
    required this.currencyCode,
    required this.valor,
    required this.periodicidade,
  });

  final String currencyCode;
  final double valor;
  final String periodicidade;

  factory AdminPlanoPreco.fromJson(Map<String, dynamic> json) {
    return AdminPlanoPreco(
      currencyCode: json['currencyCode']?.toString() ?? '',
      valor: _toDouble(json['valor']),
      periodicidade: json['periodicidade']?.toString() ?? 'MENSAL',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currencyCode': currencyCode.trim().toUpperCase(),
    'valor': valor,
    'periodicidade': periodicidade.trim().toUpperCase(),
  };
}

class AdminPlanoCondicoes {
  const AdminPlanoCondicoes({
    required this.diasTeste,
    required this.limiteUsuarios,
    required this.mesesFidelidade,
    required this.cancelamentoLivre,
  });

  final int diasTeste;
  final int? limiteUsuarios;
  final int mesesFidelidade;
  final bool cancelamentoLivre;

  factory AdminPlanoCondicoes.fromJson(Map<String, dynamic>? json) {
    return AdminPlanoCondicoes(
      diasTeste: _toInt(json?['diasTeste']),
      limiteUsuarios:
          json?['limiteUsuarios'] == null
              ? null
              : _toInt(json?['limiteUsuarios']),
      mesesFidelidade: _toInt(json?['mesesFidelidade']),
      cancelamentoLivre: json?['cancelamentoLivre'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'diasTeste': diasTeste,
    'limiteUsuarios': limiteUsuarios,
    'mesesFidelidade': mesesFidelidade,
    'cancelamentoLivre': cancelamentoLivre,
  };
}

class AdminPlanoTraducao {
  const AdminPlanoTraducao({
    required this.nome,
    required this.descricao,
    required this.chamadaAcao,
    required this.beneficios,
  });

  final String nome;
  final String descricao;
  final String chamadaAcao;
  final List<String> beneficios;

  factory AdminPlanoTraducao.fromJson(Map<String, dynamic>? json) {
    final dynamic beneficiosRaw = json?['beneficios'];
    return AdminPlanoTraducao(
      nome: json?['nome']?.toString() ?? '',
      descricao: json?['descricao']?.toString() ?? '',
      chamadaAcao: json?['chamadaAcao']?.toString() ?? '',
      beneficios:
          beneficiosRaw is List
              ? beneficiosRaw
                  .map((dynamic value) => value.toString().trim())
                  .where((String value) => value.isNotEmpty)
                  .toList(growable: false)
              : const <String>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nome': nome.trim(),
    'descricao': descricao.trim(),
    'chamadaAcao': chamadaAcao.trim(),
    'beneficios': beneficios,
  };
}

class AdminPlanoPublico {
  const AdminPlanoPublico({
    required this.id,
    required this.codigo,
    required this.status,
    required this.destaque,
    required this.ordemExibicao,
    required this.precos,
    required this.condicoes,
    required this.traducoes,
    required this.criadoEm,
    required this.atualizadoEm,
    required this.atualizadoPor,
  });

  final String id;
  final String codigo;
  final String status;
  final bool destaque;
  final int ordemExibicao;
  final List<AdminPlanoPreco> precos;
  final AdminPlanoCondicoes condicoes;
  final Map<String, AdminPlanoTraducao> traducoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final String atualizadoPor;

  factory AdminPlanoPublico.fromJson(Map<String, dynamic> json) {
    final dynamic precosRaw = json['precos'];
    final dynamic traducoesRaw = json['traducoes'];
    final Map<String, AdminPlanoTraducao> traducoes =
        <String, AdminPlanoTraducao>{};
    if (traducoesRaw is Map) {
      traducoesRaw.forEach((dynamic key, dynamic value) {
        if (value is Map<String, dynamic>) {
          traducoes[key.toString()] = AdminPlanoTraducao.fromJson(value);
        }
      });
    }
    return AdminPlanoPublico(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      status: json['status']?.toString() ?? 'RASCUNHO',
      destaque: json['destaque'] == true,
      ordemExibicao: _toInt(json['ordemExibicao']),
      precos:
          precosRaw is List
              ? precosRaw
                  .whereType<Map<String, dynamic>>()
                  .map(AdminPlanoPreco.fromJson)
                  .toList(growable: false)
              : const <AdminPlanoPreco>[],
      condicoes: AdminPlanoCondicoes.fromJson(
        json['condicoes'] is Map<String, dynamic>
            ? json['condicoes'] as Map<String, dynamic>
            : null,
      ),
      traducoes: Map<String, AdminPlanoTraducao>.unmodifiable(traducoes),
      criadoEm: _toDateTime(json['criadoEm']),
      atualizadoEm: _toDateTime(json['atualizadoEm']),
      atualizadoPor: json['atualizadoPor']?.toString() ?? '',
    );
  }
}

class AdminPlanoSalvarInput {
  const AdminPlanoSalvarInput({
    required this.codigo,
    required this.status,
    required this.destaque,
    required this.ordemExibicao,
    required this.precos,
    required this.condicoes,
    required this.traducoes,
  });

  final String codigo;
  final String status;
  final bool destaque;
  final int ordemExibicao;
  final List<AdminPlanoPreco> precos;
  final AdminPlanoCondicoes condicoes;
  final Map<String, AdminPlanoTraducao> traducoes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'codigo': codigo.trim().toUpperCase(),
    'status': status.trim().toUpperCase(),
    'destaque': destaque,
    'ordemExibicao': ordemExibicao,
    'precos': precos.map((AdminPlanoPreco preco) => preco.toJson()).toList(),
    'condicoes': condicoes.toJson(),
    'traducoes': traducoes.map(
      (String locale, AdminPlanoTraducao traducao) =>
          MapEntry<String, dynamic>(locale, traducao.toJson()),
    ),
  };
}

class AdminPlanosService {
  AdminPlanosService({AuthService? authService, http.Client? client})
    : _authService = authService ?? AuthService(),
      _client = client ?? createHttpClient();

  final AuthService _authService;
  final http.Client _client;

  Future<List<AdminPlanoPublico>> listar() async {
    final http.Response response = await _client.get(
      _endpoint(),
      headers: await _headers(),
    );
    _validarResposta(response, const <int>{200});
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw Exception('Resposta inválida dos planos administrativos.');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AdminPlanoPublico.fromJson)
        .toList(growable: false);
  }

  Future<AdminPlanoPublico> salvar({
    String? id,
    required AdminPlanoSalvarInput input,
  }) async {
    final Uri uri = id == null || id.trim().isEmpty ? _endpoint() : _endpoint(id);
    final String body = jsonEncode(input.toJson());
    final http.Response response =
        id == null || id.trim().isEmpty
            ? await _client.post(uri, headers: await _headers(), body: body)
            : await _client.put(uri, headers: await _headers(), body: body);
    _validarResposta(response, const <int>{200, 201});
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao salvar o plano.');
    }
    return AdminPlanoPublico.fromJson(decoded);
  }

  Future<void> arquivar(String id) async {
    final http.Response response = await _client.delete(
      _endpoint(id),
      headers: await _headers(),
    );
    _validarResposta(response, const <int>{204});
  }

  Uri _endpoint([String? id]) {
    final String baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL não configurado.');
    }
    final String suffix = id == null ? '' : '/${Uri.encodeComponent(id)}';
    return Uri.parse('$baseUrl/private/api/admin/planos$suffix');
  }

  Future<Map<String, String>> _headers() async {
    final String? token = await _authService.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    return <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _validarResposta(http.Response response, Set<int> aceitos) {
    if (aceitos.contains(response.statusCode)) return;
    if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    if (response.statusCode == 403) {
      throw Exception('Seu usuário não possui a role administrativa necessária.');
    }
    String detalhe = '';
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        detalhe =
            decoded['detail']?.toString() ??
            decoded['message']?.toString() ??
            decoded['mensagem']?.toString() ??
            '';
      }
    } catch (_) {}
    throw Exception(
      detalhe.trim().isEmpty
          ? 'Falha na operação de planos (${response.statusCode}).'
          : detalhe,
    );
  }
}

int _toInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

double _toDouble(dynamic value) =>
    value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _toDateTime(dynamic value) {
  final String normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : DateTime.tryParse(normalized);
}
