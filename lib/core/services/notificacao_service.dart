import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificacaoService extends ChangeNotifier {
  static const String _storageKey = 'six.notificacoes.eventos.v1';
  static const int _maxNotificacoesPersistidas = 100;
  static final NotificacaoService _instance = NotificacaoService._internal();

  factory NotificacaoService() => _instance;

  NotificacaoService._internal();

  final List<SixNotificationEvent> _notificacoes = <SixNotificationEvent>[];
  Future<void>? _inicializacao;

  List<SixNotificationEvent> get notificacoes =>
      List.unmodifiable(_notificacoes);

  SixNotificationEvent? get ultimaNotificacao =>
      _notificacoes.isEmpty ? null : _notificacoes.first;

  int get total => _notificacoes.length;

  int get naoLidas => _notificacoes
      .where((SixNotificationEvent event) => event.isUnread)
      .length;

  int get comErro =>
      _notificacoes.where((SixNotificationEvent event) => event.isError).length;

  Future<void> initialize() {
    return _inicializacao ??= _carregarPersistidas();
  }

  bool registrarPayload(Map<String, dynamic> payload) {
    final SixNotificationEvent event = SixNotificationEvent.fromPayload(
      payload,
    );

    if (_notificacoes.any(
      (SixNotificationEvent existente) => existente.id == event.id,
    )) {
      return false;
    }

    _notificacoes.insert(0, event);
    if (_notificacoes.length > _maxNotificacoesPersistidas) {
      _notificacoes.removeRange(
        _maxNotificacoesPersistidas,
        _notificacoes.length,
      );
    }
    notifyListeners();
    unawaited(_persistir());
    return true;
  }

  Future<bool> registrarPayloadPersistente(Map<String, dynamic> payload) async {
    await initialize();
    final bool registrado = registrarPayload(payload);
    if (registrado) {
      await _persistir();
    }
    return registrado;
  }

  void marcarTodasComoLidas() {
    if (_notificacoes.every((SixNotificationEvent event) => !event.isUnread)) {
      return;
    }

    for (int index = 0; index < _notificacoes.length; index++) {
      _notificacoes[index] = _notificacoes[index].copyWith(isUnread: false);
    }
    notifyListeners();
    unawaited(_persistir());
  }

  void limpar() {
    if (_notificacoes.isEmpty) {
      return;
    }

    _notificacoes.clear();
    notifyListeners();
    unawaited(_persistir());
  }

  Future<void> _carregarPersistidas() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.reload();
      final String? raw = preferences.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return;
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }

      final List<SixNotificationEvent> carregadas =
          decoded
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) => SixNotificationEvent.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
            ..sort(
              (SixNotificationEvent a, SixNotificationEvent b) =>
                  b.receivedAt.compareTo(a.receivedAt),
            );

      for (final SixNotificationEvent event in carregadas) {
        if (_notificacoes.any(
          (SixNotificationEvent existente) => existente.id == event.id,
        )) {
          continue;
        }
        _notificacoes.add(event);
      }

      if (_notificacoes.length > _maxNotificacoesPersistidas) {
        _notificacoes.removeRange(
          _maxNotificacoesPersistidas,
          _notificacoes.length,
        );
      }
      notifyListeners();
    } catch (error) {
      debugPrint(
        '[NotificacaoService] Falha ao restaurar notificacoes locais: $error',
      );
    }
  }

  Future<void> _persistir() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String raw = jsonEncode(
        _notificacoes
            .take(_maxNotificacoesPersistidas)
            .map((SixNotificationEvent event) => event.toJson())
            .toList(),
      );
      await preferences.setString(_storageKey, raw);
    } catch (error) {
      debugPrint(
        '[NotificacaoService] Falha ao persistir notificacoes locais: $error',
      );
    }
  }
}

