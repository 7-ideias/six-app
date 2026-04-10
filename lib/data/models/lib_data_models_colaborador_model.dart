class ColaboradorCadastroRequest {
  const ColaboradorCadastroRequest({
    required this.foto,
    required this.celularDeAcesso,
    required this.senhaParaPermitirOAcessoDoColaborador,
    required this.objInformacoesDoCadastro,
    required this.objDadosFuncionais,
    required this.objPessoa,
    required this.objAutorizacoes,
    required this.objIdentidadeGlobal,
    required this.objFotoRegistro,
    required this.objDadosPagamento,
    required this.objPermissoesAplicacao,
  });

  final String foto;
  final String celularDeAcesso;
  final String senhaParaPermitirOAcessoDoColaborador;
  final ColaboradorInformacoesCadastro objInformacoesDoCadastro;
  final ColaboradorDadosFuncionais objDadosFuncionais;
  final ColaboradorPessoa objPessoa;
  final ColaboradorAutorizacoes objAutorizacoes;
  final ColaboradorIdentidadeGlobal objIdentidadeGlobal;
  final ColaboradorFotoRegistro objFotoRegistro;
  final ColaboradorDadosPagamento objDadosPagamento;
  final ColaboradorPermissoesAplicacao objPermissoesAplicacao;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'foto': foto,
      'celularDeAcesso': celularDeAcesso,
      'senhaParaPermitirOAcessoDoColaborador':
          senhaParaPermitirOAcessoDoColaborador,
      'objInformacoesDoCadastro': objInformacoesDoCadastro.toJson(),
      'objDadosFuncionais': objDadosFuncionais.toJson(),
      'objPessoa': objPessoa.toJson(),
      'objAutorizacoes': objAutorizacoes.toJson(),
      'objIdentidadeGlobal': objIdentidadeGlobal.toJson(),
      'objFotoRegistro': objFotoRegistro.toJson(),
      'objDadosPagamento': objDadosPagamento.toJson(),
      'objPermissoesAplicacao': objPermissoesAplicacao.toJson(),
    };
  }
}

class ColaboradorAtualizacaoRequest {
  const ColaboradorAtualizacaoRequest({
    required this.idColaborador,
    required this.objInformacoesDoCadastro,
    required this.objDadosFuncionais,
    required this.objPessoa,
    required this.objAutorizacoes,
    required this.objIdentidadeGlobal,
    required this.objFotoRegistro,
    required this.objDadosPagamento,
    required this.objPermissoesAplicacao,
    this.foto,
    this.celularDeAcesso,
    this.senhaParaPermitirOAcessoDoColaborador,
  });

  final String idColaborador;
  final String? foto;
  final String? celularDeAcesso;
  final String? senhaParaPermitirOAcessoDoColaborador;
  final ColaboradorInformacoesCadastro objInformacoesDoCadastro;
  final ColaboradorDadosFuncionais objDadosFuncionais;
  final ColaboradorPessoa objPessoa;
  final ColaboradorAutorizacoes objAutorizacoes;
  final ColaboradorIdentidadeGlobal objIdentidadeGlobal;
  final ColaboradorFotoRegistro objFotoRegistro;
  final ColaboradorDadosPagamento objDadosPagamento;
  final ColaboradorPermissoesAplicacao objPermissoesAplicacao;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'idColaborador': idColaborador,
      'foto': foto,
      'celularDeAcesso': celularDeAcesso,
      'senhaParaPermitirOAcessoDoColaborador':
          senhaParaPermitirOAcessoDoColaborador,
      'objInformacoesDoCadastro': objInformacoesDoCadastro.toJson(),
      'objDadosFuncionais': objDadosFuncionais.toJson(),
      'objPessoa': objPessoa.toJson(),
      'objAutorizacoes': objAutorizacoes.toJson(),
      'objIdentidadeGlobal': objIdentidadeGlobal.toJson(),
      'objFotoRegistro': objFotoRegistro.toJson(),
      'objDadosPagamento': objDadosPagamento.toJson(),
      'objPermissoesAplicacao': objPermissoesAplicacao.toJson(),
    }..removeWhere((String _, dynamic value) => value == null);
  }
}

class ColaboradorInformacoesCadastro {
  const ColaboradorInformacoesCadastro({
    required this.idUnicoDoUsuario,
    required this.dataCadastro,
    required this.idiomaPreferencial,
    required this.fusoHorario,
    required this.status,
  });

  final String idUnicoDoUsuario;
  final String dataCadastro;
  final String idiomaPreferencial;
  final String fusoHorario;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'idUnicoDoUsuario': idUnicoDoUsuario,
      'dataCadastro': dataCadastro,
      'idiomaPreferencial': idiomaPreferencial,
      'fusoHorario': fusoHorario,
      'status': status,
    };
  }
}

