import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

enum _PdvClearSaleDialogState { review, processing, success, error }

Future<bool> showSixWebPdvClearSaleDialog({
  required BuildContext context,
  required int itemCount,
  required String totalLabel,
  required String customerLabel,
  required Future<void> Function() onConfirm,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final bool? result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: context.t(
      'pdv.clearSale.dialogBarrier',
      fallback: 'Confirmar limpeza da venda atual',
    ),
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 280),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _PdvClearSaleRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: SixWebPdvClearSaleDialog(
          itemCount: itemCount,
          totalLabel: totalLabel,
          customerLabel: customerLabel,
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

class SixWebPdvClearSaleDialog extends StatefulWidget {
  const SixWebPdvClearSaleDialog({
    super.key,
    required this.itemCount,
    required this.totalLabel,
    required this.customerLabel,
    required this.onConfirm,
  });

  final int itemCount;
  final String totalLabel;
  final String customerLabel;
  final Future<void> Function() onConfirm;

  @override
  State<SixWebPdvClearSaleDialog> createState() =>
      _SixWebPdvClearSaleDialogState();
}

class _SixWebPdvClearSaleDialogState extends State<SixWebPdvClearSaleDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  _PdvClearSaleDialogState _state = _PdvClearSaleDialogState.review;

  bool get _isBusy =>
      _state == _PdvClearSaleDialogState.processing ||
      _state == _PdvClearSaleDialogState.success;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
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
    setState(() => _state = _PdvClearSaleDialogState.processing);

    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _state = _PdvClearSaleDialogState.success);
      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 220 : 760),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _PdvClearSaleDialogState.error);
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
    final Color accent =
        _state == _PdvClearSaleDialogState.success ? tokens.success : attention;

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
                if (_state == _PdvClearSaleDialogState.review ||
                    _state == _PdvClearSaleDialogState.error) {
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
              label: _txt('pdv.clearSale.dialogTitle', 'Limpar venda atual?'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.30),
                        blurRadius: 42,
                        offset: const Offset(0, 24),
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
                            child: switch (_state) {
                              _PdvClearSaleDialogState.processing =>
                                _buildProcessing(theme, tokens, attention),
                              _PdvClearSaleDialogState.success => _buildSuccess(
                                theme,
                                tokens,
                              ),
                              _ => _buildReview(theme, tokens, attention),
                            },
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: accent),
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
      key: const Key('pdv-clear-sale-review'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PdvClearSaleDialogIcon(
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
                      _txt('pdv.clearSale.dialogTitle', 'Limpar venda atual?'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'pdv.clearSale.dialogSubtitle',
                        'Revise o resumo antes de limpar. O atendimento atual será reiniciado para abrir uma nova venda.',
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _PdvClearSaleSummaryCard(
                label: _txt('pdv.clearSale.summaryItems', 'Itens'),
                value: widget.itemCount.toString(),
                icon: Icons.inventory_2_outlined,
                tokens: tokens,
              ),
              _PdvClearSaleSummaryCard(
                label: _txt('pdv.clearSale.summaryTotal', 'Total'),
                value: widget.totalLabel,
                icon: Icons.payments_outlined,
                tokens: tokens,
              ),
              _PdvClearSaleSummaryCard(
                label: _txt('pdv.clearSale.summaryCustomer', 'Cliente'),
                value: widget.customerLabel,
                icon: Icons.person_outline_rounded,
                tokens: tokens,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: attention.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: attention.withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, color: attention, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _txt(
                      'pdv.clearSale.impactHint',
                      'Itens, cliente identificado e recebimentos temporários serão removidos deste PDV.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.primaryText,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_state == _PdvClearSaleDialogState.error) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              key: const Key('pdv-clear-sale-error'),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tokens.danger.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                _txt(
                  'pdv.clearSale.error',
                  'Não foi possível limpar a venda agora. Tente novamente em instantes.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.danger,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: <Widget>[
              TextButton(
                key: const Key('pdv-clear-sale-cancel'),
                onPressed: _cancel,
                child: Text(_txt('common.back', 'Voltar')),
              ),
              FilledButton.icon(
                key: const Key('pdv-clear-sale-confirm'),
                onPressed: _confirm,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(
                  _txt('pdv.clearSale.confirmAction', 'Limpar venda'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing(
    ThemeData theme,
    WebThemeTokens tokens,
    Color attention,
  ) {
    return _PdvClearSaleFeedbackState(
      key: const Key('pdv-clear-sale-processing'),
      icon: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(attention),
        ),
      ),
      title: _txt('pdv.clearSale.processingTitle', 'Limpando venda...'),
      message: _txt(
        'pdv.clearSale.processingMessage',
        'Aguarde enquanto os dados temporários desta venda são removidos.',
      ),
      color: attention,
      theme: theme,
      tokens: tokens,
    );
  }

  Widget _buildSuccess(ThemeData theme, WebThemeTokens tokens) {
    return _PdvClearSaleFeedbackState(
      key: const Key('pdv-clear-sale-success'),
      icon: Icon(
        Icons.check_circle_outline_rounded,
        color: tokens.success,
        size: 28,
      ),
      title: _txt('pdv.clearSale.successTitle', 'Venda limpa com sucesso'),
      message: _txt(
        'pdv.clearSale.successMessage',
        'O PDV está pronto para iniciar uma nova venda.',
      ),
      color: tokens.success,
      theme: theme,
      tokens: tokens,
    );
  }
}

class _PdvClearSaleRouteSurface extends StatelessWidget {
  const _PdvClearSaleRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (BuildContext context, Widget? dialogChild) {
          final double progress = curved.value;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: reduceMotion ? 0 : 12 * progress,
                      sigmaY: reduceMotion ? 0 : 12 * progress,
                    ),
                    child: ColoredBox(
                      key: const Key('pdv-clear-sale-backdrop'),
                      color:
                          Color.lerp(
                            Colors.transparent,
                            const Color(0xC20A1324),
                            progress,
                          )!,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, (1 - progress) * 24),
                        child: Transform.scale(
                          scale: 0.96 + (0.04 * progress),
                          child: dialogChild,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PdvClearSaleSummaryCard extends StatelessWidget {
  const _PdvClearSaleSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tokens,
  });

  final String label;
  final String value;
  final IconData icon;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 176, maxWidth: 184),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: tokens.info),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdvClearSaleFeedbackState extends StatelessWidget {
  const _PdvClearSaleFeedbackState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.theme,
    required this.tokens,
  });

  final Widget icon;
  final String title;
  final String message;
  final Color color;
  final ThemeData theme;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
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

class _PdvClearSaleDialogIcon extends StatelessWidget {
  const _PdvClearSaleDialogIcon({
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
        final double progress = animation.value;
        final double scale = ui.lerpDouble(0.92, 1.0, progress) ?? 1.0;
        final double ringOpacity = ui.lerpDouble(0.0, 0.18, progress) ?? 0.18;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: accent.withValues(alpha: ringOpacity),
                      width: 8,
                    ),
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surfaceColor,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18 * progress),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_sweep_outlined,
                    color: accent,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
