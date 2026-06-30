import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'notificacao_service.dart';

StompClient? _stompClient;
bool _stompInicializado = false;
bool _stompAtivo = false;
bool _stompDesconectando = false;
String? _idUnicoDaEmpresaInscrita;

Function(Map<String, dynamic>)? onMensagemRecebida;
VoidCallback? onStompConectado;
VoidCallback? onStompDesconectado;
ValueChanged<Object>? onStompErro;

Future<void> connectStomp({String? idUnicoDaEmpresa}) async {
  final String? empresaId = _normalizarEmpresaId(
    idUnicoDaEmpresa ?? await AuthService().getEmpresaId(),
  );

  if (empresaId == null) {
    const String erro = 'idUnicoDaEmpresa não encontrado para assinar WebSocket.';
    debugPrint(erro);
    onStompErro?.call(erro);
    onStompDesconectado?.call();
    return;
  }

  if (_stompAtivo && !_stompDesconectando) {
    if (_idUnicoDaEmpresaInscrita == empresaId) {
      return;
    }

    disconnectStomp();
  }

  if (_stompDesconectando) {
    return;
  }

  _stompInicializado = true;
  _stompAtivo = true;
  _idUnicoDaEmpresaInscrita = empresaId;

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

  final String? empresaId = _idUnicoDaEmpresaInscrita;
  if (empresaId == null || empresaId.isEmpty) {
    const String erro = 'WebSocket conectado sem idUnicoDaEmpresa para inscrição.';
    debugPrint(erro);
    onStompErro?.call(erro);
    return;
  }

  onStompConectado?.call();

  final String destination = '/topic/empresa/$empresaId/vendas';

  _stompClient?.subscribe(
    destination: destination,
    callback: (StompFrame frame) {
      if (!_stompAtivo) return;

      final String? body = frame.body;
      debugPrint('📩 Mensagem recebida em $destination: $body');

      if (body == null || body.isEmpty) return;

      try {
        final dynamic decoded = jsonDecode(body);
        final Map<String, dynamic> jsonBody = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded as Map);

        final Map<String, dynamic> payload = <String, dynamic>{
          ...jsonBody,
          'recebidoEm': DateTime.now().toIso8601String(),
        };

        NotificacaoService().registrarPayload(payload);
        onMensagemRecebida?.call(payload);
      } catch (e) {
        debugPrint('Erro ao converter mensagem do WebSocket: $e');
      }
    },
  );

  debugPrint('✅ Conectado ao WebSocket em $destination');
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

String? _normalizarEmpresaId(String? idUnicoDaEmpresa) {
  final String? empresaId = idUnicoDaEmpresa?.trim();
  if (empresaId == null || empresaId.isEmpty) {
    return null;
  }

  return empresaId;
}