class SixNotificationEvent {
  const SixNotificationEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.entity,
    required this.channel,
    required this.status,
    required this.receivedAt,
    required this.payload,
    this.isUnread = true,
    this.isError = false,
  });

  final String id;
  final String title;
  final String description;
  final String entity;
  final String channel;
  final String status;
  final DateTime receivedAt;
  final Map<String, dynamic> payload;
  final bool isUnread;
  final bool isError;

  factory SixNotificationEvent.fromPayload(Map<String, dynamic> payload) {
    final DateTime receivedAt =
        _parseDate(payload['recebidoEmIso']) ??
        _parseDate(payload['recebidoEm']) ??
        DateTime.now();
    final String eventType = _read(payload, 'tipoDeEvento') ?? 'EVENTO_BACKEND';
    final String title = _read(payload, 'titulo') ?? _titleFor(eventType);
    final String description = _read(payload, 'mensagem') ?? title;
    final String channel = _read(payload, 'canal') ?? 'WEBSOCKET';
    final String status = _read(payload, 'status') ?? _statusFor(eventType);
    final String entity = _entityFor(payload, eventType);
    final bool isError =
        status.toUpperCase().contains('ERRO') ||
        eventType.toUpperCase().contains('ERRO');

    return SixNotificationEvent(
      id: _idFor(payload, receivedAt),
      title: title,
      description: description,
      entity: entity,
      channel: channel,
      status: status,
      receivedAt: receivedAt,
      payload: Map<String, dynamic>.unmodifiable(payload),
      isError: isError,
    );
  }

  factory SixNotificationEvent.fromJson(Map<String, dynamic> json) {
    final dynamic rawPayload = json['payload'];
    final Map<String, dynamic> payload = rawPayload is Map
        ? Map<String, dynamic>.from(rawPayload)
        : <String, dynamic>{};

    return SixNotificationEvent(
      id: json['id']?.toString() ?? _idFor(payload, DateTime.now()),
      title: json['title']?.toString() ?? 'Mensagem recebida do backend',
      description: json['description']?.toString() ?? '',
      entity: json['entity']?.toString() ?? 'Evento do backend',
      channel: json['channel']?.toString() ?? 'DESCONHECIDO',
      status: json['status']?.toString() ?? 'RECEBIDA',
      receivedAt:
          DateTime.tryParse(json['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
      payload: Map<String, dynamic>.unmodifiable(payload),
      isUnread: json['isUnread'] != false,
      isError: json['isError'] == true,
    );
  }

  SixNotificationEvent copyWith({bool? isUnread}) {
    return SixNotificationEvent(
      id: id,
      title: title,
      description: description,
      entity: entity,
      channel: channel,
      status: status,
      receivedAt: receivedAt,
      payload: payload,
      isUnread: isUnread ?? this.isUnread,
      isError: isError,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'entity': entity,
      'channel': channel,
      'status': status,
      'receivedAt': receivedAt.toIso8601String(),
      'payload': payload,
      'isUnread': isUnread,
      'isError': isError,
    };
  }

  String get timeLabel {
    final String hour = receivedAt.hour.toString().padLeft(2, '0');
    final String minute = receivedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get groupTitle {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime eventDay = DateTime(
      receivedAt.year,
      receivedAt.month,
      receivedAt.day,
    );

    if (eventDay == today) {
      return 'Hoje';
    }

    if (eventDay == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    }

    final String day = receivedAt.day.toString().padLeft(2, '0');
    final String month = receivedAt.month.toString().padLeft(2, '0');
    final String year = receivedAt.year.toString();
    return '$day/$month/$year';
  }

  static String? _read(Map<String, dynamic> payload, String key) {
    final dynamic value = payload[key];
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static String _idFor(Map<String, dynamic> payload, DateTime receivedAt) {
    final String? stableId =
        _read(payload, 'eventId') ?? _read(payload, 'messageId');
    if (stableId != null) {
      return stableId;
    }

    final String? legacyId =
        _read(payload, 'idOperacao') ??
        _read(payload, 'idProduto') ??
        _read(payload, 'idOperacaoApp') ??
        _read(payload, 'ordemId');

    if (legacyId != null) {
      return '${legacyId}_${receivedAt.microsecondsSinceEpoch}';
    }

    return receivedAt.microsecondsSinceEpoch.toString();
  }

  static String _titleFor(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'NOVA_VENDA':
        return 'Nova venda registrada';
      case 'NOVO_PRODUTO':
        return 'Produto cadastrado';
      case 'NOVA_OPERACAO':
        return 'Nova operação recebida';
      default:
        return 'Mensagem recebida do backend';
    }
  }

  static String _statusFor(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'NOVA_VENDA':
        return 'NOVA';
      case 'NOVO_PRODUTO':
        return 'CADASTRADO';
      default:
        return 'RECEBIDA';
    }
  }

  static String _entityFor(Map<String, dynamic> payload, String eventType) {
    final String? nomeProduto = _read(payload, 'nomeProduto');
    final String? idProduto = _read(payload, 'idProduto');
    final String? numeroOperacao = _read(payload, 'numeroOperacao');
    final String? idOperacao =
        _read(payload, 'idOperacao') ??
        _read(payload, 'idOperacaoApp') ??
        _read(payload, 'ordemId');

    if (eventType.toUpperCase() == 'NOVO_PRODUTO') {
      if (nomeProduto != null) {
        return 'Produto $nomeProduto';
      }

      if (idProduto != null) {
        return 'Produto $idProduto';
      }
    }

    if (numeroOperacao != null) {
      return eventType.toUpperCase() == 'NOVA_VENDA'
          ? 'Venda $numeroOperacao'
          : 'Operação $numeroOperacao';
    }

    if (idOperacao != null) {
      return eventType.toUpperCase() == 'NOVA_VENDA'
          ? 'Venda $idOperacao'
          : 'Operação $idOperacao';
    }

    return 'Evento do backend';
  }
}
