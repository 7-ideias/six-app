import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/locale_settings_provider.dart';

String infrastructureNumber(
  BuildContext context,
  num value, {
  int decimals = 0,
}) {
  final locale =
      context.read<LocaleSettingsProvider>().currentLocale.toLanguageTag();
  return (NumberFormat.decimalPattern(locale)
    ..maximumFractionDigits = decimals).format(value);
}

String infrastructureBytes(BuildContext context, int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${infrastructureNumber(context, value, decimals: value >= 100 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

String infrastructureDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${(seconds % 60).toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}
