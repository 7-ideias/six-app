import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'notificacao_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebasePushNotificationService.initializeFirebaseIfConfigured();
  FirebasePushNotificationService.registrarRemoteMessage(message);
}

class FirebasePushNotificationService {
  FirebasePushNotificationService({
    AuthService? authService,
    http.Client? httpClient,
  })  : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  static bool _firebaseInicializado = false;
  static bool _listenersConfigurados = false;
  static bool _backgroundHandlerRegistrado = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  final AuthService _authService;
  final http.Client _httpClient;

  static Future<bool> initializeFirebaseIfConfigured() async {
    if (kIsWeb) {
      return false;
    }

    if (_firebaseInicializado) {
      return true;
    }

    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        '[FirebasePushNotificationService] Firebase não configurado. '
        'Informe os dart-defines do Firebase para habilitar push.',
      );
      return false;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseInicializado = true;
      return true;
    } catch (e) {
      debugPrint('[FirebasePushNotificationService] Falha ao inicializar Firebase: $e');
      return false;
    }
  }

  static Future<void> initializeOnAppStart() async {
    if (!await initializeFirebaseIfConfigured()) {
      return;
    }

    if (!_backgroundHandlerRegistrado) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _backgroundHandlerRegistrado = true;
    }

    if (_listenersConfigurados) {
      return;
    }

    await initNotifications();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(registrarRemoteMessage);

    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      registrarRemoteMessage(initialMessage);
    }

    _listenersConfigurados = true;
  }

  Future<void> syncTokenForLoggedUser() async {
    await initializeOnAppStart();
    if (!_firebaseInicializado) {
      return;
    }

    final NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FirebasePushNotificationService] Permissão de push negada.');
      return;
    }

    final String? token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await _registrarTokenNoBackend(token);
    }

    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((String novoToken) {
      _registrarTokenNoBackend(novoToken);
    });
  }

  Future<void> _registrarTokenNoBackend(String token) async {
    final String tokenNormalizado = token.trim();
    if (tokenNormalizado.isEmpty) {
      return;
    }

    final String? accessToken = await _authService.getAccessToken();
    final String? idUnicoDaEmpresa = await _authService.getEmpresaId();

    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        idUnicoDaEmpresa == null ||
        idUnicoDaEmpresa.trim().isEmpty) {
      debugPrint(
        '[FirebasePushNotificationService] Token FCM aguardando sessão autenticada.',
      );
      return;
    }

    final Uri uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/notificacoes/push-token',
    );

    try {
      final http.Response response = await _httpClient.post(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'idUnicoDaEmpresa': idUnicoDaEmpresa,
        },
        body: jsonEncode(<String, String>{
          'token': tokenNormalizado,
          'plataforma': _plataformaAtual(),
          'appVersion': '1.0.0',
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[FirebasePushNotificationService] Backend recusou token FCM: '
          '${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[FirebasePushNotificationService] Falha ao enviar token FCM: $e');
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    registrarRemoteMessage(message);

    final String title = _titleFrom(message);
    final String body = _bodyFrom(message);

    showNotification(title, body, payload: jsonEncode(message.data));
  }

  static void registrarRemoteMessage(RemoteMessage message) {
    final Map<String, dynamic> payload = <String, dynamic>{
      ...message.data,
      'tipoDeEvento': message.data['tipoDeEvento'] ?? 'PUSH_FIREBASE',
      'titulo': _titleFrom(message),
      'mensagem': _bodyFrom(message),
      'canal': 'FIREBASE_PUSH',
      'recebidoEmIso': DateTime.now().toIso8601String(),
      if (message.messageId != null) 'messageId': message.messageId,
      if (message.sentTime != null) 'sentTime': message.sentTime!.toIso8601String(),
    };

    NotificacaoService().registrarPayload(payload);
  }

  static String _titleFrom(RemoteMessage message) {
    final String? notificationTitle = message.notification?.title;
    final Object? dataTitle = message.data['titulo'] ?? message.data['title'];
    return _textoOuPadrao(
      notificationTitle ?? dataTitle?.toString(),
      'Mensagem recebida',
    );
  }

  static String _bodyFrom(RemoteMessage message) {
    final String? notificationBody = message.notification?.body;
    final Object? dataBody = message.data['mensagem'] ?? message.data['body'];
    return _textoOuPadrao(
      notificationBody ?? dataBody?.toString(),
      'Você recebeu uma nova atualização do Six.',
    );
  }

  static String _textoOuPadrao(String? value, String fallback) {
    final String? text = value?.trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  static String _plataformaAtual() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      default:
        return 'MOBILE';
    }
  }
}
