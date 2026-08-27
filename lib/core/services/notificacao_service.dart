import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificacaoService extends ChangeNotifier {
  static const String _storageKey = 'six.notificacoes.eventos.v1';
  static const int _maxNotificacoesPersistidas = 100;
  static const Duration _saleFlowMergeWindow = Duration(minutes: 2);
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

  int get naoLidas =>
      _notificacoes
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

    final int mergeIndex = _notificacoes.indexWhere(
      (SixNotificationEvent existente) =>
          existente.canMergeWith(event, maxWindow: _saleFlowMergeWindow),
    );
    if (mergeIndex >= 0) {
      final SixNotificationEvent mesclado = _notificacoes[mergeIndex].mergeWith(
        event,
      );
      _notificacoes.removeAt(mergeIndex);
      _notificacoes.insert(0, mesclado);
      notifyListeners();
      unawaited(_persistir());
      return true;
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
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

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
    final Map<String, dynamic> normalizedPayload = Map<String, dynamic>.from(
      payload,
    );
    final DateTime receivedAt =
        _parseDate(normalizedPayload['recebidoEmIso']) ??
        _parseDate(normalizedPayload['recebidoEm']) ??
        DateTime.now();
    final String eventType =
        _read(normalizedPayload, 'tipoDeEvento') ?? 'EVENTO_BACKEND';
    final _VendaResumo? vendaResumo = _saleSummaryFor(normalizedPayload);
    if (vendaResumo != null) {
      normalizedPayload['tipoDeEvento'] = 'NOVA_VENDA';
      normalizedPayload['titulo'] = 'Nova venda registrada';
      normalizedPayload['mensagem'] = vendaResumo.description;
      normalizedPayload['status'] = vendaResumo.statusCode;
      normalizedPayload['valorTotal'] = vendaResumo.valor;
      normalizedPayload['statusLiquidacaoCodigo'] = vendaResumo.statusCode;
      normalizedPayload['operacaoLiquidada'] = vendaResumo.isLiquidada;
      normalizedPayload['notificacaoChaveAgrupamento'] = vendaResumo.mergeKey;
      if (vendaResumo.numeroOperacao != null) {
        normalizedPayload['numeroOperacao'] = vendaResumo.numeroOperacao;
      }
    }

    final String normalizedEventType =
        _read(normalizedPayload, 'tipoDeEvento') ?? eventType;
    final String title =
        _read(normalizedPayload, 'titulo') ?? _titleFor(normalizedEventType);
    final String description = _read(normalizedPayload, 'mensagem') ?? title;
    final String channel = _read(normalizedPayload, 'canal') ?? 'WEBSOCKET';
    final String status =
        _read(normalizedPayload, 'status') ?? _statusFor(normalizedEventType);
    final String entity = _entityFor(normalizedPayload, normalizedEventType);
    final bool isError =
        status.toUpperCase().contains('ERRO') ||
        normalizedEventType.toUpperCase().contains('ERRO');

    return SixNotificationEvent(
      id: _idFor(normalizedPayload, receivedAt),
      title: title,
      description: description,
      entity: entity,
      channel: channel,
      status: status,
      receivedAt: receivedAt,
      payload: Map<String, dynamic>.unmodifiable(normalizedPayload),
      isError: isError,
    );
  }

  factory SixNotificationEvent.fromJson(Map<String, dynamic> json) {
    final dynamic rawPayload = json['payload'];
    final Map<String, dynamic> payload =
        rawPayload is Map
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

  bool canMergeWith(SixNotificationEvent other, {required Duration maxWindow}) {
    final Set<String> ownKeys = _mergeKeysFromPayload(payload);
    final Set<String> otherKeys = _mergeKeysFromPayload(other.payload);
    if (ownKeys.isEmpty || otherKeys.isEmpty) {
      return false;
    }

    final bool sharesBusinessKey = ownKeys.any(otherKeys.contains);
    if (!sharesBusinessKey) {
      return false;
    }

    final Duration delta =
        receivedAt.isAfter(other.receivedAt)
            ? receivedAt.difference(other.receivedAt)
            : other.receivedAt.difference(receivedAt);
    return delta <= maxWindow;
  }

  SixNotificationEvent mergeWith(SixNotificationEvent other) {
    final SixNotificationEvent newer =
        receivedAt.isAfter(other.receivedAt) ? this : other;
    final SixNotificationEvent older = identical(newer, this) ? other : this;

    final Map<String, dynamic> mergedPayload = <String, dynamic>{
      ...older.payload,
      ...newer.payload,
    };

    return SixNotificationEvent.fromPayload(
      mergedPayload,
    ).copyWith(isUnread: isUnread || other.isUnread);
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

  static Set<String> _mergeKeysFromPayload(Map<String, dynamic> payload) {
    final Set<String> keys = <String>{};

    void add(String field, {String? prefix}) {
      final String? value = _read(payload, field);
      if (value == null) {
        return;
      }
      keys.add(prefix == null ? value : '$prefix:$value');
    }

    add('notificacaoChaveAgrupamento');
    add('eventId', prefix: 'event');
    add('numeroOperacao', prefix: 'numero');
    add('idOperacao', prefix: 'operacao');
    add('idOperacaoApp', prefix: 'operacao');
    add('ordemId', prefix: 'operacao');

    return keys;
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

  static _VendaResumo? _saleSummaryFor(Map<String, dynamic> payload) {
    final Set<String> mergeKeys = _mergeKeysFromPayload(payload);
    if (mergeKeys.isEmpty) {
      return null;
    }

    final String tipo =
        (_read(payload, 'tipoDeEvento') ?? '').trim().toUpperCase();
    final String titulo = (_read(payload, 'titulo') ?? '').toUpperCase();
    final String mensagem = (_read(payload, 'mensagem') ?? '').toUpperCase();
    final bool saleLike =
        tipo.contains('VENDA') ||
        tipo.contains('OPERACAO') ||
        titulo.contains('VENDA') ||
        mensagem.contains('VENDA');
    if (!saleLike) {
      return null;
    }

    final double? valor = _readSaleAmount(payload);
    final bool? liquidada = _readSaleSettlement(payload, valor: valor);
    if (valor == null && liquidada == null) {
      return null;
    }

    final String mergeKey = mergeKeys.first;
    final String? numeroOperacao = _read(payload, 'numeroOperacao');
    final bool isLiquidada = liquidada ?? false;
    final String statusCode = isLiquidada ? 'LIQUIDADA' : 'NAO_LIQUIDADA';
    final String valorFormatado =
        valor == null ? 'Valor indisponível' : _formatCurrency(valor);
    final String description =
        'Venda de $valorFormatado. ${isLiquidada ? 'Liquidada' : 'Não liquidada'}.';

    return _VendaResumo(
      mergeKey: mergeKey,
      numeroOperacao: numeroOperacao,
      valor: valor,
      isLiquidada: isLiquidada,
      statusCode: statusCode,
      description: description,
    );
  }

  static double? _readSaleAmount(Map<String, dynamic> payload) {
    for (final String key in <String>[
      'valorTotalVenda',
      'valorTotalOperacao',
      'valorTotal',
      'valorVenda',
      'valorOriginal',
      'valor',
      'valorRecebido',
      'valorLiquidado',
    ]) {
      final double? value = _toDouble(payload[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static bool? _readSaleSettlement(
    Map<String, dynamic> payload, {
    required double? valor,
  }) {
    final bool? liquidadaDireta =
        _toBool(payload['operacaoLiquidada']) ?? _toBool(payload['liquidada']);
    if (liquidadaDireta != null) {
      return liquidadaDireta;
    }

    final String statusLiquidacao =
        (_read(payload, 'statusLiquidacaoCodigo') ?? '').toUpperCase();
    if (statusLiquidacao.contains('NAO_LIQUIDADA')) {
      return false;
    }
    if (statusLiquidacao.contains('LIQUIDADA')) {
      return true;
    }

    final String statusPagamento =
        (_read(payload, 'statusPagamento') ?? '').toUpperCase();
    if (statusPagamento.contains('PENDENTE')) {
      return false;
    }
    if (statusPagamento.contains('LIQUIDADO') ||
        statusPagamento.contains('RECEBIDO') ||
        statusPagamento.contains('PAGO')) {
      return true;
    }

    final double? valorEmAberto =
        _toDouble(payload['valorEmAberto']) ?? _toDouble(payload['saldo']);
    if (valorEmAberto != null) {
      return valorEmAberto <= 0.0001;
    }

    final double? valorRecebido =
        _toDouble(payload['valorRecebido']) ??
        _toDouble(payload['valorLiquidado']);
    if (valor != null && valorRecebido != null) {
      return valorRecebido + 0.0001 >= valor;
    }

    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text.replaceAll(',', '.'));
  }

  static bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value == null) {
      return null;
    }

    final String normalized = value.toString().trim().toUpperCase();
    if (normalized == 'TRUE') {
      return true;
    }
    if (normalized == 'FALSE') {
      return false;
    }
    return null;
  }

  static String _formatCurrency(double value) {
    return _currencyFormatter.format(value).replaceAll('\u00A0', '');
  }
}

class _VendaResumo {
  const _VendaResumo({
    required this.mergeKey,
    required this.valor,
    required this.isLiquidada,
    required this.statusCode,
    required this.description,
    this.numeroOperacao,
  });

  final String mergeKey;
  final String? numeroOperacao;
  final double? valor;
  final bool isLiquidada;
  final String statusCode;
  final String description;
}
