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
