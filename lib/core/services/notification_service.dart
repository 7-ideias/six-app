import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef NotificationPayloadTapHandler =
    FutureOr<void> Function(Map<String, dynamic> payload);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel sixNotificationChannel =
    AndroidNotificationChannel(
      'six_push_channel',
      'Six Push',
      description: 'Notificações operacionais do Six',
      importance: Importance.high,
    );

NotificationPayloadTapHandler? _notificationPayloadTapHandler;
bool _notificationLaunchPayloadHandled = false;

Future<void> initNotifications({
  NotificationPayloadTapHandler? onPayloadTap,
}) async {
  _notificationPayloadTapHandler = onPayloadTap;

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('ic_stat_notify');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(sixNotificationChannel);

  await _consumeLaunchPayloadIfNeeded();
}

Future<void> showNotification(
  String title,
  String body, {
  String? payload,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'six_push_channel',
    'Six Push',
    channelDescription: 'Notificações operacionais do Six',
    importance: Importance.max,
    priority: Priority.high,
    icon: 'ic_stat_notify',
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails generalNotificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    generalNotificationDetails,
    payload: payload,
  );
}

void _onDidReceiveNotificationResponse(NotificationResponse response) {
  unawaited(_dispatchPayload(response.payload, notificationId: response.id));
}

Future<void> _consumeLaunchPayloadIfNeeded() async {
  if (_notificationLaunchPayloadHandled) {
    return;
  }

  final NotificationAppLaunchDetails? launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp != true) {
    return;
  }

  _notificationLaunchPayloadHandled = true;
  await _dispatchPayload(
    launchDetails?.notificationResponse?.payload,
    notificationId: launchDetails?.notificationResponse?.id,
  );
}

Future<void> _dispatchPayload(String? rawPayload, {int? notificationId}) async {
  final NotificationPayloadTapHandler? handler = _notificationPayloadTapHandler;
  if (handler == null) {
    return;
  }

  final String text = rawPayload?.trim() ?? '';
  if (text.isEmpty) {
    return;
  }

  try {
    final dynamic decoded = jsonDecode(text);
    if (decoded is! Map) {
      return;
    }
    final Map<String, dynamic> payload = Map<String, dynamic>.from(decoded);
    if (notificationId != null && payload['notificationId'] == null) {
      payload['notificationId'] = notificationId;
    }
    await Future<void>.sync(() => handler(payload));
  } catch (error) {
    debugPrint(
      '[NotificationService] Nao foi possivel processar payload local: $error',
    );
  }
}
