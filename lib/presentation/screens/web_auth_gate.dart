import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/six_i18n.dart';
import '../../core/utils/browser_location.dart';
import '../auth/web_auth_gate_controller.dart';
import '../components/six_web_splash_scene.dart';
import '../services/web_authenticated_bootstrap_service.dart';
import '../theme/web_theme_tokens.dart';

class WebAuthGate extends StatefulWidget {
  const WebAuthGate({
    super.key,
    required this.child,
    this.requestedLocation,
    this.controller,
  });

  final Widget child;
  final String? requestedLocation;
  final WebAuthGateController? controller;

  @override
  State<WebAuthGate> createState() => _WebAuthGateState();
}

class _WebAuthGateState extends State<WebAuthGate> {
  WebAuthGateController? _controller;
  bool _ownsController = false;
  bool _redirectScheduled = false;
  bool _started = false;

  WebAuthGateController get _activeController => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb) {
      return;
    }
    _ensureController();
    _startOnce();
  }

  @override
  void didUpdateWidget(covariant WebAuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!kIsWeb) {
      return;
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.requestedLocation != widget.requestedLocation) {
      _disposeOwnedController();
      _controller = null;
      _ownsController = false;
      _redirectScheduled = false;
      _started = false;
      _ensureController();
      _startOnce();
    }
  }

  @override
  void dispose() {
    _disposeOwnedController();
    super.dispose();
  }

  void _ensureController() {
    if (_controller != null) {
      return;
    }

    _controller =
        widget.controller ??
        WebAuthGateController(
          session: AuthServiceWebAuthGateSession(),
          bootstrap: _BuildContextWebAuthGateBootstrap(context),
          requestedLocation: _requestedLocation(),
        );
    _ownsController = widget.controller == null;
    _controller!.addListener(_onControllerChanged);
  }

  void _disposeOwnedController() {
    final WebAuthGateController? controller = _controller;
    if (controller == null) {
      return;
    }
    controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      controller.dispose();
    }
  }

  void _startOnce() {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _activeController.start();
    });
  }

  String _requestedLocation() {
    final String? explicit = widget.requestedLocation;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit;
    }

    final String? routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != null && routeName.trim().isNotEmpty) {
      return routeName;
    }

    return Uri.base.hasQuery
        ? '${Uri.base.path}?${Uri.base.query}'
        : Uri.base.path;
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    if (_activeController.status == WebAuthGateStatus.unauthenticated) {
      _scheduleLoginRedirect();
      return;
    }

    setState(() {});
  }

  void _scheduleLoginRedirect() {
    if (_redirectScheduled) {
      return;
    }
    _redirectScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (replaceBrowserLocation(_activeController.loginRoute)) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        _activeController.loginRoute,
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return widget.child;
    }

    final WebAuthGateStatus status = _activeController.status;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (status) {
        WebAuthGateStatus.authenticated => widget.child,
        WebAuthGateStatus.temporaryError => _WebAuthGateTemporaryError(
          key: const ValueKey<String>('web-auth-gate-temporary-error'),
          onRetry: _activeController.retry,
        ),
        WebAuthGateStatus.initializing ||
        WebAuthGateStatus.checkingSession ||
        WebAuthGateStatus.restoringSession ||
        WebAuthGateStatus.bootstrapping ||
        WebAuthGateStatus.unauthenticated => const Scaffold(
          key: ValueKey<String>('web-auth-gate-loading'),
          body: SixWebSplashScene(),
        ),
      },
    );
  }
}

class _BuildContextWebAuthGateBootstrap implements WebAuthGateBootstrap {
  _BuildContextWebAuthGateBootstrap(
    this.context, {
    WebAuthenticatedBootstrapService? service,
  }) : _service = service ?? WebAuthenticatedBootstrapService();

  final BuildContext context;
  final WebAuthenticatedBootstrapService _service;

  @override
  Future<void> bootstrap({bool force = false}) {
    return _service.bootstrap(context, force: force);
  }

  @override
  void reset() {
    _service.clearInMemorySession(context);
  }
}

class _WebAuthGateTemporaryError extends StatelessWidget {
  const _WebAuthGateTemporaryError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tokens.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.cardBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tokens.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    color: tokens.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.t(
                    'webAuthGate.temporaryError.title',
                    fallback: 'Não foi possível validar sua sessão',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t(
                    'webAuthGate.temporaryError.message',
                    fallback:
                        'Verifique sua conexão ou aguarde o backend responder e tente novamente.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      context.t(
                        'common.tryAgain',
                        fallback: 'Tentar novamente',
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
