import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/mobile_session_restoration_service.dart';
import '../../core/services/firebase_push_notification_service.dart';
import '../../core/services/notificacao_evento_sync_service.dart';
import '../../core/services/websocket_service.dart';
import '../../data/models/streak_models.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/streak_provider.dart';
import '../navigation/mobile_navigation_controller.dart';
import 'auth_entry_mobile.dart';
import 'atendimento_mobile_screen.dart';
import 'gestao_mobile_screen.dart';
import 'home_page_mobile_screen.dart';

class MobileMainShell extends StatefulWidget {
  const MobileMainShell({
    super.key,
    this.initialIndex = MobileNavigationController.dashIndex,
  }) : assert(
         initialIndex >= MobileNavigationController.firstIndex &&
             initialIndex <= MobileNavigationController.lastIndex,
       );

  final int initialIndex;

  @override
  State<MobileMainShell> createState() => _MobileMainShellState();
}

class _MobileMainShellState extends State<MobileMainShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _transitionDuration = Duration(milliseconds: 340);
  static const Curve _transitionCurve = Curves.easeOutQuart;
  static const double _slideDistance = 12;

  late final MobileNavigationController _navigationController;
  late final AnimationController _transitionController;
  late final Animation<double> _entryAnimation;
  late final List<Widget?> _pages;
  late int _selectedIndex;
  int _transitionDirection = 0;
  final MobileSessionRestorationService _sessionRestorationService =
      MobileSessionRestorationService();
  bool _restoringSessionAfterResume = false;
  bool _resumingRealtimeSession = false;
  bool _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();

    _navigationController = MobileNavigationController(
      initialIndex: widget.initialIndex,
    );
    _transitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      value: 1,
    );
    _entryAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: _transitionCurve,
    );
    _pages = List<Widget?>.filled(3, null);
    _pages[widget.initialIndex] = _createPage(widget.initialIndex);
    _selectedIndex = widget.initialIndex;

    WidgetsBinding.instance.addObserver(this);
    _navigationController.addListener(_onNavigationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registrarOfensivaMobile();
      unawaited(_resumeRealtimeSession());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navigationController.removeListener(_onNavigationChanged);
    _navigationController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_handleAppResumed());
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      disconnectStomp();
    }
  }

  Future<void> _handleAppResumed() async {
    if (_restoringSessionAfterResume || _redirectingToLogin) {
      return;
    }

    _restoringSessionAfterResume = true;
    try {
      final MobileSessionRestorationResult restoration =
          await _sessionRestorationService.restore();

      switch (restoration.status) {
        case MobileSessionRestorationStatus.restored:
          await _resumeRealtimeSession();
          await _registrarOfensivaMobile();
          return;
        case MobileSessionRestorationStatus.temporaryFailure:
          debugPrint(
            '[MobileMainShell] Sessão preservada após falha temporária: '
            '${restoration.error}',
          );
          unawaited(_resumeRealtimeSession());
          return;
        case MobileSessionRestorationStatus.noStoredSession:
        case MobileSessionRestorationStatus.invalidSession:
          _goToLogin();
          return;
      }
    } finally {
      _restoringSessionAfterResume = false;
    }
  }

  Future<void> _resumeRealtimeSession() async {
    if (_redirectingToLogin) {
      return;
    }

    unawaited(reconnectStomp());
    if (_resumingRealtimeSession) {
      return;
    }

    _resumingRealtimeSession = true;
    try {
      await Future.wait<void>(<Future<void>>[
        FirebasePushNotificationService().syncTokenForLoggedUser(),
        NotificacaoEventoSyncService().syncForLoggedUser().then((_) {}),
      ]);
    } catch (error) {
      debugPrint(
        '[MobileMainShell] Falha temporaria ao retomar comunicacao: $error',
      );
    } finally {
      _resumingRealtimeSession = false;
    }
  }

  void _goToLogin() {
    if (!mounted || _redirectingToLogin) {
      return;
    }

    _redirectingToLogin = true;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const AuthEntryMobile()),
      (Route<dynamic> route) => false,
    );
  }

  void _onNavigationChanged() {
    final int index = _navigationController.value;
    if (index == _selectedIndex) return;

    _pages[index] ??= _createPage(index);

    if (!mounted) return;

    _selectPage(index);
  }

  void _selectPage(int index) {
    setState(() {
      _transitionDirection = (index - _selectedIndex).sign;
      _selectedIndex = index;
    });
    _transitionController.forward(from: 0);
  }

  Widget _createPage(int index) {
    switch (index) {
      case MobileNavigationController.dashIndex:
        return const HomePageMobile(title: 'dash');
      case MobileNavigationController.managementIndex:
        return const GestaoMobileScreen();
      case MobileNavigationController.serviceIndex:
        return const AtendimentoMobileScreen();
      default:
        throw ArgumentError.value(
          index,
          'index',
          'Índice de navegação inválido',
        );
    }
  }

  Future<void> _registrarOfensivaMobile() async {
    if (!mounted) {
      return;
    }
    final String timezone = context.read<LocaleSettingsProvider>().timeZone;
    await context.read<StreakProvider>().registerActivity(
      platform: StreakPlatform.mobile,
      timezone: timezone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;

    return MobileNavigationScope(
      controller: _navigationController,
      child: reduceMotion
          ? _buildIndexedPages()
          : AnimatedBuilder(
              animation: _entryAnimation,
              child: _buildIndexedPages(),
              builder: (BuildContext context, Widget? child) {
                final double progress = _entryAnimation.value;
                final double dx =
                    (1 - progress) * _slideDistance * _transitionDirection;

                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
            ),
    );
  }

  Widget _buildIndexedPages() {
    return IndexedStack(
      index: _selectedIndex,
      children: List<Widget>.generate(
        _pages.length,
        (int index) => _pages[index] ?? const SizedBox.shrink(),
      ),
    );
  }
}
