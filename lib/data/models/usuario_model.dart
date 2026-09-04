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
  final bool fezOnboardingInicial;

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
    this.fezOnboardingInicial = false,
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
      fezOnboardingInicial: json['fezOnboardingInicial'] == true,
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
    bool? fezOnboardingInicial,
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
      fezOnboardingInicial: fezOnboardingInicial ?? this.fezOnboardingInicial,
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

class AgendaFinanceiraFiltrosPreferencia {
  AgendaFinanceiraFiltrosPreferencia({
    this.periodo = AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
    this.dataInicio,
    this.dataFim,
    this.tipo = AgendaFinanceiraTipoWebPreferencia.todos,
    this.status = AgendaFinanceiraStatusWebPreferencia.todos,
    List<String>? tiposDePagamento,
  }) : tiposDePagamento = List<String>.unmodifiable(
         PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(
           tiposDePagamento,
         ),
       );

  final AgendaFinanceiraPeriodoWebPreferencia periodo;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final AgendaFinanceiraTipoWebPreferencia tipo;
  final AgendaFinanceiraStatusWebPreferencia status;
  final List<String> tiposDePagamento;

  factory AgendaFinanceiraFiltrosPreferencia.vazia() {
    return AgendaFinanceiraFiltrosPreferencia();
  }

  factory AgendaFinanceiraFiltrosPreferencia.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return AgendaFinanceiraFiltrosPreferencia.vazia();
    }

    return AgendaFinanceiraFiltrosPreferencia(
      periodo: AgendaFinanceiraPeriodoWebPreferenciaApi.fromCodigo(
        json['periodo'],
        AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
      ),
      dataInicio: _dateFromJson(json['dataInicio']),
      dataFim: _dateFromJson(json['dataFim']),
      tipo: AgendaFinanceiraTipoWebPreferenciaApi.fromCodigo(
        json['tipo'],
        AgendaFinanceiraTipoWebPreferencia.todos,
      ),
      status: AgendaFinanceiraStatusWebPreferenciaApi.fromCodigo(
        json['status'],
        AgendaFinanceiraStatusWebPreferencia.todos,
      ),
      tiposDePagamento:
          PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(
            json['tiposDePagamento'],
          ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (periodo != AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias)
        'periodo': periodo.codigo,
      if (periodo == AgendaFinanceiraPeriodoWebPreferencia.personalizado &&
          dataInicio != null)
        'dataInicio': _dateToJson(dataInicio!),
      if (periodo == AgendaFinanceiraPeriodoWebPreferencia.personalizado &&
          dataFim != null)
        'dataFim': _dateToJson(dataFim!),
      if (tipo != AgendaFinanceiraTipoWebPreferencia.todos) 'tipo': tipo.codigo,
      if (status != AgendaFinanceiraStatusWebPreferencia.todos)
        'status': status.codigo,
      if (tiposDePagamento.isNotEmpty) 'tiposDePagamento': tiposDePagamento,
    };
  }

  AgendaFinanceiraFiltrosPreferencia copyWith({
    AgendaFinanceiraPeriodoWebPreferencia? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    AgendaFinanceiraTipoWebPreferencia? tipo,
    AgendaFinanceiraStatusWebPreferencia? status,
    List<String>? tiposDePagamento,
  }) {
    return AgendaFinanceiraFiltrosPreferencia(
      periodo: periodo ?? this.periodo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      tipo: tipo ?? this.tipo,
      status: status ?? this.status,
      tiposDePagamento: tiposDePagamento ?? this.tiposDePagamento,
    );
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

class EstoqueFiltrosPreferencia {
  EstoqueFiltrosPreferencia({
    String busca = '',
    String tipo = 'PRODUTO',
    String? categoriaId,
    String status = 'TODOS',
    String situacaoEstoque = 'TODOS',
    String marcacao = 'TODOS',
    String ordenacao = 'NOME_ASC',
    String resumoRapido = 'PRODUTOS',
    int itensPorPagina = 12,
  }) : busca = busca.trim(),
       tipo = _normalizarCodigo(tipo, const <String>{
         'PRODUTO',
         'SERVICO',
       }, 'PRODUTO'),
       categoriaId = _normalizarTextoOpcional(categoriaId),
       status = _normalizarCodigo(status, const <String>{
         'TODOS',
         'ATIVOS',
         'INATIVOS',
       }, 'TODOS'),
       situacaoEstoque = _normalizarCodigo(situacaoEstoque, const <String>{
         'TODOS',
         'EM_ESTOQUE',
         'ESTOQUE_BAIXO',
         'SEM_ESTOQUE',
         'ESTOQUE_NEGATIVO',
       }, 'TODOS'),
       marcacao = _normalizarCodigo(marcacao, const <String>{
         'TODOS',
         'FAVORITOS',
         'CATALOGO',
         'FAVORITOS_E_CATALOGO',
       }, 'TODOS'),
       ordenacao = _normalizarCodigo(ordenacao, const <String>{
         'NOME_ASC',
         'PRECO_ASC',
         'PRECO_DESC',
       }, 'NOME_ASC'),
       resumoRapido = _normalizarCodigo(resumoRapido, const <String>{
         'TODOS',
         'PRODUTOS',
         'SERVICOS',
         'COM_IMAGEM',
         'ESTOQUE_BAIXO',
       }, 'PRODUTOS'),
       itensPorPagina =
           const <int>{12, 24, 48}.contains(itensPorPagina)
               ? itensPorPagina
               : 12;

  final String busca;
  final String tipo;
  final String? categoriaId;
  final String status;
  final String situacaoEstoque;
  final String marcacao;
  final String ordenacao;
  final String resumoRapido;
  final int itensPorPagina;

  factory EstoqueFiltrosPreferencia.vazia() {
    return EstoqueFiltrosPreferencia();
  }

  factory EstoqueFiltrosPreferencia.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return EstoqueFiltrosPreferencia.vazia();
    }

    return EstoqueFiltrosPreferencia(
      busca: json['busca']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'PRODUTO',
      categoriaId: json['categoriaId']?.toString(),
      status: json['status']?.toString() ?? 'TODOS',
      situacaoEstoque: json['situacaoEstoque']?.toString() ?? 'TODOS',
      marcacao: json['marcacao']?.toString() ?? 'TODOS',
      ordenacao: json['ordenacao']?.toString() ?? 'NOME_ASC',
      resumoRapido: json['resumoRapido']?.toString() ?? 'PRODUTOS',
      itensPorPagina:
          int.tryParse(json['itensPorPagina']?.toString() ?? '') ?? 12,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (busca.isNotEmpty) 'busca': busca,
      if (tipo != 'PRODUTO') 'tipo': tipo,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (status != 'TODOS') 'status': status,
      if (situacaoEstoque != 'TODOS') 'situacaoEstoque': situacaoEstoque,
      if (marcacao != 'TODOS') 'marcacao': marcacao,
      if (ordenacao != 'NOME_ASC') 'ordenacao': ordenacao,
      if (resumoRapido != 'PRODUTOS') 'resumoRapido': resumoRapido,
      if (itensPorPagina != 12) 'itensPorPagina': itensPorPagina,
    };
  }

  static String _normalizarCodigo(
    String value,
    Set<String> permitidos,
    String fallback,
  ) {
    final String codigo = value.trim().toUpperCase();
    return permitidos.contains(codigo) ? codigo : fallback;
  }

  static String? _normalizarTextoOpcional(String? value) {
    final String texto = value?.trim() ?? '';
    return texto.isEmpty ? null : texto;
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

enum GestaoMobileCardPreferencia {
  catalogo,
  pessoas,
  financeiro,
  configuracoes,
}

extension GestaoMobileCardPreferenciaApi on GestaoMobileCardPreferencia {
  String get codigo {
    switch (this) {
      case GestaoMobileCardPreferencia.catalogo:
        return 'CATALOGO';
      case GestaoMobileCardPreferencia.pessoas:
        return 'PESSOAS';
      case GestaoMobileCardPreferencia.financeiro:
        return 'FINANCEIRO';
      case GestaoMobileCardPreferencia.configuracoes:
        return 'CONFIGURACOES';
    }
  }

  static GestaoMobileCardPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().trim().toUpperCase() ?? '';
    switch (codigo) {
      case 'CATALOGO':
        return GestaoMobileCardPreferencia.catalogo;
      case 'PESSOAS':
        return GestaoMobileCardPreferencia.pessoas;
      case 'FINANCEIRO':
        return GestaoMobileCardPreferencia.financeiro;
      case 'CONFIGURACOES':
        return GestaoMobileCardPreferencia.configuracoes;
      default:
        return null;
    }
  }

  static List<GestaoMobileCardPreferencia> normalizarOrdem(dynamic value) {
    if (value is Iterable) {
      final List<GestaoMobileCardPreferencia> ordem = value
          .map(
            (dynamic item) =>
                item is GestaoMobileCardPreferencia
                    ? item
                    : tryFromCodigo(item),
          )
          .whereType<GestaoMobileCardPreferencia>()
          .toList(growable: false);
      if (ordem.length == GestaoMobileCardPreferencia.values.length &&
          ordem.toSet().length == GestaoMobileCardPreferencia.values.length) {
        return List<GestaoMobileCardPreferencia>.unmodifiable(ordem);
      }
    }
    return List<GestaoMobileCardPreferencia>.unmodifiable(
      GestaoMobileCardPreferencia.values,
    );
  }
}

