import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class AdminBancoDadosResumo {
  const AdminBancoDadosResumo({
    required this.nome,
    required this.tamanhoDadosBytes,
    required this.tamanhoArmazenadoBytes,
    required this.tamanhoIndicesBytes,
    required this.tamanhoTotalBytes,
    required this.quantidadeColecoes,
    required this.quantidadeObjetos,
  });

  final String nome;
  final int tamanhoDadosBytes;
  final int tamanhoArmazenadoBytes;
  final int tamanhoIndicesBytes;
  final int tamanhoTotalBytes;
  final int quantidadeColecoes;
  final int quantidadeObjetos;

  factory AdminBancoDadosResumo.fromJson(Map<String, dynamic> json) {
    return AdminBancoDadosResumo(
      nome: json['nome']?.toString() ?? 'MongoDB',
      tamanhoDadosBytes: _toInt(json['tamanhoDadosBytes']),
      tamanhoArmazenadoBytes: _toInt(json['tamanhoArmazenadoBytes']),
      tamanhoIndicesBytes: _toInt(json['tamanhoIndicesBytes']),
      tamanhoTotalBytes: _toInt(json['tamanhoTotalBytes']),
      quantidadeColecoes: _toInt(json['quantidadeColecoes']),
      quantidadeObjetos: _toInt(json['quantidadeObjetos']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AdminPortalResumo {
  const AdminPortalResumo({
    required this.totalEmpresasCadastradas,
    required this.totalEmpresasAtivas,
    this.bancosDeDados = const <AdminBancoDadosResumo>[],
  });

  final int totalEmpresasCadastradas;
  final int totalEmpresasAtivas;
  final List<AdminBancoDadosResumo> bancosDeDados;

  factory AdminPortalResumo.fromJson(Map<String, dynamic> json) {
    final dynamic bancosRaw = json['bancosDeDados'];
    final List<AdminBancoDadosResumo> bancos = bancosRaw is List
        ? bancosRaw
            .whereType<Map<String, dynamic>>()
            .map(AdminBancoDadosResumo.fromJson)
            .toList(growable: false)
        : const <AdminBancoDadosResumo>[];

    return AdminPortalResumo(
      totalEmpresasCadastradas: _toInt(json['totalEmpresasCadastradas']),
      totalEmpresasAtivas: _toInt(json['totalEmpresasAtivas']),
      bancosDeDados: bancos,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AdminPortalService {
  AdminPortalService({AuthService? authService, http.Client? client})
      : _authService = authService ?? AuthService(),
        _client = client ?? createHttpClient();

  final AuthService _authService;
  final http.Client _client;

  Future<AdminPortalResumo> buscarResumo() async {
    final String? token = await _authService.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    final String baseUrl = AppConfig.baseUrl;
    if (baseUrl.trim().isEmpty) {
      throw Exception('API_BASE_URL não configurado.');
    }

    final Uri uri = Uri.parse('$baseUrl/private/api/admin/resumo');
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return AdminPortalResumo.fromJson(decoded);
      }
      throw Exception('Resposta inválida do resumo administrativo.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Você precisa fazer login para acessar o portal administrativo.');
    }

    throw Exception('Falha ao carregar resumo administrativo (${response.statusCode}).');
  }
}
