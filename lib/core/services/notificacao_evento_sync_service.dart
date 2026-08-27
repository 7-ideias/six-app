import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'http_client_factory.dart';
import 'notificacao_service.dart';

class NotificacaoEventoSyncService {
  NotificacaoEventoSyncService({
    AuthService? authService,
    http.Client? httpClient,
    NotificacaoService? notificacaoService,
  }) : _authService = authService ?? AuthService(),
       _httpClient = httpClient ?? createHttpClient(),
       _notificacaoService = notificacaoService ?? NotificacaoService();

  static const Duration _janelaInicial = Duration(hours: 24);
  static const int _limite = 100;
  static const String _cursorPrefix = 'six.notificacoes.cursor.v1';
  static Future<int>? _syncEmAndamento;

  final AuthService _authService;
  final http.Client _httpClient;
  final NotificacaoService _notificacaoService;

  Future<int> syncForLoggedUser() async {
    final Future<int>? atual = _syncEmAndamento;
    if (atual != null) {
      return atual;
    }

    final Future<int> sync = _syncInternal();
    _syncEmAndamento = sync;
    try {
      return await sync;
    } finally {
      if (identical(_syncEmAndamento, sync)) {
        _syncEmAndamento = null;
      }
    }
  }

  Future<int> _syncInternal() async {
    final String accessToken =
        (await _authService.getAccessToken())?.trim() ?? '';
    final String idUnicoDaEmpresa =
        (await _authService.getEmpresaId())?.trim() ?? '';
    if (accessToken.isEmpty || idUnicoDaEmpresa.isEmpty) {
      return 0;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String cursorKey = '$_cursorPrefix.$idUnicoDaEmpresa';
    final DateTime inicioDaRequisicao = DateTime.now().toUtc();
    final DateTime desde =
        DateTime.tryParse(preferences.getString(cursorKey) ?? '')?.toUtc() ??
        inicioDaRequisicao.subtract(_janelaInicial);
    final Uri uri =
        Uri.parse(
          '${AppConfig.baseUrl}/private/api/notificacoes/eventos',
        ).replace(
          queryParameters: <String, String>{
            'desde': desde.toIso8601String(),
            'limite': _limite.toString(),
          },
        );

    try {
      final http.Response response = await _httpClient.get(
        uri,
        headers: <String, String>{
          'accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'idUnicoDaEmpresa': idUnicoDaEmpresa,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[NotificacaoEventoSyncService] Backend recusou sincronizacao: '
          '${response.statusCode} ${response.body}',
        );
        return 0;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        debugPrint(
          '[NotificacaoEventoSyncService] Resposta de eventos invalida.',
        );
        return 0;
      }

      DateTime ultimoEvento = desde;
      int registrados = 0;
      int eventosValidos = 0;
      for (final dynamic item in decoded) {
        if (item is! Map) {
          continue;
        }

        final Map<String, dynamic> envelope = Map<String, dynamic>.from(item);
        final dynamic rawPayload = envelope['payload'];
        if (rawPayload is! Map) {
          continue;
        }
        eventosValidos++;

        final Map<String, dynamic> payload = <String, dynamic>{
          ...Map<String, dynamic>.from(rawPayload),
          if (envelope['eventId'] != null) 'eventId': envelope['eventId'],
          if (envelope['recebidoEmIso'] != null)
            'recebidoEmIso': envelope['recebidoEmIso'],
          'canal': 'SYNC_BACKEND',
        };
        if (await _notificacaoService.registrarPayloadPersistente(payload)) {
          registrados++;
        }

        final DateTime? recebidoEm = DateTime.tryParse(
          envelope['recebidoEmIso']?.toString() ?? '',
        )?.toUtc();
        if (recebidoEm != null && recebidoEm.isAfter(ultimoEvento)) {
          ultimoEvento = recebidoEm;
        }
      }

      final DateTime cursorSeguro = eventosValidos >= _limite
          ? ultimoEvento
          : inicioDaRequisicao;
      await preferences.setString(cursorKey, cursorSeguro.toIso8601String());
      return registrados;
    } catch (error) {
      debugPrint(
        '[NotificacaoEventoSyncService] Falha temporaria ao sincronizar: '
        '$error',
      );
      return 0;
    }
  }
}
