import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

enum _CatalogUnpublishDialogState { review, processing, success, error }

Future<bool> showSixWebCatalogUnpublishDialog({
  required BuildContext context,
  required String commerceName,
  required String publicUrl,
  required Future<void> Function() onConfirm,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: context.t(
          'catalog.publicPage.unpublish.barrier',
          fallback: 'Confirmar despublicação do catálogo',
        ),
        barrierColor: Colors.transparent,
        transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
        pageBuilder: (BuildContext dialogContext, _, __) {
          return _CatalogUnpublishDialog(
            commerceName: commerceName,
            publicUrl: publicUrl,
            onConfirm: onConfirm,
          );
        },
        transitionBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.035),
                    end: Offset.zero,
                  ).animate(curved),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                    child: child,
                  ),
                ),
              );
            },
      ) ??
      false;
}

class _CatalogUnpublishDialog extends StatefulWidget {
  const _CatalogUnpublishDialog({
    required this.commerceName,
    required this.publicUrl,
    required this.onConfirm,
  });

  final String commerceName;
  final String publicUrl;
  final Future<void> Function() onConfirm;

  @override
  State<_CatalogUnpublishDialog> createState() =>
      _CatalogUnpublishDialogStateWidget();
}

class _CatalogUnpublishDialogStateWidget
    extends State<_CatalogUnpublishDialog> {
  _CatalogUnpublishDialogState _state = _CatalogUnpublishDialogState.review;
  String _errorMessage = '';

  bool get _busy =>
      _state == _CatalogUnpublishDialogState.processing ||
      _state == _CatalogUnpublishDialogState.success;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _state = _CatalogUnpublishDialogState.processing;
      _errorMessage = '';
    });

    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _state = _CatalogUnpublishDialogState.success);
      final bool reduceMotion = MediaQuery.of(context).disableAnimations;
      await Future<void>.delayed(
        Duration(milliseconds: reduceMotion ? 1 : 750),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _CatalogUnpublishDialogState.error;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return PopScope(
      canPop: !_busy,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  key: const Key('catalog-unpublish-backdrop'),
                  color: const Color(0xC200163A),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Semantics(
                    namesRoute: true,
                    label: context.t(
                      'catalog.publicPage.unpublish.title',
                      fallback: 'Despublicar catálogo?',
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: tokens.cardBorder),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x52020A18),
                              blurRadius: 44,
                              offset: Offset(0, 24),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                height: 5,
                                color:
                                    _state ==
                                        _CatalogUnpublishDialogState.success
                                    ? tokens.success
                                    : tokens.warning,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(28),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _buildContent(tokens),
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildContent(WebThemeTokens tokens) {
    if (_state == _CatalogUnpublishDialogState.processing) {
      return _buildFeedback(
        key: const Key('catalog-unpublish-processing'),
        tokens: tokens,
        icon: Icons.cloud_off_outlined,
        color: tokens.warning,
        title: context.t(
          'catalog.publicPage.unpublish.processing',
          fallback: 'Retirando o catálogo do ar...',
        ),
        body: context.t(
          'catalog.publicPage.unpublish.processingBody',
          fallback: 'Aguarde enquanto atualizamos o acesso público.',
        ),
        progress: true,
      );
    }
    if (_state == _CatalogUnpublishDialogState.success) {
      return _buildFeedback(
        key: const Key('catalog-unpublish-success'),
        tokens: tokens,
        icon: Icons.check_circle_outline_rounded,
        color: tokens.success,
        title: context.t(
          'catalog.publicPage.unpublish.success',
          fallback: 'Catálogo despublicado',
        ),
        body: context.t(
          'catalog.publicPage.unpublish.successBody',
          fallback: 'O link foi preservado e poderá ser reativado depois.',
        ),
      );
    }

    return Column(
      key: ValueKey<_CatalogUnpublishDialogState>(_state),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: tokens.warning.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.visibility_off_outlined,
            color: tokens.warning,
            size: 34,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.t(
            'catalog.publicPage.unpublish.title',
            fallback: 'Despublicar catálogo?',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: tokens.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.t(
            'catalog.publicPage.unpublish.body',
            fallback:
                'Clientes com o link deixarão de ver os produtos até uma nova publicação.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.secondaryText, height: 1.45),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.commerceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.publicUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_state == _CatalogUnpublishDialogState.error) ...<Widget>[
          const SizedBox(height: 14),
          Container(
            key: const Key('catalog-unpublish-error'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.danger.withValues(alpha: 0.35)),
            ),
            child: Text(
              _errorMessage.isEmpty
                  ? context.t(
                      'catalog.publicPage.unpublish.error',
                      fallback:
                          'Não foi possível despublicar. Tente novamente.',
                    )
                  : _errorMessage,
              style: TextStyle(color: tokens.danger),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: Text(context.t('common.cancel', fallback: 'Cancelar')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              key: const Key('catalog-unpublish-confirm'),
              onPressed: _busy ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: tokens.warning,
                foregroundColor: const Color(0xFF1B1300),
              ),
              icon: const Icon(Icons.visibility_off_outlined),
              label: Text(
                _state == _CatalogUnpublishDialogState.error
                    ? context.t('common.tryAgain', fallback: 'Tentar novamente')
                    : context.t(
                        'catalog.publicPage.unpublish.action',
                        fallback: 'Despublicar',
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedback({
    required Key key,
    required WebThemeTokens tokens,
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    bool progress = false,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: progress
              ? Padding(
                  padding: const EdgeInsets.all(22),
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 3,
                  ),
                )
              : Icon(icon, color: color, size: 38),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: tokens.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.secondaryText, height: 1.45),
        ),
      ],
    );
  }
}
