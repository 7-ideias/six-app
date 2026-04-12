class ProdutoModel {
  final String? id;
  final bool ativo;
  final String codigoDeBarras;
  final String nomeProduto;
  final String tipoProduto;
  final ObjAgrupamento? objAgrupamento;
  final ObjetoServico? objetoServico;
  final String modeloProduto;
  final int estoqueMaximo;
  final int estoqueMinimo;
  final double precoVenda;
  final ObjComissao objComissao;
  final List<ObjEntradaSaidaProduto>? objEntradaSaidaProduto;

  ProdutoModel({
    this.id,
    required this.ativo,
    required this.codigoDeBarras,
    required this.nomeProduto,
    required this.tipoProduto,
    this.objAgrupamento,
    this.objetoServico,
    required this.modeloProduto,
    required this.estoqueMaximo,
    required this.estoqueMinimo,
    required this.precoVenda,
    required this.objComissao,
    this.objEntradaSaidaProduto,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      id: json['id'],
      ativo: json['ativo'] ?? true,
      codigoDeBarras: json['codigoDeBarras'] ?? '',
      nomeProduto: json['nomeProduto'] ?? '',
      tipoProduto: json['tipoPoduto'] ?? 'PRODUTO', // Note o 'tipoPoduto' do curl
      objAgrupamento: json['objAgrupamento'] != null
          ? ObjAgrupamento.fromJson(json['objAgrupamento'])
          : null,
      objetoServico: json['objetoServico'] != null
          ? ObjetoServico.fromJson(json['objetoServico'])
          : null,
      modeloProduto: json['modeloProduto'] ?? 'UNIDADE',
      estoqueMaximo: (json['estoqueMaximo'] ?? 0).toInt(),
      estoqueMinimo: (json['estoqueMinimo'] ?? 0).toInt(),
      precoVenda: (json['precoVenda'] ?? 0.0).toDouble(),
      objComissao: json['objComissao'] = ObjComissao.fromJson(json['objComissao']),
      objEntradaSaidaProduto: json['objEntradaSaidaProduto'] != null
          ? (json['objEntradaSaidaProduto'] as List)
              .map((i) => ObjEntradaSaidaProduto.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ativo': ativo,
      'codigoDeBarras': codigoDeBarras,
      'nomeProduto': nomeProduto,
      'tipoPoduto': tipoProduto, // Note o 'tipoPoduto' do curl
      'objAgrupamento': objAgrupamento?.toJson(),
      'objetoServico': objetoServico?.toJson(),
      'modeloProduto': modeloProduto,
      'estoqueMaximo': estoqueMaximo,
      'estoqueMinimo': estoqueMinimo,
      'precoVenda': precoVenda,
      'objComissao': objComissao.toJson(),
      'objEntradaSaidaProduto':
          objEntradaSaidaProduto?.map((e) => e.toJson()).toList(),
    };
  }
}

class ProdutoResponseModel {
  final int skusTotaisNoEstoque;
  final double qtNoEstoque;
  final bool erroNoEstoque;
  final double qtSemEstoque;
  final double vlEstoqueEmGrana;
  final List<ProdutoModel> produtosList;

  ProdutoResponseModel({
    required this.skusTotaisNoEstoque,
    required this.qtNoEstoque,
    required this.erroNoEstoque,
    required this.qtSemEstoque,
    required this.vlEstoqueEmGrana,
    required this.produtosList,
  });

  factory ProdutoResponseModel.fromJson(Map<String, dynamic> json) {
    return ProdutoResponseModel(
      skusTotaisNoEstoque: json['skusTotaisNoEstoque'],
      qtNoEstoque: (json['qtNoEstoque'] ?? 0.0).toDouble(),
      erroNoEstoque: (json['erroNoEstoque'] ?? false) as bool,
      qtSemEstoque: (json['qtSemEstoque'] ?? 0.0).toDouble(),
      vlEstoqueEmGrana: (json['vlEstoqueEmGrana'] ?? 0.0).toDouble(),
      produtosList: json['produtosList'] != null
          ? (json['produtosList'] as List)
              .map((i) => ProdutoModel.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skusTotaisNoEstoque': skusTotaisNoEstoque,
      'qtNoEstoque': qtNoEstoque,
      'erroNoEstoque': erroNoEstoque,
      'qtSemEstoque': qtSemEstoque,
      'vlEstoqueEmGrana': vlEstoqueEmGrana,
      'produtosList': produtosList.map((e) => e.toJson()).toList(),
    };
  }
}

class ObjAgrupamento {
  final String grupoDoProduto;

  ObjAgrupamento({required this.grupoDoProduto});

  factory ObjAgrupamento.fromJson(Map<String, dynamic> json) {
    return ObjAgrupamento(
      grupoDoProduto: json['grupoDoProduto'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'grupoDoProduto': grupoDoProduto};
}

class ObjetoServico {
  final String tempoDaGarantia;
  final bool podeAlterarOValorNaHora;

  ObjetoServico({
    required this.tempoDaGarantia,
    required this.podeAlterarOValorNaHora,
  });

  factory ObjetoServico.fromJson(Map<String, dynamic> json) {
    return ObjetoServico(
      tempoDaGarantia: json['tempoDaGarantia'] ?? '',
      podeAlterarOValorNaHora: json['podeAlterarOValorNaHora'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'tempoDaGarantia': tempoDaGarantia,
        'podeAlterarOValorNaHora': podeAlterarOValorNaHora,
      };
}

class ObjComissao {
  final bool produtoTemComissaoEspecial;
  final double valorFixoDeComissaoParaEsseProduto;

  ObjComissao({
    required this.produtoTemComissaoEspecial,
    required this.valorFixoDeComissaoParaEsseProduto,
  });

  factory ObjComissao.fromJson(Map<String, dynamic> json) {
    return ObjComissao(
      produtoTemComissaoEspecial: json['produtoTemComissaoEspecial'] ?? false,
      valorFixoDeComissaoParaEsseProduto:
          (json['valorFixoDeComissaoParaEsseProduto'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'produtoTemComissaoEspecial': produtoTemComissaoEspecial,
        'valorFixoDeComissaoParaEsseProduto': valorFixoDeComissaoParaEsseProduto,
      };
}

class ObjEntradaSaidaProduto {
  final double quantidade;
  final double valorCusto;
  final double valorDaVenda;

  ObjEntradaSaidaProduto({
    required this.quantidade,
    required this.valorCusto,
    required this.valorDaVenda,
  });

  factory ObjEntradaSaidaProduto.fromJson(Map<String, dynamic> json) {
    return ObjEntradaSaidaProduto(
      quantidade: (json['quantidade'] ?? 0.0).toDouble(),
      valorCusto: (json['valorCusto'] ?? 0.0).toDouble(),
      valorDaVenda: (json['valorDaVenda'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'quantidade': quantidade,
        'valorCusto': valorCusto,
        'valorDaVenda': valorDaVenda,
      };
}
