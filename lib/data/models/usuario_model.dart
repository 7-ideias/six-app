import 'package:flutter/foundation.dart';

class UsuarioModel {
  final String nome;
  final String sobrenome;
  final String cpf;
  final String registroProfissional;
  final String email;
  final String nomeDeGuerra;
  final String celular;
  final String senha;
  final String salt;
  final String rg;
  final String dataNascimento;
  final String foto;
  final EnderecoModel? objEndereco;
  final PreferenciasIndividuaisDoUsuarioModel preferenciasIndividuaisDoUsuario;
  final bool enviarPreferenciasIndividuaisDoUsuario;

  UsuarioModel({
    required this.nome,
    required this.sobrenome,
    required this.cpf,
    required this.registroProfissional,
    required this.email,
    this.nomeDeGuerra = '',
    this.celular = '',
    this.senha = '',
    this.salt = '',
    this.rg = '',
    this.dataNascimento = '',
    this.foto = '',
    this.objEndereco,
    PreferenciasIndividuaisDoUsuarioModel? preferenciasIndividuaisDoUsuario,
    bool? enviarPreferenciasIndividuaisDoUsuario,
  }) : preferenciasIndividuaisDoUsuario =
           preferenciasIndividuaisDoUsuario ??
           PreferenciasIndividuaisDoUsuarioModel.padrao(),
       enviarPreferenciasIndividuaisDoUsuario =
           enviarPreferenciasIndividuaisDoUsuario ??
           (preferenciasIndividuaisDoUsuario != null);

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      nome: json['nome'] ?? '',
      sobrenome: json['sobrenome'] ?? '',
      cpf: json['cpf'] ?? '',
      registroProfissional: json['registroProfissional'] ?? '',
      email: json['email'] ?? '',
      nomeDeGuerra: json['nomeDeGuerra'] ?? '',
      celular: json['celular'] ?? '',
      senha: json['senha'] ?? '',
      salt: json['salt'] ?? '',
      rg: json['rg'] ?? '',
      dataNascimento: json['dataNascimento'] ?? '',
      foto: _stringFromJson(
        json['foto'] ??
            json['fotoDePerfil'] ??
            json['urlFoto'] ??
            json['imagemPerfil'] ??
            json['imagemDoUsuario'],
      ),
      objEndereco:
          json['objEndereco'] != null
              ? EnderecoModel.fromJson(json['objEndereco'])
              : null,
      preferenciasIndividuaisDoUsuario:
          PreferenciasIndividuaisDoUsuarioModel.fromJson(
            json['preferenciasIndividuaisDoUsuario'],
          ),
      enviarPreferenciasIndividuaisDoUsuario: true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'nome': nome,
      'sobrenome': sobrenome,
      'cpf': cpf,
      'registroProfissional': registroProfissional,
      'email': email,
      'nomeDeGuerra': nomeDeGuerra,
      'celular': celular,
      'senha': senha,
      'salt': salt,
      'rg': rg,
      'dataNascimento': dataNascimento,
      'foto': foto,
      'objEndereco': objEndereco?.toJson(),
    };

    if (enviarPreferenciasIndividuaisDoUsuario) {
      json['preferenciasIndividuaisDoUsuario'] =
          preferenciasIndividuaisDoUsuario.toJson();
    }

    return json;
  }

  UsuarioModel copyWith({
    String? nome,
    String? sobrenome,
    String? cpf,
    String? registroProfissional,
    String? email,
    String? nomeDeGuerra,
    String? celular,
    String? senha,
    String? salt,
    String? rg,
    String? dataNascimento,
    String? foto,
    EnderecoModel? objEndereco,
    PreferenciasIndividuaisDoUsuarioModel? preferenciasIndividuaisDoUsuario,
    bool? enviarPreferenciasIndividuaisDoUsuario,
  }) {
    return UsuarioModel(
      nome: nome ?? this.nome,
      sobrenome: sobrenome ?? this.sobrenome,
      cpf: cpf ?? this.cpf,
      registroProfissional: registroProfissional ?? this.registroProfissional,
      email: email ?? this.email,
      nomeDeGuerra: nomeDeGuerra ?? this.nomeDeGuerra,
      celular: celular ?? this.celular,
      senha: senha ?? this.senha,
      salt: salt ?? this.salt,
      rg: rg ?? this.rg,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      foto: foto ?? this.foto,
      objEndereco: objEndereco ?? this.objEndereco,
      preferenciasIndividuaisDoUsuario:
          preferenciasIndividuaisDoUsuario ??
          this.preferenciasIndividuaisDoUsuario,
      enviarPreferenciasIndividuaisDoUsuario:
          enviarPreferenciasIndividuaisDoUsuario ??
          this.enviarPreferenciasIndividuaisDoUsuario,
    );
  }

  static String _stringFromJson(dynamic value) {
    return value?.toString() ?? '';
  }
}