class ColaboradorDadosFuncionais {
  const ColaboradorDadosFuncionais({
    required this.dataDeContratacao,
    required this.salario,
    required this.cargo,
    required this.departamento,
    required this.tipoContrato,
    required this.centroDeCusto,
  });

  final String dataDeContratacao;
  final double salario;
  final String cargo;
  final String departamento;
  final String tipoContrato;
  final String centroDeCusto;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dataDeContratacao': dataDeContratacao,
      'salario': salario,
      'cargo': cargo,
      'departamento': departamento,
      'tipoContrato': tipoContrato,
      'centroDeCusto': centroDeCusto,
    };
  }
}

class ColaboradorPessoa {
  const ColaboradorPessoa({
    required this.atencao,
    required this.nome,
    required this.nomeDeGuerra,
    required this.celular,
    required this.senha,
    required this.cpf,
    required this.rg,
    required this.dataDeNascimento,
    required this.email,
    required this.objEndereco,
  });

  final String atencao;
  final String nome;
  final String nomeDeGuerra;
  final String celular;
  final String senha;
  final String cpf;
  final String rg;
  final String dataDeNascimento;
  final String email;
  final ColaboradorEndereco objEndereco;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'atencao': atencao,
      'nome': nome,
      'nomeDeGuerra': nomeDeGuerra,
      'celular': celular,
      'senha': senha,
      'cpf': cpf,
      'rg': rg,
      'dataDeNascimento': dataDeNascimento,
      'email': email,
      'objEndereco': objEndereco.toJson(),
    };
  }
}

class ColaboradorEndereco {
  const ColaboradorEndereco({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
    required this.pais,
  });

  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;
  final String pais;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cep': cep,
      'logradouro': logradouro,
      'complemento': complemento,
      'bairro': bairro,
      'localidade': localidade,
      'uf': uf,
      'pais': pais,
    };
  }
}

class ColaboradorAutorizacoes {
  const ColaboradorAutorizacoes({
    required this.podeFazerDevolucao,
    required this.podeCadastrarProduto,
    required this.objProdutosPode,
    required this.objVendasPode,
    required this.objAssistenciaTecnicaPode,
    required this.objClientesPode,
    required this.objRelatoriosPode,
    required this.objLancamentosFinanceirosPode,
  });

  final bool podeFazerDevolucao;
  final bool podeCadastrarProduto;
  final ColaboradorProdutosPode objProdutosPode;
  final ColaboradorVendasPode objVendasPode;
  final ColaboradorAssistenciaTecnicaPode objAssistenciaTecnicaPode;
  final ColaboradorClientesPode objClientesPode;
  final ColaboradorRelatoriosPode objRelatoriosPode;
  final ColaboradorLancamentosFinanceirosPode objLancamentosFinanceirosPode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'podeFazerDevolucao': podeFazerDevolucao,
      'podeCadastrarProduto': podeCadastrarProduto,
      'objProdutosPode': objProdutosPode.toJson(),
      'objVendasPode': objVendasPode.toJson(),
      'objAssistenciaTecnicaPode': objAssistenciaTecnicaPode.toJson(),
      'objClientesPode': objClientesPode.toJson(),
      'objRelatoriosPode': objRelatoriosPode.toJson(),
      'objLancamentosFinanceirosPode': objLancamentosFinanceirosPode.toJson(),
    };
  }
}

class ColaboradorProdutosPode {
  const ColaboradorProdutosPode({
    required this.podeVerEstoqueDeProduto,
    required this.podeEditarProduto,
    required this.valorDaComissao,
  });

  final bool podeVerEstoqueDeProduto;
  final bool podeEditarProduto;
  final double valorDaComissao;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'podeVerEstoqueDeProduto': podeVerEstoqueDeProduto,
      'podeEditarProduto': podeEditarProduto,
      'valorDaComissao': valorDaComissao,
    };
  }
}

class ColaboradorVendasPode {
  const ColaboradorVendasPode({
    required this.fazVenda,
    required this.comissaoDeVendas,
  });

  final bool fazVenda;
  final double comissaoDeVendas;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fazVenda': fazVenda,
      'comissaoDeVendas': comissaoDeVendas,
    };
  }
}

class ColaboradorAssistenciaTecnicaPode {
  const ColaboradorAssistenciaTecnicaPode({
    required this.lancaServico,
    required this.ehUmTecnicoEFazAssistenciaTecnica,
    required this.comissaoDeAssistencia,
  });

