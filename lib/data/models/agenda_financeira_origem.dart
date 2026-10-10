/// Origem de lançamento identifica o fluxo que o criou, nunca uma preferência
/// editável do usuário. Os códigos históricos continuam pertencendo ao backend.
abstract final class AgendaFinanceiraOrigem {
  static String manual(String tipo) {
    return tipo.trim().toUpperCase() == 'RECEBER'
        ? 'RECEITA_MANUAL'
        : 'DESPESA_MANUAL';
  }

  static String preservada(Object? origem, String tipo) {
    final valor = origem is Map ? origem['tipo'] : origem;
    final codigo = valor?.toString().trim() ?? '';
    return codigo.isNotEmpty ? codigo : manual(tipo);
  }
}
