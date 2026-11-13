import 'company_time.dart';

enum UltimoLoginRecencia { hoje, recente, antigo, semRegistro }

/// Datas de login são instantes UTC; a recência usa dias do fuso selecionado.
class UltimoLogin {
  const UltimoLogin._(this.data, this.dias, this.fuso);

  final DateTime? data;
  final int? dias;
  final String fuso;

  factory UltimoLogin.fromInstant(
    DateTime? instant, {
    required String timeZone,
    DateTime? now,
  }) {
    DateTime localize(DateTime value) =>
        CompanyTime.fromInstant(value, timeZone);
    final DateTime current = localize(now ?? DateTime.now());
    final DateTime? date = instant == null ? null : localize(instant);
    final int? days =
        date == null
            ? null
            : DateTime.utc(
              current.year,
              current.month,
              current.day,
            ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
    return UltimoLogin._(date, days, timeZone);
  }

  UltimoLoginRecencia get recencia {
    if (data == null) return UltimoLoginRecencia.semRegistro;
    if (dias == 0) return UltimoLoginRecencia.hoje;
    if (dias! >= 1 && dias! <= 7) return UltimoLoginRecencia.recente;
    return UltimoLoginRecencia.antigo;
  }
}
