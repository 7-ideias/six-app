import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';
import 'websocket_service.dart';

class VisualAssetSyncService {
  VisualAssetSyncService._();

  static final VisualAssetSyncService instance = VisualAssetSyncService._();

  static const String _versionPreference = 'six_visual_assets_version';
  static const String _eventType = 'ASSETS_VERSION_CHANGED';

  final StreamController<void> _changes =
      StreamController<void>.broadcast(sync: true);

  StreamSubscription<Map<String, dynamic>>? _stompSubscription;
  Timer? _activationTimer;
  bool _initialized = false;
  bool _synchronizing = false;
  String? _version;

  Stream<void> get changes => _changes.stream;
  String? get version => _version;

  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      _version = preferences.getString(_versionPreference);
      _stompSubscription = stompMessages.listen(_handleStompMessage);
    }
    await synchronize();
  }

  Future<void> synchronize({bool notifyWhenSame = false}) async {
    if (_synchronizing) return;
    _synchronizing = true;
    final http.Client client = createHttpClient();

    try {
      final AuthService auth = AuthService();
      final String token = (await auth.getAccessToken())?.trim() ?? '';
      if (token.isEmpty) return;

      final String? companyId = (await auth.getEmpresaId())?.trim();
      final Map<String, String> headers = <String, String>{
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
        if (companyId != null && companyId.isNotEmpty)
          'idUnicoDaEmpresa': companyId,
      };

      final http.Response response = await client
          .get(
            Uri.parse('${AppConfig.baseUrl}/private/api/assets/version'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return;

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return;

      final Map<String, dynamic> json =
          Map<String, dynamic>.from(decoded);
      final String serverVersion =
          json['assetsVersion']?.toString().trim() ?? '';
      if (!_isVersion(serverVersion)) return;

      final bool changed = _isNewer(serverVersion, _version);
      if (changed) {
        await _storeVersion(serverVersion);
      }

      _scheduleDefensiveCheck(
        DateTime.tryParse(json['proximaAtivacaoUtc']?.toString() ?? ''),
      );

      if (changed || notifyWhenSame) {
        _changes.add(null);
      }
    } catch (error) {
      debugPrint('[VisualAssets] falha ao sincronizar versão: $error');
    } finally {
      client.close();
      _synchronizing = false;
    }
  }

  void _handleStompMessage(Map<String, dynamic> payload) {
    if (payload['tipoDeEvento']?.toString() != _eventType) return;

    final String incoming =
        payload['assetsVersion']?.toString().trim() ?? '';
    if (!_isVersion(incoming) || !_isNewer(incoming, _version)) return;

    unawaited(() async {
      await _storeVersion(incoming);
      _changes.add(null);

      // O backend é a autoridade. Esta consulta atualiza também a próxima
      // ativação, permitindo recuperar clientes que perderam algum evento.
      await synchronize();
    }());
  }

  Future<void> _storeVersion(String value) async {
    _version = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_versionPreference, value);
  }

  void _scheduleDefensiveCheck(DateTime? nextUtc) {
    _activationTimer?.cancel();
    _activationTimer = null;
    if (nextUtc == null) return;

    final DateTime target = nextUtc.toUtc();
    final Duration delay = target.difference(DateTime.now().toUtc());
    if (delay.isNegative) {
      _activationTimer = Timer(
        const Duration(seconds: 2),
        () => unawaited(synchronize()),
      );
      return;
    }

    _activationTimer = Timer(
      delay + const Duration(seconds: 3),
      () => unawaited(synchronize()),
    );
  }

  bool _isVersion(String value) => RegExp(r'^\d{12}$').hasMatch(value);

  bool _isNewer(String incoming, String? current) {
    if (!_isVersion(incoming)) return false;
    if (current == null || !_isVersion(current)) return true;
    return incoming.compareTo(current) > 0;
  }
}