class EnderecoModel {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;

  EnderecoModel({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  factory EnderecoModel.fromJson(Map<String, dynamic> json) {
    return EnderecoModel(
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      complemento: json['complemento'] ?? '',
      bairro: json['bairro'] ?? '',
      localidade: json['localidade'] ?? '',
      uf: json['uf'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cep': cep,
      'logradouro': logradouro,
      'complemento': complemento,
      'bairro': bairro,
      'localidade': localidade,
      'uf': uf,
    };
  }
}

enum ModoDeExibicaoUsuario { horizontal, vertical, grade, lista }

extension ModoDeExibicaoUsuarioApi on ModoDeExibicaoUsuario {
  String get codigo {
    switch (this) {
      case ModoDeExibicaoUsuario.horizontal:
        return 'HORIZONTAL';
      case ModoDeExibicaoUsuario.vertical:
        return 'VERTICAL';
      case ModoDeExibicaoUsuario.grade:
        return 'GRADE';
      case ModoDeExibicaoUsuario.lista:
        return 'LISTA';
    }
  }

  static ModoDeExibicaoUsuario? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().toUpperCase() ?? '';
    switch (codigo) {
      case 'HORIZONTAL':
        return ModoDeExibicaoUsuario.horizontal;
      case 'VERTICAL':
        return ModoDeExibicaoUsuario.vertical;
      case 'GRADE':
        return ModoDeExibicaoUsuario.grade;
      case 'LISTA':
        return ModoDeExibicaoUsuario.lista;
      default:
        return null;
    }
  }

  static ModoDeExibicaoUsuario fromCodigo(
    dynamic value,
    ModoDeExibicaoUsuario fallback,
  ) {
    return tryFromCodigo(value) ?? fallback;
  }
}

enum AgendaFinanceiraPeriodoWebPreferencia {
  hoje,
  proximos7Dias,
  esteMes,
  proximoMes,
  personalizado,
}

extension AgendaFinanceiraPeriodoWebPreferenciaApi
    on AgendaFinanceiraPeriodoWebPreferencia {
  String get codigo {
    switch (this) {
      case AgendaFinanceiraPeriodoWebPreferencia.hoje:
        return 'HOJE';
      case AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias:
        return 'PROXIMOS_7_DIAS';
      case AgendaFinanceiraPeriodoWebPreferencia.esteMes:
        return 'ESTE_MES';
      case AgendaFinanceiraPeriodoWebPreferencia.proximoMes:
        return 'PROXIMO_MES';
      case AgendaFinanceiraPeriodoWebPreferencia.personalizado:
        return 'PERSONALIZADO';
    }
  }

  static AgendaFinanceiraPeriodoWebPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().toUpperCase() ?? '';
    switch (codigo) {
      case 'HOJE':
        return AgendaFinanceiraPeriodoWebPreferencia.hoje;
      case 'PROXIMOS_7_DIAS':
      case 'PROXIMOS7DIAS':
        return AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias;
      case 'ESTE_MES':
      case 'ESTE_MÊS':
        return AgendaFinanceiraPeriodoWebPreferencia.esteMes;
      case 'PROXIMO_MES':
      case 'PRÓXIMO_MÊS':
        return AgendaFinanceiraPeriodoWebPreferencia.proximoMes;
      case 'PERSONALIZADO':
      case 'INTERVALO_PERSONALIZADO':
        return AgendaFinanceiraPeriodoWebPreferencia.personalizado;
      default:
        return null;
    }
  }

  static AgendaFinanceiraPeriodoWebPreferencia fromCodigo(
    dynamic value,
    AgendaFinanceiraPeriodoWebPreferencia fallback,
  ) {
    return tryFromCodigo(value) ?? fallback;
  }
}

enum AgendaFinanceiraTipoWebPreferencia { todos, receber, pagar }

extension AgendaFinanceiraTipoWebPreferenciaApi
    on AgendaFinanceiraTipoWebPreferencia {
  String get codigo {
    switch (this) {
      case AgendaFinanceiraTipoWebPreferencia.todos:
        return 'TODOS';
      case AgendaFinanceiraTipoWebPreferencia.receber:
        return 'RECEBER';
      case AgendaFinanceiraTipoWebPreferencia.pagar:
        return 'PAGAR';
    }
  }

  static AgendaFinanceiraTipoWebPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().toUpperCase() ?? '';
    switch (codigo) {
      case 'TODOS':
        return AgendaFinanceiraTipoWebPreferencia.todos;
      case 'RECEBER':
        return AgendaFinanceiraTipoWebPreferencia.receber;
      case 'PAGAR':
        return AgendaFinanceiraTipoWebPreferencia.pagar;
      default:
        return null;
    }
  }

