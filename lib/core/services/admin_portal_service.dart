import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

enum AdminRequestWindowUnit {
  minutes('MINUTES'),
  hours('HOURS');

  const AdminRequestWindowUnit(this.apiValue);

  final String apiValue;

  static AdminRequestWindowUnit fromApiValue(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'HOURS':
        return AdminRequestWindowUnit.hours;
      case 'MINUTES':
      default:
        return AdminRequestWindowUnit.minutes;
    }
  }
}

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

  factory AdminActuatorResumo.fromJson(Map<String, dynamic> json) =>
      AdminActuatorResumo(
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

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _toDouble(dynamic value) =>
      value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? 0;
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

  factory AdminBancoDadosResumo.fromJson(Map<String, dynamic> json) =>
      AdminBancoDadosResumo(
        nome: json['nome']?.toString() ?? 'MongoDB',
        tamanhoDadosBytes: _toInt(json['tamanhoDadosBytes']),
        tamanhoArmazenadoBytes: _toInt(json['tamanhoArmazenadoBytes']),
        tamanhoIndicesBytes: _toInt(json['tamanhoIndicesBytes']),
        tamanhoTotalBytes: _toInt(json['tamanhoTotalBytes']),
        quantidadeColecoes: _toInt(json['quantidadeColecoes']),
        quantidadeObjetos: _toInt(json['quantidadeObjetos']),
      );

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}

class AdminRequestStatusResumo {
  const AdminRequestStatusResumo({
    required this.status200,
    required this.status400,
    required this.status500,
    required this.janelaValor,
    required this.janelaUnidade,
  });

  final int status200;
  final int status400;
  final int status500;
  final int janelaValor;
  final AdminRequestWindowUnit janelaUnidade;

  factory AdminRequestStatusResumo.fromJson(Map<String, dynamic> json) =>
      AdminRequestStatusResumo(
        status200: _toInt(json['status200']),
        status400: _toInt(json['status400']),
        status500: _toInt(json['status500']),
        janelaValor: _toInt(json['janelaValor']),
        janelaUnidade: AdminRequestWindowUnit.fromApiValue(
          json['janelaUnidade']?.toString(),
        ),
      );

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}

class AdminPortalResumo {
  const AdminPortalResumo({
    required this.totalEmpresasCadastradas,
    required this.totalEmpresasAtivas,
    this.bancosDeDados = const <AdminBancoDadosResumo>[],
    this.actuator,
    this.requestsHttp,
  });

  final int totalEmpresasCadastradas;
  final int totalEmpresasAtivas;
  final List<AdminBancoDadosResumo> bancosDeDados;
  final AdminActuatorResumo? actuator;
  final AdminRequestStatusResumo? requestsHttp;

  factory AdminPortalResumo.fromJson(Map<String, dynamic> json) {
    final dynamic bancosRaw = json['bancosDeDados'];
    final dynamic actuatorRaw = json['actuator'];
    final dynamic requestsRaw = json['requestsHttp'];
    return AdminPortalResumo(
      totalEmpresasCadastradas: _toInt(json['totalEmpresasCadastradas']),
      totalEmpresasAtivas: _toInt(json['totalEmpresasAtivas']),
      bancosDeDados:
          bancosRaw is List
              ? bancosRaw
                  .whereType<Map<String, dynamic>>()
                  .map(AdminBancoDadosResumo.fromJson)
                  .toList(growable: false)
              : const <AdminBancoDadosResumo>[],
      actuator:
          actuatorRaw is Map<String, dynamic>
              ? AdminActuatorResumo.fromJson(actuatorRaw)
              : null,
      requestsHttp:
          requestsRaw is Map<String, dynamic>
              ? AdminRequestStatusResumo.fromJson(requestsRaw)
              : null,
    );
  }

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}

class AdminEmpresaAtiva {
  const AdminEmpresaAtiva({
    required this.idUnicoDaEmpresa,
    required this.nomeEmpresa,
    required this.nomeFantasia,
    required this.documentoNoBrasilCNPJ,
    required this.ativo,
    required this.dataCadastro,
    required this.usuarios,
  });

  final String idUnicoDaEmpresa;
  final String nomeEmpresa;
  final String nomeFantasia;
  final String documentoNoBrasilCNPJ;
  final bool ativo;
  final DateTime? dataCadastro;
  final List<AdminUsuarioEmpresaAtiva> usuarios;

  String get nomeExibicao {
    if (nomeFantasia.trim().isNotEmpty) return nomeFantasia.trim();
    if (nomeEmpresa.trim().isNotEmpty) return nomeEmpresa.trim();
    return idUnicoDaEmpresa;
  }

  factory AdminEmpresaAtiva.fromJson(Map<String, dynamic> json) {
    final dynamic usuariosRaw = json['usuarios'];
    return AdminEmpresaAtiva(
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      nomeEmpresa: json['nomeEmpresa']?.toString() ?? '',
      nomeFantasia: json['nomeFantasia']?.toString() ?? '',
      documentoNoBrasilCNPJ: json['documentoNoBrasilCNPJ']?.toString() ?? '',
      ativo: json['ativo'] == true,
      dataCadastro: _parseDate(json['dataCadastro']),
      usuarios:
          usuariosRaw is List
              ? usuariosRaw
                  .whereType<Map<String, dynamic>>()
                  .map(AdminUsuarioEmpresaAtiva.fromJson)
                  .toList(growable: false)
              : const <AdminUsuarioEmpresaAtiva>[],
    );
  }
}

