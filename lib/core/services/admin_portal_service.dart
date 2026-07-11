import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class AdminActuatorResumo {
  const AdminActuatorResumo({
    required this.status,
    required this.uptimeSegundos,
    required this.memoriaHeapUsadaBytes,
    required this.memoriaHeapMaxBytes,
    required this.memoriaNonHeapUsadaBytes,
    required this.memoriaNonHeapMaxBytes,
    required this.threadsAtivas,
    required this.threadsPico,
    required this.threadsDaemon,
    required this.processadoresDisponiveis,
    required this.cargaSistema,
    required this.versaoJava,
  });

  final String status;
  final int uptimeSegundos;
  final int memoriaHeapUsadaBytes;
  final int memoriaHeapMaxBytes;
  final int memoriaNonHeapUsadaBytes;
  final int memoriaNonHeapMaxBytes;
  final int threadsAtivas;
  final int threadsPico;
  final int threadsDaemon;
  final int processadoresDisponiveis;
  final double cargaSistema;
  final String versaoJava;

  factory AdminActuatorResumo.fromJson(Map<String, dynamic> json) => AdminActuatorResumo(
    status: json['status']?.toString() ?? 'UNKNOWN',
    uptimeSegundos: _toInt(json['uptimeSegundos']),
    memoriaHeapUsadaBytes: _toInt(json['memoriaHeapUsadaBytes']),
    memoriaHeapMaxBytes: _toInt(json['memoriaHeapMaxBytes']),
    memoriaNonHeapUsadaBytes: _toInt(json['memoriaNonHeapUsadaBytes']),
    memoriaNonHeapMaxBytes: _toInt(json['memoriaNonHeapMaxBytes']),
    threadsAtivas: _toInt(json['threadsAtivas']),
    threadsPico: _toInt(json['threadsPico']),
    threadsDaemon: _toInt(json['threadsDaemon']),
    processadoresDisponiveis: _toInt(json['processadoresDisponiveis']),
    cargaSistema: _toDouble(json['cargaSistema']),
    versaoJava: json['versaoJava']?.toString() ?? '-',
  );

  static int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _toDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}

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

  factory AdminBancoDadosResumo.fromJson(Map<String, dynamic> json) => AdminBancoDadosResumo(
    nome: json['nome']?.toString() ?? 'MongoDB',
    tamanhoDadosBytes: _toInt(json['tamanhoDadosBytes']),
    tamanhoArmazenadoBytes: _toInt(json['tamanhoArmazenadoBytes']),
    tamanhoIndicesBytes: _toInt(json['tamanhoIndicesBytes']),
    tamanhoTotalBytes: _toInt(json['tamanhoTotalBytes']),
    quantidadeColecoes: _toInt(json['quantidadeColecoes']),
    quantidadeObjetos: _toInt(json['quantidadeObjetos']),
  );

  static int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}

class AdminPortalResumo {
  const AdminPortalResumo({
    required this.totalEmpresasCadastradas,
    required this.totalEmpresasAtivas,
    this.bancosDeDados = const <AdminBancoDadosResumo>[],
    this.actuator,
  });

  final int totalEmpresasCadastradas;
  final int totalEmpresasAtivas;
  final List<AdminBancoDadosResumo> bancosDeDados;
  final AdminActuatorResumo? actuator;

  factory AdminPortalResumo.fromJson(Map<String, dynamic> json) {
    final dynamic bancosRaw = json['bancosDeDados'];
    final dynamic actuatorRaw = json['actuator'];
    return AdminPortalResumo(
      totalEmpresasCadastradas: _toInt(json['totalEmpresasCadastradas']),
      totalEmpresasAtivas: _toInt(json['totalEmpresasAtivas']),
      bancosDeDados: bancosRaw is List
          ? bancosRaw.whereType<Map<String, dynamic>>().map(AdminBancoDadosResumo.fromJson).toList(growable: false)
          : const <AdminBancoDadosResumo>[],
      actuator: actuatorRaw is Map<String, dynamic> ? AdminActuatorResumo.fromJson(actuatorRaw) : null,
    );
  }

  static int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}

class AdminAiFeedbackResumo {
  const AdminAiFeedbackResumo({required this.total, required this.ajudou, required this.naoAjudou, required this.aderenciaPercentual});

  final int total;
  final int ajudou;
  final int naoAjudou;
  final double aderenciaPercentual;

  factory AdminAiFeedbackResumo.fromJson(Map<String, dynamic> json) => AdminAiFeedbackResumo(
    total: _toInt(json['total']),
    ajudou: _toInt(json['ajudou']),
    naoAjudou: _toInt(json['naoAjudou']),
    aderenciaPercentual: _toDouble(json['aderenciaPercentual']),
  );

  static int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _toDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}

class AdminPortalService {
  AdminPortalService({AuthService? authService, http.Client? client})
      : _authService = authService ?? AuthService(),
        _client = client ?? createHttpClient();

  final AuthService _authService;
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final String? token = await _authService.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    return <String, String>{'accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<AdminPortalResumo> buscarResumo() async {
    final String baseUrl = AppConfig.baseUrl;
    if (baseUrl.trim().isEmpty) throw Exception('API_BASE_URL não configurado.');
    final http.Response response = await _client.get(Uri.parse('$baseUrl/private/api/admin/resumo'), headers: await _headers());
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return AdminPortalResumo.fromJson(decoded);
      throw Exception('Resposta inválida do resumo administrativo.');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Você precisa fazer login para acessar o portal administrativo.');
    }
    throw Exception('Falha ao carregar resumo administrativo (${response.statusCode}).');
  }

  Future<AdminAiFeedbackResumo> buscarResumoFeedbackIa() async {
    final String baseUrl = AppConfig.baseUrl;
    if (baseUrl.trim().isEmpty) throw Exception('API_BASE_URL não configurado.');
    final http.Response response = await _client.get(
      Uri.parse('$baseUrl/private/api/admin/ia/feedbacks/resumo'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return AdminAiFeedbackResumo.fromJson(decoded);
      throw Exception('Resposta inválida das métricas de IA.');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Você precisa fazer login para acessar o portal administrativo.');
    }
    throw Exception('Falha ao carregar métricas da IA (${response.statusCode}).');
  }
}
