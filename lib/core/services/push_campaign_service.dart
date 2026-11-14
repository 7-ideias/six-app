import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';

class CampaignRecipient {
  CampaignRecipient.fromJson(Map<String, dynamic> json)
    : userId = json['usuarioId'] as String,
      companyId = json['empresaId'] as String,
      name = json['nome']?.toString() ?? '',
      email = json['email']?.toString() ?? '',
      company = json['empresa']?.toString() ?? '',
      language = json['idioma'] as String,
      subscription = json['assinatura'] as String,
      devices = (json['dispositivos'] as num).toInt();
  final String userId, companyId, name, email, company, language, subscription;
  final int devices;
  String get key => '$userId:$companyId';
  Map<String, String> get selection => {
    'usuarioId': userId,
    'empresaId': companyId,
  };
}

class PushCampaignException implements Exception {
  const PushCampaignException(this.code);
  final String code;
}

class PushCampaignService {
  PushCampaignService({http.Client? client, AuthService? auth})
    : _client = client ?? createHttpClient(),
      _auth = auth ?? AuthService();
  final http.Client _client;
  final AuthService _auth;
  void dispose() => _client.close();
  Future<dynamic> _request(String path, {Map<String, dynamic>? body}) async {
    final token = await _auth.getAccessToken();
    if (token == null) throw const PushCampaignException('access');
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/admin/campanhas-push$path',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response =
        await (body == null
                ? _client.get(uri, headers: headers)
                : _client.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 60));
    if (response.statusCode >= 400) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const PushCampaignException('access');
      }
      throw const PushCampaignException('requestError');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<CampaignRecipient>> audience() async =>
      (await _request('/publico') as List)
          .map((e) => CampaignRecipient.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<List<CampaignRecipient>> review(Map<String, dynamic> body) async =>
      (await _request('/revisar', body: body) as List)
          .map((e) => CampaignRecipient.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<Map<String, dynamic>> send(Map<String, dynamic> body) async =>
      await _request('', body: body) as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> history(int page) async =>
      (await _request('?pagina=$page') as List).cast<Map<String, dynamic>>();
}
