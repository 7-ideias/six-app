import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'notificacao_evento_sync_service.dart';
import 'notificacao_service.dart';

StompClient? _stompClient;
bool _stompInicializado = false;
bool _stompDevePermanecerAtivo = false;
int _stompGeneration = 0;
String? _idUnicoDaEmpresaInscrita;

Function(Map<String, dynamic>)? onMensagemRecebida;
VoidCallback? onStompConectado;
VoidCallback? onStompDesconectado;
ValueChanged<Object>? onStompErro;

Future<void> connectStomp({String? idUnicoDaEmpresa}) async {
  final AuthService authService = AuthService();
  final String? empresaId = _normalizarEmpresaId(
    idUnicoDaEmpresa ?? await authService.getEmpresaId(),
  );
  final String accessToken = (await authService.getAccessToken())?.trim() ?? '';

  if (empresaId == null || accessToken.isEmpty) {
    const String erro =
        'Sessao autenticada incompleta para assinar o WebSocket.';
    debugPrint(erro);
    onStompErro?.call(erro);
    onStompDesconectado?.call();
    return;
  }

  if (_stompDevePermanecerAtivo &&
      _idUnicoDaEmpresaInscrita == empresaId &&
      _stompClient != null) {
    return;
  }

  _desativarClienteAtual(notificar: false);

  final int generation = ++_stompGeneration;
  _stompInicializado = true;
  _stompDevePermanecerAtivo = true;
  _idUnicoDaEmpresaInscrita = empresaId;

  final Completer<void> conexaoConcluida = Completer<void>();
  final Map<String, String> stompHeaders = <String, String>{
    'Authorization': 'Bearer $accessToken',
    'idUnicoDaEmpresa': empresaId,
  };
  late final StompClient client;
  client = StompClient(
    config: StompConfig.SockJS(
      url: '${AppConfig.baseUrl}/ws',
      reconnectDelay: const Duration(seconds: 5),
      heartbeatIncoming: const Duration(seconds: 15),
      heartbeatOutgoing: const Duration(seconds: 15),
      connectionTimeout: const Duration(seconds: 12),
      stompConnectHeaders: stompHeaders,
      beforeConnect: () async {
        final String tokenAtual =
            (await authService.getAccessToken())?.trim() ?? '';
        if (tokenAtual.isNotEmpty) {
          stompHeaders['Authorization'] = 'Bearer $tokenAtual';
        }
      },
      onConnect: (StompFrame frame) {
        _onConnect(
          generation: generation,
          client: client,
          empresaId: empresaId,
        );
        if (!conexaoConcluida.isCompleted) {
          conexaoConcluida.complete();
        }
      },
      onWebSocketError: (dynamic error) {
        if (!_ehConexaoAtual(generation)) return;
        debugPrint('Erro no WebSocket: $error');
        onStompErro?.call(error);
        onStompDesconectado?.call();
        if (!conexaoConcluida.isCompleted) {
          conexaoConcluida.complete();
        }
      },
      onDisconnect: (StompFrame frame) {
        if (!_ehConexaoAtual(generation)) return;
        debugPrint('WebSocket desconectado; aguardando reconexao automatica.');
        onStompDesconectado?.call();
      },
      onStompError: (StompFrame frame) {
        if (!_ehConexaoAtual(generation)) return;
        final Object erro = frame.body ?? 'Erro STOMP desconhecido';
        debugPrint('Erro STOMP: ${frame.body}');
        onStompErro?.call(erro);
        if (!conexaoConcluida.isCompleted) {
          conexaoConcluida.complete();
        }
      },
      onDebugMessage: (String msg) => debugPrint('DEBUG STOMP: $msg'),
    ),
  );

  _stompClient = client;
  client.activate();

  try {
    await conexaoConcluida.future.timeout(const Duration(seconds: 13));
  } on TimeoutException {
    debugPrint(
      'WebSocket ainda nao conectou; a reconexao automatica permanecera ativa.',
    );
  }
}

Future<void> reconnectStomp({String? idUnicoDaEmpresa}) async {
  _desativarClienteAtual(notificar: false);
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await connectStomp(idUnicoDaEmpresa: idUnicoDaEmpresa);
}

void _onConnect({
  required int generation,
  required StompClient client,
  required String empresaId,
}) {
  if (!_ehConexaoAtual(generation)) {
    return;
  }

  onStompConectado?.call();
  if (!kIsWeb) {
    unawaited(NotificacaoEventoSyncService().syncForLoggedUser());
  }

  final List<String> destinations = <String>[
    '/topic/empresa/$empresaId/vendas',
    '/topic/empresa/$empresaId/produtos',
  ];

  for (final String destination in destinations) {
    _assinarDestino(
      client: client,
      generation: generation,
      destination: destination,
    );
  }

  debugPrint('Conectado ao WebSocket em ${destinations.join(', ')}');
}

void _assinarDestino({
  required StompClient client,
  required int generation,
  required String destination,
}) {
  client.subscribe(
    destination: destination,
    callback: (StompFrame frame) {
      if (!_ehConexaoAtual(generation)) return;

      final String? body = frame.body;
      debugPrint('Mensagem recebida em $destination: $body');

      if (body == null || body.isEmpty) return;

      try {
        final dynamic decoded = jsonDecode(body);
        final Map<String, dynamic> jsonBody = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded as Map);

        final DateTime recebidoEm = DateTime.now();
        final Map<String, dynamic> payload = <String, dynamic>{
          ...jsonBody,
          'recebidoEm': _formatarDataHoraLocal(recebidoEm),
          'recebidoEmIso':
              jsonBody['recebidoEmIso'] ?? recebidoEm.toIso8601String(),
          'canal': jsonBody['canal'] ?? 'WEBSOCKET',
        };

        NotificacaoService().registrarPayload(payload);
        onMensagemRecebida?.call(payload);
      } catch (error) {
        debugPrint('Erro ao converter mensagem do WebSocket: $error');
      }
    },
  );
}

void disconnectStomp() {
  _desativarClienteAtual(notificar: true);
}

void _desativarClienteAtual({required bool notificar}) {
  final StompClient? client = _stompClient;
  final bool haviaCliente = client != null;

  _stompGeneration++;
  _stompClient = null;
  _stompInicializado = false;
  _stompDevePermanecerAtivo = false;
  _idUnicoDaEmpresaInscrita = null;

  try {
    client?.deactivate();
  } catch (error) {
    debugPrint('Erro ao desconectar WebSocket: $error');
  }

  if (haviaCliente && notificar) {
    onStompDesconectado?.call();
  }
}

bool isStompConnected() {
  return _stompInicializado && (_stompClient?.connected ?? false);
}

bool _ehConexaoAtual(int generation) {
  return _stompDevePermanecerAtivo && generation == _stompGeneration;
}

String? _normalizarEmpresaId(String? idUnicoDaEmpresa) {
  final String? empresaId = idUnicoDaEmpresa?.trim();
  if (empresaId == null || empresaId.isEmpty) {
    return null;
  }

  return empresaId;
}

String _formatarDataHoraLocal(DateTime value) {
  final String day = value.day.toString().padLeft(2, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String year = value.year.toString();
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