  static AgendaFinanceiraTipoWebPreferencia fromCodigo(
    dynamic value,
    AgendaFinanceiraTipoWebPreferencia fallback,
  ) {
    return tryFromCodigo(value) ?? fallback;
  }
}

enum AgendaFinanceiraStatusWebPreferencia {
  todos,
  previsto,
  pendente,
  venceHoje,
  vencido,
  pago,
  recebido,
  parcial,
  cancelado,
}

extension AgendaFinanceiraStatusWebPreferenciaApi
    on AgendaFinanceiraStatusWebPreferencia {
  String get codigo {
    switch (this) {
      case AgendaFinanceiraStatusWebPreferencia.todos:
        return 'TODOS';
      case AgendaFinanceiraStatusWebPreferencia.previsto:
        return 'PREVISTO';
      case AgendaFinanceiraStatusWebPreferencia.pendente:
        return 'PENDENTE';
      case AgendaFinanceiraStatusWebPreferencia.venceHoje:
        return 'VENCE_HOJE';
      case AgendaFinanceiraStatusWebPreferencia.vencido:
        return 'VENCIDO';
      case AgendaFinanceiraStatusWebPreferencia.pago:
        return 'PAGO';
      case AgendaFinanceiraStatusWebPreferencia.recebido:
        return 'RECEBIDO';
      case AgendaFinanceiraStatusWebPreferencia.parcial:
        return 'PARCIAL';
      case AgendaFinanceiraStatusWebPreferencia.cancelado:
        return 'CANCELADO';
    }
  }

  static AgendaFinanceiraStatusWebPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().toUpperCase() ?? '';
    switch (codigo) {
      case 'TODOS':
        return AgendaFinanceiraStatusWebPreferencia.todos;
      case 'PREVISTO':
        return AgendaFinanceiraStatusWebPreferencia.previsto;
      case 'PENDENTE':
        return AgendaFinanceiraStatusWebPreferencia.pendente;
      case 'VENCE_HOJE':
        return AgendaFinanceiraStatusWebPreferencia.venceHoje;
      case 'VENCIDO':
        return AgendaFinanceiraStatusWebPreferencia.vencido;
      case 'PAGO':
        return AgendaFinanceiraStatusWebPreferencia.pago;
      case 'RECEBIDO':
        return AgendaFinanceiraStatusWebPreferencia.recebido;
      case 'PARCIAL':
        return AgendaFinanceiraStatusWebPreferencia.parcial;
      case 'CANCELADO':
        return AgendaFinanceiraStatusWebPreferencia.cancelado;
      default:
        return null;
    }
  }

  static AgendaFinanceiraStatusWebPreferencia fromCodigo(
    dynamic value,
    AgendaFinanceiraStatusWebPreferencia fallback,
  ) {
    return tryFromCodigo(value) ?? fallback;
  }
}

enum CatalogoReservasPeriodoWebPreferencia {
  hoje,
  proximos7Dias,
  esteMes,
  proximoMes,
  personalizado,
}

extension CatalogoReservasPeriodoWebPreferenciaApi
    on CatalogoReservasPeriodoWebPreferencia {
  String get codigo {
    switch (this) {
      case CatalogoReservasPeriodoWebPreferencia.hoje:
        return 'HOJE';
      case CatalogoReservasPeriodoWebPreferencia.proximos7Dias:
        return 'PROXIMOS_7_DIAS';
      case CatalogoReservasPeriodoWebPreferencia.esteMes:
        return 'ESTE_MES';
      case CatalogoReservasPeriodoWebPreferencia.proximoMes:
        return 'PROXIMO_MES';
      case CatalogoReservasPeriodoWebPreferencia.personalizado:
        return 'PERSONALIZADO';
    }
  }

  static CatalogoReservasPeriodoWebPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().trim().toUpperCase() ?? '';
    switch (codigo) {
      case 'HOJE':
        return CatalogoReservasPeriodoWebPreferencia.hoje;
      case 'PROXIMOS_7_DIAS':
      case 'PROXIMOS7DIAS':
        return CatalogoReservasPeriodoWebPreferencia.proximos7Dias;
      case 'ESTE_MES':
      case 'ESTE_MÊS':
        return CatalogoReservasPeriodoWebPreferencia.esteMes;
      case 'PROXIMO_MES':
      case 'PRÓXIMO_MÊS':
        return CatalogoReservasPeriodoWebPreferencia.proximoMes;
      case 'PERSONALIZADO':
      case 'INTERVALO_PERSONALIZADO':
        return CatalogoReservasPeriodoWebPreferencia.personalizado;
      default:
        return null;
    }
  }

  static CatalogoReservasPeriodoWebPreferencia fromCodigo(
    dynamic value,
    CatalogoReservasPeriodoWebPreferencia fallback,
  ) {
    return tryFromCodigo(value) ?? fallback;
  }
}