enum AtendimentoMobileCardPreferencia {
  novaVenda,
  novoServico,
  receber,
  operacoesCaixa,
  devolucao,
}

extension AtendimentoMobileCardPreferenciaApi
    on AtendimentoMobileCardPreferencia {
  String get codigo {
    switch (this) {
      case AtendimentoMobileCardPreferencia.novaVenda:
        return 'NOVA_VENDA';
      case AtendimentoMobileCardPreferencia.novoServico:
        return 'NOVO_SERVICO';
      case AtendimentoMobileCardPreferencia.receber:
        return 'RECEBER';
      case AtendimentoMobileCardPreferencia.operacoesCaixa:
        return 'OPERACOES_CAIXA';
      case AtendimentoMobileCardPreferencia.devolucao:
        return 'DEVOLUCAO';
    }
  }

  static AtendimentoMobileCardPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().trim().toUpperCase() ?? '';
    switch (codigo) {
      case 'NOVA_VENDA':
        return AtendimentoMobileCardPreferencia.novaVenda;
      case 'NOVO_SERVICO':
      case 'SERVICOS':
        return AtendimentoMobileCardPreferencia.novoServico;
      case 'RECEBER':
        return AtendimentoMobileCardPreferencia.receber;
      case 'OPERACOES_CAIXA':
        return AtendimentoMobileCardPreferencia.operacoesCaixa;
      case 'DEVOLUCAO':
      case 'DEVOLUCOES':
        return AtendimentoMobileCardPreferencia.devolucao;
      default:
        return null;
    }
  }

  static List<AtendimentoMobileCardPreferencia> normalizarOrdem(
    dynamic value,
  ) => _normalizarOrdemDeCards<AtendimentoMobileCardPreferencia>(
    value,
    AtendimentoMobileCardPreferencia.values,
    tryFromCodigo,
  );
}

