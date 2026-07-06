class ColaboradorAutorizacoesModel {
  const ColaboradorAutorizacoesModel({
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
  final ObjProdutosPodeAutorizacao objProdutosPode;
  final ObjVendasPodeAutorizacao objVendasPode;
  final ObjAssistenciaTecnicaPodeAutorizacao objAssistenciaTecnicaPode;
  final ObjClientesPodeAutorizacao objClientesPode;
  final ObjRelatoriosPodeAutorizacao objRelatoriosPode;
  final ObjLancamentosFinanceirosPodeAutorizacao objLancamentosFinanceirosPode;

  factory ColaboradorAutorizacoesModel.fromJson(Map<String, dynamic> json) {
    return ColaboradorAutorizacoesModel(
      podeFazerDevolucao: _asBool(json['podeFazerDevolucao']),
      podeCadastrarProduto: _asBool(json['podeCadastrarProduto']),
      objProdutosPode: ObjProdutosPodeAutorizacao.fromJson(
        _asMap(json['objProdutosPode']),
      ),
      objVendasPode: ObjVendasPodeAutorizacao.fromJson(
        _asMap(json['objVendasPode']),
      ),
      objAssistenciaTecnicaPode: ObjAssistenciaTecnicaPodeAutorizacao.fromJson(
        _asMap(json['objAssistenciaTecnicaPode']),
      ),
      objClientesPode: ObjClientesPodeAutorizacao.fromJson(
        _asMap(json['objClientesPode']),
      ),
      objRelatoriosPode: ObjRelatoriosPodeAutorizacao.fromJson(
        _asMap(json['objRelatoriosPode']),
      ),
      objLancamentosFinanceirosPode:
          ObjLancamentosFinanceirosPodeAutorizacao.fromJson(
        _asMap(json['objLancamentosFinanceirosPode']),
      ),
    );
  }

  factory ColaboradorAutorizacoesModel.permitirTudo() {
    return const ColaboradorAutorizacoesModel(
      podeFazerDevolucao: true,
      podeCadastrarProduto: true,
      objProdutosPode: ObjProdutosPodeAutorizacao(
        podeVerEstoqueDeProduto: true,
        podeEditarProduto: true,
      ),
      objVendasPode: ObjVendasPodeAutorizacao(fazVenda: true),
      objAssistenciaTecnicaPode: ObjAssistenciaTecnicaPodeAutorizacao(
        lancaServico: true,
        ehUmTecnicoEFazAssistenciaTecnica: true,
      ),
      objClientesPode: ObjClientesPodeAutorizacao(podeEditarCliente: true),
      objRelatoriosPode: ObjRelatoriosPodeAutorizacao(
        geraRelatorioDeVendas: true,
      ),
      objLancamentosFinanceirosPode: ObjLancamentosFinanceirosPodeAutorizacao(
        podeReceberNoCaixa: true,
        podeVerQuantoVendeu: true,
      ),
    );
  }

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

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic value) => MapEntry<String, dynamic>(
          key.toString(),
          value,
        ),
      );
    }
    return <String, dynamic>{};
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.trim().toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }
}

class ObjProdutosPodeAutorizacao {
  const ObjProdutosPodeAutorizacao({
    required this.podeVerEstoqueDeProduto,
    required this.podeEditarProduto,
  });

  final bool podeVerEstoqueDeProduto;
  final bool podeEditarProduto;

  factory ObjProdutosPodeAutorizacao.fromJson(Map<String, dynamic> json) {
    return ObjProdutosPodeAutorizacao(
      podeVerEstoqueDeProduto:
          ColaboradorAutorizacoesModel._asBool(json['podeVerEstoqueDeProduto']),
      podeEditarProduto:
          ColaboradorAutorizacoesModel._asBool(json['podeEditarProduto']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'podeVerEstoqueDeProduto': podeVerEstoqueDeProduto,
        'podeEditarProduto': podeEditarProduto,
      };
}

class ObjVendasPodeAutorizacao {
  const ObjVendasPodeAutorizacao({required this.fazVenda});

  final bool fazVenda;

  factory ObjVendasPodeAutorizacao.fromJson(Map<String, dynamic> json) {
    return ObjVendasPodeAutorizacao(
      fazVenda: ColaboradorAutorizacoesModel._asBool(json['fazVenda']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'fazVenda': fazVenda};
}

class ObjAssistenciaTecnicaPodeAutorizacao {
  const ObjAssistenciaTecnicaPodeAutorizacao({
    required this.lancaServico,
    required this.ehUmTecnicoEFazAssistenciaTecnica,
  });

  final bool lancaServico;
  final bool ehUmTecnicoEFazAssistenciaTecnica;

  factory ObjAssistenciaTecnicaPodeAutorizacao.fromJson(
    Map<String, dynamic> json,
  ) {
    return ObjAssistenciaTecnicaPodeAutorizacao(
      lancaServico: ColaboradorAutorizacoesModel._asBool(json['lancaServico']),
      ehUmTecnicoEFazAssistenciaTecnica: ColaboradorAutorizacoesModel._asBool(
        json['ehUmTecnicoEFazAssistenciaTecnica'],
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lancaServico': lancaServico,
        'ehUmTecnicoEFazAssistenciaTecnica': ehUmTecnicoEFazAssistenciaTecnica,
      };
}

class ObjClientesPodeAutorizacao {
  const ObjClientesPodeAutorizacao({required this.podeEditarCliente});

  final bool podeEditarCliente;

  factory ObjClientesPodeAutorizacao.fromJson(Map<String, dynamic> json) {
    return ObjClientesPodeAutorizacao(
      podeEditarCliente:
          ColaboradorAutorizacoesModel._asBool(json['podeEditarCliente']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'podeEditarCliente': podeEditarCliente,
      };
}

class ObjRelatoriosPodeAutorizacao {
  const ObjRelatoriosPodeAutorizacao({required this.geraRelatorioDeVendas});

  final bool geraRelatorioDeVendas;

  factory ObjRelatoriosPodeAutorizacao.fromJson(Map<String, dynamic> json) {
    return ObjRelatoriosPodeAutorizacao(
      geraRelatorioDeVendas:
          ColaboradorAutorizacoesModel._asBool(json['geraRelatorioDeVendas']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'geraRelatorioDeVendas': geraRelatorioDeVendas,
      };
}

class ObjLancamentosFinanceirosPodeAutorizacao {
  const ObjLancamentosFinanceirosPodeAutorizacao({
    required this.podeReceberNoCaixa,
    required this.podeVerQuantoVendeu,
  });

  final bool podeReceberNoCaixa;
  final bool podeVerQuantoVendeu;

  factory ObjLancamentosFinanceirosPodeAutorizacao.fromJson(
    Map<String, dynamic> json,
  ) {
    return ObjLancamentosFinanceirosPodeAutorizacao(
      podeReceberNoCaixa:
          ColaboradorAutorizacoesModel._asBool(json['podeReceberNoCaixa']),
      podeVerQuantoVendeu:
          ColaboradorAutorizacoesModel._asBool(json['podeVerQuantoVendeu']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'podeReceberNoCaixa': podeReceberNoCaixa,
        'podeVerQuantoVendeu': podeVerQuantoVendeu,
      };
}