enum AtendimentosCriadosStatusPagamentoFiltro { todos, emAberto, liquidado }

extension AtendimentosCriadosStatusPagamentoFiltroApi
    on AtendimentosCriadosStatusPagamentoFiltro {
  String get codigo {
    switch (this) {
      case AtendimentosCriadosStatusPagamentoFiltro.todos:
        return 'TODOS';
      case AtendimentosCriadosStatusPagamentoFiltro.emAberto:
        return 'EM_ABERTO';
      case AtendimentosCriadosStatusPagamentoFiltro.liquidado:
        return 'LIQUIDADO';
    }
  }

  static AtendimentosCriadosStatusPagamentoFiltro? tryFromCodigo(
    dynamic value,
  ) {
    final String codigo = value?.toString().trim().toUpperCase() ?? '';
    switch (codigo) {
      case 'TODOS':
        return AtendimentosCriadosStatusPagamentoFiltro.todos;
      case 'EM_ABERTO':
      case 'ABERTO':
      case 'PENDENTE':
        return AtendimentosCriadosStatusPagamentoFiltro.emAberto;
      case 'LIQUIDADO':
      case 'PAGO':
      case 'QUITADO':
        return AtendimentosCriadosStatusPagamentoFiltro.liquidado;
      default:
        return null;
    }
  }

  static AtendimentosCriadosStatusPagamentoFiltro fromCodigo(
    dynamic value,
    AtendimentosCriadosStatusPagamentoFiltro fallback,
  ) {
    return tryFromCodigo(value) ?? fallback;
  }
}

class PreferenciasIndividuaisDoUsuarioModel {
  final String idiomaDePreferencia;
  final ModoDeExibicaoUsuario modoDeExibicaoProdutosWeb;
  final ModoDeExibicaoUsuario modoDeExibicaoProdutosMobile;
  final ModoDeExibicaoUsuario modoDeExibicaoServicosWeb;
  final ModoDeExibicaoUsuario modoDeExibicaoServicosMobile;
  final bool ocultarValoresFinanceirosWeb;
  final AgendaFinanceiraPeriodoWebPreferencia agendaFinanceiraPeriodoWeb;
  final AgendaFinanceiraTipoWebPreferencia agendaFinanceiraTipoWeb;
  final AgendaFinanceiraStatusWebPreferencia agendaFinanceiraStatusWeb;
  final List<String> agendaFinanceiraTipoDePagamentoWeb;
  final CatalogoReservasFiltrosWebPreferencia catalogoReservasFiltrosWeb;
  final AtendimentosCriadosFiltrosWebPreferencia atendimentosCriadosFiltrosWeb;
  final AtendimentosCriadosFiltrosMobilePreferencia
  atendimentosCriadosFiltrosMobile;

  PreferenciasIndividuaisDoUsuarioModel({
    this.idiomaDePreferencia = '',
    ModoDeExibicaoUsuario? modoDeExibicaoProdutos,
    ModoDeExibicaoUsuario? modoDeExibicaoServicos,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutosWeb,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutosMobile,
    ModoDeExibicaoUsuario? modoDeExibicaoServicosWeb,
    ModoDeExibicaoUsuario? modoDeExibicaoServicosMobile,
    required this.ocultarValoresFinanceirosWeb,
    AgendaFinanceiraPeriodoWebPreferencia? agendaFinanceiraPeriodoWeb,
    AgendaFinanceiraTipoWebPreferencia? agendaFinanceiraTipoWeb,
    AgendaFinanceiraStatusWebPreferencia? agendaFinanceiraStatusWeb,
    List<String>? agendaFinanceiraTipoDePagamentoWeb,
    CatalogoReservasFiltrosWebPreferencia? catalogoReservasFiltrosWeb,
    AtendimentosCriadosFiltrosWebPreferencia? atendimentosCriadosFiltrosWeb,
    AtendimentosCriadosFiltrosMobilePreferencia?
    atendimentosCriadosFiltrosMobile,
  }) : modoDeExibicaoProdutosWeb =
           modoDeExibicaoProdutosWeb ??
           modoDeExibicaoProdutos ??
           ModoDeExibicaoUsuario.vertical,
       modoDeExibicaoProdutosMobile =
           modoDeExibicaoProdutosMobile ??
           modoDeExibicaoProdutos ??
           ModoDeExibicaoUsuario.vertical,
       modoDeExibicaoServicosWeb =
           modoDeExibicaoServicosWeb ??
           modoDeExibicaoServicos ??
           ModoDeExibicaoUsuario.grade,
       modoDeExibicaoServicosMobile =
           modoDeExibicaoServicosMobile ??
           modoDeExibicaoServicos ??
           ModoDeExibicaoUsuario.vertical,
       agendaFinanceiraPeriodoWeb =
           agendaFinanceiraPeriodoWeb ??
           AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
       agendaFinanceiraTipoWeb =
           agendaFinanceiraTipoWeb ?? AgendaFinanceiraTipoWebPreferencia.todos,
       agendaFinanceiraStatusWeb =
           agendaFinanceiraStatusWeb ??
           AgendaFinanceiraStatusWebPreferencia.todos,
       agendaFinanceiraTipoDePagamentoWeb = List<String>.unmodifiable(
         _normalizarListaDeStrings(agendaFinanceiraTipoDePagamentoWeb),
       ),
       catalogoReservasFiltrosWeb =
           catalogoReservasFiltrosWeb ??
           CatalogoReservasFiltrosWebPreferencia.vazia(),
       atendimentosCriadosFiltrosWeb =
           atendimentosCriadosFiltrosWeb ??
           AtendimentosCriadosFiltrosWebPreferencia.vazia(),
       atendimentosCriadosFiltrosMobile =
           atendimentosCriadosFiltrosMobile ??
           AtendimentosCriadosFiltrosMobilePreferencia.vazia();

