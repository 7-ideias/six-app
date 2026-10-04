import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../data/models/admin_visual_assets_models.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class AdminVisualAssetsService {
  AdminVisualAssetsService({AuthService? authService, http.Client? client})
    : _auth = authService ?? AuthService(),
      _client = client ?? createHttpClient();

  final AuthService _auth;
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final String token = (await _auth.getAccessToken())?.trim() ?? '';
    if (token.isEmpty) throw Exception('Sessão expirada.');
    return <String, String>{
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<AdminVisualAssetPanel> panel({
    required String scope,
    String? companyId,
    String? segment,
    String? subsegment,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/admin/visual-assets/painel',
    ).replace(
      queryParameters: <String, String>{
        'scope': scope,
        if (_has(companyId)) 'idUnicoDaEmpresa': companyId!.trim(),
        if (_has(segment)) 'segmentoPrincipal': segment!.trim(),
        if (_has(subsegment)) 'subsegmento': subsegment!.trim(),
      },
    );

    final http.Response response = await _client.get(
      uri,
      headers: await _headers(),
    );
    return AdminVisualAssetPanel.fromJson(_map(response));
  }

  Future<List<AdminVisualAssetCompany>> companies() async {
    final http.Response response = await _client.get(
      Uri.parse(
        '${AppConfig.baseUrl}/private/api/admin/visual-assets/empresas',
      ),
      headers: await _headers(),
    );

    final dynamic decoded = _decode(response);
    if (decoded is! List) throw Exception('Resposta inválida.');

    return decoded
        .whereType<Map>()
        .map(
          (Map item) => AdminVisualAssetCompany.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  Future<List<AdminVisualAssetItem>> history({
    required String slot,
    required String scope,
    String? companyId,
    String? segment,
    String? subsegment,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/admin/visual-assets/slots/'
      '${Uri.encodeComponent(slot)}/historico',
    ).replace(
      queryParameters: <String, String>{
        'scope': scope,
        if (_has(companyId)) 'idUnicoDaEmpresa': companyId!.trim(),
        if (_has(segment)) 'segmentoPrincipal': segment!.trim(),
        if (_has(subsegment)) 'subsegmento': subsegment!.trim(),
      },
    );

    final http.Response response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final dynamic decoded = _decode(response);
    if (decoded is! List) throw Exception('Resposta inválida.');

    return decoded
        .whereType<Map>()
        .map(
          (Map item) => AdminVisualAssetItem.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  Future<AdminVisualAssetItem> upload({
    required String slot,
    required String scope,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required double focalX,
    required double focalY,
    String? companyId,
    String? segment,
    String? subsegment,
    bool includeWithoutSubsegment = false,
    DateTime? activateAtLocal,
    String? timeZone,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/admin/visual-assets/upload',
    );
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _headers());
    request.fields.addAll(<String, String>{
      'slot': slot,
      'scope': scope,
      'focalX': focalX.toStringAsFixed(4),
      'focalY': focalY.toStringAsFixed(4),
      'incluiSemSubsegmento': includeWithoutSubsegment.toString(),
      if (_has(companyId)) 'idUnicoDaEmpresa': companyId!.trim(),
      if (_has(segment)) 'segmentoPrincipal': segment!.trim(),
      if (_has(subsegment)) 'subsegmento': subsegment!.trim(),
      if (activateAtLocal != null)
        'ativarEm': _localIsoWithoutOffset(activateAtLocal),
      if (_has(timeZone)) 'timeZone': timeZone!.trim(),
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final http.StreamedResponse streamed = await request.send();
    final http.Response response = await http.Response.fromStream(streamed);
    return AdminVisualAssetItem.fromJson(_map(response));
  }

  Future<AdminVisualAssetItem> archive(String id) async {
    final http.Response response = await _client.post(
      Uri.parse(
        '${AppConfig.baseUrl}/private/api/admin/visual-assets/'
        '${Uri.encodeComponent(id)}/arquivar',
      ),
      headers: await _headers(),
    );
    return AdminVisualAssetItem.fromJson(_map(response));
  }

  Future<AdminVisualAssetItem> reuse({
    required String id,
    DateTime? activateAtLocal,
    String? timeZone,
  }) async {
    final Map<String, String> headers = await _headers();
    headers['content-type'] = 'application/json';

    final http.Response response = await _client.post(
      Uri.parse(
        '${AppConfig.baseUrl}/private/api/admin/visual-assets/'
        '${Uri.encodeComponent(id)}/reutilizar',
      ),
      headers: headers,
      body: jsonEncode(<String, dynamic>{
        if (activateAtLocal != null)
          'ativarEm': _localIsoWithoutOffset(activateAtLocal),
        if (_has(timeZone)) 'timeZone': timeZone!.trim(),
      }),
    );

    return AdminVisualAssetItem.fromJson(_map(response));
  }

  Future<String> forceRefresh() async {
    final http.Response response = await _client.post(
      Uri.parse(
        '${AppConfig.baseUrl}/private/api/admin/visual-assets/'
        'forcar-atualizacao',
      ),
      headers: await _headers(),
    );
    return _map(response)['assetsVersion']?.toString() ?? '';
  }

  Map<String, dynamic> _map(http.Response response) {
    final dynamic decoded = _decode(response);
    if (decoded is! Map) throw Exception('Resposta inválida.');
    return Map<String, dynamic>.from(decoded);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String reason = 'Falha (${response.statusCode}).';
      try {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          reason =
              decoded['message']?.toString() ??
              decoded['code']?.toString() ??
              reason;
        }
      } catch (_) {}
      throw Exception(reason);
    }

    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  bool _has(String? value) => value != null && value.trim().isNotEmpty;

  String _localIsoWithoutOffset(DateTime value) {
    final DateTime local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-'
        '${two(local.month)}-${two(local.day)}T'
        '${two(local.hour)}:${two(local.minute)}:00';
  }

  void dispose() => _client.close();
}
