import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/colaborador_convite_model.dart';
import '../../../data/models/usuario_model.dart';
import '../../../data/services/usuario/usuario_api_client.dart';
import '../../../providers/usuario_provider.dart';

class UsuarioService {
  static final UsuarioService _instance = UsuarioService._internal();
  factory UsuarioService() => _instance;
  UsuarioService._internal();

  final UsuarioApiClient _apiClient = HttpUsuarioApiClient();
  static const String _preferenciasCacheKey =
      'sixapp.preferenciasIndividuaisDoUsuario';

  Future<String?> buscarDadosDoUsuario_atualizaProviders() async {
    try {
      final UsuarioModel usuario = await _apiClient.buscarDadosPessoais();
      UsuarioProvider().setUsuario(usuario);
      await salvarPreferenciasIndividuaisNoCache(
        usuario.preferenciasIndividuaisDoUsuario,
      );
      return usuario.preferenciasIndividuaisDoUsuario.idiomaDePreferencia;
    } catch (e) {
      debugPrint('Erro na requisição de dados do usuário: $e');
      rethrow;
    }
  }

  Future<PreferenciasIndividuaisDoUsuarioModel?>
  carregarPreferenciasIndividuaisDoCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_preferenciasCacheKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      final dynamic decoded = jsonDecode(raw);
      return PreferenciasIndividuaisDoUsuarioModel.fromJson(decoded);
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao carregar cache de preferencias individuais: $error\n$stackTrace',
      );
      return null;
    }
  }

  Future<void> salvarPreferenciasIndividuaisNoCache(
    PreferenciasIndividuaisDoUsuarioModel preferencias,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _preferenciasCacheKey,
        jsonEncode(preferencias.toJson()),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao salvar cache de preferencias individuais: $error\n$stackTrace',
      );
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
    String? agendaFinanceiraPeriodoWeb,
    String? agendaFinanceiraTipoWeb,
    String? agendaFinanceiraStatusWeb,
    List<String>? agendaFinanceiraTipoDePagamentoWeb,
    Map<String, dynamic>? catalogoReservasFiltrosWeb,
    Map<String, dynamic>? consultaVendasFiltrosWeb,
    Map<String, dynamic>? atendimentosCriadosFiltrosWeb,
    Map<String, dynamic>? atendimentosCriadosFiltrosMobile,
    List<String>? ordemCardsGestaoMobile,
    List<String>? ordemCardsAtendimentoMobile,
    List<String>? ordemCardsVendasMobile,
    List<String>? ordemCardsServicosMobile,
    List<String>? ordemCardsReceberMobile,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (idiomaDePreferencia != null) {
      body['idiomaDePreferencia'] = idiomaDePreferencia;
    }
    if (modoDeExibicaoProdutos != null) {
      final String campo = kIsWeb
          ? 'modoDeExibicaoProdutosWeb'
          : 'modoDeExibicaoProdutosMobile';
      body[campo] = modoDeExibicaoProdutos;
    }
    if (modoDeExibicaoServicos != null) {
      final String campo = kIsWeb
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
    if (agendaFinanceiraPeriodoWeb != null) {
      body['agendaFinanceiraPeriodoWeb'] = agendaFinanceiraPeriodoWeb;
    }
    if (agendaFinanceiraTipoWeb != null) {
      body['agendaFinanceiraTipoWeb'] = agendaFinanceiraTipoWeb;
    }
    if (agendaFinanceiraStatusWeb != null) {
      body['agendaFinanceiraStatusWeb'] = agendaFinanceiraStatusWeb;
    }
    if (agendaFinanceiraTipoDePagamentoWeb != null) {
      body['agendaFinanceiraTipoDePagamentoWeb'] =
          agendaFinanceiraTipoDePagamentoWeb;
    }
    if (catalogoReservasFiltrosWeb != null) {
      body['catalogoReservasFiltrosWeb'] = catalogoReservasFiltrosWeb;
    }
    if (consultaVendasFiltrosWeb != null) {
      body['consultaVendasFiltrosWeb'] = consultaVendasFiltrosWeb;
    }
    if (atendimentosCriadosFiltrosWeb != null) {
      body['atendimentosCriadosFiltrosWeb'] = atendimentosCriadosFiltrosWeb;
    }
    if (atendimentosCriadosFiltrosMobile != null) {
      body['atendimentosCriadosFiltrosMobile'] =
          atendimentosCriadosFiltrosMobile;
    }
    if (ordemCardsGestaoMobile != null) {
      body['ordemCardsGestaoMobile'] = ordemCardsGestaoMobile;
    }
    if (ordemCardsAtendimentoMobile != null) {
      body['ordemCardsAtendimentoMobile'] = ordemCardsAtendimentoMobile;
    }
    if (ordemCardsVendasMobile != null) {
      body['ordemCardsVendasMobile'] = ordemCardsVendasMobile;
    }
    if (ordemCardsServicosMobile != null) {
      body['ordemCardsServicosMobile'] = ordemCardsServicosMobile;
    }
    if (ordemCardsReceberMobile != null) {
      body['ordemCardsReceberMobile'] = ordemCardsReceberMobile;
    }

    if (body.isEmpty) {
      return;
    }

    await _sincronizarPreferenciasLocais(body);
    await _apiClient.atualizarPreferenciasIndividuais(body);
  }

  Future<void> atualizarDadosDoUsuario(UsuarioModel usuario) async {
    try {
      final UsuarioModel? usuarioAtualizado = await _apiClient
          .atualizarDadosPessoais(usuario);
      final UsuarioModel usuarioSincronizado = usuarioAtualizado ?? usuario;
      UsuarioProvider().setUsuario(usuarioSincronizado);
      await salvarPreferenciasIndividuaisNoCache(
        usuarioSincronizado.preferenciasIndividuaisDoUsuario,
      );
    } catch (e) {
      debugPrint('Erro na atualização de dados do usuário: $e');
      rethrow;
    }
  }

  Future<List<EmpresaVinculoWebModel>> listarEmpresasVinculadas() {
    return _apiClient.listarEmpresasVinculadas();
  }

  Future<void> atualizarFotoDoUsuario(String foto) async {
    UsuarioModel? usuarioAtual = UsuarioProvider().usuario;
    usuarioAtual ??= await _apiClient.buscarDadosPessoais();

    final UsuarioModel atualizado = usuarioAtual.copyWith(foto: foto);
    final UsuarioModel? usuarioAtualizado = await _apiClient
        .atualizarDadosPessoais(atualizado);

    final UsuarioModel usuarioSincronizado = usuarioAtualizado ?? atualizado;
    UsuarioProvider().setUsuario(usuarioSincronizado);
    await salvarPreferenciasIndividuaisNoCache(
      usuarioSincronizado.preferenciasIndividuaisDoUsuario,
    );
  }

  Future<void> _sincronizarPreferenciasLocais(
    Map<String, dynamic> atualizacaoParcial,
  ) async {
    UsuarioModel? usuarioAtual = UsuarioProvider().usuario;
    final PreferenciasIndividuaisDoUsuarioModel? preferenciasCache =
        await carregarPreferenciasIndividuaisDoCache();
    final PreferenciasIndividuaisDoUsuarioModel preferenciasAtuais =
        usuarioAtual?.preferenciasIndividuaisDoUsuario ??
        preferenciasCache ??
        PreferenciasIndividuaisDoUsuarioModel.padrao();

    final Map<String, dynamic> preferenciasMescladas = <String, dynamic>{
      ...preferenciasAtuais.toJson(),
      ...atualizacaoParcial,
    };
    final PreferenciasIndividuaisDoUsuarioModel preferenciasAtualizadas =
        PreferenciasIndividuaisDoUsuarioModel.fromJson(preferenciasMescladas);

    await salvarPreferenciasIndividuaisNoCache(preferenciasAtualizadas);

    if (usuarioAtual == null) {
      return;
    }

    UsuarioProvider().setUsuario(
      usuarioAtual.copyWith(
        preferenciasIndividuaisDoUsuario: preferenciasAtualizadas,
        enviarPreferenciasIndividuaisDoUsuario: true,
      ),
    );
  }
}