  ModoDeExibicaoUsuario get modoDeExibicaoProdutos =>
      kIsWeb ? modoDeExibicaoProdutosWeb : modoDeExibicaoProdutosMobile;

  ModoDeExibicaoUsuario get modoDeExibicaoServicos =>
      kIsWeb ? modoDeExibicaoServicosWeb : modoDeExibicaoServicosMobile;

  factory PreferenciasIndividuaisDoUsuarioModel.padrao() {
    return PreferenciasIndividuaisDoUsuarioModel(
      idiomaDePreferencia: '',
      modoDeExibicaoProdutosWeb: ModoDeExibicaoUsuario.vertical,
      modoDeExibicaoProdutosMobile: ModoDeExibicaoUsuario.vertical,
      modoDeExibicaoServicosWeb: ModoDeExibicaoUsuario.grade,
      modoDeExibicaoServicosMobile: ModoDeExibicaoUsuario.vertical,
      ocultarValoresFinanceirosWeb: false,
      agendaFinanceiraPeriodoWeb:
          AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
      agendaFinanceiraTipoWeb: AgendaFinanceiraTipoWebPreferencia.todos,
      agendaFinanceiraStatusWeb: AgendaFinanceiraStatusWebPreferencia.todos,
      agendaFinanceiraTipoDePagamentoWeb: const <String>[],
      catalogoReservasFiltrosWeb: CatalogoReservasFiltrosWebPreferencia.vazia(),
      atendimentosCriadosFiltrosWeb:
          AtendimentosCriadosFiltrosWebPreferencia.vazia(),
      atendimentosCriadosFiltrosMobile:
          AtendimentosCriadosFiltrosMobilePreferencia.vazia(),
    );
  }

