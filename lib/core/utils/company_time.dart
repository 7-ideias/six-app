import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

/// Instantes são convertidos apenas para o fuso IANA da empresa.
/// Datas civis e respostas legadas sem offset preservam seus componentes.
abstract final class CompanyTime {
  static bool _initialized = false;

  static tz.Location location(String timeZone) {
    if (!_initialized) {
      timezone_data.initializeTimeZones();
      _initialized = true;
    }
    try {
      return tz.getLocation(timeZone);
    } on tz.LocationNotFoundException {
      // An old invalid configuration must not prevent rendering the screen.
      return tz.UTC;
    }
  }

  static DateTime fromInstant(DateTime instant, String timeZone) =>
      tz.TZDateTime.from(instant, location(timeZone));

  static DateTime forDisplay(DateTime value, String timeZone) =>
      value.isUtc || value is tz.TZDateTime
          ? fromInstant(value, timeZone)
          : value;

  static DateTime toInstant(DateTime value, String timeZone) =>
      value.isUtc || value is tz.TZDateTime
          ? value.toUtc()
          : tz.TZDateTime(
            location(timeZone),
            value.year,
            value.month,
            value.day,
            value.hour,
            value.minute,
            value.second,
            value.millisecond,
            value.microsecond,
          ).toUtc();

  static DateTime? tryParse(Object? value) {
    if (value is DateTime) return value;
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }
}
