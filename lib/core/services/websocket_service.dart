import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../config/app_config.dart';

late StompClient stompClient;
bool _stompInicializado = false;

Function(Map<String, dynamic>)? onMensagemRecebida;
VoidCallback? onStompConectado;
VoidCallback? onStompDesconectado;
ValueChanged<Object>? onStompErro;

void connectStomp() {
  _stompInicializado = true;
  stompClient = StompClient(
    config: StompConfig.SockJS(
      url: '${AppConfig.baseUrl}/ws',
      onConnect: onConnectCallback,
      onWebSocketError: (error) {
        print('Erro no WebSocket: $error');
        onStompErro?.call(error);
        onStompDesconectado?.call();
      },
      onDisconnect: (frame) {
        print('WebSocket desconectado');
        onStompDesconectado?.call();
      },
      onStompError: (frame) {
        final Object erro = frame.body ?? 'Erro STOMP desconhecido';
        print('Erro STOMP: ${frame.body}');
        onStompErro?.call(erro);
      },
      onDebugMessage: (msg) => print('DEBUG: $msg'),
    ),
  );

  stompClient.activate();
}

void onConnectCallback(StompFrame frame) {
  onStompConectado?.call();

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
  if (!isStompConnected()) {
    return;
  }
  stompClient.deactivate();
}

bool isStompConnected() {
  return _stompInicializado && stompClient.connected;
}