  factory PreferenciasIndividuaisDoUsuarioModel.fromJson(dynamic json) {
    final PreferenciasIndividuaisDoUsuarioModel padrao =
        PreferenciasIndividuaisDoUsuarioModel.padrao();

    if (json is! Map<String, dynamic>) {
      return padrao;
    }

    final ModoDeExibicaoUsuario? modoProdutosLegado =
        ModoDeExibicaoUsuarioApi.tryFromCodigo(json['modoDeExibicaoProdutos']);
    final ModoDeExibicaoUsuario? modoServicosLegado =
        ModoDeExibicaoUsuarioApi.tryFromCodigo(json['modoDeExibicaoServicos']);

    return PreferenciasIndividuaisDoUsuarioModel(
      idiomaDePreferencia: json['idiomaDePreferencia']?.toString() ?? '',
      modoDeExibicaoProdutosWeb:
          ModoDeExibicaoUsuarioApi.tryFromCodigo(
            json['modoDeExibicaoProdutosWeb'],
          ) ??
          modoProdutosLegado ??
          padrao.modoDeExibicaoProdutosWeb,
      modoDeExibicaoProdutosMobile:
          ModoDeExibicaoUsuarioApi.tryFromCodigo(
            json['modoDeExibicaoProdutosMobile'],
          ) ??
          modoProdutosLegado ??
          padrao.modoDeExibicaoProdutosMobile,
      modoDeExibicaoServicosWeb:
          ModoDeExibicaoUsuarioApi.tryFromCodigo(
            json['modoDeExibicaoServicosWeb'],
          ) ??
          modoServicosLegado ??
          padrao.modoDeExibicaoServicosWeb,
      modoDeExibicaoServicosMobile:
          ModoDeExibicaoUsuarioApi.tryFromCodigo(
            json['modoDeExibicaoServicosMobile'],
          ) ??
          modoServicosLegado ??
          padrao.modoDeExibicaoServicosMobile,
      ocultarValoresFinanceirosWeb:
          json['ocultarValoresFinanceirosWeb'] == true,
      agendaFinanceiraPeriodoWeb:
          AgendaFinanceiraPeriodoWebPreferenciaApi.fromCodigo(
            json['agendaFinanceiraPeriodoWeb'],
            padrao.agendaFinanceiraPeriodoWeb,
          ),
      agendaFinanceiraTipoWeb: AgendaFinanceiraTipoWebPreferenciaApi.fromCodigo(
        json['agendaFinanceiraTipoWeb'],
        padrao.agendaFinanceiraTipoWeb,
      ),
      agendaFinanceiraStatusWeb:
          AgendaFinanceiraStatusWebPreferenciaApi.fromCodigo(
            json['agendaFinanceiraStatusWeb'],
            padrao.agendaFinanceiraStatusWeb,
          ),
      agendaFinanceiraTipoDePagamentoWeb: _normalizarListaDeStrings(
        json['agendaFinanceiraTipoDePagamentoWeb'],
      ),
      catalogoReservasFiltrosWeb:
          CatalogoReservasFiltrosWebPreferencia.fromJson(
            json['catalogoReservasFiltrosWeb'],
          ),
      atendimentosCriadosFiltrosWeb:
          AtendimentosCriadosFiltrosWebPreferencia.fromJson(
            json['atendimentosCriadosFiltrosWeb'],
          ),
      atendimentosCriadosFiltrosMobile:
          AtendimentosCriadosFiltrosMobilePreferencia.fromJson(
            json['atendimentosCriadosFiltrosMobile'],
          ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idiomaDePreferencia.trim().isNotEmpty)
        'idiomaDePreferencia': idiomaDePreferencia,
      'modoDeExibicaoProdutos': modoDeExibicaoProdutos.codigo,
      'modoDeExibicaoServicos': modoDeExibicaoServicos.codigo,
      'modoDeExibicaoProdutosWeb': modoDeExibicaoProdutosWeb.codigo,
      'modoDeExibicaoProdutosMobile': modoDeExibicaoProdutosMobile.codigo,
      'modoDeExibicaoServicosWeb': modoDeExibicaoServicosWeb.codigo,
      'modoDeExibicaoServicosMobile': modoDeExibicaoServicosMobile.codigo,
      'ocultarValoresFinanceirosWeb': ocultarValoresFinanceirosWeb,
      'agendaFinanceiraPeriodoWeb': agendaFinanceiraPeriodoWeb.codigo,
      'agendaFinanceiraTipoWeb': agendaFinanceiraTipoWeb.codigo,
      'agendaFinanceiraStatusWeb': agendaFinanceiraStatusWeb.codigo,
      'agendaFinanceiraTipoDePagamentoWeb': agendaFinanceiraTipoDePagamentoWeb,
      'catalogoReservasFiltrosWeb': catalogoReservasFiltrosWeb.toJson(),
      'atendimentosCriadosFiltrosWeb': atendimentosCriadosFiltrosWeb.toJson(),
      'atendimentosCriadosFiltrosMobile':
          atendimentosCriadosFiltrosMobile.toJson(),
    };
  }

  PreferenciasIndividuaisDoUsuarioModel copyWith({
    String? idiomaDePreferencia,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutos,
    ModoDeExibicaoUsuario? modoDeExibicaoServicos,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutosWeb,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutosMobile,
    ModoDeExibicaoUsuario? modoDeExibicaoServicosWeb,
    ModoDeExibicaoUsuario? modoDeExibicaoServicosMobile,
    bool? ocultarValoresFinanceirosWeb,
    AgendaFinanceiraPeriodoWebPreferencia? agendaFinanceiraPeriodoWeb,
    AgendaFinanceiraTipoWebPreferencia? agendaFinanceiraTipoWeb,
    AgendaFinanceiraStatusWebPreferencia? agendaFinanceiraStatusWeb,
    List<String>? agendaFinanceiraTipoDePagamentoWeb,
    CatalogoReservasFiltrosWebPreferencia? catalogoReservasFiltrosWeb,
    AtendimentosCriadosFiltrosWebPreferencia? atendimentosCriadosFiltrosWeb,
    AtendimentosCriadosFiltrosMobilePreferencia?
    atendimentosCriadosFiltrosMobile,
  }) {
    return PreferenciasIndividuaisDoUsuarioModel(
      idiomaDePreferencia: idiomaDePreferencia ?? this.idiomaDePreferencia,
      modoDeExibicaoProdutosWeb:
          modoDeExibicaoProdutosWeb ??
          (modoDeExibicaoProdutos != null && kIsWeb
              ? modoDeExibicaoProdutos
              : this.modoDeExibicaoProdutosWeb),
      modoDeExibicaoProdutosMobile:
          modoDeExibicaoProdutosMobile ??
          (modoDeExibicaoProdutos != null && !kIsWeb
              ? modoDeExibicaoProdutos
              : this.modoDeExibicaoProdutosMobile),
      modoDeExibicaoServicosWeb:
          modoDeExibicaoServicosWeb ??
          (modoDeExibicaoServicos != null && kIsWeb
              ? modoDeExibicaoServicos
              : this.modoDeExibicaoServicosWeb),
      modoDeExibicaoServicosMobile:
          modoDeExibicaoServicosMobile ??
          (modoDeExibicaoServicos != null && !kIsWeb
              ? modoDeExibicaoServicos
              : this.modoDeExibicaoServicosMobile),
      ocultarValoresFinanceirosWeb:
          ocultarValoresFinanceirosWeb ?? this.ocultarValoresFinanceirosWeb,
      agendaFinanceiraPeriodoWeb:
          agendaFinanceiraPeriodoWeb ?? this.agendaFinanceiraPeriodoWeb,
      agendaFinanceiraTipoWeb:
          agendaFinanceiraTipoWeb ?? this.agendaFinanceiraTipoWeb,
      agendaFinanceiraStatusWeb:
          agendaFinanceiraStatusWeb ?? this.agendaFinanceiraStatusWeb,
      agendaFinanceiraTipoDePagamentoWeb:
          agendaFinanceiraTipoDePagamentoWeb ??
          this.agendaFinanceiraTipoDePagamentoWeb,
      catalogoReservasFiltrosWeb:
          catalogoReservasFiltrosWeb ?? this.catalogoReservasFiltrosWeb,
      atendimentosCriadosFiltrosWeb:
          atendimentosCriadosFiltrosWeb ?? this.atendimentosCriadosFiltrosWeb,
      atendimentosCriadosFiltrosMobile:
          atendimentosCriadosFiltrosMobile ??
          this.atendimentosCriadosFiltrosMobile,
    );
  }

