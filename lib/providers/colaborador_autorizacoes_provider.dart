import 'package:flutter/foundation.dart';

import '../core/services/auth_service.dart';
import '../data/models/colaborador_autorizacoes_model.dart';
import '../data/models/colaborador_usuario_model.dart';
import '../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../domain/services/etiqueta/etiqueta_service.dart';

class ColaboradorAutorizacoesProvider extends ChangeNotifier {
  ColaboradorAutorizacoesProvider({
    AuthService? authService,
    ColaboradorUsuarioApiClient? apiClient,
    EtiquetaService? etiquetaService,
  })  : _authService = authService ?? AuthService(),
        _apiClient = apiClient ?? HttpColaboradorUsuarioApiClient(),
        _etiquetaService = etiquetaService ?? EtiquetaService();

  final AuthService _authService;
  final ColaboradorUsuarioApiClient _apiClient;
  final EtiquetaService _etiquetaService;

  ColaboradorAutorizacoesModel? _autorizacoes;
  bool _loading = false;
  String? _erro;
  String? _idUnicoDoUsuarioCarregado;
  String _tipoPerfilUsuario = 'DESCONHECIDO';
  bool _ehAdministrador = false;
  bool _autorizacoesCarregadasComSucesso = false;
  bool _podeAcessarEtiquetas = false;
  bool _podeFazerDevolucao = false;

  ColaboradorAutorizacoesModel get autorizacoes =>
      _autorizacoes ?? ColaboradorAutorizacoesModel.permitirTudo();

  bool get loading => _loading;
  String? get erro => _erro;
  String? get idUnicoDoUsuarioCarregado => _idUnicoDoUsuarioCarregado;
  String get tipoPerfilUsuario => _tipoPerfilUsuario;
  bool get ehAdministrador => _ehAdministrador;
  bool get autorizacoesCarregadasComSucesso =>
      _autorizacoesCarregadasComSucesso;
  bool get podeAcessarEtiquetas => _ehAdministrador || _podeAcessarEtiquetas;

  bool get podeFazerVenda => autorizacoes.objVendasPode.fazVenda;
  bool get podeFazerDevolucao => _ehAdministrador || _podeFazerDevolucao;
  bool get podeLancarAssistenciaTecnica =>
      autorizacoes.objAssistenciaTecnicaPode.lancaServico;
  bool get podeEditarCliente => autorizacoes.objClientesPode.podeEditarCliente;
  bool get podeCadastrarProduto => autorizacoes.podeCadastrarProduto;
  bool get podeEditarProduto => autorizacoes.objProdutosPode.podeEditarProduto;
  bool get podeVerEstoqueDeProduto =>
      autorizacoes.objProdutosPode.podeVerEstoqueDeProduto;
  bool get podeAcessarCatalogo =>
      podeCadastrarProduto ||
      podeEditarProduto ||
      podeVerEstoqueDeProduto ||
      podeAcessarEtiquetas;
  bool get podeGerarRelatorio =>
      autorizacoes.objRelatoriosPode.geraRelatorioDeVendas;
  bool get podeReceberNoCaixa =>
      autorizacoes.objLancamentosFinanceirosPode.podeReceberNoCaixa;
  bool get podeVerQuantoVendeu =>
      autorizacoes.objLancamentosFinanceirosPode.podeVerQuantoVendeu;
  bool get podeAcessarFinanceiro =>
      autorizacoes.objLancamentosFinanceirosPode.podeReceberNoCaixa ||
      autorizacoes.objLancamentosFinanceirosPode.podeVerQuantoVendeu;

