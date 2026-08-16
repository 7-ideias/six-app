import 'produto_imagem_model.dart';

class ProdutoModel {
  final String? id;
  final bool ativo;
  final bool favorito;
  final bool disponivelParaCatalogo;
  final String codigoDeBarras;
  final String nomeProduto;
  final String tipoProduto;
  final ObjCategoria? objCategoria;
  final ObjAgrupamento? objAgrupamento;
  final ObjetoServico? objetoServico;
  final String modeloProduto;
  final int estoqueMaximo;
  final int estoqueMinimo;
  final double precoVenda;
  final ObjComissao objComissao;
  final List<ObjEntradaSaidaProduto>? objEntradaSaidaProduto;
  final List<ProdutoImagemModel>? imagens;

  ProdutoModel({
    this.id,
    required this.ativo,
    this.favorito = false,
    this.disponivelParaCatalogo = false,
    required this.codigoDeBarras,
    required this.nomeProduto,
    required this.tipoProduto,
    this.objCategoria,
    this.objAgrupamento,
    this.objetoServico,
    required this.modeloProduto,
    required this.estoqueMaximo,
    required this.estoqueMinimo,
    required this.precoVenda,
    required this.objComissao,
    this.objEntradaSaidaProduto,
    this.imagens,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    final dynamic objetoServicoJson =
        json['objetoServico'] ?? json['objServico'];

    return ProdutoModel(
      id: json['id']?.toString(),
      ativo: json['ativo'] ?? true,
      favorito: json['favorito'] == true,
      disponivelParaCatalogo: json['disponivelParaCatalogo'] == true,
      codigoDeBarras: json['codigoDeBarras'] ?? '',
      nomeProduto: json['nomeProduto'] ?? '',
      tipoProduto:
          json['tipoPoduto'] ?? 'PRODUTO', // Note o 'tipoPoduto' do curl
      objCategoria:
          json['objCategoria'] != null
              ? ObjCategoria.fromJson(
                Map<String, dynamic>.from(json['objCategoria']),
              )
              : null,
      objAgrupamento:
          json['objAgrupamento'] != null
              ? ObjAgrupamento.fromJson(
                Map<String, dynamic>.from(json['objAgrupamento']),
              )
              : null,
      objetoServico:
          objetoServicoJson != null
              ? ObjetoServico.fromJson(
                Map<String, dynamic>.from(objetoServicoJson),
              )
              : null,
      modeloProduto: json['modeloProduto'] ?? 'UNIDADE',
      estoqueMaximo: (json['estoqueMaximo'] ?? 0).toInt(),
      estoqueMinimo: (json['estoqueMinimo'] ?? 0).toInt(),
      precoVenda: (json['precoVenda'] ?? 0.0).toDouble(),
      objComissao:
          json['objComissao'] != null
              ? ObjComissao.fromJson(
                Map<String, dynamic>.from(json['objComissao']),
              )
              : ObjComissao(
                produtoTemComissaoEspecial: false,
                valorFixoDeComissaoParaEsseProduto: 0,
              ),
      objEntradaSaidaProduto:
          json['objEntradaSaidaProduto'] != null
              ? (json['objEntradaSaidaProduto'] as List)
                  .whereType<Map>()
                  .map(
                    (Map i) => ObjEntradaSaidaProduto.fromJson(
                      Map<String, dynamic>.from(i),
                    ),
                  )
                  .toList()
              : null,
      imagens: _imagensFromJson(json),
    );
  }

  static List<ProdutoImagemModel>? _imagensFromJson(Map<String, dynamic> json) {
    final dynamic imagensJson = json['imagens'];
    if (imagensJson is List && imagensJson.isNotEmpty) {
      return imagensJson
          .whereType<Map>()
          .map(
            (Map item) =>
                ProdutoImagemModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    final dynamic fotoProdutoListJson = json['fotoProdutoList'];
    if (fotoProdutoListJson is! List || fotoProdutoListJson.isEmpty) {
      return imagensJson is List ? <ProdutoImagemModel>[] : null;
    }

    return fotoProdutoListJson
        .map((item) => item?.toString().trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .take(5)
        .map((value) {
          final bool isUrl =
              value.startsWith('http://') ||
              value.startsWith('https://') ||
              value.startsWith('data:image');

          return ProdutoImagemModel.fromJson({
            'origem': 'LEGADO',
            'nomeArquivo': 'Imagem do produto',
            if (isUrl) 'url': value,
            if (!isUrl) 'imagemBase64': value,
          });
        })
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ativo': ativo,
      'favorito': favorito,
      'disponivelParaCatalogo': disponivelParaCatalogo,
      'codigoDeBarras': codigoDeBarras,
      'nomeProduto': nomeProduto,
      'tipoPoduto': tipoProduto, // Note o 'tipoPoduto' do curl
      'objCategoria': objCategoria?.toJson(),
      'objAgrupamento': objAgrupamento?.toJson(),
      'objetoServico': objetoServico?.toJson(),
      'modeloProduto': modeloProduto,
      'estoqueMaximo': estoqueMaximo,
      'estoqueMinimo': estoqueMinimo,
      'precoVenda': precoVenda,
      'objComissao': objComissao.toJson(),
      'objEntradaSaidaProduto':
          objEntradaSaidaProduto?.map((e) => e.toJson()).toList(),
      'imagens': imagens?.take(5).map((e) => e.toJson()).toList(),
    };
  }

  ProdutoModel copyWith({
    String? id,
    bool? ativo,
    bool? favorito,
    bool? disponivelParaCatalogo,
    String? codigoDeBarras,
    String? nomeProduto,
    String? tipoProduto,
    ObjCategoria? objCategoria,
    ObjAgrupamento? objAgrupamento,
    ObjetoServico? objetoServico,
    String? modeloProduto,
    int? estoqueMaximo,
    int? estoqueMinimo,
    double? precoVenda,
    ObjComissao? objComissao,
    List<ObjEntradaSaidaProduto>? objEntradaSaidaProduto,
    List<ProdutoImagemModel>? imagens,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      ativo: ativo ?? this.ativo,
      favorito: favorito ?? this.favorito,
      disponivelParaCatalogo:
          disponivelParaCatalogo ?? this.disponivelParaCatalogo,
      codigoDeBarras: codigoDeBarras ?? this.codigoDeBarras,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      tipoProduto: tipoProduto ?? this.tipoProduto,
      objCategoria: objCategoria ?? this.objCategoria,
      objAgrupamento: objAgrupamento ?? this.objAgrupamento,
      objetoServico: objetoServico ?? this.objetoServico,
      modeloProduto: modeloProduto ?? this.modeloProduto,
      estoqueMaximo: estoqueMaximo ?? this.estoqueMaximo,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      precoVenda: precoVenda ?? this.precoVenda,
      objComissao: objComissao ?? this.objComissao,
      objEntradaSaidaProduto:
          objEntradaSaidaProduto ?? this.objEntradaSaidaProduto,
      imagens: imagens ?? this.imagens,
    );
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
      produtosList:
          json['produtosList'] != null
              ? (json['produtosList'] as List)
                  .map(
                    (i) => ProdutoModel.fromJson(Map<String, dynamic>.from(i)),
                  )
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

class ObjCategoria {
  final String idCategoria;
  final String nomeCategoria;

  ObjCategoria({required this.idCategoria, required this.nomeCategoria});

  factory ObjCategoria.fromJson(Map<String, dynamic> json) {
    return ObjCategoria(
      idCategoria: json['idCategoria']?.toString() ?? '',
      nomeCategoria: json['nomeCategoria']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'idCategoria': idCategoria,
    'nomeCategoria': nomeCategoria,
  };
}

class ObjAgrupamento {
  final String grupoDoProduto;

  ObjAgrupamento({required this.grupoDoProduto});

  factory ObjAgrupamento.fromJson(Map<String, dynamic> json) {
    return ObjAgrupamento(grupoDoProduto: json['grupoDoProduto'] ?? '');
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
