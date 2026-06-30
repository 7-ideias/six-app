import 'package:flutter/foundation.dart';

class NotificacaoService extends ChangeNotifier {
  static final NotificacaoService _instance = NotificacaoService._internal();

  factory NotificacaoService() => _instance;

  NotificacaoService._internal();

  final List<SixNotificationEvent> _notificacoes = <SixNotificationEvent>[];

  List<SixNotificationEvent> get notificacoes => List.unmodifiable(_notificacoes);

  SixNotificationEvent? get ultimaNotificacao =>
      _notificacoes.isEmpty ? null : _notificacoes.first;

  int get total => _notificacoes.length;

  int get naoLidas =>
      _notificacoes.where((SixNotificationEvent event) => event.isUnread).length;

  int get comErro =>
      _notificacoes.where((SixNotificationEvent event) => event.isError).length;

  void registrarPayload(Map<String, dynamic> payload) {
    final SixNotificationEvent event = SixNotificationEvent.fromPayload(payload);
    _notificacoes.insert(0, event);
    notifyListeners();
  }

  void marcarTodasComoLidas() {
    if (_notificacoes.every((SixNotificationEvent event) => !event.isUnread)) {
      return;
    }

    for (int index = 0; index < _notificacoes.length; index++) {
      _notificacoes[index] = _notificacoes[index].copyWith(isUnread: false);
    }
    notifyListeners();
  }

  void limpar() {
    if (_notificacoes.isEmpty) {
      return;
    }

    _notificacoes.clear();
    notifyListeners();
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
    final DateTime receivedAt = _parseDate(payload['recebidoEm']) ?? DateTime.now();
    final String eventType = _read(payload, 'tipoDeEvento') ?? 'EVENTO_BACKEND';
    final String title = _read(payload, 'titulo') ?? _titleFor(eventType);
    final String description = _read(payload, 'mensagem') ?? title;
    final String channel = _read(payload, 'canal') ?? 'WEBSOCKET';
    final String status = _read(payload, 'status') ?? _statusFor(eventType);
    final String entity = _entityFor(payload, eventType);
    final bool isError = status.toUpperCase().contains('ERRO') ||
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

  String get timeLabel {
    final String hour = receivedAt.hour.toString().padLeft(2, '0');
    final String minute = receivedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get groupTitle {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime eventDay = DateTime(receivedAt.year, receivedAt.month, receivedAt.day);

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
    final String? idOperacao = _read(payload, 'idOperacao') ??
        _read(payload, 'idOperacaoApp') ??
        _read(payload, 'ordemId');

    if (idOperacao != null) {
      return '${idOperacao}_${receivedAt.microsecondsSinceEpoch}';
    }

    return receivedAt.microsecondsSinceEpoch.toString();
  }

  static String _titleFor(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'NOVA_VENDA':
        return 'Nova venda registrada';
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
      default:
        return 'RECEBIDA';
    }
  }

  static String _entityFor(Map<String, dynamic> payload, String eventType) {
    final String? numeroOperacao = _read(payload, 'numeroOperacao');
    final String? idOperacao = _read(payload, 'idOperacao') ??
        _read(payload, 'idOperacaoApp') ??
        _read(payload, 'ordemId');

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
