import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class AdminIdeaModel {
  const AdminIdeaModel({
    required this.id,
    required this.empresaId,
    required this.usuarioId,
    required this.descricao,
    required this.modulo,
    required this.telaAtual,
    required this.plataforma,
    required this.idioma,
    required this.status,
    required this.criadaEm,
  });

  final String id;
  final String empresaId;
  final String usuarioId;
  final String descricao;
  final String modulo;
  final String telaAtual;
  final String plataforma;
  final String idioma;
  final String status;
  final DateTime? criadaEm;

  factory AdminIdeaModel.fromJson(Map<String, dynamic> json) {
    return AdminIdeaModel(
      id: json['id']?.toString() ?? '',
      empresaId: json['idUnicoDaEmpresa']?.toString() ?? '',
      usuarioId: json['idUnicoDoUsuario']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      modulo: json['modulo']?.toString() ?? 'geral',
      telaAtual: json['telaAtual']?.toString() ?? '-',
      plataforma: json['plataforma']?.toString() ?? '-',
      idioma: json['idioma']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'RECEBIDA',
      criadaEm: DateTime.tryParse(json['criadaEm']?.toString() ?? ''),
    );
  }
}

class AdminIdeasService {
  AdminIdeasService({AuthService? authService, http.Client? client})
      : _authService = authService ?? AuthService(),
        _client = client ?? createHttpClient();

  final AuthService _authService;
  final http.Client _client;

  Future<List<AdminIdeaModel>> listar() async {
    final String? token = await _authService.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/admin/novas-ideias');
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(AdminIdeaModel.fromJson)
            .toList(growable: false);
      }
      throw Exception('Resposta inválida ao carregar as ideias.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Você não possui acesso ao portal administrativo.');
    }

    throw Exception('Falha ao carregar as ideias (${response.statusCode}).');
  }
}
