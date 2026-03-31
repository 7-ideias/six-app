import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../config/app_config.dart';

late StompClient stompClient;

Function(Map<String, dynamic>)? onMensagemRecebida;

void connectStomp() {
  stompClient = StompClient(
    config: StompConfig.SockJS(
      url: '${AppConfig.baseUrl}/ws',
      onConnect: onConnectCallback,
      onWebSocketError: (error) => print('Erro no WebSocket: $error'),
      onDisconnect: (frame) => print('WebSocket desconectado'),
      onStompError: (frame) => print('Erro STOMP: ${frame.body}'),
      onDebugMessage: (msg) => print('DEBUG: $msg'),
    ),
  );

  stompClient.activate();
}

void onConnectCallback(StompFrame frame) {
  stompClient.subscribe(
    destination: '/topic/ordem',
    callback: (StompFrame frame) {
      final body = frame.body;
      print('📩 Mensagem recebida: $body');

      if (body == null || body.isEmpty) return;

      try {
        final Map<String, dynamic> jsonBody = jsonDecode(body);

        if (onMensagemRecebida != null) {
          onMensagemRecebida!(jsonBody);
        }
      } catch (e) {
        print('Erro ao converter mensagem do WebSocket: $e');
      }
    },
  );

  print('✅ Conectado ao WebSocket!');
}

void disconnectStomp() {
  stompClient.deactivate();
}