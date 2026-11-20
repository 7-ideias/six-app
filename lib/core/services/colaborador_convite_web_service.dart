import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/colaborador_convite_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class ColaboradorConviteWebService {
  final AuthService _authService;
  final http.Client _client;

  ColaboradorConviteWebService({AuthService? authService, http.Client? client})
    : _authService = authService ?? AuthService(),
      _client = client ?? createHttpClient();

  Future<ColaboradorConviteResponse> criarConvite(
    ColaboradorConviteRequest request,
  ) async {
    final String? token = await _authService.getAccessToken();
    final String? empresaId = await _authService.getEmpresaId();

    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/colaborador/convites',
    );
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
      throw Exception(
        'Erro ao gerar convite de colaborador: ${response.statusCode} ${response.body}',
      );
    }

    return ColaboradorConviteResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> enviarConvitePorEmail({
    required String idConvite,
    required String linkConvite,
    required String idioma,
  }) async {
    final String? token = await _authService.getAccessToken();
    final String? empresaId = await _authService.getEmpresaId();

    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/colaborador/convites/$idConvite/enviar-email',
    );
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'idUnicoDaEmpresa': empresaId ?? '',
      },
      body: jsonEncode(<String, String>{
        'linkConvite': linkConvite,
        'idioma': idioma,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Erro ao enviar convite por e-mail: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<ColaboradorConvitePublicoResponse> validarConvitePublico(
    String codigo,
  ) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/public/api/colaborador/convites/$codigo',
    );
    final http.Response response = await _client.get(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json'},
    );

    _validarResposta(response);

    return ColaboradorConvitePublicoResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> enviarCodigo(String codigo, String idioma) async {
    await _postPublico(codigo, 'enviar-codigo', {}, idioma: idioma);
  }

  Future<({String prova, String email})> verificarCodigo(
    String codigo,
    String otp,
  ) async {
    final response = await _postPublico(codigo, 'confirmar-email', {
      'codigo': otp,
    });
    final dados = jsonDecode(response.body) as Map<String, dynamic>;
    return (prova: dados['prova'] as String, email: dados['email'] as String);
  }

  Future<void> criarSenha(String codigo, String prova, String senha) async {
    await _postPublico(codigo, 'criar-senha', {'prova': prova, 'senha': senha});
  }

  Future<http.Response> _postPublico(
    String codigo,
    String etapa,
    Map<String, String> dados, {
    String idioma = 'pt',
  }) async {
    final response = await _client
        .post(
          Uri.parse(
            '${AppConfig.baseUrl}/public/api/colaborador/convites/${Uri.encodeComponent(codigo)}/$etapa',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept-Language': idioma,
          },
          body: jsonEncode(dados),
        )
        .timeout(const Duration(seconds: 20));
    _validarResposta(response);
    return response;
  }

  void _validarResposta(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = '';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message']?.toString() ?? '';
    } on FormatException {
      /* A proxy may return HTML. */
    }
    final key = switch (message) {
      'CONVITE_EMAIL_DIVERGENTE' => 'wrongAccount',
      'CONVITE_VERIFIQUE_NOVAMENTE' => 'verifyAgain',
      'CONVITE_CODIGO_INVALIDO' => 'invalid',
      'CONVITE_ENTRAR_COM_CONTA' => 'signIn',
      _ => switch (response.statusCode) {
        401 => 'signIn',
        429 => 'wait',
        404 || 409 || 410 => 'closed',
        _ => 'unavailable',
      },
    };
    throw ConviteException(key);
  }

  Future<void> aceitarConvite(String codigo) async {
    final String? token = await _authService.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const ConviteException('signIn');
    }

    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/colaborador/convites/$codigo/aceitar',
    );
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _validarResposta(response);
  }

  Future<List<EmpresaVinculoWebModel>> listarVinculos() async {
    final String? token = await _authService.getAccessToken();
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/usuario/empresas-vinculos',
    );
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar vínculos do usuário: ${response.statusCode} ${response.body}',
      );
    }

    final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(EmpresaVinculoWebModel.fromJson)
        .toList(growable: false);
  }
}

class ConviteException implements Exception {
  const ConviteException(this.key);
  final String key;
}
