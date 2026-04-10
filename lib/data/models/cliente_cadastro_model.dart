class ClienteCadastroRequest {
  const ClienteCadastroRequest({
    required this.objInformacoesCadastro,
    required this.objPessoa,
    required this.objEndereco,
    required this.objPreferenciasContato,
    required this.objIdentidadeGlobal,
    required this.objFinanceiro,
    required this.objPermissoes,
    required this.objFotoRegistro,
  });

  final ClienteInformacoesCadastro objInformacoesCadastro;
  final ClientePessoa objPessoa;
  final ClienteEndereco objEndereco;
  final ClientePreferenciasContato objPreferenciasContato;
  final ClienteIdentidadeGlobal objIdentidadeGlobal;
  final ClienteFinanceiro objFinanceiro;
  final ClientePermissoes objPermissoes;
  final ClienteFotoRegistro objFotoRegistro;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'objInformacoesCadastro': objInformacoesCadastro.toJson(),
      'objPessoa': objPessoa.toJson(),
      'objEndereco': objEndereco.toJson(),
      'objPreferenciasContato': objPreferenciasContato.toJson(),
      'objIdentidadeGlobal': objIdentidadeGlobal.toJson(),
      'objFinanceiro': objFinanceiro.toJson(),
      'objPermissoes': objPermissoes.toJson(),
      'objFotoRegistro': objFotoRegistro.toJson(),
    };
  }
}

class ClienteAtualizacaoRequest {
  const ClienteAtualizacaoRequest({
    required this.idCliente,
    required this.objInformacoesCadastro,
    required this.objPessoa,
    required this.objEndereco,
    required this.objPreferenciasContato,
    required this.objIdentidadeGlobal,
    required this.objFinanceiro,
    required this.objPermissoes,
    required this.objFotoRegistro,
  });

  final String idCliente;
  final ClienteInformacoesCadastro objInformacoesCadastro;
  final ClientePessoa objPessoa;
  final ClienteEndereco objEndereco;
  final ClientePreferenciasContato objPreferenciasContato;
  final ClienteIdentidadeGlobal objIdentidadeGlobal;
  final ClienteFinanceiro objFinanceiro;
  final ClientePermissoes objPermissoes;
  final ClienteFotoRegistro objFotoRegistro;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'idCliente': idCliente,
      'objInformacoesCadastro': objInformacoesCadastro.toJson(),
      'objPessoa': objPessoa.toJson(),
      'objEndereco': objEndereco.toJson(),
      'objPreferenciasContato': objPreferenciasContato.toJson(),
      'objIdentidadeGlobal': objIdentidadeGlobal.toJson(),
      'objFinanceiro': objFinanceiro.toJson(),
      'objPermissoes': objPermissoes.toJson(),
      'objFotoRegistro': objFotoRegistro.toJson(),
    };
  }
}

class ClienteInformacoesCadastro {
  const ClienteInformacoesCadastro({
    required this.idClienteExterno,
    required this.dataCadastro,
    required this.idiomaPreferido,
    required this.fusoHorario,
    required this.status,
  });

  final String idClienteExterno;
  final String dataCadastro;
  final String idiomaPreferido;
  final String fusoHorario;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'idClienteExterno': idClienteExterno,
      'dataCadastro': dataCadastro,
      'idiomaPreferido': idiomaPreferido,
      'fusoHorario': fusoHorario,
      'status': status,
    };
  }
}

class ClientePessoa {
  const ClientePessoa({
    required this.nome,
    required this.nomeSocial,
    required this.email,
    required this.telefone,
    required this.documento,
    required this.dataNascimento,
    required this.observacoes,
  });

  final String nome;
  final String nomeSocial;
  final String email;
  final String telefone;
  final String documento;
  final String dataNascimento;
  final String observacoes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nome': nome,
      'nomeSocial': nomeSocial,
      'email': email,
      'telefone': telefone,
      'documento': documento,
      'dataNascimento': dataNascimento,
      'observacoes': observacoes,
    };
  }
}

class ClienteEndereco {
  const ClienteEndereco({
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
    required this.pais,
  });

  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final String pais;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'pais': pais,
    };
  }
}

class ClientePreferenciasContato {
  const ClientePreferenciasContato({
    required this.autorizaContato,
    required this.canalPreferido,
    required this.aceitaWhatsapp,
    required this.aceitaEmail,
    required this.aceitaSms,
  });

  final bool autorizaContato;
  final String canalPreferido;
  final bool aceitaWhatsapp;
  final bool aceitaEmail;
  final bool aceitaSms;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'autorizaContato': autorizaContato,
      'canalPreferido': canalPreferido,
      'aceitaWhatsapp': aceitaWhatsapp,
      'aceitaEmail': aceitaEmail,
      'aceitaSms': aceitaSms,
    };
  }
}

class ClienteIdentidadeGlobal {
  const ClienteIdentidadeGlobal({
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.paisDocumento,
    required this.nacionalidade,
  });

  final String tipoDocumento;
  final String numeroDocumento;
  final String paisDocumento;
  final String nacionalidade;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'paisDocumento': paisDocumento,
      'nacionalidade': nacionalidade,
    };
  }
}

class ClienteFinanceiro {
  const ClienteFinanceiro({
    required this.moedaPreferencial,
    required this.limiteCredito,
    required this.diaFechamentoFatura,
    required this.metodoPagamentoPreferencial,
    required this.iban,
    required this.swift,
    required this.chavePix,
    required this.incluirNaAgendaFinanceira,
  });

  final String moedaPreferencial;
  final double limiteCredito;
  final int diaFechamentoFatura;
  final String metodoPagamentoPreferencial;
  final String iban;
  final String swift;
  final String chavePix;
  final bool incluirNaAgendaFinanceira;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'moedaPreferencial': moedaPreferencial,
      'limiteCredito': limiteCredito,
      'diaFechamentoFatura': diaFechamentoFatura,
      'metodoPagamentoPreferencial': metodoPagamentoPreferencial,
      'iban': iban,
      'swift': swift,
      'chavePix': chavePix,
      'incluirNaAgendaFinanceira': incluirNaAgendaFinanceira,
    };
  }
}

class ClientePermissoes {
  const ClientePermissoes({
    required this.podeReceberComunicados,
    required this.podeCompartilharDadosComFinanceiro,
    required this.podeCompartilharDadosComTecnico,
    required this.consentimentoLgpd,
  });

  final bool podeReceberComunicados;
  final bool podeCompartilharDadosComFinanceiro;
  final bool podeCompartilharDadosComTecnico;
  final bool consentimentoLgpd;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'podeReceberComunicados': podeReceberComunicados,
      'podeCompartilharDadosComFinanceiro': podeCompartilharDadosComFinanceiro,
      'podeCompartilharDadosComTecnico': podeCompartilharDadosComTecnico,
      'consentimentoLgpd': consentimentoLgpd,
    };
  }
}

class ClienteFotoRegistro {
  const ClienteFotoRegistro({
    required this.urlFoto,
    required this.modoCaptura,
    required this.dataCaptura,
    required this.hashArquivo,
    required this.consentimentoUsoImagem,
  });

  final String urlFoto;
  final String modoCaptura;
  final String dataCaptura;
  final String hashArquivo;
  final bool consentimentoUsoImagem;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'urlFoto': urlFoto,
      'modoCaptura': modoCaptura,
      'dataCaptura': dataCaptura,
      'hashArquivo': hashArquivo,
      'consentimentoUsoImagem': consentimentoUsoImagem,
    };
  }
}
