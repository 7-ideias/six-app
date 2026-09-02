import 'dart:collection';
import 'dart:convert';

enum PushNavigationSource {
  firebaseNotificationTap,
  firebaseInitialMessage,
  localNotificationTap,
}

enum PushNavigationShellTab { dash, management, service }

enum PushNavigationDestination {
  notificationsInbox,
  supportChat,
  salesPending,
  technicalOrders,
  customersList,
}

class PushNavigationIntent {
  PushNavigationIntent({
    required Map<String, dynamic> payload,
    required this.source,
    this.notificationId,
  }) : payload = Map<String, dynamic>.unmodifiable(
         Map<String, dynamic>.from(payload),
       );

  final Map<String, dynamic> payload;
  final PushNavigationSource source;
  final int? notificationId;

  String get dedupKey {
    final String? stableId = _readAny(<String>[
      'eventId',
      'messageId',
      'conversationId',
      'entityId',
      'idOperacao',
      'idOperacaoApp',
      'idCliente',
      'ordemId',
      'idProduto',
      'numeroOperacao',
    ]);
    if (stableId != null) {
      return stableId;
    }

    if (notificationId != null) {
      return 'local:$notificationId';
    }

    return jsonEncode(_normalizeValue(payload));
  }

  String? get destinationHint => _readAny(<String>['destination', 'destino']);

  String? get eventType => _readAny(<String>['tipoDeEvento', 'eventType']);

  String? get feedbackMessage => _readAny(<String>['mensagem', 'body']);

  String? _readAny(List<String> keys) {
    for (final String key in keys) {
      final dynamic value = payload[key];
      if (value == null) {
        continue;
      }
      final String text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      final SplayTreeMap<String, dynamic> sorted =
          SplayTreeMap<String, dynamic>();
      value.forEach((dynamic key, dynamic child) {
        sorted[key.toString()] = _normalizeValue(child);
      });
      return sorted;
    }
    if (value is List) {
      return value.map<dynamic>(_normalizeValue).toList(growable: false);
    }
    return value;
  }
}

class ResolvedPushNavigation {
  const ResolvedPushNavigation({
    required this.intent,
    required this.destination,
    required this.destinationKey,
    required this.shellTab,
  });

  final PushNavigationIntent intent;
  final PushNavigationDestination destination;
  final String destinationKey;
  final PushNavigationShellTab? shellTab;

  Map<String, dynamic> get payload => intent.payload;
}

class PushDestinationResolver {
  const PushDestinationResolver();

  ResolvedPushNavigation resolve(PushNavigationIntent intent) {
    final PushNavigationDestination? explicitDestination =
        _explicitDestinationFor(intent.destinationHint);
    if (explicitDestination != null) {
      return _resolved(intent, explicitDestination);
    }

    final String eventType = (intent.eventType ?? '').trim().toUpperCase();
    final Map<String, dynamic> payload = intent.payload;

    if (_containsAny(eventType, const <String>['CHAT_SUPORTE', 'SUPPORT']) ||
        _hasAnyField(payload, const <String>['conversationId'])) {
      return _resolved(intent, PushNavigationDestination.supportChat);
    }

    if (_containsAny(eventType, const <String>['CLIENTE', 'CUSTOMER']) ||
        _hasAnyField(payload, const <String>['idCliente', 'clienteId'])) {
      return _resolved(intent, PushNavigationDestination.customersList);
    }

    if (_containsAny(eventType, const <String>[
          'ATENDIMENTO',
          'ASSIST',
          'ORDEM_SERVICO',
          'TECHNICAL',
        ]) ||
        _hasAnyField(payload, const <String>[
          'ordemId',
          'idAtendimentoTecnico',
        ])) {
      return _resolved(intent, PushNavigationDestination.technicalOrders);
    }

    if (_containsAny(eventType, const <String>['VENDA', 'OPERACAO', 'SALE']) ||
        _hasAnyField(payload, const <String>[
          'idOperacao',
          'idOperacaoApp',
          'numeroOperacao',
        ])) {
      return _resolved(intent, PushNavigationDestination.salesPending);
    }

    return _resolved(intent, PushNavigationDestination.notificationsInbox);
  }

  ResolvedPushNavigation _resolved(
    PushNavigationIntent intent,
    PushNavigationDestination destination,
  ) {
    return ResolvedPushNavigation(
      intent: intent,
      destination: destination,
      destinationKey: _destinationKey(destination),
      shellTab: _shellTabFor(destination),
    );
  }

  PushNavigationDestination? _explicitDestinationFor(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'notifications.inbox':
        return PushNavigationDestination.notificationsInbox;
      case 'support.chat':
        return PushNavigationDestination.supportChat;
      case 'sales.pending':
        return PushNavigationDestination.salesPending;
      case 'technical.orders':
        return PushNavigationDestination.technicalOrders;
      case 'customers.list':
        return PushNavigationDestination.customersList;
      default:
        return null;
    }
  }

  String _destinationKey(PushNavigationDestination destination) {
    switch (destination) {
      case PushNavigationDestination.notificationsInbox:
        return 'notifications.inbox';
      case PushNavigationDestination.supportChat:
        return 'support.chat';
      case PushNavigationDestination.salesPending:
        return 'sales.pending';
      case PushNavigationDestination.technicalOrders:
        return 'technical.orders';
      case PushNavigationDestination.customersList:
        return 'customers.list';
    }
  }

  PushNavigationShellTab? _shellTabFor(PushNavigationDestination destination) {
    switch (destination) {
      case PushNavigationDestination.notificationsInbox:
      case PushNavigationDestination.supportChat:
        return null;
      case PushNavigationDestination.salesPending:
      case PushNavigationDestination.technicalOrders:
        return PushNavigationShellTab.service;
      case PushNavigationDestination.customersList:
        return PushNavigationShellTab.management;
    }
  }

  bool _containsAny(String value, List<String> candidates) {
    for (final String candidate in candidates) {
      if (value.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  bool _hasAnyField(Map<String, dynamic> payload, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = payload[key];
      if (value == null) {
        continue;
      }
      if (value.toString().trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
