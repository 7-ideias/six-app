import 'dart:async';

import 'package:flutter/widgets.dart';

import 'push_destination_resolver.dart';

typedef PushNavigationExecutor =
    FutureOr<void> Function(ResolvedPushNavigation navigation);

class PushNavigationService {
  PushNavigationService._internal({PushDestinationResolver? resolver})
    : _resolver = resolver ?? const PushDestinationResolver();

  factory PushNavigationService() => _instance;

  @visibleForTesting
  PushNavigationService.test({PushDestinationResolver? resolver})
    : _resolver = resolver ?? const PushDestinationResolver();

  static final PushNavigationService _instance =
      PushNavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final PushDestinationResolver _resolver;

  PushNavigationExecutor? _executor;
  PushNavigationIntent? _pendingIntent;
  String? _lastHandledIntentKey;
  bool _dispatching = false;

  @visibleForTesting
  PushNavigationIntent? get pendingIntent => _pendingIntent;

  @visibleForTesting
  String? get lastHandledIntentKey => _lastHandledIntentKey;

  Future<void> handlePayload(
    Map<String, dynamic> payload, {
    PushNavigationSource source = PushNavigationSource.firebaseNotificationTap,
    int? notificationId,
  }) {
    return enqueueIntent(
      PushNavigationIntent(
        payload: payload,
        source: source,
        notificationId: notificationId,
      ),
    );
  }

  Future<void> enqueueIntent(PushNavigationIntent intent) async {
    final String dedupKey = intent.dedupKey;
    if (_pendingIntent?.dedupKey == dedupKey ||
        _lastHandledIntentKey == dedupKey) {
      return;
    }

    _pendingIntent = intent;
    await _dispatchPendingIfPossible();
  }

  void bindExecutor(PushNavigationExecutor executor) {
    _executor = executor;
    unawaited(_dispatchPendingIfPossible());
  }

  void unbindExecutor(PushNavigationExecutor executor) {
    if (identical(_executor, executor)) {
      _executor = null;
    }
  }

  @visibleForTesting
  void reset() {
    _executor = null;
    _pendingIntent = null;
    _lastHandledIntentKey = null;
    _dispatching = false;
  }

  Future<void> _dispatchPendingIfPossible() async {
    if (_dispatching) {
      return;
    }

    final PushNavigationExecutor? executor = _executor;
    final PushNavigationIntent? intent = _pendingIntent;
    if (executor == null || intent == null) {
      return;
    }

    if (_lastHandledIntentKey == intent.dedupKey) {
      _pendingIntent = null;
      return;
    }

    _dispatching = true;
    bool handledWithSuccess = false;
    try {
      final ResolvedPushNavigation navigation = _resolver.resolve(intent);
      await Future<void>.sync(() => executor(navigation));
      if (_pendingIntent?.dedupKey == intent.dedupKey) {
        _pendingIntent = null;
      }
      _lastHandledIntentKey = intent.dedupKey;
      handledWithSuccess = true;
    } catch (error) {
      debugPrint(
        '[PushNavigationService] Navegacao pendente mantida apos falha: $error',
      );
    } finally {
      _dispatching = false;
    }

    final PushNavigationIntent? pending = _pendingIntent;
    if (handledWithSuccess &&
        pending != null &&
        pending.dedupKey != _lastHandledIntentKey &&
        _executor != null) {
      unawaited(_dispatchPendingIfPossible());
    }
  }
}
