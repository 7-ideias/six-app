import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';

Map<String, String> pdvSelecaoUrls(
  Map<String, dynamic> source, {
  String apiBaseUrl = AppConfig.baseUrl,
}) {
  final urls = <String, String>{};
  for (final key in ['PRODUTO', 'SERVICO']) {
    final value = source[key];
    if (value is! String) continue;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty) continue;
    if (uri.scheme == 'https') {
      urls[key] = uri.toString();
      continue;
    }
    if (!kDebugMode || uri.scheme != 'http') continue;
    final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
    final api = Uri.parse(apiBaseUrl);
    // No emulador Android, localhost é o próprio dispositivo.
    if (api.host == '10.0.2.2' && (loopback || uri.host == api.host)) {
      urls[key] = uri.replace(host: api.host).toString();
    } else if (loopback) {
      urls[key] = uri.toString();
    }
  }
  return urls;
}
