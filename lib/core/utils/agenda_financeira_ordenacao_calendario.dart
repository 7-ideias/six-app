/// Ordena os lancamentos pelo vencimento real, sem comparar datas formatadas
/// como texto (dd/MM/yyyy). Datas ausentes ou invalidas ficam por ultimo.
class AgendaFinanceiraOrdenacaoCalendario {
  const AgendaFinanceiraOrdenacaoCalendario._();

  static List<Map<String, dynamic>> ordenarPorVencimento(
    List<Map<String, dynamic>> lancamentos, {
    bool decrescente = true,
  }) {
    final registros = lancamentos.asMap().entries.toList();
    registros.sort((a, b) {
      final dataA = _lerVencimento(a.value);
      final dataB = _lerVencimento(b.value);

      if (dataA == null && dataB == null) return a.key.compareTo(b.key);
      if (dataA == null) return 1;
      if (dataB == null) return -1;

      final comparacao = dataA.compareTo(dataB);
      if (comparacao == 0) return a.key.compareTo(b.key);
      return decrescente ? -comparacao : comparacao;
    });
    return <Map<String, dynamic>>[
      for (final registro in registros) registro.value,
    ];
  }

  static DateTime? _lerVencimento(Map<String, dynamic> item) =>
      _lerData(item['dataVencimento']) ?? _lerData(item['vencimento']);

  static DateTime? _lerData(dynamic valor) {
    if (valor is DateTime) return DateTime(valor.year, valor.month, valor.day);
    final texto = valor?.toString().trim() ?? '';
    if (texto.isEmpty || texto == '-') return null;

    final formatoBr = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto);
    if (formatoBr != null) {
      final dia = int.parse(formatoBr.group(1)!);
      final mes = int.parse(formatoBr.group(2)!);
      final ano = int.parse(formatoBr.group(3)!);
      final data = DateTime(ano, mes, dia);
      if (data.year != ano || data.month != mes || data.day != dia) {
        return null;
      }
      return data;
    }

    final data = DateTime.tryParse(texto);
    return data == null ? null : DateTime(data.year, data.month, data.day);
  }
}
