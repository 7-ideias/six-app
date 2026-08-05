import 'package:flutter/foundation.dart';

import '../../../data/models/usuario_model.dart';
import '../../../data/services/usuario/usuario_api_client.dart';
import '../../../providers/usuario_provider.dart';

class UsuarioService {
  static final UsuarioService _instance = UsuarioService._internal();
  factory UsuarioService() => _instance;
  UsuarioService._internal();

  final UsuarioApiClient _apiClient = HttpUsuarioApiClient();

  Future<String?> buscarDadosDoUsuario_atualizaProviders() async {
    try {
      final UsuarioModel usuario = await _apiClient.buscarDadosPessoais();
      UsuarioProvider().setUsuario(usuario);
      return usuario.preferenciasIndividuaisDoUsuario.idiomaDePreferencia;
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
    final Map<String, dynamic> body = <String, dynamic>{};
    if (idiomaDePreferencia != null) {
      body['idiomaDePreferencia'] = idiomaDePreferencia;
    }
    if (modoDeExibicaoProdutos != null) {
      final String campo =
          kIsWeb ? 'modoDeExibicaoProdutosWeb' : 'modoDeExibicaoProdutosMobile';
      body[campo] = modoDeExibicaoProdutos;
    }
    if (modoDeExibicaoServicos != null) {
      final String campo =
          kIsWeb ? 'modoDeExibicaoServicosWeb' : 'modoDeExibicaoServicosMobile';
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

    await _apiClient.atualizarPreferenciasIndividuais(body);
  }

  Future<void> atualizarDadosDoUsuario(UsuarioModel usuario) async {
    try {
      final UsuarioModel? usuarioAtualizado = await _apiClient
          .atualizarDadosPessoais(usuario);
      UsuarioProvider().setUsuario(usuarioAtualizado ?? usuario);
    } catch (e) {
      debugPrint('Erro na atualização de dados do usuário: $e');
      rethrow;
    }
  }

  Future<void> atualizarFotoDoUsuario(String foto) async {
    UsuarioModel? usuarioAtual = UsuarioProvider().usuario;
    usuarioAtual ??= await _apiClient.buscarDadosPessoais();

    final UsuarioModel atualizado = usuarioAtual.copyWith(foto: foto);
    final UsuarioModel? usuarioAtualizado = await _apiClient
        .atualizarDadosPessoais(atualizado);

    UsuarioProvider().setUsuario(usuarioAtualizado ?? atualizado);
  }
}
