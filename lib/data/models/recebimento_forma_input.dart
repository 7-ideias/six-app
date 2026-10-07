class RecebimentoFormaInput {
  const RecebimentoFormaInput({
    required this.codigo,
    required this.valor,
    this.descricao,
    this.contaFinanceiraId,
    this.maquininhaId,
    this.dataPrevista,
    this.taxa = 0,
    this.recebimentoFuturo = false,
  });

  final String codigo;
  final double valor;
  final String? descricao;
  final String? contaFinanceiraId, maquininhaId, dataPrevista;
  final double taxa;
  final bool recebimentoFuturo;

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'descricao': descricao,
      'valor': valor,
      'contaFinanceiraId': contaFinanceiraId,
      'maquininhaId': maquininhaId,
      'dataPrevista': dataPrevista,
      'taxa': taxa,
      'recebimentoFuturo': recebimentoFuturo,
    };
  }
}
