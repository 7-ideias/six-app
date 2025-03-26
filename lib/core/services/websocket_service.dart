import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'notification_service.dart';

late StompClient stompClient;

// Criamos uma função que pode ser injetada de fora:
Function(String)? onMensagemRecebida;

void connectStomp() {
  stompClient = StompClient(
    config: StompConfig.SockJS(
      // url: 'http://localhost:8082/ws',
      // url: 'http://10.0.2.2:8082/ws',
      url:
          kIsWeb
              ? 'http://localhost:8082/ws' // ou o IP da sua máquina se não estiver rodando localmente
              : 'http://10.0.2.2:8082/ws',

      // ASSIM FUNCIONA. ESSE É O CORRETO PARA LOCAL
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

      if (onMensagemRecebida != null && body != null) {
        onMensagemRecebida!(body);
      }

      if (body != null) {
        showNotification("Nova mensagem recebida", body);
      }
    },
  );

  print('✅ Conectado ao WebSocket!');
}
