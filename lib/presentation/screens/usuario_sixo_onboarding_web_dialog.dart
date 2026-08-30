import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../l10n/six_i18n.dart';
import '../theme/web_theme_tokens.dart';

Future<bool> showUsuarioSixoOnboardingWebDialog({
  required BuildContext context,
  required String nomeUsuario,
  required bool valorAtual,
  required Future<void> Function(bool novoValor) onConfirm,
}) async {
  final bool? changed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: context.t(
      'usuariosSixo.onboarding.dialogBarrier',
      fallback: 'Alterar status do onboarding inicial',
    ),
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => _UsuarioSixoOnboardingWebDialog(
      nomeUsuario: nomeUsuario,
      novoValor: !valorAtual,
      onConfirm: onConfirm,
    ),
    transitionBuilder: (context, animation, _, child) {
      final bool reduceMotion =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      if (reduceMotion) return child;
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
          child: child,
        ),
      );
    },
  );
  return changed == true;
}

enum _DialogPhase { review, processing, success, error }

class _UsuarioSixoOnboardingWebDialog extends StatefulWidget {
  const _UsuarioSixoOnboardingWebDialog({
    required this.nomeUsuario,
    required this.novoValor,
    required this.onConfirm,
  });

  final String nomeUsuario;
  final bool novoValor;
  final Future<void> Function(bool novoValor) onConfirm;

  @override
  State<_UsuarioSixoOnboardingWebDialog> createState() =>
      _UsuarioSixoOnboardingWebDialogState();
}

class _UsuarioSixoOnboardingWebDialogState
    extends State<_UsuarioSixoOnboardingWebDialog> {
  _DialogPhase _phase = _DialogPhase.review;

  Future<void> _confirm() async {
    setState(() => _phase = _DialogPhase.processing);
    try {
      await widget.onConfirm(widget.novoValor);
      if (!mounted) return;
      setState(() => _phase = _DialogPhase.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _DialogPhase.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return PopScope(
      canPop: _phase != _DialogPhase.processing,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(
                color: const Color(0xFF06152F).withValues(alpha: 0.78),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: tokens.cardBackground,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: tokens.cardBorder),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 36,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: _buildPhase(context, tokens),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context, WebThemeTokens tokens) {
    return switch (_phase) {
      _DialogPhase.review => _review(context, tokens),
      _DialogPhase.processing => _processing(context, tokens),
      _DialogPhase.success => _success(context, tokens),
      _DialogPhase.error => _error(context, tokens),
    };
  }

  Widget _review(BuildContext context, WebThemeTokens tokens) {
    final bool reset = !widget.novoValor;
    return Column(
      key: const ValueKey<String>('review'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _DialogIcon(
          icon: reset ? Icons.restart_alt_rounded : Icons.task_alt_rounded,
          color: reset ? const Color(0xFFE28A16) : tokens.success,
        ),
        const SizedBox(height: 18),
        Text(
          reset
              ? context.t(
                  'usuariosSixo.onboarding.resetTitle',
                  fallback: 'Solicitar novo onboarding?',
                )
              : context.t(
                  'usuariosSixo.onboarding.completeTitle',
                  fallback: 'Marcar onboarding como concluído?',
                ),
          style: TextStyle(
            color: tokens.primaryText,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          reset
              ? context.t(
                  'usuariosSixo.onboarding.resetMessage',
                  fallback:
                      'No próximo acesso, o usuário deverá confirmar novamente seus dados iniciais antes de entrar no sistema.',
                )
              : context.t(
                  'usuariosSixo.onboarding.completeMessage',
                  fallback:
                      'O usuário deixará de ver o onboarding inicial nos próximos acessos.',
                ),
          style: TextStyle(color: tokens.secondaryText, height: 1.45),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.person_outline_rounded, color: tokens.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.nomeUsuario,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.t('common.cancel', fallback: 'Cancelar')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _confirm,
              icon: Icon(
                reset ? Icons.restart_alt_rounded : Icons.check_rounded,
              ),
              label: Text(
                reset
                    ? context.t(
                        'usuariosSixo.onboarding.resetAction',
                        fallback: 'Refazer onboarding',
                      )
                    : context.t(
                        'usuariosSixo.onboarding.completeAction',
                        fallback: 'Marcar como concluído',
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _processing(BuildContext context, WebThemeTokens tokens) {
    return _CenteredDialogState(
      key: const ValueKey<String>('processing'),
      indicator: const CircularProgressIndicator(),
      title: context.t(
        'usuariosSixo.onboarding.processingTitle',
        fallback: 'Atualizando onboarding...',
      ),
      message: context.t(
        'usuariosSixo.onboarding.processingMessage',
        fallback: 'Aguarde enquanto a nova configuração é salva.',
      ),
      tokens: tokens,
    );
  }

  Widget _success(BuildContext context, WebThemeTokens tokens) {
    return _CenteredDialogState(
      key: const ValueKey<String>('success'),
      indicator: _DialogIcon(icon: Icons.check_rounded, color: tokens.success),
      title: context.t(
        'usuariosSixo.onboarding.successTitle',
        fallback: 'Onboarding atualizado',
      ),
      message: context.t(
        'usuariosSixo.onboarding.successMessage',
        fallback: 'A nova regra já valerá no próximo acesso do usuário.',
      ),
      tokens: tokens,
      action: FilledButton(
        autofocus: true,
        onPressed: () => Navigator.of(context).pop(true),
        child: Text(context.t('common.close', fallback: 'Fechar')),
      ),
    );
  }

  Widget _error(BuildContext context, WebThemeTokens tokens) {
    return _CenteredDialogState(
      key: const ValueKey<String>('error'),
      indicator: const _DialogIcon(
        icon: Icons.error_outline_rounded,
        color: Color(0xFFD94B57),
      ),
      title: context.t(
        'usuariosSixo.onboarding.errorTitle',
        fallback: 'Não foi possível atualizar',
      ),
      message: context.t(
        'usuariosSixo.onboarding.errorMessage',
        fallback: 'Tente novamente. Nenhuma outra informação foi alterada.',
      ),
      tokens: tokens,
      action: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t('common.close', fallback: 'Fechar')),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            autofocus: true,
            onPressed: _confirm,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _CenteredDialogState extends StatelessWidget {
  const _CenteredDialogState({
    super.key,
    required this.indicator,
    required this.title,
    required this.message,
    required this.tokens,
    this.action,
  });

  final Widget indicator;
  final String title;
  final String message;
  final WebThemeTokens tokens;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          indicator,
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.secondaryText, height: 1.45),
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );
  }
}