  final bool lancaServico;
  final bool ehUmTecnicoEFazAssistenciaTecnica;
  final double comissaoDeAssistencia;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lancaServico': lancaServico,
      'ehUmTecnicoEFazAssistenciaTecnica':
          ehUmTecnicoEFazAssistenciaTecnica,
      'comissaoDeAssistencia': comissaoDeAssistencia,
    };
  }
}

class ColaboradorClientesPode {
  const ColaboradorClientesPode({
    required this.podeEditarCliente,
  });

  final bool podeEditarCliente;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'podeEditarCliente': podeEditarCliente,
    };
  }
}

class ColaboradorRelatoriosPode {
  const ColaboradorRelatoriosPode({
    required this.geraRelatorioDeVendas,
  });

  final bool geraRelatorioDeVendas;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'geraRelatorioDeVendas': geraRelatorioDeVendas,
    };
  }
}

class ColaboradorLancamentosFinanceirosPode {
  const ColaboradorLancamentosFinanceirosPode({
    required this.podeReceberNoCaixa,
    required this.podeVerQuantoVendeu,
  });

  final bool podeReceberNoCaixa;
  final bool podeVerQuantoVendeu;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'podeReceberNoCaixa': podeReceberNoCaixa,
      'podeVerQuantoVendeu': podeVerQuantoVendeu,
    };
  }
}

class ColaboradorIdentidadeGlobal {
  const ColaboradorIdentidadeGlobal({
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.paisDoDocumento,
    required this.nacionalidade,
    required this.paisResidencia,
  });

  final String tipoDocumento;
  final String numeroDocumento;
  final String paisDoDocumento;
  final String nacionalidade;
  final String paisResidencia;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'paisDoDocumento': paisDoDocumento,
      'nacionalidade': nacionalidade,
      'paisResidencia': paisResidencia,
    };
  }
}

class ColaboradorFotoRegistro {
  const ColaboradorFotoRegistro({
    required this.modoCaptura,
    required this.urlFoto,
    required this.hashArquivo,
    required this.dataCaptura,
    required this.consentimentoUsoImagem,
  });

  final String modoCaptura;
  final String urlFoto;
  final String hashArquivo;
  final String dataCaptura;
  final bool consentimentoUsoImagem;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'modoCaptura': modoCaptura,
      'urlFoto': urlFoto,
      'hashArquivo': hashArquivo,
      'dataCaptura': dataCaptura,
      'consentimentoUsoImagem': consentimentoUsoImagem,
    };
  }
}

class ColaboradorDadosPagamento {
  const ColaboradorDadosPagamento({
    required this.moeda,
    required this.periodicidadePagamento,
    required this.valorBase,
    required this.metodoPagamentoPreferencial,
    required this.banco,
    required this.agencia,
    required this.conta,
    required this.iban,
    required this.swiftBic,
    required this.chavePix,
    required this.diaDePagamento,
    required this.incluirNaAgendaFinanceira,
  });

  final String moeda;
  final String periodicidadePagamento;
  final double valorBase;
  final String metodoPagamentoPreferencial;
  final String banco;
  final String agencia;
  final String conta;
  final String iban;
  final String swiftBic;
  final String chavePix;
  final int diaDePagamento;
  final bool incluirNaAgendaFinanceira;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'moeda': moeda,
      'periodicidadePagamento': periodicidadePagamento,
      'valorBase': valorBase,
      'metodoPagamentoPreferencial': metodoPagamentoPreferencial,
      'banco': banco,
      'agencia': agencia,
      'conta': conta,
      'iban': iban,
      'swiftBic': swiftBic,
      'chavePix': chavePix,
      'diaDePagamento': diaDePagamento,
      'incluirNaAgendaFinanceira': incluirNaAgendaFinanceira,
    };
  }
}

class ColaboradorPermissoesAplicacao {
  const ColaboradorPermissoesAplicacao({
    required this.podeAcessarAgendaFinanceira,
    required this.podeEditarDadosPagamento,
    required this.podeExportarRelatorios,
    required this.podeGerenciarPermissoes,
    required this.escopoDeDados,
    required this.modulosPermitidos,
  });

  final bool podeAcessarAgendaFinanceira;
  final bool podeEditarDadosPagamento;
  final bool podeExportarRelatorios;
  final bool podeGerenciarPermissoes;
  final String escopoDeDados;
  final List<String> modulosPermitidos;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'podeAcessarAgendaFinanceira': podeAcessarAgendaFinanceira,
      'podeEditarDadosPagamento': podeEditarDadosPagamento,
      'podeExportarRelatorios': podeExportarRelatorios,
      'podeGerenciarPermissoes': podeGerenciarPermissoes,
      'escopoDeDados': escopoDeDados,
      'modulosPermitidos': modulosPermitidos,
    };
  }
}

class ColaboradorCadastroResponse {
  const ColaboradorCadastroResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}
