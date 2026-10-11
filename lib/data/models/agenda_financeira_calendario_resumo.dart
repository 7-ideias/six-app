/// Totais por data de vencimento. Recebimentos/saídas confirmadas e saldos
/// pendentes são campos distintos e nunca se confundem com o valor original.
class AgendaFinanceiraCalendarioResumo {
  const AgendaFinanceiraCalendarioResumo({
    required this.recebido,
    required this.pago,
    required this.aReceber,
    required this.aPagar,
  });

  final double recebido;
  final double pago;
  final double aReceber;
  final double aPagar;

  static double numero(Object? value) {
    if (value is num) return value.toDouble();
    final texto = value?.toString().trim() ?? '';
    final normalizado = texto.contains(',') && texto.contains('.')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto.replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
  }

  static bool finalizado(Map<String, dynamic> item) {
    final status = item['status']?.toString().trim().toLowerCase() ?? '';
    return status == 'recebido' || status == 'pago';
  }

  static double confirmado(Map<String, dynamic> item) {
    final informado = numero(item['valorConfirmado']);
    return informado > 0
        ? informado
        : (finalizado(item) ? numero(item['valorOriginal'] ?? item['valor']) : 0);
  }

  static double aberto(Map<String, dynamic> item) {
    if (finalizado(item)) return 0;
    final restante = item['valorRestante'];
    if (restante != null) return numero(restante).clamp(0.0, double.infinity);
    final original = numero(item['valorOriginal'] ?? item['valor']);
    return (original - confirmado(item)).clamp(0.0, double.infinity);
  }

  static double valorPrincipal(Map<String, dynamic> item) {
    final saldo = aberto(item);
    return saldo > 0 ? saldo : confirmado(item);
  }

  static String rotuloValor(Map<String, dynamic> item) =>
      aberto(item) > 0 ? 'Em aberto' :
      (item['tipo']?.toString().toLowerCase() == 'pagar' ? 'Pago' : 'Recebido');

  factory AgendaFinanceiraCalendarioResumo.calcular(
    List<Map<String, dynamic>> itens,
  ) {
    double recebido = 0;
    double pago = 0;
    double aReceber = 0;
    double aPagar = 0;
    for (final item in itens) {
      final status = item['status']?.toString().trim().toLowerCase() ?? '';
      if (status == 'cancelado' || status == 'cancelada') continue;
      final entrada = item['tipo']?.toString().toLowerCase() == 'receber';
      if (entrada) {
        recebido += confirmado(item);
        aReceber += aberto(item);
      } else {
        pago += confirmado(item);
        aPagar += aberto(item);
      }
    }
    return AgendaFinanceiraCalendarioResumo(
      recebido: recebido,
      pago: pago,
      aReceber: aReceber,
      aPagar: aPagar,
    );
  }
}
