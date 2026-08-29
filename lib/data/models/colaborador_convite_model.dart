class ColaboradorConviteRequest {
  const ColaboradorConviteRequest({
    required this.nome,
    required this.email,
    required this.celular,
    required this.permissoes,
    this.tipoCadastro = 'SIMPLES',
    this.percentualQualidadeCadastro = 0,
    this.dadosPessoais,
    this.dadosContratuais,
  });

  final String nome;
  final String email;
  final String celular;
  final List<String> permissoes;
  final String tipoCadastro;
  final int percentualQualidadeCadastro;
  final ColaboradorDadosPessoaisCadastro? dadosPessoais;
  final ColaboradorDadosContratuaisCadastro? dadosContratuais;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nome': nome,
      'email': email,
      'celular': celular,
      'permissoes': permissoes,
      'tipoCadastro': tipoCadastro,
      'percentualQualidadeCadastro': percentualQualidadeCadastro,
      'dadosPessoais': dadosPessoais?.toJson(),
      'dadosContratuais': dadosContratuais?.toJson(),
    }..removeWhere((String _, dynamic value) => value == null);
  }
}

class ColaboradorDadosPessoaisCadastro {
  const ColaboradorDadosPessoaisCadastro({
    this.nomeSocial = '',
    this.cpf = '',
    this.rg = '',
    this.dataNascimento = '',
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.pais = '',
  });

  final String nomeSocial;
  final String cpf;
  final String rg;
  final String dataNascimento;
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String pais;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nomeSocial': nomeSocial,
    'cpf': cpf,
    'rg': rg,
    'dataNascimento': dataNascimento,
    'cep': cep,
    'logradouro': logradouro,
    'numero': numero,
    'complemento': complemento,
    'bairro': bairro,
    'cidade': cidade,
    'estado': estado,
    'pais': pais,
  };
}

class ColaboradorDadosContratuaisCadastro {
  const ColaboradorDadosContratuaisCadastro({
    this.tipoVinculo = '',
    this.numeroContrato = '',
    this.cargo = '',
    this.departamento = '',
    this.dataInicio = '',
    this.dataTermino = '',
    this.cargaHorariaSemanal,
    this.regimeTrabalho = '',
    this.valorBase,
    this.moeda = '',
    this.periodicidadePagamento = '',
    this.diaPagamento,
    this.metodoPagamento = '',
    this.banco = '',
    this.agencia = '',
    this.conta = '',
    this.chavePix = '',
    this.escopoPrestacaoServico = '',
    this.observacoes = '',
  });

  final String tipoVinculo;
  final String numeroContrato;
  final String cargo;
  final String departamento;
  final String dataInicio;
  final String dataTermino;
  final int? cargaHorariaSemanal;
  final String regimeTrabalho;
  final double? valorBase;
  final String moeda;
  final String periodicidadePagamento;
  final int? diaPagamento;
  final String metodoPagamento;
  final String banco;
  final String agencia;
  final String conta;
  final String chavePix;
  final String escopoPrestacaoServico;
  final String observacoes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'tipoVinculo': tipoVinculo,
    'numeroContrato': numeroContrato,
    'cargo': cargo,
    'departamento': departamento,
    'dataInicio': dataInicio,
    'dataTermino': dataTermino,
    'cargaHorariaSemanal': cargaHorariaSemanal,
    'regimeTrabalho': regimeTrabalho,
    'valorBase': valorBase,
    'moeda': moeda,
    'periodicidadePagamento': periodicidadePagamento,
    'diaPagamento': diaPagamento,
    'metodoPagamento': metodoPagamento,
    'banco': banco,
    'agencia': agencia,
    'conta': conta,
    'chavePix': chavePix,
    'escopoPrestacaoServico': escopoPrestacaoServico,
    'observacoes': observacoes,
  }..removeWhere((String _, dynamic value) => value == null);
}

class ColaboradorConviteResponse {
  const ColaboradorConviteResponse({
    required this.id,
    required this.emailConvidado,
    required this.nomeConvidado,
    required this.idUnicoDaEmpresa,
    required this.nomeFantasia,
    required this.papel,
    required this.status,
    required this.permissoes,
    required this.codigo,
    required this.expiraEm,
  });

  final String id;
  final String emailConvidado;
  final String nomeConvidado;
  final String idUnicoDaEmpresa;
  final String nomeFantasia;
  final String papel;
  final String status;
  final List<String> permissoes;
  final String codigo;
  final DateTime? expiraEm;

  factory ColaboradorConviteResponse.fromJson(Map<String, dynamic> json) {
    return ColaboradorConviteResponse(
      id: json['id']?.toString() ?? '',
      emailConvidado: json['emailConvidado']?.toString() ?? '',
      nomeConvidado: json['nomeConvidado']?.toString() ?? '',
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      nomeFantasia: json['nomeFantasia']?.toString() ?? '',
      papel: json['papel']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      permissoes: (json['permissoes'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      codigo: json['token']?.toString() ?? '',
      expiraEm: DateTime.tryParse(json['expiraEm']?.toString() ?? ''),
    );
  }
}

class ColaboradorConvitePublicoResponse {
  const ColaboradorConvitePublicoResponse({
    required this.emailConvidado,
    required this.nomeConvidado,
    required this.idUnicoDaEmpresa,
    required this.nomeFantasia,
    required this.status,
    required this.expiraEm,
  });

  final String emailConvidado;
  final String nomeConvidado;
  final String idUnicoDaEmpresa;
  final String nomeFantasia;
  final String status;
  final DateTime? expiraEm;

  factory ColaboradorConvitePublicoResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ColaboradorConvitePublicoResponse(
      emailConvidado: json['emailConvidado']?.toString() ?? '',
      nomeConvidado: json['nomeConvidado']?.toString() ?? '',
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      nomeFantasia: json['nomeFantasia']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      expiraEm: DateTime.tryParse(json['expiraEm']?.toString() ?? ''),
    );
  }
}

class EmpresaVinculoWebModel {
  const EmpresaVinculoWebModel({
    required this.idUnicoDaEmpresa,
    required this.nomeFantasia,
    required this.papel,
    required this.status,
    required this.permissoes,
  });

  final String idUnicoDaEmpresa;
  final String nomeFantasia;
  final String papel;
  final String status;
  final List<String> permissoes;

  factory EmpresaVinculoWebModel.fromJson(Map<String, dynamic> json) {
    return EmpresaVinculoWebModel(
      idUnicoDaEmpresa: json['idUnicoDaEmpresa']?.toString() ?? '',
      nomeFantasia: json['nomeFantasia']?.toString() ?? '',
      papel: json['papel']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      permissoes: (json['permissoes'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
    );
  }

  bool get ativo => status.toUpperCase() == 'ATIVO';
  bool get administrador => papel.toUpperCase() == 'ADMINISTRADOR';

  bool pode(String permissao) {
    if (!ativo) {
      return false;
    }
    if (administrador || permissoes.contains('TODAS')) {
      return true;
    }
    return permissoes.contains(permissao);
  }
}
