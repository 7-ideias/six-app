class RecebimentoFormaInput {
  const RecebimentoFormaInput({
    required this.codigo,
    required this.valor,
    this.descricao,
  });

  final String codigo;
  final double valor;
  final String? descricao;

  Map<String, dynamic> toJson() {
    return {'codigo': codigo, 'descricao': descricao, 'valor': valor};
  }
}