class AdminUsuarioEmpresaAtiva {
  const AdminUsuarioEmpresaAtiva({
    required this.idUnicoDoUsuario,
    required this.keycloakId,
    required this.nome,
    required this.email,
    required this.celular,
    required this.tipoDoAssinante,
    required this.papel,
    required this.status,
    required this.dataCadastro,
  });

  final String idUnicoDoUsuario;
  final String keycloakId;
  final String nome;
  final String email;
  final String celular;
  final String tipoDoAssinante;
  final String papel;
  final String status;
  final DateTime? dataCadastro;

  String get nomeExibicao {
    if (nome.trim().isNotEmpty) return nome.trim();
    if (email.trim().isNotEmpty) return email.trim();
    if (celular.trim().isNotEmpty) return celular.trim();
    if (idUnicoDoUsuario.trim().isNotEmpty) return idUnicoDoUsuario.trim();
    return keycloakId.trim();
  }

  factory AdminUsuarioEmpresaAtiva.fromJson(Map<String, dynamic> json) {
    return AdminUsuarioEmpresaAtiva(
      idUnicoDoUsuario: json['idUnicoDoUsuario']?.toString() ?? '',
      keycloakId: json['keycloakId']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      celular: json['celular']?.toString() ?? '',
      tipoDoAssinante: json['tipoDoAssinante']?.toString() ?? '',
      papel: json['papel']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      dataCadastro: _parseDate(json['dataCadastro']),
    );
  }
}

class AdminAiFeedbackResumo {
  const AdminAiFeedbackResumo({
    required this.total,
    required this.ajudou,
    required this.naoAjudou,
    required this.aderenciaPercentual,
  });

  final int total;
  final int ajudou;
  final int naoAjudou;
  final double aderenciaPercentual;

  factory AdminAiFeedbackResumo.fromJson(Map<String, dynamic> json) =>
      AdminAiFeedbackResumo(
        total: _toInt(json['total']),
        ajudou: _toInt(json['ajudou']),
        naoAjudou: _toInt(json['naoAjudou']),
        aderenciaPercentual: _toDouble(json['aderenciaPercentual']),
      );

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _toDouble(dynamic value) =>
      value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? 0;
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
    return <String, String>{
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<AdminPortalResumo> buscarResumo({
    int? janelaValor,
    AdminRequestWindowUnit? janelaUnidade,
  }) async {
    final String baseUrl = AppConfig.baseUrl;
    if (baseUrl.trim().isEmpty) {
      throw Exception('API_BASE_URL não configurado.');
    }
    final Uri uri = Uri.parse('$baseUrl/private/api/admin/resumo').replace(
      queryParameters: <String, String>{
        if (janelaValor != null) 'janelaValor': janelaValor.toString(),
        if (janelaUnidade != null) 'janelaUnidade': janelaUnidade.apiValue,
      },
    );
    final http.Response response = await _client.get(
      uri,
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return AdminPortalResumo.fromJson(decoded);
      }
      throw Exception('Resposta inválida do resumo administrativo.');
    }
    if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Seu usuário não possui autorização para acessar o portal administrativo.',
      );
    }
    throw Exception(
      'Falha ao carregar resumo administrativo (${response.statusCode}).',
    );
  }

  Future<List<AdminEmpresaAtiva>> listarUsuariosAtivos() async {
    final String baseUrl = AppConfig.baseUrl;
    if (baseUrl.trim().isEmpty) {
      throw Exception('API_BASE_URL não configurado.');
    }
    final http.Response response = await _client.get(
      Uri.parse('$baseUrl/private/api/admin/usuarios-ativos'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(AdminEmpresaAtiva.fromJson)
            .toList(growable: false);
      }
      throw Exception('Resposta inválida dos usuários ativos.');
    }
    if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Seu usuário não possui autorização para acessar o portal administrativo.',
      );
    }
    throw Exception(
      'Falha ao carregar usuários ativos (${response.statusCode}).',
    );
  }

  Future<List<AdminUsuarioEmpresaAtiva>> listarUsuariosSixo() async {
    final String baseUrl = AppConfig.baseUrl;
    if (baseUrl.trim().isEmpty) {
      throw Exception('API_BASE_URL não configurado.');
    }
    final http.Response response = await _client.get(
      Uri.parse('$baseUrl/private/api/admin/usuarios-sixo'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(AdminUsuarioEmpresaAtiva.fromJson)
            .toList(growable: false);
      }
      throw Exception('Resposta inválida dos usuários do Sixo.');
    }
    if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Seu usuário não possui autorização para acessar os usuários do Sixo.',
      );
    }
    throw Exception(
      'Falha ao carregar usuários do Sixo (${response.statusCode}).',
    );
  }

  Future<AdminAiFeedbackResumo> buscarResumoFeedbackIa() async {
    final String baseUrl = AppConfig.baseUrl;
    if (baseUrl.trim().isEmpty) {
      throw Exception('API_BASE_URL não configurado.');
    }
    final http.Response response = await _client.get(
      Uri.parse('$baseUrl/private/api/admin/ia/feedbacks/resumo'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return AdminAiFeedbackResumo.fromJson(decoded);
      }
      throw Exception('Resposta inválida das métricas de IA.');
    }
    if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Seu usuário não possui autorização para acessar o portal administrativo.',
      );
    }
    throw Exception(
      'Falha ao carregar métricas da IA (${response.statusCode}).',
    );
  }
}

DateTime? _parseDate(dynamic value) {
  final String normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) return null;
  return DateTime.tryParse(normalized);
}
