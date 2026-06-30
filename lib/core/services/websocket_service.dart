import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../config/app_config.dart';

StompClient? _stompClient;
bool _stompInicializado = false;
bool _stompAtivo = false;
bool _stompDesconectando = false;

Function(Map<String, dynamic>)? onMensagemRecebida;
VoidCallback? onStompConectado;
VoidCallback? onStompDesconectado;
ValueChanged<Object>? onStompErro;

void connectStomp() {
  if (_stompAtivo || _stompDesconectando) {
    return;
  }

  _stompInicializado = true;
  _stompAtivo = true;

  final StompClient client = StompClient(
    config: StompConfig.SockJS(
      url: '${AppConfig.baseUrl}/ws',
      onConnect: onConnectCallback,
      onWebSocketError: (error) {
        if (!_stompAtivo) return;
        debugPrint('Erro no WebSocket: $error');
        onStompErro?.call(error);
        onStompDesconectado?.call();
      },
      onDisconnect: (StompFrame frame) {
        debugPrint('WebSocket desconectado');
        if (_stompAtivo) {
          onStompDesconectado?.call();
        }
        _stompAtivo = false;
        _stompDesconectando = false;
      },
      onStompError: (StompFrame frame) {
        if (!_stompAtivo) return;
        final Object erro = frame.body ?? 'Erro STOMP desconhecido';
        debugPrint('Erro STOMP: ${frame.body}');
        onStompErro?.call(erro);
      },
      onDebugMessage: (String msg) => debugPrint('DEBUG: $msg'),
    ),
  );

  _stompClient = client;
  client.activate();
}

void onConnectCallback(StompFrame frame) {
  if (!_stompAtivo) {
    return;
  }

  onStompConectado?.call();

  _stompClient?.subscribe(
    destination: '/topic/ordem',
    callback: (StompFrame frame) {
      if (!_stompAtivo) return;

      final String? body = frame.body;
      debugPrint('📩 Mensagem recebida: $body');

      if (body == null || body.isEmpty) return;

      try {
        final Map<String, dynamic> jsonBody = jsonDecode(body);
        onMensagemRecebida?.call(jsonBody);
      } catch (e) {
        debugPrint('Erro ao converter mensagem do WebSocket: $e');
      }
    },
  );

  debugPrint('✅ Conectado ao WebSocket!');
}

void disconnectStomp() {
  if (!_stompInicializado || _stompClient == null || _stompDesconectando) {
    return;
  }

  _stompAtivo = false;
  _stompDesconectando = true;

  try {
    _stompClient?.deactivate();
  } catch (e) {
    _stompDesconectando = false;
    debugPrint('Erro ao desconectar WebSocket: $e');
  }
}

bool isStompConnected() {
  return _stompInicializado && (_stompClient?.connected ?? false);
}
