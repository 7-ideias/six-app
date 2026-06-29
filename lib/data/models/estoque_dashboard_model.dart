class EstoqueDashboardModel {
  final double valorTotalEstoque;
  final double quantidadeTotalEstoque;
  final int totalProdutos;
  final int produtosAbaixoMinimo;
  final int produtosSemEstoque;
  final int produtosEstoqueNegativo;
  final int produtosAcimaMaximo;
  final int produtosSemMovimentacao;
  final int entradasRecentes;
  final int saidasRecentes;
  final List<EstoqueDashboardSerieItem> situacaoEstoque;
  final List<EstoqueDashboardSerieItem> valorEstoquePorCategoria;
  final List<EstoqueDashboardProdutoItem> produtosParaReposicao;
  final List<EstoqueDashboardProdutoItem> produtosComErroEstoque;
  final List<EstoqueDashboardProdutoItem> produtosMaiorValorParado;
  final List<EstoqueDashboardMovimentoItem> movimentacoesRecentes;
  final List<EstoqueDashboardAlerta> alertas;

  const EstoqueDashboardModel({
    required this.valorTotalEstoque,
    required this.quantidadeTotalEstoque,
    required this.totalProdutos,
    required this.produtosAbaixoMinimo,
    required this.produtosSemEstoque,
    required this.produtosEstoqueNegativo,
    required this.produtosAcimaMaximo,
    required this.produtosSemMovimentacao,
    required this.entradasRecentes,
    required this.saidasRecentes,
    required this.situacaoEstoque,
    required this.valorEstoquePorCategoria,
    required this.produtosParaReposicao,
    required this.produtosComErroEstoque,
    required this.produtosMaiorValorParado,
    required this.movimentacoesRecentes,
    required this.alertas,
  });

  factory EstoqueDashboardModel.fromJson(Map<String, dynamic> json) {
    return EstoqueDashboardModel(
      valorTotalEstoque: _toDouble(json['valorTotalEstoque']),
      quantidadeTotalEstoque: _toDouble(json['quantidadeTotalEstoque']),
      totalProdutos: _toInt(json['totalProdutos']),
      produtosAbaixoMinimo: _toInt(json['produtosAbaixoMinimo']),
      produtosSemEstoque: _toInt(json['produtosSemEstoque']),
      produtosEstoqueNegativo: _toInt(json['produtosEstoqueNegativo']),
      produtosAcimaMaximo: _toInt(json['produtosAcimaMaximo']),
      produtosSemMovimentacao: _toInt(json['produtosSemMovimentacao']),
      entradasRecentes: _toInt(json['entradasRecentes']),
      saidasRecentes: _toInt(json['saidasRecentes']),
      situacaoEstoque: _parseList(
        json['situacaoEstoque'],
        EstoqueDashboardSerieItem.fromJson,
      ),
      valorEstoquePorCategoria: _parseList(
        json['valorEstoquePorCategoria'],
        EstoqueDashboardSerieItem.fromJson,
      ),
      produtosParaReposicao: _parseList(
        json['produtosParaReposicao'],
        EstoqueDashboardProdutoItem.fromJson,
      ),
      produtosComErroEstoque: _parseList(
        json['produtosComErroEstoque'],
        EstoqueDashboardProdutoItem.fromJson,
      ),
      produtosMaiorValorParado: _parseList(
        json['produtosMaiorValorParado'],
        EstoqueDashboardProdutoItem.fromJson,
      ),
      movimentacoesRecentes: _parseList(
        json['movimentacoesRecentes'],
        EstoqueDashboardMovimentoItem.fromJson,
      ),
      alertas: _parseList(json['alertas'], EstoqueDashboardAlerta.fromJson),
    );
  }

  bool get isEmpty => totalProdutos == 0;
}

class EstoqueDashboardSerieItem {
  final String label;
  final double quantidade;
  final double valor;

  const EstoqueDashboardSerieItem({
    required this.label,
    required this.quantidade,
    required this.valor,
  });

  factory EstoqueDashboardSerieItem.fromJson(Map<String, dynamic> json) {
    return EstoqueDashboardSerieItem(
      label: json['label']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      valor: _toDouble(json['valor']),
    );
  }
}

class EstoqueDashboardProdutoItem {
  final String id;
  final String nome;
  final String codigoDeBarras;
  final String categoria;
  final double quantidadeEstoque;
  final double estoqueMinimo;
  final double estoqueMaximo;
  final double diferencaParaMinimo;
  final double precoVenda;
  final double ultimoCusto;
  final double valorEstoque;
  final String problema;

  const EstoqueDashboardProdutoItem({
    required this.id,
    required this.nome,
    required this.codigoDeBarras,
    required this.categoria,
    required this.quantidadeEstoque,
    required this.estoqueMinimo,
    required this.estoqueMaximo,
    required this.diferencaParaMinimo,
    required this.precoVenda,
    required this.ultimoCusto,
    required this.valorEstoque,
    required this.problema,
  });

  factory EstoqueDashboardProdutoItem.fromJson(Map<String, dynamic> json) {
    return EstoqueDashboardProdutoItem(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      codigoDeBarras: json['codigoDeBarras']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'Sem categoria',
      quantidadeEstoque: _toDouble(json['quantidadeEstoque']),
      estoqueMinimo: _toDouble(json['estoqueMinimo']),
      estoqueMaximo: _toDouble(json['estoqueMaximo']),
      diferencaParaMinimo: _toDouble(json['diferencaParaMinimo']),
      precoVenda: _toDouble(json['precoVenda']),
      ultimoCusto: _toDouble(json['ultimoCusto']),
      valorEstoque: _toDouble(json['valorEstoque']),
      problema: json['problema']?.toString() ?? '',
    );
  }
}

class EstoqueDashboardMovimentoItem {
  final String idProduto;
  final String nomeProduto;
  final String categoria;
  final String tipo;
  final DateTime? dataCadastro;
  final double quantidade;
  final double valorCusto;
  final double valorVenda;

  const EstoqueDashboardMovimentoItem({
    required this.idProduto,
    required this.nomeProduto,
    required this.categoria,
    required this.tipo,
    required this.dataCadastro,
    required this.quantidade,
    required this.valorCusto,
    required this.valorVenda,
  });

  factory EstoqueDashboardMovimentoItem.fromJson(Map<String, dynamic> json) {
    final String? data = json['dataCadastro']?.toString();
    return EstoqueDashboardMovimentoItem(
      idProduto: json['idProduto']?.toString() ?? '',
      nomeProduto: json['nomeProduto']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'Sem categoria',
      tipo: json['tipo']?.toString() ?? 'MOVIMENTACAO',
      dataCadastro: data == null || data.isEmpty ? null : DateTime.tryParse(data),
      quantidade: _toDouble(json['quantidade']),
      valorCusto: _toDouble(json['valorCusto']),
      valorVenda: _toDouble(json['valorVenda']),
    );
  }
}

class EstoqueDashboardAlerta {
  final String tipo;
  final String titulo;
  final String descricao;
  final int quantidade;

  const EstoqueDashboardAlerta({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.quantidade,
  });

  factory EstoqueDashboardAlerta.fromJson(Map<String, dynamic> json) {
    return EstoqueDashboardAlerta(
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
