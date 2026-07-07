import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/colaborador_convite_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class ColaboradorConviteWebService {
  final AuthService _authService;
  final http.Client _client;

  ColaboradorConviteWebService({
    AuthService? authService,
    http.Client? client,
  })  : _authService = authService ?? AuthService(),
        _client = client ?? createHttpClient();

  Future<ColaboradorConviteResponse> criarConvite(
    ColaboradorConviteRequest request,
  ) async {
    final String? token = await _authService.getAccessToken();
    final String? empresaId = await _authService.getEmpresaId();

    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/colaborador/convites');
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'idUnicoDaEmpresa': empresaId ?? '',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao gerar convite de colaborador: ${response.statusCode} ${response.body}');
    }

    return ColaboradorConviteResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ColaboradorConvitePublicoResponse> validarConvitePublico(
    String codigo,
  ) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/public/api/colaborador/convites/$codigo');
    final http.Response response = await _client.get(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao validar convite de colaborador: ${response.statusCode} ${response.body}');
    }

    return ColaboradorConvitePublicoResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ColaboradorConviteResponse> confirmarEmailConvite(
    String codigo,
    String email,
  ) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/public/api/colaborador/convites/$codigo/confirmar-email');
    final http.Response response = await _client.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{'email': email.trim()}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao confirmar e-mail do convite: ${response.statusCode} ${response.body}');
    }

    return ColaboradorConviteResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> aceitarConvite(String codigo) async {
    final String? token = await _authService.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Faça login com o e-mail convidado para aceitar este convite.');
    }

    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/colaborador/convites/$codigo/aceitar');
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao aceitar convite de colaborador: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<EmpresaVinculoWebModel>> listarVinculos() async {
    final String? token = await _authService.getAccessToken();
    final Uri uri = Uri.parse('${AppConfig.baseUrl}/private/api/usuario/empresas-vinculos');
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar vínculos do usuário: ${response.statusCode} ${response.body}');
    }

    final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(EmpresaVinculoWebModel.fromJson)
        .toList(growable: false);
  }
}
