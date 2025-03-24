class ProdutoModel {
  final int id;
  final String nome;
  final double preco;

  ProdutoModel({required this.id, required this.nome, required this.preco});

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      id: json['id'],
      nome: json['nome'],
      preco: json['preco'].toDouble(),
    );
  }
}