  Future<void> carregarAutorizacoesDoUsuarioLogado({bool force = false}) async {
    final String? idUnicoDoUsuario = await _authService.getUserId();
    final String tipoPerfilUsuario = await _authService.getUserProfileType();
    final bool perfilAdmin = tipoPerfilUsuario == 'ADMIN';
    _tipoPerfilUsuario = tipoPerfilUsuario;
    _ehAdministrador = perfilAdmin;

    if (idUnicoDoUsuario == null || idUnicoDoUsuario.trim().isEmpty) {
      _autorizacoes = ColaboradorAutorizacoesModel.permitirTudo();
      _idUnicoDoUsuarioCarregado = null;
      _erro = null;
      _podeAcessarEtiquetas = kIsWeb && perfilAdmin;
      _podeFazerDevolucao = perfilAdmin;
      _autorizacoesCarregadasComSucesso = perfilAdmin;
      notifyListeners();
      return;
    }

    if (!force &&
        _idUnicoDoUsuarioCarregado == idUnicoDoUsuario &&
        _autorizacoes != null) {
      return;
    }

    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      final ColaboradorUsuarioDetalhe detalhe =
          await _apiClient.buscarColaborador(idUnicoDoUsuario);
      final Map<String, dynamic> json = detalhe.toJson();
      final Map<String, dynamic> autorizacoesJson = _ensureMap(
        json['objAutorizacoes'],
      );
      final ColaboradorAutorizacoesModel carregadas =
          ColaboradorAutorizacoesModel.fromJson(autorizacoesJson);

      final bool administradorSemVinculo = _deveAssumirAdministradorSemVinculo(
        detalhe: detalhe,
        autorizacoes: carregadas,
      );
      _ehAdministrador = perfilAdmin || administradorSemVinculo;
      _autorizacoes =
          _ehAdministrador
              ? ColaboradorAutorizacoesModel.permitirTudo()
              : carregadas;
      _idUnicoDoUsuarioCarregado = idUnicoDoUsuario;
      _podeFazerDevolucao =
          _ehAdministrador || carregadas.podeFazerDevolucao;

      if (!kIsWeb) {
        _podeAcessarEtiquetas = false;
      } else if (_ehAdministrador) {
        _podeAcessarEtiquetas = true;
      } else {
        try {
          _podeAcessarEtiquetas = await _etiquetaService.buscarAcesso();
        } catch (_) {
          _podeAcessarEtiquetas = false;
        }
      }
      _autorizacoesCarregadasComSucesso = true;
    } catch (e) {
      _erro = e.toString();
      _autorizacoes ??= ColaboradorAutorizacoesModel.permitirTudo();
      _podeAcessarEtiquetas = kIsWeb && _ehAdministrador;
      _podeFazerDevolucao = _ehAdministrador;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void limpar() {
    _autorizacoes = null;
    _loading = false;
    _erro = null;
    _idUnicoDoUsuarioCarregado = null;
    _tipoPerfilUsuario = 'DESCONHECIDO';
    _ehAdministrador = false;
    _autorizacoesCarregadasComSucesso = false;
    _podeAcessarEtiquetas = false;
    _podeFazerDevolucao = false;
    notifyListeners();
  }

  bool _deveAssumirAdministradorSemVinculo({
    required ColaboradorUsuarioDetalhe detalhe,
    required ColaboradorAutorizacoesModel autorizacoes,
  }) {
    final bool semDadosDePessoa =
        detalhe.nome.trim().isEmpty &&
        detalhe.nomeDeGuerra.trim().isEmpty &&
        detalhe.email.trim().isEmpty &&
        detalhe.celularDeAcesso.trim().isEmpty;

    final bool semAutorizacaoOperacional =
        !autorizacoes.podeFazerDevolucao &&
        !autorizacoes.objVendasPode.fazVenda &&
        !autorizacoes.objAssistenciaTecnicaPode.lancaServico &&
        !autorizacoes.objClientesPode.podeEditarCliente &&
        !autorizacoes.objRelatoriosPode.geraRelatorioDeVendas &&
        !autorizacoes.objLancamentosFinanceirosPode.podeReceberNoCaixa &&
        !autorizacoes.objLancamentosFinanceirosPode.podeVerQuantoVendeu;

    return semDadosDePessoa && semAutorizacaoOperacional;
  }

  static Map<String, dynamic> _ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }
}
