class ProdutoModel {
  final String id;
  final String nomeProduto;
  final double precoVenda;

  ProdutoModel(
      {required this.id, required this.nomeProduto, required this.precoVenda});

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      id: json['id'],
      nomeProduto: json['nomeProduto'],
      precoVenda: json['precoVenda'].toDouble(),
    );
  }
}
