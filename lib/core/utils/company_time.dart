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
    return tz.getLocation(timeZone);
  }

  static DateTime fromInstant(DateTime instant, String timeZone) =>
      tz.TZDateTime.from(instant, location(timeZone));

  static DateTime forDisplay(DateTime value, String timeZone) =>
      value.isUtc || value is tz.TZDateTime
          ? fromInstant(value, timeZone)
          : value;
}
