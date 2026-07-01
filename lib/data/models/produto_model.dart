import 'produto_imagem_model.dart';

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
  final List<ProdutoImagemModel>? imagens;

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
    this.imagens,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    final dynamic objetoServicoJson = json['objetoServico'] ?? json['objServico'];

    return ProdutoModel(
      id: json['id']?.toString(),
      ativo: json['ativo'] ?? true,
      codigoDeBarras: json['codigoDeBarras'] ?? '',
      nomeProduto: json['nomeProduto'] ?? '',
      tipoProduto: json['tipoPoduto'] ?? 'PRODUTO', // Note o 'tipoPoduto' do curl
      objAgrupamento: json['objAgrupamento'] != null
          ? ObjAgrupamento.fromJson(Map<String, dynamic>.from(json['objAgrupamento']))
          : null,
      objetoServico: objetoServicoJson != null
          ? ObjetoServico.fromJson(Map<String, dynamic>.from(objetoServicoJson))
          : null,
      modeloProduto: json['modeloProduto'] ?? 'UNIDADE',
      estoqueMaximo: (json['estoqueMaximo'] ?? 0).toInt(),
      estoqueMinimo: (json['estoqueMinimo'] ?? 0).toInt(),
      precoVenda: (json['precoVenda'] ?? 0.0).toDouble(),
      objComissao: json['objComissao'] != null
          ? ObjComissao.fromJson(Map<String, dynamic>.from(json['objComissao']))
          : ObjComissao(
              produtoTemComissaoEspecial: false,
              valorFixoDeComissaoParaEsseProduto: 0,
            ),
      objEntradaSaidaProduto: json['objEntradaSaidaProduto'] != null
          ? (json['objEntradaSaidaProduto'] as List)
              .where((i) => i is Map)
              .map((i) => ObjEntradaSaidaProduto.fromJson(Map<String, dynamic>.from(i as Map)))
              .toList()
          : null,
      imagens: _imagensFromJson(json),
    );
  }

  static List<ProdutoImagemModel>? _imagensFromJson(Map<String, dynamic> json) {
    final dynamic imagensJson = json['imagens'];
    if (imagensJson is List && imagensJson.isNotEmpty) {
      return imagensJson
          .where((item) => item is Map)
          .map(
            (item) => ProdutoImagemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
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
          final bool isUrl = value.startsWith('http://') ||
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
      'imagens': imagens?.take(5).map((e) => e.toJson()).toList(),
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
              .map((i) => ProdutoModel.fromJson(Map<String, dynamic>.from(i)))
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