enum VendasMobileCardPreferencia { novaVenda, vendasAReceber, consultarVendas }

extension VendasMobileCardPreferenciaApi on VendasMobileCardPreferencia {
  String get codigo {
    switch (this) {
      case VendasMobileCardPreferencia.novaVenda:
        return 'NOVA_VENDA';
      case VendasMobileCardPreferencia.vendasAReceber:
        return 'VENDAS_A_RECEBER';
      case VendasMobileCardPreferencia.consultarVendas:
        return 'CONSULTAR_VENDAS';
    }
  }

  static VendasMobileCardPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().trim().toUpperCase() ?? '';
    switch (codigo) {
      case 'NOVA_VENDA':
        return VendasMobileCardPreferencia.novaVenda;
      case 'VENDAS_A_RECEBER':
        return VendasMobileCardPreferencia.vendasAReceber;
      case 'CONSULTAR_VENDAS':
        return VendasMobileCardPreferencia.consultarVendas;
      default:
        return null;
    }
  }

  static List<VendasMobileCardPreferencia> normalizarOrdem(dynamic value) =>
      _normalizarOrdemDeCards<VendasMobileCardPreferencia>(
        value,
        VendasMobileCardPreferencia.values,
        tryFromCodigo,
      );
}

enum ServicosMobileCardPreferencia {
  novoServico,
  servicosEmAndamento,
  orcamentosAguardandoAprovacao,
  servicosJaEncerrados,
}

extension ServicosMobileCardPreferenciaApi on ServicosMobileCardPreferencia {
  String get codigo {
    switch (this) {
      case ServicosMobileCardPreferencia.novoServico:
        return 'NOVO_SERVICO';
      case ServicosMobileCardPreferencia.servicosEmAndamento:
        return 'SERVICOS_EM_ANDAMENTO';
      case ServicosMobileCardPreferencia.orcamentosAguardandoAprovacao:
        return 'ORCAMENTOS_AGUARDANDO_APROVACAO';
      case ServicosMobileCardPreferencia.servicosJaEncerrados:
        return 'SERVICOS_JA_ENCERRADOS';
    }
  }

  static ServicosMobileCardPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().trim().toUpperCase() ?? '';
    switch (codigo) {
      case 'NOVO_SERVICO':
        return ServicosMobileCardPreferencia.novoServico;
      case 'SERVICOS_EM_ANDAMENTO':
        return ServicosMobileCardPreferencia.servicosEmAndamento;
      case 'ORCAMENTOS_AGUARDANDO_APROVACAO':
        return ServicosMobileCardPreferencia.orcamentosAguardandoAprovacao;
      case 'SERVICOS_JA_ENCERRADOS':
        return ServicosMobileCardPreferencia.servicosJaEncerrados;
      default:
        return null;
    }
  }

  static List<ServicosMobileCardPreferencia> normalizarOrdem(dynamic value) =>
      _normalizarOrdemDeCards<ServicosMobileCardPreferencia>(
        value,
        ServicosMobileCardPreferencia.values,
        tryFromCodigo,
      );
}

enum ReceberMobileCardPreferencia { vendasAReceber, servicosAReceber }

extension ReceberMobileCardPreferenciaApi on ReceberMobileCardPreferencia {
  String get codigo {
    switch (this) {
      case ReceberMobileCardPreferencia.vendasAReceber:
        return 'VENDAS_A_RECEBER';
      case ReceberMobileCardPreferencia.servicosAReceber:
        return 'SERVICOS_A_RECEBER';
    }
  }

  static ReceberMobileCardPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().trim().toUpperCase() ?? '';
    switch (codigo) {
      case 'VENDAS_A_RECEBER':
        return ReceberMobileCardPreferencia.vendasAReceber;
      case 'SERVICOS_A_RECEBER':
        return ReceberMobileCardPreferencia.servicosAReceber;
      default:
        return null;
    }
  }

  static List<ReceberMobileCardPreferencia> normalizarOrdem(dynamic value) =>
      _normalizarOrdemDeCards<ReceberMobileCardPreferencia>(
        value,
        ReceberMobileCardPreferencia.values,
        tryFromCodigo,
      );
}

