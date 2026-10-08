/// Descricao recebida da API, sem expor o codigo operacional ao usuario.
String agendaFormaPagamentoExibicao(
  Map<String, dynamic> item, {
  Map<String, dynamic>? fallback,
}) {
  for (final origem in [item, if (fallback != null) fallback]) {
    for (final campo in ['formaPagamentoRealizada', 'formaPagamento']) {
      final valor = origem[campo]?.toString().trim() ?? '';
      if (valor.isNotEmpty &&
          !RegExp(r'^tipo\d+$', caseSensitive: false).hasMatch(valor)) {
        return valor;
      }
    }
  }
  return '-';
}
