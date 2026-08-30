import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/onboarding_inicial_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class OnboardingInicialService {
  OnboardingInicialService({AuthService? authService, http.Client? client})
    : _authService = authService ?? AuthService(),
      _client = client ?? createHttpClient();

  final AuthService _authService;
  final http.Client _client;

  Uri get _uri => Uri.parse(
    '${AppConfig.baseUrl}/private/api/onboarding-inicial',
  );

  Future<OnboardingInicialModel> buscar() async {
    final http.Response response = await _client.get(
      _uri,
      headers: await _headers(contentType: false),
    );
    return _decode(response);
  }

  Future<OnboardingInicialModel> concluir(
    ConcluirOnboardingInicialRequest request,
  ) async {
    final http.Response response = await _client.put(
      _uri,
      headers: await _headers(contentType: true),
      body: jsonEncode(request.toJson()),
    );
    return _decode(response);
  }

  Future<Map<String, String>> _headers({required bool contentType}) async {
    final String? token = await _authService.getAccessToken();
    final String? empresaId = await _authService.getEmpresaId();
    if (token == null ||
        token.trim().isEmpty ||
        empresaId == null ||
        empresaId.trim().isEmpty) {
      throw const OnboardingInicialException(statusCode: 401);
    }
    return <String, String>{
      'accept': 'application/json',
      if (contentType) 'Content-Type': 'application/json',
      'idUnicoDaEmpresa': empresaId,
      'Authorization': 'Bearer $token',
    };
  }

  OnboardingInicialModel _decode(http.Response response) {
    if (response.statusCode != 200) {
      String? code;
      try {
        final dynamic body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          code = body['codigo']?.toString() ?? body['code']?.toString();
        }
      } catch (_) {
        // A tela resolve a falha pelo status quando a API não retorna JSON.
      }
      throw OnboardingInicialException(
        statusCode: response.statusCode,
        code: code,
      );
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const OnboardingInicialException(statusCode: 0);
    }
    return OnboardingInicialModel.fromJson(decoded);
  }
}

class OnboardingInicialException implements Exception {
  const OnboardingInicialException({required this.statusCode, this.code});

  final int statusCode;
  final String? code;

  @override
  String toString() =>
      'OnboardingInicialException(statusCode: $statusCode, code: $code)';
}