List<T> _normalizarOrdemDeCards<T extends Object>(
  dynamic value,
  List<T> ordemPadrao,
  T? Function(dynamic value) parser,
) {
  if (value is Iterable) {
    final List<T> ordem = value
        .map((dynamic item) => item is T ? item : parser(item))
        .whereType<T>()
        .toList(growable: false);
    if (ordem.length == ordemPadrao.length &&
        ordem.toSet().length == ordemPadrao.length &&
        ordem.toSet().containsAll(ordemPadrao)) {
      return List<T>.unmodifiable(ordem);
    }
  }
  return List<T>.unmodifiable(ordemPadrao);
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
  final AgendaFinanceiraFiltrosPreferencia agendaFinanceiraFiltrosWeb;
  final AgendaFinanceiraFiltrosPreferencia agendaFinanceiraFiltrosMobile;
  final EstoqueFiltrosPreferencia estoqueFiltrosWeb;
  final EstoqueFiltrosPreferencia estoqueFiltrosMobile;
  final CatalogoReservasFiltrosWebPreferencia catalogoReservasFiltrosWeb;
  final ConsultaVendasFiltrosWebPreferencia consultaVendasFiltrosWeb;
  final ConsultaVendasFiltrosWebPreferencia consultaVendasFiltrosMobile;
  final AtendimentosCriadosFiltrosWebPreferencia atendimentosCriadosFiltrosWeb;
  final AtendimentosCriadosFiltrosMobilePreferencia
  atendimentosCriadosFiltrosMobile;
  final AtendimentosCriadosFiltrosMobilePreferencia
  servicosEmAndamentoFiltrosMobile;
  final Map<String, dynamic> desempenhoInicioFiltrosWeb;
  final Map<String, dynamic> desempenhoInicioFiltrosMobile;
  final List<GestaoMobileCardPreferencia> ordemCardsGestaoMobile;
  final List<AtendimentoMobileCardPreferencia> ordemCardsAtendimentoMobile;
  final List<VendasMobileCardPreferencia> ordemCardsVendasMobile;
  final List<ServicosMobileCardPreferencia> ordemCardsServicosMobile;
  final List<ReceberMobileCardPreferencia> ordemCardsReceberMobile;

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
    AgendaFinanceiraFiltrosPreferencia? agendaFinanceiraFiltrosWeb,
    AgendaFinanceiraFiltrosPreferencia? agendaFinanceiraFiltrosMobile,
    EstoqueFiltrosPreferencia? estoqueFiltrosWeb,
    EstoqueFiltrosPreferencia? estoqueFiltrosMobile,
    CatalogoReservasFiltrosWebPreferencia? catalogoReservasFiltrosWeb,
    ConsultaVendasFiltrosWebPreferencia? consultaVendasFiltrosWeb,
    ConsultaVendasFiltrosWebPreferencia? consultaVendasFiltrosMobile,
    AtendimentosCriadosFiltrosWebPreferencia? atendimentosCriadosFiltrosWeb,
    AtendimentosCriadosFiltrosMobilePreferencia?
    atendimentosCriadosFiltrosMobile,
    AtendimentosCriadosFiltrosMobilePreferencia?
    servicosEmAndamentoFiltrosMobile,
    Map<String, dynamic>? desempenhoInicioFiltrosWeb,
    Map<String, dynamic>? desempenhoInicioFiltrosMobile,
    List<GestaoMobileCardPreferencia>? ordemCardsGestaoMobile,
    List<AtendimentoMobileCardPreferencia>? ordemCardsAtendimentoMobile,
    List<VendasMobileCardPreferencia>? ordemCardsVendasMobile,
    List<ServicosMobileCardPreferencia>? ordemCardsServicosMobile,
    List<ReceberMobileCardPreferencia>? ordemCardsReceberMobile,
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
           agendaFinanceiraFiltrosWeb?.periodo ??
           agendaFinanceiraPeriodoWeb ??
           AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
       agendaFinanceiraTipoWeb =
           agendaFinanceiraFiltrosWeb?.tipo ??
           agendaFinanceiraTipoWeb ??
           AgendaFinanceiraTipoWebPreferencia.todos,
       agendaFinanceiraStatusWeb =
           agendaFinanceiraFiltrosWeb?.status ??
           agendaFinanceiraStatusWeb ??
           AgendaFinanceiraStatusWebPreferencia.todos,
       agendaFinanceiraTipoDePagamentoWeb = List<String>.unmodifiable(
         agendaFinanceiraFiltrosWeb?.tiposDePagamento ??
             _normalizarListaDeStrings(agendaFinanceiraTipoDePagamentoWeb),
       ),
       agendaFinanceiraFiltrosWeb =
           agendaFinanceiraFiltrosWeb ??
           AgendaFinanceiraFiltrosPreferencia(
             periodo:
                 agendaFinanceiraPeriodoWeb ??
                 AgendaFinanceiraPeriodoWebPreferencia.proximos7Dias,
             tipo:
                 agendaFinanceiraTipoWeb ??
                 AgendaFinanceiraTipoWebPreferencia.todos,
             status:
                 agendaFinanceiraStatusWeb ??
                 AgendaFinanceiraStatusWebPreferencia.todos,
             tiposDePagamento: agendaFinanceiraTipoDePagamentoWeb,
           ),
       agendaFinanceiraFiltrosMobile =
           agendaFinanceiraFiltrosMobile ??
           AgendaFinanceiraFiltrosPreferencia.vazia(),
       estoqueFiltrosWeb =
           estoqueFiltrosWeb ?? EstoqueFiltrosPreferencia.vazia(),
       estoqueFiltrosMobile =
           estoqueFiltrosMobile ?? EstoqueFiltrosPreferencia.vazia(),
       catalogoReservasFiltrosWeb =
           catalogoReservasFiltrosWeb ??
           CatalogoReservasFiltrosWebPreferencia.vazia(),
       consultaVendasFiltrosWeb =
           consultaVendasFiltrosWeb ??
           ConsultaVendasFiltrosWebPreferencia.vazia(),
       consultaVendasFiltrosMobile =
           consultaVendasFiltrosMobile ??
           const ConsultaVendasFiltrosWebPreferencia(
             periodo: ConsultaVendasPeriodoWebPreferencia.hoje,
           ),
       atendimentosCriadosFiltrosWeb =
           atendimentosCriadosFiltrosWeb ??
           AtendimentosCriadosFiltrosWebPreferencia.vazia(),
       atendimentosCriadosFiltrosMobile =
           atendimentosCriadosFiltrosMobile ??
           AtendimentosCriadosFiltrosMobilePreferencia.vazia(),
       servicosEmAndamentoFiltrosMobile =
           servicosEmAndamentoFiltrosMobile ??
           AtendimentosCriadosFiltrosMobilePreferencia.vazia(),
       desempenhoInicioFiltrosWeb = Map<String, dynamic>.unmodifiable(
         _normalizarMapa(desempenhoInicioFiltrosWeb),
       ),
       desempenhoInicioFiltrosMobile = Map<String, dynamic>.unmodifiable(
         _normalizarMapa(desempenhoInicioFiltrosMobile),
       ),
       ordemCardsGestaoMobile = GestaoMobileCardPreferenciaApi.normalizarOrdem(
         ordemCardsGestaoMobile,
       ),
       ordemCardsAtendimentoMobile =
           AtendimentoMobileCardPreferenciaApi.normalizarOrdem(
             ordemCardsAtendimentoMobile,
           ),
       ordemCardsVendasMobile = VendasMobileCardPreferenciaApi.normalizarOrdem(
         ordemCardsVendasMobile,
       ),
       ordemCardsServicosMobile =
           ServicosMobileCardPreferenciaApi.normalizarOrdem(
             ordemCardsServicosMobile,
           ),
       ordemCardsReceberMobile =
           ReceberMobileCardPreferenciaApi.normalizarOrdem(
             ordemCardsReceberMobile,
           );

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
      agendaFinanceiraFiltrosWeb: AgendaFinanceiraFiltrosPreferencia.vazia(),
      agendaFinanceiraFiltrosMobile: AgendaFinanceiraFiltrosPreferencia.vazia(),
      estoqueFiltrosWeb: EstoqueFiltrosPreferencia.vazia(),
      estoqueFiltrosMobile: EstoqueFiltrosPreferencia.vazia(),
      catalogoReservasFiltrosWeb: CatalogoReservasFiltrosWebPreferencia.vazia(),
      consultaVendasFiltrosWeb: ConsultaVendasFiltrosWebPreferencia.vazia(),
      consultaVendasFiltrosMobile: const ConsultaVendasFiltrosWebPreferencia(
        periodo: ConsultaVendasPeriodoWebPreferencia.hoje,
      ),
      atendimentosCriadosFiltrosWeb:
          AtendimentosCriadosFiltrosWebPreferencia.vazia(),
      atendimentosCriadosFiltrosMobile:
          AtendimentosCriadosFiltrosMobilePreferencia.vazia(),
      servicosEmAndamentoFiltrosMobile:
          AtendimentosCriadosFiltrosMobilePreferencia.vazia(),
      desempenhoInicioFiltrosWeb: const <String, dynamic>{},
      desempenhoInicioFiltrosMobile: const <String, dynamic>{},
      ordemCardsGestaoMobile: GestaoMobileCardPreferencia.values,
      ordemCardsAtendimentoMobile: AtendimentoMobileCardPreferencia.values,
      ordemCardsVendasMobile: VendasMobileCardPreferencia.values,
      ordemCardsServicosMobile: ServicosMobileCardPreferencia.values,
      ordemCardsReceberMobile: ReceberMobileCardPreferencia.values,
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
    final AgendaFinanceiraFiltrosPreferencia agendaFinanceiraFiltrosWebLegado =
        AgendaFinanceiraFiltrosPreferencia(
          periodo: AgendaFinanceiraPeriodoWebPreferenciaApi.fromCodigo(
            json['agendaFinanceiraPeriodoWeb'],
            padrao.agendaFinanceiraPeriodoWeb,
          ),
          tipo: AgendaFinanceiraTipoWebPreferenciaApi.fromCodigo(
            json['agendaFinanceiraTipoWeb'],
            padrao.agendaFinanceiraTipoWeb,
          ),
          status: AgendaFinanceiraStatusWebPreferenciaApi.fromCodigo(
            json['agendaFinanceiraStatusWeb'],
            padrao.agendaFinanceiraStatusWeb,
          ),
          tiposDePagamento: _normalizarListaDeStrings(
            json['agendaFinanceiraTipoDePagamentoWeb'],
          ),
        );

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
      agendaFinanceiraFiltrosWeb:
          json['agendaFinanceiraFiltrosWeb'] is Map<String, dynamic> &&
                  (json['agendaFinanceiraFiltrosWeb'] as Map<String, dynamic>)
                      .isNotEmpty
              ? AgendaFinanceiraFiltrosPreferencia.fromJson(
                json['agendaFinanceiraFiltrosWeb'],
              )
              : agendaFinanceiraFiltrosWebLegado,
      agendaFinanceiraFiltrosMobile:
          json['agendaFinanceiraFiltrosMobile'] is Map<String, dynamic>
              ? AgendaFinanceiraFiltrosPreferencia.fromJson(
                json['agendaFinanceiraFiltrosMobile'],
              )
              : padrao.agendaFinanceiraFiltrosMobile,
      estoqueFiltrosWeb: EstoqueFiltrosPreferencia.fromJson(
        json['estoqueFiltrosWeb'],
      ),
      estoqueFiltrosMobile: EstoqueFiltrosPreferencia.fromJson(
        json['estoqueFiltrosMobile'],
      ),
      catalogoReservasFiltrosWeb:
          CatalogoReservasFiltrosWebPreferencia.fromJson(
            json['catalogoReservasFiltrosWeb'],
          ),
      consultaVendasFiltrosWeb: ConsultaVendasFiltrosWebPreferencia.fromJson(
        json['consultaVendasFiltrosWeb'],
      ),
      consultaVendasFiltrosMobile:
          json['consultaVendasFiltrosMobile'] is Map<String, dynamic>
              ? ConsultaVendasFiltrosWebPreferencia.fromJson(
                json['consultaVendasFiltrosMobile'],
                periodoPadrao: ConsultaVendasPeriodoWebPreferencia.hoje,
              )
              : padrao.consultaVendasFiltrosMobile,
      atendimentosCriadosFiltrosWeb:
          AtendimentosCriadosFiltrosWebPreferencia.fromJson(
            json['atendimentosCriadosFiltrosWeb'],
          ),
      atendimentosCriadosFiltrosMobile:
          AtendimentosCriadosFiltrosMobilePreferencia.fromJson(
            json['atendimentosCriadosFiltrosMobile'],
          ),
      servicosEmAndamentoFiltrosMobile:
          AtendimentosCriadosFiltrosMobilePreferencia.fromJson(
            json['servicosEmAndamentoFiltrosMobile'],
          ),
      desempenhoInicioFiltrosWeb: _normalizarMapa(
        json['desempenhoInicioFiltrosWeb'],
      ),
      desempenhoInicioFiltrosMobile: _normalizarMapa(
        json['desempenhoInicioFiltrosMobile'],
      ),
      ordemCardsGestaoMobile: GestaoMobileCardPreferenciaApi.normalizarOrdem(
        json['ordemCardsGestaoMobile'],
      ),
      ordemCardsAtendimentoMobile:
          AtendimentoMobileCardPreferenciaApi.normalizarOrdem(
            json['ordemCardsAtendimentoMobile'],
          ),
      ordemCardsVendasMobile: VendasMobileCardPreferenciaApi.normalizarOrdem(
        json['ordemCardsVendasMobile'],
      ),
      ordemCardsServicosMobile:
          ServicosMobileCardPreferenciaApi.normalizarOrdem(
            json['ordemCardsServicosMobile'],
          ),
      ordemCardsReceberMobile: ReceberMobileCardPreferenciaApi.normalizarOrdem(
        json['ordemCardsReceberMobile'],
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
      'agendaFinanceiraFiltrosWeb': agendaFinanceiraFiltrosWeb.toJson(),
      'agendaFinanceiraFiltrosMobile': agendaFinanceiraFiltrosMobile.toJson(),
      'estoqueFiltrosWeb': estoqueFiltrosWeb.toJson(),
      'estoqueFiltrosMobile': estoqueFiltrosMobile.toJson(),
      'catalogoReservasFiltrosWeb': catalogoReservasFiltrosWeb.toJson(),
      'consultaVendasFiltrosWeb': consultaVendasFiltrosWeb.toJson(),
      'consultaVendasFiltrosMobile': consultaVendasFiltrosMobile.toJson(),
      'atendimentosCriadosFiltrosWeb': atendimentosCriadosFiltrosWeb.toJson(),
      'atendimentosCriadosFiltrosMobile':
          atendimentosCriadosFiltrosMobile.toJson(),
      'servicosEmAndamentoFiltrosMobile':
          servicosEmAndamentoFiltrosMobile.toJson(),
      'desempenhoInicioFiltrosWeb': desempenhoInicioFiltrosWeb,
      'desempenhoInicioFiltrosMobile': desempenhoInicioFiltrosMobile,
      'ordemCardsGestaoMobile': ordemCardsGestaoMobile
          .map((GestaoMobileCardPreferencia item) => item.codigo)
          .toList(growable: false),
      'ordemCardsAtendimentoMobile': ordemCardsAtendimentoMobile
          .map((AtendimentoMobileCardPreferencia item) => item.codigo)
          .toList(growable: false),
      'ordemCardsVendasMobile': ordemCardsVendasMobile
          .map((VendasMobileCardPreferencia item) => item.codigo)
          .toList(growable: false),
      'ordemCardsServicosMobile': ordemCardsServicosMobile
          .map((ServicosMobileCardPreferencia item) => item.codigo)
          .toList(growable: false),
      'ordemCardsReceberMobile': ordemCardsReceberMobile
          .map((ReceberMobileCardPreferencia item) => item.codigo)
          .toList(growable: false),
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
    AgendaFinanceiraFiltrosPreferencia? agendaFinanceiraFiltrosWeb,
    AgendaFinanceiraFiltrosPreferencia? agendaFinanceiraFiltrosMobile,
    EstoqueFiltrosPreferencia? estoqueFiltrosWeb,
    EstoqueFiltrosPreferencia? estoqueFiltrosMobile,
    CatalogoReservasFiltrosWebPreferencia? catalogoReservasFiltrosWeb,
    ConsultaVendasFiltrosWebPreferencia? consultaVendasFiltrosWeb,
    ConsultaVendasFiltrosWebPreferencia? consultaVendasFiltrosMobile,
    AtendimentosCriadosFiltrosWebPreferencia? atendimentosCriadosFiltrosWeb,
    AtendimentosCriadosFiltrosMobilePreferencia?
    atendimentosCriadosFiltrosMobile,
    AtendimentosCriadosFiltrosMobilePreferencia?
    servicosEmAndamentoFiltrosMobile,
    Map<String, dynamic>? desempenhoInicioFiltrosWeb,
    Map<String, dynamic>? desempenhoInicioFiltrosMobile,
    List<GestaoMobileCardPreferencia>? ordemCardsGestaoMobile,
    List<AtendimentoMobileCardPreferencia>? ordemCardsAtendimentoMobile,
    List<VendasMobileCardPreferencia>? ordemCardsVendasMobile,
    List<ServicosMobileCardPreferencia>? ordemCardsServicosMobile,
    List<ReceberMobileCardPreferencia>? ordemCardsReceberMobile,
  }) {
    final bool atualizouFiltrosAgendaWebLegados =
        agendaFinanceiraPeriodoWeb != null ||
        agendaFinanceiraTipoWeb != null ||
        agendaFinanceiraStatusWeb != null ||
        agendaFinanceiraTipoDePagamentoWeb != null;
    final AgendaFinanceiraFiltrosPreferencia filtrosAgendaWebAtualizados =
        agendaFinanceiraFiltrosWeb ??
        (atualizouFiltrosAgendaWebLegados
            ? this.agendaFinanceiraFiltrosWeb.copyWith(
              periodo: agendaFinanceiraPeriodoWeb,
              tipo: agendaFinanceiraTipoWeb,
              status: agendaFinanceiraStatusWeb,
              tiposDePagamento: agendaFinanceiraTipoDePagamentoWeb,
            )
            : this.agendaFinanceiraFiltrosWeb);
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
      agendaFinanceiraFiltrosWeb: filtrosAgendaWebAtualizados,
      agendaFinanceiraFiltrosMobile:
          agendaFinanceiraFiltrosMobile ?? this.agendaFinanceiraFiltrosMobile,
      estoqueFiltrosWeb: estoqueFiltrosWeb ?? this.estoqueFiltrosWeb,
      estoqueFiltrosMobile: estoqueFiltrosMobile ?? this.estoqueFiltrosMobile,
      catalogoReservasFiltrosWeb:
          catalogoReservasFiltrosWeb ?? this.catalogoReservasFiltrosWeb,
      consultaVendasFiltrosWeb:
          consultaVendasFiltrosWeb ?? this.consultaVendasFiltrosWeb,
      consultaVendasFiltrosMobile:
          consultaVendasFiltrosMobile ?? this.consultaVendasFiltrosMobile,
      atendimentosCriadosFiltrosWeb:
          atendimentosCriadosFiltrosWeb ?? this.atendimentosCriadosFiltrosWeb,
      atendimentosCriadosFiltrosMobile:
          atendimentosCriadosFiltrosMobile ??
          this.atendimentosCriadosFiltrosMobile,
      servicosEmAndamentoFiltrosMobile:
          servicosEmAndamentoFiltrosMobile ??
          this.servicosEmAndamentoFiltrosMobile,
      desempenhoInicioFiltrosWeb:
          desempenhoInicioFiltrosWeb ?? this.desempenhoInicioFiltrosWeb,
      desempenhoInicioFiltrosMobile:
          desempenhoInicioFiltrosMobile ?? this.desempenhoInicioFiltrosMobile,
      ordemCardsGestaoMobile:
          ordemCardsGestaoMobile ?? this.ordemCardsGestaoMobile,
      ordemCardsAtendimentoMobile:
          ordemCardsAtendimentoMobile ?? this.ordemCardsAtendimentoMobile,
      ordemCardsVendasMobile:
          ordemCardsVendasMobile ?? this.ordemCardsVendasMobile,
      ordemCardsServicosMobile:
          ordemCardsServicosMobile ?? this.ordemCardsServicosMobile,
      ordemCardsReceberMobile:
          ordemCardsReceberMobile ?? this.ordemCardsReceberMobile,
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

  static Map<String, dynamic> _normalizarMapa(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic item) =>
            MapEntry<String, dynamic>(key.toString(), item),
      );
    }
    return <String, dynamic>{};
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

