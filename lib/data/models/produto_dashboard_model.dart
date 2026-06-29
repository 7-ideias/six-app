class ProdutoDashboardModel {
  final int totalProdutos;
  final int produtosAtivos;
  final double valorTotalEstoque;
  final double quantidadeTotalEstoque;
  final int produtosEstoqueBaixo;
  final int produtosSemEstoque;
  final int produtosEstoqueNegativo;
  final double margemMediaPercentual;
  final List<ProdutoDashboardSerieItem> produtosPorCategoria;
  final List<ProdutoDashboardSerieItem> valorEstoquePorCategoria;
  final List<ProdutoDashboardSerieItem> situacaoEstoque;
  final List<ProdutoDashboardItem> topProdutosMaiorValorEstoque;
  final List<ProdutoDashboardItem> produtosEstoqueBaixoLista;
  final List<ProdutoDashboardAlerta> alertas;

  const ProdutoDashboardModel({
    required this.totalProdutos,
    required this.produtosAtivos,
    required this.valorTotalEstoque,
    required this.quantidadeTotalEstoque,
    required this.produtosEstoqueBaixo,
    required this.produtosSemEstoque,
    required this.produtosEstoqueNegativo,
    required this.margemMediaPercentual,
    required this.produtosPorCategoria,
    required this.valorEstoquePorCategoria,
    required this.situacaoEstoque,
    required this.topProdutosMaiorValorEstoque,
    required this.produtosEstoqueBaixoLista,
    required this.alertas,
  });

  factory ProdutoDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProdutoDashboardModel(
      totalProdutos: _toInt(json['totalProdutos']),
      produtosAtivos: _toInt(json['produtosAtivos']),
      valorTotalEstoque: _toDouble(json['valorTotalEstoque']),
      quantidadeTotalEstoque: _toDouble(json['quantidadeTotalEstoque']),
      produtosEstoqueBaixo: _toInt(json['produtosEstoqueBaixo']),
      produtosSemEstoque: _toInt(json['produtosSemEstoque']),
      produtosEstoqueNegativo: _toInt(json['produtosEstoqueNegativo']),
      margemMediaPercentual: _toDouble(json['margemMediaPercentual']),
      produtosPorCategoria: _parseList(
        json['produtosPorCategoria'],
        ProdutoDashboardSerieItem.fromJson,
      ),
      valorEstoquePorCategoria: _parseList(
        json['valorEstoquePorCategoria'],
        ProdutoDashboardSerieItem.fromJson,
      ),
      situacaoEstoque: _parseList(
        json['situacaoEstoque'],
        ProdutoDashboardSerieItem.fromJson,
      ),
      topProdutosMaiorValorEstoque: _parseList(
        json['topProdutosMaiorValorEstoque'],
        ProdutoDashboardItem.fromJson,
      ),
      produtosEstoqueBaixoLista: _parseList(
        json['produtosEstoqueBaixoLista'],
        ProdutoDashboardItem.fromJson,
      ),
      alertas: _parseList(json['alertas'], ProdutoDashboardAlerta.fromJson),
    );
  }

  bool get isEmpty => totalProdutos == 0;
}

class ProdutoDashboardSerieItem {
  final String label;
  final double quantidade;
  final double valor;

  const ProdutoDashboardSerieItem({
    required this.label,
    required this.quantidade,
    required this.valor,
  });

  factory ProdutoDashboardSerieItem.fromJson(Map<String, dynamic> json) {
    return ProdutoDashboardSerieItem(
      label: json['label']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      valor: _toDouble(json['valor']),
    );
  }
}

class ProdutoDashboardItem {
  final String id;
  final String nome;
  final String codigoDeBarras;
  final String categoria;
  final double quantidadeEstoque;
  final double estoqueMinimo;
  final double precoVenda;
  final double ultimoCusto;
  final double valorEstoque;
  final double margemPercentual;

  const ProdutoDashboardItem({
    required this.id,
    required this.nome,
    required this.codigoDeBarras,
    required this.categoria,
    required this.quantidadeEstoque,
    required this.estoqueMinimo,
    required this.precoVenda,
    required this.ultimoCusto,
    required this.valorEstoque,
    required this.margemPercentual,
  });

  factory ProdutoDashboardItem.fromJson(Map<String, dynamic> json) {
    return ProdutoDashboardItem(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      codigoDeBarras: json['codigoDeBarras']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'Sem categoria',
      quantidadeEstoque: _toDouble(json['quantidadeEstoque']),
      estoqueMinimo: _toDouble(json['estoqueMinimo']),
      precoVenda: _toDouble(json['precoVenda']),
      ultimoCusto: _toDouble(json['ultimoCusto']),
      valorEstoque: _toDouble(json['valorEstoque']),
      margemPercentual: _toDouble(json['margemPercentual']),
    );
  }
}

class ProdutoDashboardAlerta {
  final String tipo;
  final String titulo;
  final String descricao;
  final int quantidade;

  const ProdutoDashboardAlerta({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.quantidade,
  });

  factory ProdutoDashboardAlerta.fromJson(Map<String, dynamic> json) {
    return ProdutoDashboardAlerta(
      tipo: json['tipo']?.toString() ?? 'INFO',
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      quantidade: _toInt(json['quantidade']),
    );
  }
}

List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map>()
      .map((item) => parser(Map<String, dynamic>.from(item)))
      .toList();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0.0;
}
