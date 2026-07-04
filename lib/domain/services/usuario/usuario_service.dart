import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/http_client_factory.dart';
import '../../../data/models/usuario_model.dart';
import '../../../providers/usuario_provider.dart';

class UsuarioService {
  static final UsuarioService _instance = UsuarioService._internal();
  factory UsuarioService() => _instance;
  UsuarioService._internal();

  http.Client _client() => createHttpClient();

  Future<String?> buscarDadosDoUsuario_atualizaProviders() async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas USUARIO_SERVICE L23');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-pessoais');
    final client = _client();

    try {
      final response = await client.get(
        uri,
        headers: {
          'accept': 'application/json',
          'idUnicoDaEmpresa': empresaId,
          'Authorization': 'Bearer ' + token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final usuario = UsuarioModel.fromJson(decoded);

        // Salvar em memória usando o Provider
        UsuarioProvider().setUsuario(usuario);

        final preferencias = decoded['preferenciasIndividuaisDoUsuario'];
        if (preferencias is Map<String, dynamic>) {
          return preferencias['idiomaDePreferencia']?.toString();
        }
        return null;
      } else {
        throw Exception('Falha ao buscar dados do usuário: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na requisição de dados do usuário: $e');
      rethrow;
    }
  }

  Future<void> atualizarPreferenciasIndividuais({
    String? idiomaDePreferencia,
    String? modoDeExibicaoProdutos,
    String? modoDeExibicaoServicos,
    String? modoDeExibicaoProdutosWeb,
    String? modoDeExibicaoProdutosMobile,
    String? modoDeExibicaoServicosWeb,
    String? modoDeExibicaoServicosMobile,
    bool? ocultarValoresFinanceirosWeb,
  }) async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas USUARIO_SERVICE preferencias');
    }

    final body = <String, dynamic>{};
    if (idiomaDePreferencia != null) {
      body['idiomaDePreferencia'] = idiomaDePreferencia;
    }
    if (modoDeExibicaoProdutos != null) {
      final campo = kIsWeb
          ? 'modoDeExibicaoProdutosWeb'
          : 'modoDeExibicaoProdutosMobile';
      body[campo] = modoDeExibicaoProdutos;
    }
    if (modoDeExibicaoServicos != null) {
      final campo = kIsWeb
          ? 'modoDeExibicaoServicosWeb'
          : 'modoDeExibicaoServicosMobile';
      body[campo] = modoDeExibicaoServicos;
    }
    if (modoDeExibicaoProdutosWeb != null) {
      body['modoDeExibicaoProdutosWeb'] = modoDeExibicaoProdutosWeb;
    }
    if (modoDeExibicaoProdutosMobile != null) {
      body['modoDeExibicaoProdutosMobile'] = modoDeExibicaoProdutosMobile;
    }
    if (modoDeExibicaoServicosWeb != null) {
      body['modoDeExibicaoServicosWeb'] = modoDeExibicaoServicosWeb;
    }
    if (modoDeExibicaoServicosMobile != null) {
      body['modoDeExibicaoServicosMobile'] = modoDeExibicaoServicosMobile;
    }
    if (ocultarValoresFinanceirosWeb != null) {
      body['ocultarValoresFinanceirosWeb'] = ocultarValoresFinanceirosWeb;
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-pessoais/preferencias');
    final response = await _client().patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'idUnicoDaEmpresa': empresaId,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao atualizar preferências do usuário: ${response.statusCode}');
    }
  }

  Future<void> atualizarDadosDoUsuario(UsuarioModel usuario) async {
    final authService = AuthService();
    final token = await authService.getAccessToken();
    final empresaId = await authService.getEmpresaId();

    if (token == null || empresaId == null) {
      throw Exception('Credenciais não encontradas USUARIO_SERVICE L60');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/private/api/dados-pessoais');
    final client = _client();

    try {
      final response = await client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'idUnicoDaEmpresa': empresaId,
          'Authorization': 'Bearer ' + token,
        },
        body: jsonEncode(usuario.toJson()),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final usuarioAtualizado = UsuarioModel.fromJson(decoded);

        // Atualizar em memória usando o Provider com o retorno normalizado pelo backend
        UsuarioProvider().setUsuario(usuarioAtualizado);
      } else {
        throw Exception('Falha ao atualizar dados do usuário: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na atualização de dados do usuário: $e');
      rethrow;
    }
  }
}
