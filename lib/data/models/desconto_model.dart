class DescontoModel {
  final String id;
  final String nomeDoDesconto;
  final double valor;

  DescontoModel({
    required this.id,
    required this.nomeDoDesconto,
    required this.valor,
  });

  factory DescontoModel.fromJson(Map<String, dynamic> json) {
    return DescontoModel(
      id: json['id'],
      nomeDoDesconto: json['nomeDoDesconto'],
      valor: json['valor'].toDouble(),
    );
  }
}
