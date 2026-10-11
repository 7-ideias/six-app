/// Regras puramente visuais para não confundir forma prevista com pagamento realizado.
///
/// O backend pode devolver a forma configurada mesmo antes da primeira liquidação.
/// Isso não autoriza mostrá-la como forma utilizada no resumo financeiro.
abstract final class AgendaFinanceiraResumoVisual {
  static double _numero(Object? value) {
    if (value is num) return value.toDouble();
    final texto = value?.toString().trim() ?? '';
    if (texto.isEmpty) return 0;
    final normalizado = texto.contains(',') && texto.contains('.')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto.replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
  }

  static bool possuiRecebimento(Map<String, dynamic> item) =>
      _numero(item['valorConfirmado'] ?? item['valorPagoRecebido']) > 0;

  static String? contatoInformado(Object? contato) {
    final valor = contato?.toString().trim() ?? '';
    if (valor.isEmpty || valor == '-' ||
        <String>{
          'não informado', 'nao informado', 'no informado',
          'not informed', 'not provided', 'null',
        }.contains(valor.toLowerCase())) {
      return null;
    }
    return valor;
  }

  static String? formaRealizada(Map<String, dynamic> item) {
    if (!possuiRecebimento(item)) return null;
    final forma = item['formaPagamento']?.toString().trim() ?? '';
    return forma.isNotEmpty && forma != '-' && forma.toLowerCase() != 'null'
        ? forma
        : null;
  }
}