enum ConsultaVendasPeriodoWebPreferencia {
  hoje,
  ultimos7Dias,
  ultimos30Dias,
  esteMes,
  mesPassado,
  personalizado,
}

extension ConsultaVendasPeriodoWebPreferenciaApi
    on ConsultaVendasPeriodoWebPreferencia {
  String get codigo {
    switch (this) {
      case ConsultaVendasPeriodoWebPreferencia.hoje:
        return 'HOJE';
      case ConsultaVendasPeriodoWebPreferencia.ultimos7Dias:
        return 'ULTIMOS_7_DIAS';
      case ConsultaVendasPeriodoWebPreferencia.ultimos30Dias:
        return 'ULTIMOS_30_DIAS';
      case ConsultaVendasPeriodoWebPreferencia.esteMes:
        return 'ESTE_MES';
      case ConsultaVendasPeriodoWebPreferencia.mesPassado:
        return 'MES_PASSADO';
      case ConsultaVendasPeriodoWebPreferencia.personalizado:
        return 'PERSONALIZADO';
    }
  }

  static ConsultaVendasPeriodoWebPreferencia? tryFromCodigo(dynamic value) {
    final String codigo = value?.toString().trim().toUpperCase() ?? '';
    switch (codigo) {
      case 'HOJE':
        return ConsultaVendasPeriodoWebPreferencia.hoje;
      case 'ULTIMOS_7_DIAS':
      case 'ÚLTIMOS_7_DIAS':
      case 'ULTIMOS7DIAS':
        return ConsultaVendasPeriodoWebPreferencia.ultimos7Dias;
      case 'ULTIMOS_30_DIAS':
      case 'ÚLTIMOS_30_DIAS':
      case 'ULTIMOS30DIAS':
        return ConsultaVendasPeriodoWebPreferencia.ultimos30Dias;
      case 'ESTE_MES':
      case 'ESTE_MÊS':
        return ConsultaVendasPeriodoWebPreferencia.esteMes;
      case 'MES_PASSADO':
      case 'MÊS_PASSADO':
        return ConsultaVendasPeriodoWebPreferencia.mesPassado;
      case 'PERSONALIZADO':
      case 'INTERVALO_PERSONALIZADO':
        return ConsultaVendasPeriodoWebPreferencia.personalizado;
      default:
        return null;
    }
  }

  static ConsultaVendasPeriodoWebPreferencia fromCodigo(
    dynamic value,
    ConsultaVendasPeriodoWebPreferencia fallback,
  ) {
    return tryFromCodigo(value) ?? fallback;
  }
}

