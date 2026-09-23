import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

Future<bool> showSixWebFinancialLaunchDeleteDialog({
  required BuildContext context,
  required String description,
  required String amountLabel,
  required String statusLabel,
  required Future<void> Function() onConfirm,
  required String Function(Object error) errorMessageBuilder,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final bool? result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: context.t(
      'agenda.launchDelete.dialogBarrier',
      fallback: 'Confirmar exclusão do lançamento financeiro',
    ),
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _FinancialLaunchDeleteRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: SixWebFinancialLaunchDeleteDialog(
          description: description,
          amountLabel: amountLabel,
          statusLabel: statusLabel,
          onConfirm: onConfirm,
          errorMessageBuilder: errorMessageBuilder,
        ),
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

class SixWebFinancialLaunchDeleteDialog extends StatefulWidget {
  const SixWebFinancialLaunchDeleteDialog({
    super.key,
    required this.description,
    required this.amountLabel,
    required this.statusLabel,
    required this.onConfirm,
    required this.errorMessageBuilder,
  });

  final String description;
  final String amountLabel;
  final String statusLabel;
  final Future<void> Function() onConfirm;
  final String Function(Object error) errorMessageBuilder;

  @override
  State<SixWebFinancialLaunchDeleteDialog> createState() =>
      _SixWebFinancialLaunchDeleteDialogState();
}

enum _FinancialLaunchDeleteDialogState { review, processing, success, error }

class _SixWebFinancialLaunchDeleteDialogState
    extends State<SixWebFinancialLaunchDeleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  _FinancialLaunchDeleteDialogState _state =
      _FinancialLaunchDeleteDialogState.review;
  String? _errorMessage;

  bool get _isBusy =>
      _state == _FinancialLaunchDeleteDialogState.processing ||
      _state == _FinancialLaunchDeleteDialogState.success;

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
    setState(() {
      _state = _FinancialLaunchDeleteDialogState.processing;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _state = _FinancialLaunchDeleteDialogState.success);
      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 320 : 820),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _FinancialLaunchDeleteDialogState.error;
        _errorMessage = widget.errorMessageBuilder(error);
      });
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
    final Color attention =
        theme.brightness == Brightness.dark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFF59E0B);

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
                if (_state == _FinancialLaunchDeleteDialogState.review ||
                    _state == _FinancialLaunchDeleteDialogState.error) {
                  _cancel();
                }
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Semantics(
              namesRoute: true,
              label: _txt(
                'agenda.launchDelete.title',
                'Excluir lançamento financeiro?',
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.30),
                        blurRadius: 42,
                        offset: const Offset(0, 22),
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
                            duration: Duration(
                              milliseconds: _reduceMotion ? 1 : 220,
                            ),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child:
                                _state ==
                                        _FinancialLaunchDeleteDialogState
                                            .success
                                    ? _buildSuccess(theme, tokens)
                                    : _buildReview(theme, tokens, attention),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: attention),
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

  Widget _buildReview(ThemeData theme, WebThemeTokens tokens, Color attention) {
    return Padding(
      key: const ValueKey<String>('financial-launch-delete-review'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _FinancialLaunchDeleteIcon(
                animation: _iconController,
                accent: attention,
                surfaceColor: tokens.surfaceElevated,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'agenda.launchDelete.title',
                        'Excluir lançamento financeiro?',
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
                        'agenda.launchDelete.subtitle',
                        'Revise o resumo antes de apagar. Esta ação remove o lançamento e suas confirmações financeiras vinculadas.',
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
          _buildSummary(tokens),
          const SizedBox(height: 16),
          _impactNotice(theme, tokens, attention),
          if (_state == _FinancialLaunchDeleteDialogState.error) ...<Widget>[
            const SizedBox(height: 16),
            _errorNotice(theme, tokens),
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
                child: Text(_txt('common.back', 'Voltar')),
              ),
              FilledButton.icon(
                onPressed: _isBusy ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.danger,
                  foregroundColor: tokens.onDanger,
                ),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child:
                      _state == _FinancialLaunchDeleteDialogState.processing
                          ? const SizedBox(
                            key: ValueKey<String>(
                              'financial-launch-delete-progress',
                            ),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.delete_forever_outlined,
                            key: ValueKey<String>(
                              'financial-launch-delete-action-icon',
                            ),
                            size: 18,
                          ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _state == _FinancialLaunchDeleteDialogState.processing
                        ? _txt('agenda.launchDelete.processing', 'Excluindo...')
                        : _txt(
                          'agenda.launchDelete.confirm',
                          'Excluir lançamento',
                        ),
                    key: ValueKey<_FinancialLaunchDeleteDialogState>(_state),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(WebThemeTokens tokens) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _FinancialLaunchDeleteSummaryTile(
          label: _txt('agenda.launchDelete.summaryLaunch', 'Lançamento'),
          value: widget.description,
          icon: Icons.description_outlined,
          accent: tokens.info,
        ),
        _FinancialLaunchDeleteSummaryTile(
          label: _txt('agenda.launchDelete.summaryAmount', 'Valor'),
          value: widget.amountLabel,
          icon: Icons.payments_outlined,
          accent: tokens.warning,
        ),
        _FinancialLaunchDeleteSummaryTile(
          label: _txt('agenda.launchDelete.summaryStatus', 'Status'),
          value: widget.statusLabel,
          icon: Icons.flag_outlined,
          accent: tokens.financialNegative,
        ),
      ],
    );
  }

  Widget _impactNotice(
    ThemeData theme,
    WebThemeTokens tokens,
    Color attention,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: attention.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: attention.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: attention, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _txt(
                'agenda.launchDelete.impact',
                'O lançamento será apagado definitivamente junto com confirmações, parciais e vínculos financeiros exibidos neste detalhe.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorNotice(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ??
                  _txt(
                    'agenda.launchDelete.error',
                    'Não foi possível excluir o lançamento agora. Tente novamente em instantes.',
                  ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme, WebThemeTokens tokens) {
    return Padding(
      key: const ValueKey<String>('financial-launch-delete-success'),
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
                color: tokens.success.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: tokens.success, size: 42),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _txt('agenda.launchDelete.successTitle', 'Lançamento excluído'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _txt(
              'agenda.launchDelete.successMessage',
              'A Agenda Financeira será atualizada com o lançamento removido.',
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

class _FinancialLaunchDeleteRouteSurface extends StatelessWidget {
  const _FinancialLaunchDeleteRouteSurface({
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
                  0xFF0B1324,
                ).withValues(alpha: 0.74 * progress),
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

class _FinancialLaunchDeleteIcon extends StatelessWidget {
  const _FinancialLaunchDeleteIcon({
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
                child: Icon(
                  Icons.delete_forever_outlined,
                  color: accent,
                  size: 30,
                ),
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
                      Icons.priority_high_rounded,
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

class _FinancialLaunchDeleteSummaryTile extends StatelessWidget {
  const _FinancialLaunchDeleteSummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 176, maxWidth: 192),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
