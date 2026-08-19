import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

Future<bool> showSixWebCashSessionCloseDialog({
  required BuildContext context,
  required String cashDeskName,
  required int movementCount,
  required String expectedBalance,
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
        ) {
          return _CashSessionCloseRouteSurface(
            animation: animation,
            reduceMotion: reduceMotion,
            child: SixWebCashSessionCloseDialog(
              cashDeskName: cashDeskName,
              movementCount: movementCount,
              expectedBalance: expectedBalance,
              onConfirm: onConfirm,
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

class SixWebCashSessionCloseDialog extends StatefulWidget {
  const SixWebCashSessionCloseDialog({
    super.key,
    required this.cashDeskName,
    required this.movementCount,
    required this.expectedBalance,
    required this.onConfirm,
  });

  final String cashDeskName;
  final int movementCount;
  final String expectedBalance;
  final Future<void> Function() onConfirm;

  @override
  State<SixWebCashSessionCloseDialog> createState() =>
      _SixWebCashSessionCloseDialogState();
}

enum _CashSessionCloseState { review, processing, success, error }

class _SixWebCashSessionCloseDialogState
    extends State<SixWebCashSessionCloseDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  _CashSessionCloseState _state = _CashSessionCloseState.review;

  bool get _isBusy =>
      _state == _CashSessionCloseState.processing ||
      _state == _CashSessionCloseState.success;

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
    setState(() => _state = _CashSessionCloseState.processing);

    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _state = _CashSessionCloseState.success);

      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 350 : 850),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _CashSessionCloseState.error);
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
    final Color attention = theme.brightness == Brightness.dark
        ? const Color(0xFFFBBF24)
        : const Color(0xFFF59E0B);

    return PopScope(
      canPop: !_isBusy,
      child: Semantics(
        namesRoute: true,
        label: _txt(
          'caixa.operacoes.closeDialogTitle',
          'Encerrar sessão de caixa?',
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF020617).withValues(alpha: 0.28),
                  blurRadius: 40,
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
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _state == _CashSessionCloseState.success
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
    );
  }

  Widget _buildReview(ThemeData theme, WebThemeTokens tokens, Color attention) {
    return Padding(
      key: const ValueKey<String>('cash-close-review'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ClosingCashIcon(
                animation: _iconController,
                attention: attention,
                surfaceColor: tokens.surfaceElevated,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'caixa.operacoes.closeDialogTitle',
                        'Encerrar sessão de caixa?',
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
                        'caixa.operacoes.closeDialogSubtitle',
                        'Revise o resumo antes de concluir. Esta ação não poderá ser desfeita.',
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
          _buildSummary(theme, tokens),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: tokens.success,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _txt(
                    'caixa.operacoes.closeDialogChecklistComplete',
                    'Resumo operacional disponível',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_state == _CashSessionCloseState.error) ...<Widget>[
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
                        'caixa.operacoes.closeDialogError',
                        'Não foi possível encerrar o caixa. Verifique sua conexão e tente novamente.',
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
                child: Text(_txt('caixa.operacoes.closeDialogBack', 'Voltar')),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isBusy ? null : _confirm,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: _state == _CashSessionCloseState.processing
                      ? const SizedBox(
                          key: ValueKey<String>('cash-close-progress'),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.lock_outline_rounded,
                          key: ValueKey<String>('cash-close-lock'),
                          size: 18,
                        ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _state == _CashSessionCloseState.processing
                        ? _txt(
                            'caixa.operacoes.closeDialogProcessing',
                            'Encerrando...',
                          )
                        : _txt(
                            'caixa.operacoes.closeDialogConfirm',
                            'Encerrar caixa',
                          ),
                    key: ValueKey<_CashSessionCloseState>(_state),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, WebThemeTokens tokens) {
    final List<_CashSessionSummaryItem> items = <_CashSessionSummaryItem>[
      _CashSessionSummaryItem(
        icon: Icons.point_of_sale_outlined,
        label: _txt('caixa.operacoes.closeDialogCashDesk', 'Caixa'),
        value: widget.cashDeskName,
      ),
      _CashSessionSummaryItem(
        icon: Icons.receipt_long_outlined,
        label: _txt('caixa.operacoes.closeDialogMovements', 'Movimentos'),
        value: widget.movementCount.toString(),
      ),
      _CashSessionSummaryItem(
        icon: Icons.account_balance_wallet_outlined,
        label: _txt(
          'caixa.operacoes.closeDialogExpectedBalance',
          'Saldo esperado',
        ),
        value: widget.expectedBalance,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 500;
          if (compact) {
            return Column(
              children: <Widget>[
                for (int index = 0; index < items.length; index++) ...<Widget>[
                  _buildSummaryItem(theme, tokens, items[index]),
                  if (index < items.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: tokens.divider),
                    ),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < items.length; index++) ...<Widget>[
                Expanded(child: _buildSummaryItem(theme, tokens, items[index])),
                if (index < items.length - 1)
                  Container(
                    width: 1,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: tokens.divider,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    WebThemeTokens tokens,
    _CashSessionSummaryItem item,
  ) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: tokens.info, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme, WebThemeTokens tokens) {
    return Padding(
      key: const ValueKey<String>('cash-close-success'),
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
            _txt(
              'caixa.operacoes.closeDialogSuccessTitle',
              'Caixa encerrado com sucesso',
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
              'caixa.operacoes.closeDialogSuccessMessage',
              'A sessão foi finalizada e permanece disponível no histórico.',
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

class _CashSessionCloseRouteSurface extends StatelessWidget {
  const _CashSessionCloseRouteSurface({
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
      child: child,
    );
  }
}

class _ClosingCashIcon extends StatelessWidget {
  const _ClosingCashIcon({
    required this.animation,
    required this.attention,
    required this.surfaceColor,
  });

  final Animation<double> animation;
  final Color attention;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double pulse = Curves.easeOutCubic.transform(
          const Interval(0, 0.72).transform(animation.value),
        );
        final double lock = Curves.easeOutBack.transform(
          const Interval(0.38, 1).transform(animation.value),
        );
        return SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Opacity(
                opacity: (1 - pulse) * 0.28,
                child: Transform.scale(
                  scale: 0.86 + (pulse * 0.48),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: attention, width: 2),
                    ),
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: attention.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: attention,
                  size: 29,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 1,
                child: Transform.scale(
                  scale: lock,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: attention,
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
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

class _CashSessionSummaryItem {
  const _CashSessionSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