class ConsultaVendasFiltrosWebPreferencia {
  const ConsultaVendasFiltrosWebPreferencia({
    this.busca = '',
    this.periodo = ConsultaVendasPeriodoWebPreferencia.ultimos30Dias,
    this.dataInicio,
    this.dataFim,
    this.statusFinanceiro,
    this.statusDevolucao,
    this.idsVendedores = const <String>[],
    this.valorMinimo = '',
    this.valorMaximo = '',
    this.ordenacao = 'MAIS_RECENTES',
    this.tamanhoPagina = 25,
  });

  static const Set<String> _ordenacoesValidas = <String>{
    'MAIS_RECENTES',
    'MAIS_ANTIGAS',
    'MAIOR_VALOR',
    'MENOR_VALOR',
  };

  static const Set<String> _statusFinanceirosValidos = <String>{
    'QUITADA',
    'PARCIAL',
    'EM_ABERTO',
    'CANCELADA',
  };

  static const Set<String> _statusDevolucaoValidos = <String>{
    'SEM_DEVOLUCAO',
    'PARCIAL',
    'TOTAL',
  };

  final String busca;
  final ConsultaVendasPeriodoWebPreferencia periodo;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? statusFinanceiro;
  final String? statusDevolucao;
  final List<String> idsVendedores;
  final String valorMinimo;
  final String valorMaximo;
  final String ordenacao;
  final int tamanhoPagina;

