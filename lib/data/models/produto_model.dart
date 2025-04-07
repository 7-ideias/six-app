class ProdutoModel {
  final String id;
  final String nomeProduto;
  final String codigoDeBarras;
  final double precoVenda;
  final bool ativo;

  ProdutoModel({required this.id,
    required this.nomeProduto,
    required this.codigoDeBarras,
    required this.precoVenda,
    required this.ativo
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      id: json['id'],
      nomeProduto: json['nomeProduto'],
      codigoDeBarras: json['codigoDeBarras'],
      precoVenda: json['precoVenda'].toDouble(),
      ativo: json['ativo'],
    );
  }
}
