/// Combina o resumo da listagem com os dados autoritativos do GET de detalhe.
///
/// Na agenda, `valor` pode ser o saldo em aberto em vez do preço total da
/// operação. Os campos de detalhe nunca devem ser sobrescritos pelo card.
abstract final class AgendaFinanceiraDetalheValores {
  static Map<String, dynamic> combinar(
    Map<String, dynamic> resumo,
    Map<String, dynamic> detalhe,
  ) {
    if (detalhe.isEmpty) return Map<String, dynamic>.from(resumo);
    return <String, dynamic>{
      ...resumo,
      ...detalhe,
      'valorOriginal': detalhe['valorOriginal'] ?? resumo['valorOriginal'],
      'valorConfirmado': detalhe['valorPagoRecebido'] ??
          detalhe['valorConfirmado'] ?? resumo['valorConfirmado'],
      'valorRestante': detalhe['valorAberto'] ??
          detalhe['valorRestante'] ?? resumo['valorRestante'],
      'contato': resumo['contato'],
      'vencimento': resumo['vencimento'],
      'status': resumo['status'],
      'formaPagamento': resumo['formaPagamento'],
      'codigoOperacao': detalhe['codigoOperacao'] ?? resumo['codigoOperacao'],
      'liquidacoes': detalhe['liquidacoes'] ?? resumo['liquidacoes'],
    };
  }
}
