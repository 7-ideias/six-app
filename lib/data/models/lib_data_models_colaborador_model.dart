class ColaboradorCadastroRequest {
  const ColaboradorCadastroRequest({
    required this.foto,
    required this.celularDeAcesso,
    required this.senhaParaPermitirOAcessoDoColaborador,
    required this.objInformacoesDoCadastro,
    required this.objDadosFuncionais,
    required this.objPessoa,
    required this.objAutorizacoes,
  });

  final String foto;
  final String celularDeAcesso;
  final String senhaParaPermitirOAcessoDoColaborador;
  final ColaboradorInformacoesCadastro objInformacoesDoCadastro;
  final ColaboradorDadosFuncionais objDadosFuncionais;
  final ColaboradorPessoa objPessoa;
  final ColaboradorAutorizacoes objAutorizacoes;

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
    };
  }
}

class ColaboradorInformacoesCadastro {
  const ColaboradorInformacoesCadastro({
    required this.idUnicoDoUsuario,
    required this.dataCadastro,
  });

  final String idUnicoDoUsuario;
  final String dataCadastro;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'idUnicoDoUsuario': idUnicoDoUsuario,
      'dataCadastro': dataCadastro,
    };
  }
}

class ColaboradorDadosFuncionais {
  const ColaboradorDadosFuncionais({
    required this.dataDeContratacao,
    required this.salario,
  });

  final String dataDeContratacao;
  final double salario;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dataDeContratacao': dataDeContratacao,
      'salario': salario,
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
  });

  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cep': cep,
      'logradouro': logradouro,
      'complemento': complemento,
      'bairro': bairro,
      'localidade': localidade,
      'uf': uf,
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

class ColaboradorCadastroResponse {
  const ColaboradorCadastroResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}
