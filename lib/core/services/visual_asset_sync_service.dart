import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';
import 'websocket_service.dart';

class VisualAssetSyncService with WidgetsBindingObserver {
  VisualAssetSyncService._();

  static final VisualAssetSyncService instance = VisualAssetSyncService._();

  static const String _versionPreferencePrefix =
      'six_visual_assets_version_';
  static const String _eventType = 'ASSETS_VERSION_CHANGED';
  static const String _lastEnvironmentPreference =
      'six_visual_assets_last_environment';

  final StreamController<void> _changes =
      StreamController<void>.broadcast(sync: true);

  StreamSubscription<Map<String, dynamic>>? _stompSubscription;
  Timer? _activationTimer;
  Timer? _recoveryTimer;
  bool _initialized = false;
  bool _localStateRestored = false;
  bool _synchronizing = false;
  String? _version;
  String? _environment;

  Stream<void> get changes => _changes.stream;
  String? get version => _version;
  String? get environment => _environment;

  Future<bool> initialize() async {
    await restoreLocalState();
    if (!_initialized) {
      _initialized = true;
      _stompSubscription = stompMessages.listen(_handleStompMessage);
      WidgetsBinding.instance.addObserver(this);
      _recoveryTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
        final state = WidgetsBinding.instance.lifecycleState;
        if (_changes.hasListener &&
            (state == null || state == AppLifecycleState.resumed)) {
          unawaited(synchronize());
        }
      });
    }
    return synchronize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _changes.hasListener) {
      // Recover events missed while the app was suspended.
      unawaited(synchronize(notifyWhenSame: true));
    }
  }

  Future<void> restoreLocalState() async {
    if (_localStateRestored) return;
    _localStateRestored = true;
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? environment = preferences
        .getString(_lastEnvironmentPreference)
        ?.trim()
        .toUpperCase();
    if (environment == null || !_isEnvironment(environment)) {
      return;
    }
    _environment = environment;
    _version = preferences.getString(
      '$_versionPreferencePrefix$environment',
    );
  }

  Future<bool> synchronize({bool notifyWhenSame = false}) async {
    await restoreLocalState();
    if (_synchronizing) return false;
    _synchronizing = true;
    final http.Client client = createHttpClient();

    try {
      final AuthService auth = AuthService();
      final String token = (await auth.getAccessToken())?.trim() ?? '';
      if (token.isEmpty) return false;

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

      if (response.statusCode != 200) return false;

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return false;

      final Map<String, dynamic> json =
          Map<String, dynamic>.from(decoded);
      final String serverVersion =
          json['assetsVersion']?.toString().trim() ?? '';
      final String serverEnvironment =
          json['environment']?.toString().trim().toUpperCase() ?? '';
      if (!_isVersion(serverVersion) ||
          !_isEnvironment(serverEnvironment)) {
        return false;
      }

      final bool environmentChanged = _environment != serverEnvironment;
      await _selectEnvironment(serverEnvironment);
      final bool changed = _isNewer(serverVersion, _version);
      if (changed) {
        await _storeVersion(serverVersion);
      }

      _scheduleDefensiveCheck(
        DateTime.tryParse(json['proximaAtivacaoUtc']?.toString() ?? ''),
      );

      if (changed || environmentChanged || notifyWhenSame) {
        _changes.add(null);
      }
      return changed || environmentChanged;
    } catch (error) {
      debugPrint('[VisualAssets] falha ao sincronizar versão: $error');
      return false;
    } finally {
      client.close();
      _synchronizing = false;
    }
  }

  void _handleStompMessage(Map<String, dynamic> payload) {
    if (payload['tipoDeEvento']?.toString() != _eventType) return;

    final String incoming =
        payload['assetsVersion']?.toString().trim() ?? '';
    final String incomingEnvironment =
        payload['environment']?.toString().trim().toUpperCase() ?? '';
    if (!_isVersion(incoming) ||
        !_isEnvironment(incomingEnvironment)) {
      return;
    }
    if (_environment != null &&
        incomingEnvironment != _environment) {
      return;
    }

    unawaited(() async {
      await _selectEnvironment(incomingEnvironment);
      if (!_isNewer(incoming, _version)) return;
      await _storeVersion(incoming);
      _changes.add(null);

      // O backend é a autoridade. Esta consulta atualiza também a próxima
      // ativação, permitindo recuperar clientes que perderam algum evento.
      await synchronize();
    }());
  }

  Future<void> _selectEnvironment(String value) async {
    if (_environment == value) return;
    _environment = value;
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString(
      _lastEnvironmentPreference,
      value,
    );
    _version = preferences.getString(
      '$_versionPreferencePrefix$value',
    );
  }

  Future<void> _storeVersion(String value) async {
    _version = value;
    final String environment = _environment ?? 'LIVE';
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString(
      '$_versionPreferencePrefix$environment',
      value,
    );
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

  bool _isEnvironment(String value) =>
      value == 'DEV' || value == 'LIVE';

  bool _isNewer(String incoming, String? current) {
    if (!_isVersion(incoming)) return false;
    if (current == null || !_isVersion(current)) return true;
    return incoming.compareTo(current) > 0;
  }
}
