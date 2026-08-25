import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

Future<bool> showSixWebLogoutDialog({
  required BuildContext context,
  required Future<void> Function() onConfirm,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final bool? result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 320),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _LogoutRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: SixWebLogoutDialog(onConfirm: onConfirm),
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => child,
  );

  return result ?? false;
}

class SixWebLogoutDialog extends StatefulWidget {
  const SixWebLogoutDialog({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<SixWebLogoutDialog> createState() => _SixWebLogoutDialogState();
}

enum _LogoutDialogState { review, processing, success, error }

class _SixWebLogoutDialogState extends State<SixWebLogoutDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  _LogoutDialogState _state = _LogoutDialogState.review;

  bool get _isBusy =>
      _state == _LogoutDialogState.processing ||
      _state == _LogoutDialogState.success;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _iconController.value = 1;
      } else {
        _iconController.forward();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isBusy) return;
    setState(() => _state = _LogoutDialogState.processing);

    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _state = _LogoutDialogState.success);
      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 320 : 780),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _LogoutDialogState.error);
    }
  }

  void _cancel() {
    if (_isBusy) return;
    Navigator.of(context).pop(false);
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _LogoutDialogPalette palette = _LogoutDialogPalette.resolve(
      theme,
      tokens,
    );

    return PopScope(
      canPop: !_isBusy,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (DismissIntent intent) {
                if (_isBusy) return null;
                _cancel();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Semantics(
              namesRoute: true,
              label: _txt('web.logout.dialog.title', 'Encerrar sessão agora?'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.outline),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.28),
                        blurRadius: 42,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: palette.surface,
                      surfaceTintColor: Colors.transparent,
                      child: Stack(
                        children: <Widget>[
                          AnimatedSwitcher(
                            duration: Duration(
                              milliseconds: _reduceMotion ? 1 : 220,
                            ),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child:
                                _state == _LogoutDialogState.success
                                    ? _buildSuccess(theme, tokens, palette)
                                    : _buildReview(theme, tokens, palette),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: palette.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReview(
    ThemeData theme,
    WebThemeTokens tokens,
    _LogoutDialogPalette palette,
  ) {
    return Padding(
      key: const ValueKey<String>('logout-review'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LogoutDialogIcon(
                animation: _iconController,
                accent: palette.accent,
                surfaceColor: palette.surface,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt('web.logout.dialog.title', 'Encerrar sessão agora?'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'web.logout.dialog.subtitle',
                        'Revise o contexto antes de sair. Você voltará para a tela pública de login neste navegador.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: palette.accent,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _txt(
                    'web.logout.dialog.checklist',
                    'A sessão atual será encerrada somente neste navegador.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_state == _LogoutDialogState.error) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tokens.danger.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.error_outline_rounded, color: tokens.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _txt(
                        'web.logout.dialog.error',
                        'Não foi possível encerrar a sessão agora. Tente novamente em alguns instantes.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Divider(height: 1, color: tokens.divider),
          const SizedBox(height: 18),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 12,
            overflowSpacing: 12,
            overflowAlignment: OverflowBarAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: _isBusy ? null : _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: palette.secondaryActionForeground,
                ),
                child: Text(
                  _txt('web.logout.dialog.back', 'Continuar conectado'),
                ),
              ),
              FilledButton.icon(
                onPressed: _isBusy ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryActionBackground,
                  foregroundColor: palette.primaryActionForeground,
                  disabledBackgroundColor:
                      palette.primaryActionDisabledBackground,
                  disabledForegroundColor:
                      palette.primaryActionDisabledForeground,
                ),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child:
                      _state == _LogoutDialogState.processing
                          ? const SizedBox(
                            key: ValueKey<String>('logout-progress'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.logout_rounded,
                            key: ValueKey<String>('logout-action-icon'),
                            size: 18,
                          ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _state == _LogoutDialogState.processing
                        ? _txt(
                          'web.logout.dialog.processing',
                          'Encerrando sessão...',
                        )
                        : _txt('web.logout.dialog.confirm', 'Sair agora'),
                    key: ValueKey<_LogoutDialogState>(_state),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(
    ThemeData theme,
    WebThemeTokens tokens,
    _LogoutDialogPalette palette,
  ) {
    return Padding(
      key: const ValueKey<String>('logout-success'),
      padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: _reduceMotion ? 1 : 360),
            curve: Curves.easeOutBack,
            tween: Tween<double>(begin: 0.72, end: 1),
            builder:
                (BuildContext context, double scale, Widget? child) =>
                    Transform.scale(scale: scale, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.successSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: tokens.success, size: 42),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _txt(
              'web.logout.dialog.successTitle',
              'Sessão encerrada com sucesso',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _txt(
              'web.logout.dialog.successMessage',
              'Preparando o retorno para a tela pública de login.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutRouteSurface extends StatelessWidget {
  const _LogoutRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double progress =
            reduceMotion ? 1 : Curves.easeOutCubic.transform(animation.value);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 12 * progress,
                sigmaY: 12 * progress,
              ),
              child: ColoredBox(
                color: const Color(
                  0xFF081120,
                ).withValues(alpha: 0.78 * progress),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - progress)),
                      child: Transform.scale(
                        scale: 0.96 + (0.04 * progress),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _LogoutDialogPalette {
  const _LogoutDialogPalette({
    required this.surface,
    required this.outline,
    required this.accent,
    required this.accentSoft,
    required this.successSoft,
    required this.secondaryActionForeground,
    required this.primaryActionBackground,
    required this.primaryActionForeground,
    required this.primaryActionDisabledBackground,
    required this.primaryActionDisabledForeground,
  });

  final Color surface;
  final Color outline;
  final Color accent;
  final Color accentSoft;
  final Color successSoft;
  final Color secondaryActionForeground;
  final Color primaryActionBackground;
  final Color primaryActionForeground;
  final Color primaryActionDisabledBackground;
  final Color primaryActionDisabledForeground;

  static _LogoutDialogPalette resolve(ThemeData theme, WebThemeTokens tokens) {
    if (theme.brightness == Brightness.dark) {
      const Color accent = Color(0xFF4F8CFF);
      return _LogoutDialogPalette(
        surface: const Color(0xFF17253A),
        outline: const Color(0xFF31507A),
        accent: accent,
        accentSoft: accent.withValues(alpha: 0.16),
        successSoft: tokens.success.withValues(alpha: 0.16),
        secondaryActionForeground: const Color(0xFF8DAAFD),
        primaryActionBackground: const Color(0xFF4151D9),
        primaryActionForeground: Colors.white,
        primaryActionDisabledBackground: const Color(0xFF24324B),
        primaryActionDisabledForeground: const Color(0xFF8FA0B8),
      );
    }

    return _LogoutDialogPalette(
      surface: tokens.surfaceElevated,
      outline: tokens.cardBorder,
      accent: tokens.info,
      accentSoft: tokens.info.withValues(alpha: 0.12),
      successSoft: tokens.success.withValues(alpha: 0.13),
      secondaryActionForeground: tokens.info,
      primaryActionBackground: theme.colorScheme.primary,
      primaryActionForeground: theme.colorScheme.onPrimary,
      primaryActionDisabledBackground: tokens.disabledBackground,
      primaryActionDisabledForeground: tokens.disabledForeground,
    );
  }
}

class _LogoutDialogIcon extends StatelessWidget {
  const _LogoutDialogIcon({
    required this.animation,
    required this.accent,
    required this.surfaceColor,
  });

  final Animation<double> animation;
  final Color accent;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double pulse = Curves.easeOutCubic.transform(
          const Interval(0, 0.7).transform(animation.value),
        );
        final double badge = Curves.easeOutBack.transform(
          const Interval(0.34, 1).transform(animation.value),
        );
        return SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Opacity(
                opacity: (1 - pulse) * 0.24,
                child: Transform.scale(
                  scale: 0.86 + (pulse * 0.5),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                    ),
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: accent, size: 29),
              ),
              Positioned(
                right: 0,
                bottom: 1,
                child: Transform.scale(
                  scale: badge,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
