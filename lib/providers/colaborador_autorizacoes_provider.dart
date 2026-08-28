import 'package:flutter/foundation.dart';

import '../core/enums/tipo_usuario_enum.dart';
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
  }) : _authService = authService ?? AuthService(),
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
  TipoUsuarioEnum? _tipoUsuario;
  bool _ehAdministrador = false;
  bool _ehSuperUsuario = false;
  bool _autorizacoesCarregadasComSucesso = false;
  bool _podeAcessarEtiquetas = false;
  bool _podeFazerDevolucao = false;

  ColaboradorAutorizacoesModel get autorizacoes =>
      _autorizacoes ?? ColaboradorAutorizacoesModel.permitirTudo();

  bool get loading => _loading;
  String? get erro => _erro;
  String? get idUnicoDoUsuarioCarregado => _idUnicoDoUsuarioCarregado;
  String get tipoPerfilUsuario => _tipoPerfilUsuario;
  TipoUsuarioEnum? get tipoUsuario => _tipoUsuario;
  String get tipoPerfilUnificado {
    switch (_tipoUsuario) {
      case TipoUsuarioEnum.SUPER:
        return 'SUPER';
      case TipoUsuarioEnum.ADMINISTRADOR:
        return 'ADMIN';
      case TipoUsuarioEnum.COLABORADOR:
        return 'COLABORADOR';
      case TipoUsuarioEnum.CLIENTE:
        return 'CLIENTE';
      case null:
        return _tipoPerfilUsuario;
    }
  }

  bool get ehAdministrador => _ehAdministrador;
  bool get ehSuperUsuario => _ehSuperUsuario;
  bool get ehColaborador => _tipoUsuario == TipoUsuarioEnum.COLABORADOR;
  bool get autorizacoesCarregadasComSucesso =>
      _autorizacoesCarregadasComSucesso;
  bool get podeAcessarEtiquetas => _ehAdministrador || _podeAcessarEtiquetas;

  bool get podeFazerVenda => autorizacoes.objVendasPode.fazVenda;
  bool get podeFazerDevolucao => _ehAdministrador || _podeFazerDevolucao;
  bool get podeLancarAssistenciaTecnica =>
      autorizacoes.objAssistenciaTecnicaPode.lancaServico;
  bool get podeAcompanharAssistenciaTecnica =>
      podeLancarAssistenciaTecnica ||
      autorizacoes.objAssistenciaTecnicaPode.ehUmTecnicoEFazAssistenciaTecnica;
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
    final bool perfilSuperUsuario = await _authService.hasRealmRole(
      'SUPER_USER',
    );
    final bool perfilAdmin = tipoPerfilUsuario == 'ADMIN';
    _atualizarPerfilDeAcesso(
      tipoPerfilUsuario: tipoPerfilUsuario,
      ehAdministrador: perfilAdmin,
      ehSuperUsuario: perfilSuperUsuario,
    );

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
      final ColaboradorUsuarioDetalhe detalhe = await _apiClient
          .buscarColaborador(idUnicoDoUsuario);
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
      final bool ehAdministrador = perfilAdmin || administradorSemVinculo;
      _atualizarPerfilDeAcesso(
        tipoPerfilUsuario: tipoPerfilUsuario,
        ehAdministrador: ehAdministrador,
        ehSuperUsuario: perfilSuperUsuario,
      );
      _autorizacoes =
          _ehAdministrador
              ? ColaboradorAutorizacoesModel.permitirTudo()
              : carregadas;
      _idUnicoDoUsuarioCarregado = idUnicoDoUsuario;
      _podeFazerDevolucao = _ehAdministrador || carregadas.podeFazerDevolucao;

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
    _tipoUsuario = null;
    _ehAdministrador = false;
    _ehSuperUsuario = false;
    _autorizacoesCarregadasComSucesso = false;
    _podeAcessarEtiquetas = false;
    _podeFazerDevolucao = false;
    notifyListeners();
  }

  void _atualizarPerfilDeAcesso({
    required String tipoPerfilUsuario,
    required bool ehAdministrador,
    required bool ehSuperUsuario,
  }) {
    _tipoPerfilUsuario = tipoPerfilUsuario;
    _ehAdministrador = ehAdministrador;
    _ehSuperUsuario = ehSuperUsuario;
    _tipoUsuario = _resolverTipoUsuario(
      tipoPerfilUsuario: tipoPerfilUsuario,
      ehAdministrador: ehAdministrador,
      ehSuperUsuario: ehSuperUsuario,
    );
  }

  TipoUsuarioEnum? _resolverTipoUsuario({
    required String tipoPerfilUsuario,
    required bool ehAdministrador,
    required bool ehSuperUsuario,
  }) {
    if (ehSuperUsuario) {
      return TipoUsuarioEnum.SUPER;
    }
    if (ehAdministrador) {
      return TipoUsuarioEnum.ADMINISTRADOR;
    }
    if (tipoPerfilUsuario == 'COLABORADOR') {
      return TipoUsuarioEnum.COLABORADOR;
    }
    if (tipoPerfilUsuario == 'CLIENTE') {
      return TipoUsuarioEnum.CLIENTE;
    }
    return null;
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
