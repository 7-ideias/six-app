import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';
import '../config/app_config.dart';
import '../ui/app_feedback.dart';
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
      AppFeedback.show('Falha ao inicializar Firebase. Notificações push podem não funcionar.');
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
    AppFeedback.show('Sincronizando notificações push...');

    final bool firebaseOk = await _inicializarFirebaseParaRegistro();
    if (!firebaseOk) {
      return;
    }

    _configurarListenersSemBloquear();

    await _solicitarPermissaoSemBloquearRegistro();

    final String? token = await _obterTokenFcm();
    if (token == null || token.trim().isEmpty) {
      AppFeedback.show('Firebase não retornou token FCM.');
      return;
    }

    AppFeedback.show('Token Firebase obtido. Registrando no backend...');
    await _registrarTokenNoBackend(token);

    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((String novoToken) {
      _registrarTokenNoBackend(novoToken);
    });
  }

  Future<bool> _inicializarFirebaseParaRegistro() async {
    try {
      final bool inicializado = await initializeFirebaseIfConfigured().timeout(
        const Duration(seconds: 8),
      );

      if (!inicializado) {
        AppFeedback.show('Firebase não inicializou no aparelho.');
      } else {
        AppFeedback.show('Firebase inicializado no aparelho.');
      }

      return inicializado;
    } on TimeoutException {
      AppFeedback.show('Tempo esgotado ao inicializar Firebase.');
      return false;
    } catch (e) {
      debugPrint('[FirebasePushNotificationService] Erro ao inicializar Firebase: $e');
      AppFeedback.show('Erro ao inicializar Firebase.');
      return false;
    }
  }

  static void _configurarListenersSemBloquear() {
    if (_listenersConfigurados) {
      return;
    }

    unawaited(
      initializeOnAppStart()
          .timeout(const Duration(seconds: 8))
          .catchError((Object e) {
        debugPrint(
          '[FirebasePushNotificationService] Listeners push não configurados: $e',
        );
        AppFeedback.show('Listeners push não configurados. Registro do token continuará.');
      }),
    );
  }

  Future<void> _solicitarPermissaoSemBloquearRegistro() async {
    try {
      final NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 10));

      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          AppFeedback.show('Permissão de notificações autorizada.');
          break;
        case AuthorizationStatus.provisional:
          AppFeedback.show('Permissão provisória de notificações.');
          break;
        case AuthorizationStatus.denied:
          debugPrint('[FirebasePushNotificationService] Permissão de push negada.');
          AppFeedback.show('Permissão de notificações negada. Tentando registrar token mesmo assim.');
          break;
        case AuthorizationStatus.notDetermined:
          AppFeedback.show('Permissão de notificações ainda não definida.');
          break;
      }
    } on TimeoutException {
      AppFeedback.show('Tempo esgotado ao solicitar permissão. Tentando registrar token.');
    } catch (e) {
      debugPrint('[FirebasePushNotificationService] Falha ao solicitar permissão: $e');
      AppFeedback.show('Falha ao solicitar permissão. Tentando registrar token.');
    }
  }

  Future<String?> _obterTokenFcm() async {
    try {
      return await FirebaseMessaging.instance.getToken().timeout(
            const Duration(seconds: 12),
          );
    } on TimeoutException {
      AppFeedback.show('Tempo esgotado ao obter token Firebase.');
      return null;
    } catch (e) {
      debugPrint('[FirebasePushNotificationService] Firebase não retornou token FCM: $e');
      AppFeedback.show('Erro ao obter token Firebase.');
      return null;
    }
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
      AppFeedback.show(
        'Token FCM aguardando sessão autenticada.',
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
        AppFeedback.show(
          'Backend recusou token FCM: ${response.statusCode}.',
        );
      } else {
        AppFeedback.show('Push registrado no backend.');
      }
    } catch (e) {
      debugPrint('[FirebasePushNotificationService] Falha ao enviar token FCM: $e');
      AppFeedback.show(
        'Falha ao enviar token FCM.',
      );
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