  static List<String> _normalizarListaDeStrings(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }
    return <String>[];
  }
}

class CatalogoReservasFiltrosWebPreferencia {
  const CatalogoReservasFiltrosWebPreferencia({
    this.status = const <String>[],
    this.periodo = CatalogoReservasPeriodoWebPreferencia.proximos7Dias,
    this.dataInicio,
    this.dataFim,
  });

  final List<String> status;
  final CatalogoReservasPeriodoWebPreferencia periodo;
  final DateTime? dataInicio;
  final DateTime? dataFim;

  factory CatalogoReservasFiltrosWebPreferencia.vazia() {
    return const CatalogoReservasFiltrosWebPreferencia();
  }

  factory CatalogoReservasFiltrosWebPreferencia.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return CatalogoReservasFiltrosWebPreferencia.vazia();
    }

    return CatalogoReservasFiltrosWebPreferencia(
      status: PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(
        json['status'],
      ),
      periodo: CatalogoReservasPeriodoWebPreferenciaApi.fromCodigo(
        json['periodo'],
        CatalogoReservasPeriodoWebPreferencia.proximos7Dias,
      ),
      dataInicio: _dateFromJson(json['dataInicio']),
      dataFim: _dateFromJson(json['dataFim']),
    );
  }

  Map<String, dynamic> toJson() {
    final List<String> statusNormalizado =
        PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(status)
          ..sort();
    return <String, dynamic>{
      if (statusNormalizado.isNotEmpty) 'status': statusNormalizado,
      if (periodo != CatalogoReservasPeriodoWebPreferencia.proximos7Dias)
        'periodo': periodo.codigo,
      if (periodo == CatalogoReservasPeriodoWebPreferencia.personalizado &&
          dataInicio != null)
        'dataInicio': _dateToJson(dataInicio!),
      if (periodo == CatalogoReservasPeriodoWebPreferencia.personalizado &&
          dataFim != null)
        'dataFim': _dateToJson(dataFim!),
    };
  }

  static DateTime? _dateFromJson(dynamic value) {
    final String raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _dateToJson(DateTime value) {
    final DateTime date = DateTime(value.year, value.month, value.day);
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class AtendimentosCriadosFiltrosWebPreferencia {
  const AtendimentosCriadosFiltrosWebPreferencia({
    this.busca = '',
    this.dataInicio,
    this.dataFim,
    this.tecnicoKeys = const <String>[],
    this.statusKeys = const <String>[],
    this.tecnicoKey,
    this.statusKey,
    this.statusPagamento = AtendimentosCriadosStatusPagamentoFiltro.todos,
  });

  final String busca;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final List<String> tecnicoKeys;
  final List<String> statusKeys;
  final String? tecnicoKey;
  final String? statusKey;
  final AtendimentosCriadosStatusPagamentoFiltro statusPagamento;

  List<String> get tecnicoKeysSelecionadas {
    final List<String> keys =
        PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(
          tecnicoKeys,
        );
    if (keys.isNotEmpty) return keys;
    final String? key = _nullableStringFromJson(tecnicoKey);
    return key == null ? const <String>[] : <String>[key];
  }

  List<String> get statusKeysSelecionadas {
    final List<String> keys =
        PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(
          statusKeys,
        );
    if (keys.isNotEmpty) return keys;
    final String? key = _nullableStringFromJson(statusKey);
    return key == null ? const <String>[] : <String>[key];
  }

  factory AtendimentosCriadosFiltrosWebPreferencia.vazia() {
    return const AtendimentosCriadosFiltrosWebPreferencia();
  }

  factory AtendimentosCriadosFiltrosWebPreferencia.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return AtendimentosCriadosFiltrosWebPreferencia.vazia();
    }

    return AtendimentosCriadosFiltrosWebPreferencia(
      busca: json['busca']?.toString().trim() ?? '',
      dataInicio: _dateFromJson(json['dataInicio']),
      dataFim: _dateFromJson(json['dataFim']),
      tecnicoKeys:
          PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(
            json['tecnicoKeys'],
          ),
      statusKeys:
          PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(
            json['statusKeys'],
          ),
      tecnicoKey: _nullableStringFromJson(json['tecnicoKey']),
      statusKey: _nullableStringFromJson(json['statusKey']),
      statusPagamento: AtendimentosCriadosStatusPagamentoFiltroApi.fromCodigo(
        json['statusPagamento'],
        AtendimentosCriadosStatusPagamentoFiltro.todos,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final List<String> tecnicos = tecnicoKeysSelecionadas;
    final List<String> status = statusKeysSelecionadas;
    return <String, dynamic>{
      if (busca.trim().isNotEmpty) 'busca': busca.trim(),
      if (dataInicio != null) 'dataInicio': _dateToJson(dataInicio!),
      if (dataFim != null) 'dataFim': _dateToJson(dataFim!),
      if (tecnicos.isNotEmpty) 'tecnicoKeys': tecnicos,
      if (status.isNotEmpty) 'statusKeys': status,
      if (statusPagamento != AtendimentosCriadosStatusPagamentoFiltro.todos)
        'statusPagamento': statusPagamento.codigo,
    };
  }

  static DateTime? _dateFromJson(dynamic value) {
    final String raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String? _nullableStringFromJson(dynamic value) {
    final String raw = value?.toString().trim() ?? '';
    return raw.isEmpty ? null : raw;
  }

  static String _dateToJson(DateTime value) {
    final DateTime date = DateTime(value.year, value.month, value.day);
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class AtendimentosCriadosFiltrosMobilePreferencia {
  const AtendimentosCriadosFiltrosMobilePreferencia({
    this.busca = '',
    this.dataInicio,
    this.dataFim,
    this.tecnicoKey,
    this.statusKey,
    this.statusPagamento = AtendimentosCriadosStatusPagamentoFiltro.todos,
  });

  final String busca;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? tecnicoKey;
  final String? statusKey;
  final AtendimentosCriadosStatusPagamentoFiltro statusPagamento;

  factory AtendimentosCriadosFiltrosMobilePreferencia.vazia() {
    return const AtendimentosCriadosFiltrosMobilePreferencia();
  }

  factory AtendimentosCriadosFiltrosMobilePreferencia.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return AtendimentosCriadosFiltrosMobilePreferencia.vazia();
    }

    return AtendimentosCriadosFiltrosMobilePreferencia(
      busca: json['busca']?.toString().trim() ?? '',
      dataInicio: _dateFromJson(json['dataInicio']),
      dataFim: _dateFromJson(json['dataFim']),
      tecnicoKey: _nullableStringFromJson(json['tecnicoKey']),
      statusKey: _nullableStringFromJson(json['statusKey']),
      statusPagamento: AtendimentosCriadosStatusPagamentoFiltroApi.fromCodigo(
        json['statusPagamento'],
        AtendimentosCriadosStatusPagamentoFiltro.todos,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (busca.trim().isNotEmpty) 'busca': busca.trim(),
      if (dataInicio != null) 'dataInicio': _dateToJson(dataInicio!),
      if (dataFim != null) 'dataFim': _dateToJson(dataFim!),
      if ((tecnicoKey ?? '').trim().isNotEmpty)
        'tecnicoKey': tecnicoKey!.trim(),
      if ((statusKey ?? '').trim().isNotEmpty) 'statusKey': statusKey!.trim(),
      if (statusPagamento != AtendimentosCriadosStatusPagamentoFiltro.todos)
        'statusPagamento': statusPagamento.codigo,
    };
  }

  static DateTime? _dateFromJson(dynamic value) {
    final String raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String? _nullableStringFromJson(dynamic value) {
    final String raw = value?.toString().trim() ?? '';
    return raw.isEmpty ? null : raw;
  }

  static String _dateToJson(DateTime value) {
    final DateTime date = DateTime(value.year, value.month, value.day);
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