  factory ConsultaVendasFiltrosWebPreferencia.vazia() {
    return const ConsultaVendasFiltrosWebPreferencia();
  }

  factory ConsultaVendasFiltrosWebPreferencia.fromJson(
    dynamic json, {
    ConsultaVendasPeriodoWebPreferencia periodoPadrao =
        ConsultaVendasPeriodoWebPreferencia.ultimos30Dias,
  }) {
    if (json is! Map<String, dynamic>) {
      return ConsultaVendasFiltrosWebPreferencia(periodo: periodoPadrao);
    }

    return ConsultaVendasFiltrosWebPreferencia(
      busca: json['busca']?.toString().trim() ?? '',
      periodo: ConsultaVendasPeriodoWebPreferenciaApi.fromCodigo(
        json['periodo'],
        periodoPadrao,
      ),
      dataInicio: _dateFromJson(json['dataInicio']),
      dataFim: _dateFromJson(json['dataFim']),
      statusFinanceiro: _validarCodigo(
        json['statusFinanceiro'],
        _statusFinanceirosValidos,
      ),
      statusDevolucao: _validarCodigo(
        json['statusDevolucao'],
        _statusDevolucaoValidos,
      ),
      idsVendedores:
          PreferenciasIndividuaisDoUsuarioModel._normalizarListaDeStrings(
            json['idsVendedores'],
          ),
      valorMinimo: json['valorMinimo']?.toString().trim() ?? '',
      valorMaximo: json['valorMaximo']?.toString().trim() ?? '',
      ordenacao:
          _validarCodigo(json['ordenacao'], _ordenacoesValidas) ??
          'MAIS_RECENTES',
      tamanhoPagina: _intFromJson(json['tamanhoPagina']) ?? 25,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (busca.trim().isNotEmpty) 'busca': busca.trim(),
      if (periodo != ConsultaVendasPeriodoWebPreferencia.ultimos30Dias)
        'periodo': periodo.codigo,
      if (periodo == ConsultaVendasPeriodoWebPreferencia.personalizado &&
          dataInicio != null)
        'dataInicio': _dateToJson(dataInicio!),
      if (periodo == ConsultaVendasPeriodoWebPreferencia.personalizado &&
          dataFim != null)
        'dataFim': _dateToJson(dataFim!),
      if ((statusFinanceiro ?? '').trim().isNotEmpty)
        'statusFinanceiro': statusFinanceiro!.trim(),
      if ((statusDevolucao ?? '').trim().isNotEmpty)
        'statusDevolucao': statusDevolucao!.trim(),
      if (idsVendedores.isNotEmpty) 'idsVendedores': idsVendedores,
      if (valorMinimo.trim().isNotEmpty) 'valorMinimo': valorMinimo.trim(),
      if (valorMaximo.trim().isNotEmpty) 'valorMaximo': valorMaximo.trim(),
      if (ordenacao != 'MAIS_RECENTES') 'ordenacao': ordenacao,
      if (tamanhoPagina != 25) 'tamanhoPagina': tamanhoPagina,
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

  static String? _validarCodigo(dynamic value, Set<String> validos) {
    final String raw = value?.toString().trim().toUpperCase() ?? '';
    if (raw.isEmpty || !validos.contains(raw)) {
      return null;
    }
    return raw;
  }

  static int? _intFromJson(dynamic value) {
    if (value is num) {
      final int parsed = value.toInt();
      return parsed > 0 ? parsed : null;
    }
    return int.tryParse(value?.toString() ?? '');
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
