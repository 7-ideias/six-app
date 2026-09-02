import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

Future<bool> showSixWebChatSupportCloseDialog({
  required BuildContext context,
  required String requesterName,
  required String companyName,
  required Future<void> Function() onConfirm,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final bool? result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 260),
    pageBuilder:
        (
          BuildContext routeContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) => _ChatSupportCloseRouteSurface(
          animation: animation,
          reduceMotion: reduceMotion,
          child: SixWebChatSupportCloseDialog(
            requesterName: requesterName,
            companyName: companyName,
            onConfirm: onConfirm,
          ),
        ),
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

class SixWebChatSupportCloseDialog extends StatefulWidget {
  const SixWebChatSupportCloseDialog({
    super.key,
    required this.requesterName,
    required this.companyName,
    required this.onConfirm,
  });

  final String requesterName;
  final String companyName;
  final Future<void> Function() onConfirm;

  @override
  State<SixWebChatSupportCloseDialog> createState() =>
      _SixWebChatSupportCloseDialogState();
}

enum _ChatSupportCloseState { review, processing, success, error }

class _SixWebChatSupportCloseDialogState
    extends State<SixWebChatSupportCloseDialog> {
  _ChatSupportCloseState _state = _ChatSupportCloseState.review;

  bool get _isBusy =>
      _state == _ChatSupportCloseState.processing ||
      _state == _ChatSupportCloseState.success;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  Future<void> _confirm() async {
    if (_isBusy) return;
    setState(() => _state = _ChatSupportCloseState.processing);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _state = _ChatSupportCloseState.success);
      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 320 : 780),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _ChatSupportCloseState.error);
    }
  }

  void _cancel() {
    if (!_isBusy) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return PopScope(
      canPop: !_isBusy,
      child: Semantics(
        namesRoute: true,
        label: _txt('chatSupport.close.title', 'Concluir este atendimento?'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF020617).withValues(alpha: 0.30),
                  blurRadius: 42,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: tokens.surfaceElevated,
                surfaceTintColor: Colors.transparent,
                child: Stack(
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: _reduceMotion ? 1 : 240),
                      child: _state == _ChatSupportCloseState.success
                          ? _buildSuccess(theme, tokens)
                          : _buildReview(theme, tokens),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 3, color: tokens.success),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReview(ThemeData theme, WebThemeTokens tokens) {
    return Padding(
      key: const ValueKey<String>('chat-support-close-review'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: tokens.success,
                  size: 31,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'chatSupport.close.title',
                        'Concluir este atendimento?',
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'chatSupport.close.subtitle',
                        'Se o usuário enviar outra mensagem, a conversa voltará para a fila.',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.person_outline_rounded, color: tokens.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.requesterName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.lock_outline_rounded, color: tokens.mutedText),
              ],
            ),
          ),
          if (_state == _ChatSupportCloseState.error) ...<Widget>[
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
                        'chatSupport.close.error',
                        'Não foi possível concluir. Verifique sua conexão e tente novamente.',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: _isBusy ? null : _cancel,
                child: Text(_txt('common.cancel', 'Cancelar')),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isBusy ? null : _confirm,
                icon: _state == _ChatSupportCloseState.processing
                    ? const SizedBox(
                        key: ValueKey<String>('chat-support-close-progress'),
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.task_alt_rounded, size: 18),
                label: Text(
                  _state == _ChatSupportCloseState.processing
                      ? _txt('chatSupport.close.processing', 'Concluindo...')
                      : _txt(
                          'chatSupport.actions.close',
                          'Concluir atendimento',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme, WebThemeTokens tokens) {
    return Padding(
      key: const ValueKey<String>('chat-support-close-success'),
      padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: _reduceMotion ? 1 : 360),
            curve: Curves.easeOutBack,
            tween: Tween<double>(begin: 0.72, end: 1),
            builder: (BuildContext context, double scale, Widget? child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tokens.success.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: tokens.success, size: 42),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _txt('chatSupport.close.successTitle', 'Atendimento concluído'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _txt(
              'chatSupport.close.successMessage',
              'A conversa permanece disponível no histórico.',
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

class _ChatSupportCloseRouteSurface extends StatelessWidget {
  const _ChatSupportCloseRouteSurface({
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
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double progress = reduceMotion
            ? 1
            : Curves.easeOutCubic.transform(animation.value);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 4 * progress,
                sigmaY: 4 * progress,
              ),
              child: ColoredBox(
                color: const Color(
                  0xFF0F172A,
                ).withValues(alpha: 0.58 * progress),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - progress)),
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
    );
  }
}
