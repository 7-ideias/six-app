import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/l10n/six_i18n.dart';

import '../../theme/web_theme_tokens.dart';

Future<bool> showSixWebLabelPdfGenerateDialog({
  required BuildContext context,
  required String templateName,
  required int productCount,
  required int totalLabels,
  required int estimatedPages,
  required Future<void> Function() onConfirm,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final bool? result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: _localizedDialogText(
      context,
      key: 'labels.print.generateDialog.barrier',
      pt: 'Confirmar geração do PDF de etiquetas',
      en: 'Confirm label PDF generation',
      es: 'Confirmar generación del PDF de etiquetas',
    ),
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _GeneratePdfRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: SixWebLabelPdfGenerateDialog(
          templateName: templateName,
          productCount: productCount,
          totalLabels: totalLabels,
          estimatedPages: estimatedPages,
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

class SixWebLabelPdfGenerateDialog extends StatefulWidget {
  const SixWebLabelPdfGenerateDialog({
    super.key,
    required this.templateName,
    required this.productCount,
    required this.totalLabels,
    required this.estimatedPages,
    required this.onConfirm,
  });

  final String templateName;
  final int productCount;
  final int totalLabels;
  final int estimatedPages;
  final Future<void> Function() onConfirm;

  @override
  State<SixWebLabelPdfGenerateDialog> createState() =>
      _SixWebLabelPdfGenerateDialogState();
}

enum _GeneratePdfDialogState { review, processing, success, error }

class _SixWebLabelPdfGenerateDialogState
    extends State<SixWebLabelPdfGenerateDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  _GeneratePdfDialogState _state = _GeneratePdfDialogState.review;
  String _errorMessage = '';

  bool get _isBusy =>
      _state == _GeneratePdfDialogState.processing ||
      _state == _GeneratePdfDialogState.success;

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
    setState(() {
      _state = _GeneratePdfDialogState.processing;
      _errorMessage = '';
    });

    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _state = _GeneratePdfDialogState.success);
      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 320 : 820),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _GeneratePdfDialogState.error;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _dismiss() {
    if (_isBusy) return;
    Navigator.of(context).pop(false);
  }

  String _tr({
    required String key,
    required String pt,
    required String en,
    required String es,
  }) => _localizedDialogText(context, key: key, pt: pt, en: en, es: es);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _GeneratePdfDialogPalette palette = _GeneratePdfDialogPalette.resolve(
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
                _dismiss();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Semantics(
              namesRoute: true,
              label: _tr(
                key: 'labels.print.generateDialog.title',
                pt: 'Gerar PDF de etiquetas?',
                en: 'Generate label PDF?',
                es: '¿Generar PDF de etiquetas?',
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.outline),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.30),
                        blurRadius: 44,
                        offset: const Offset(0, 24),
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
                                _state == _GeneratePdfDialogState.success
                                    ? _buildSuccess(theme, tokens, palette)
                                    : _buildReview(theme, tokens, palette),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              color: switch (_state) {
                                _GeneratePdfDialogState.success =>
                                  tokens.success,
                                _GeneratePdfDialogState.error => tokens.danger,
                                _ => palette.accent,
                              },
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
      ),
    );
  }

  Widget _buildReview(
    ThemeData theme,
    WebThemeTokens tokens,
    _GeneratePdfDialogPalette palette,
  ) {
    return Padding(
      key: const ValueKey<String>('labels-generate-review'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _GeneratePdfIcon(
                animation: _iconController,
                accent: palette.accent,
                accentSoft: palette.accentSoft,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _tr(
                        key: 'labels.print.generateDialog.title',
                        pt: 'Gerar PDF de etiquetas?',
                        en: 'Generate label PDF?',
                        es: '¿Generar PDF de etiquetas?',
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tr(
                        key: 'labels.print.generateDialog.subtitle',
                        pt:
                            'Revise o resumo antes de iniciar. O arquivo será montado com as medidas salvas no modelo selecionado.',
                        en:
                            'Review the summary before starting. The file will be built using the measurements saved in the selected template.',
                        es:
                            'Revise el resumen antes de iniciar. El archivo se generará con las medidas guardadas en la plantilla seleccionada.',
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
          _summary(theme, tokens),
          const SizedBox(height: 16),
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
                  Icons.straighten_rounded,
                  color: palette.accent,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tr(
                    key: 'labels.print.generateDialog.checklist',
                    pt:
                        'O PDF seguirá o tamanho físico do modelo e a quantidade ajustada para cada produto.',
                    en:
                        'The PDF will follow the template physical size and the quantity configured for each product.',
                    es:
                        'El PDF seguirá el tamaño físico de la plantilla y la cantidad ajustada para cada producto.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_state == _GeneratePdfDialogState.error) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              key: const Key('labels-generate-error'),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.error_outline_rounded, color: tokens.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage.isEmpty
                          ? _tr(
                            key: 'labels.print.generateDialog.error',
                            pt:
                                'Não foi possível gerar o PDF agora. Revise o modelo e tente novamente.',
                            en:
                                'Could not generate the PDF now. Review the template and try again.',
                            es:
                                'No se pudo generar el PDF ahora. Revise la plantilla e inténtelo de nuevo.',
                          )
                          : _errorMessage,
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
                onPressed: _isBusy ? null : _dismiss,
                style: TextButton.styleFrom(
                  foregroundColor: palette.secondaryActionForeground,
                ),
                child: Text(
                  _tr(
                    key: 'labels.print.generateDialog.back',
                    pt: 'Voltar',
                    en: 'Back',
                    es: 'Volver',
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('labels-generate-confirm'),
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
                      _state == _GeneratePdfDialogState.processing
                          ? const SizedBox(
                            key: ValueKey<String>('labels-generate-progress'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.picture_as_pdf_outlined,
                            key: ValueKey<String>(
                              'labels-generate-action-icon',
                            ),
                            size: 18,
                          ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _state == _GeneratePdfDialogState.processing
                        ? _tr(
                          key: 'labels.print.generateDialog.processing',
                          pt: 'Gerando PDF...',
                          en: 'Generating PDF...',
                          es: 'Generando PDF...',
                        )
                        : _tr(
                          key: 'labels.print.generateDialog.confirm',
                          pt: 'Gerar PDF',
                          en: 'Generate PDF',
                          es: 'Generar PDF',
                        ),
                    key: ValueKey<_GeneratePdfDialogState>(_state),
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
    _GeneratePdfDialogPalette palette,
  ) {
    return Padding(
      key: const ValueKey<String>('labels-generate-success'),
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
            _tr(
              key: 'labels.print.generateDialog.successTitle',
              pt: 'PDF pronto para download',
              en: 'PDF ready for download',
              es: 'PDF listo para descargar',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              key: 'labels.print.generateDialog.successMessage',
              pt:
                  'A geração foi concluída e o arquivo foi enviado para o navegador.',
              en: 'Generation completed and the file was sent to the browser.',
              es: 'La generación terminó y el archivo fue enviado al navegador.',
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

  Widget _summary(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.templateName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tr(
              key: 'labels.print.generateDialog.summaryTitle',
              pt: 'Resumo da geração',
              en: 'Generation summary',
              es: 'Resumen de la generación',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.secondaryText,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: <Widget>[
              _summaryMetric(
                theme,
                tokens,
                _tr(
                  key: 'labels.print.selectedProducts',
                  pt: 'Produtos',
                  en: 'Products',
                  es: 'Productos',
                ),
                widget.productCount.toString(),
              ),
              _summaryMetric(
                theme,
                tokens,
                _tr(
                  key: 'labels.print.totalLabels',
                  pt: 'Etiquetas',
                  en: 'Labels',
                  es: 'Etiquetas',
                ),
                widget.totalLabels.toString(),
              ),
              _summaryMetric(
                theme,
                tokens,
                _tr(
                  key: 'labels.print.estimatedPages',
                  pt: 'Páginas estimadas',
                  en: 'Estimated pages',
                  es: 'Páginas estimadas',
                ),
                widget.estimatedPages.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(
    ThemeData theme,
    WebThemeTokens tokens,
    String label,
    String value,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratePdfRouteSurface extends StatelessWidget {
  const _GeneratePdfRouteSurface({
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
                key: const Key('labels-generate-backdrop'),
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

class _GeneratePdfIcon extends StatelessWidget {
  const _GeneratePdfIcon({
    required this.animation,
    required this.accent,
    required this.accentSoft,
  });

  final Animation<double> animation;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    final Animation<double> scale = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    );
    final Animation<double> pulse = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(scale);
    final Animation<double> halo = Tween<double>(
      begin: 0.15,
      end: 0.30,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, _) {
        return SizedBox(
          width: 78,
          height: 78,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: halo.value),
                ),
              ),
              Transform.scale(
                scale: pulse.value,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentSoft,
                    border: Border.all(color: accent.withValues(alpha: 0.22)),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: accent,
                    size: 28,
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

class _GeneratePdfDialogPalette {
  const _GeneratePdfDialogPalette({
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

  static _GeneratePdfDialogPalette resolve(
    ThemeData theme,
    WebThemeTokens tokens,
  ) {
    if (theme.brightness == Brightness.dark) {
      const Color accent = Color(0xFF5EA2FF);
      return _GeneratePdfDialogPalette(
        surface: const Color(0xFF16253A),
        outline: const Color(0xFF29415F),
        accent: accent,
        accentSoft: const Color(0xFF193454),
        successSoft: const Color(0xFF11372E),
        secondaryActionForeground: const Color(0xFFA8C1FF),
        primaryActionBackground: const Color(0xFF4162E0),
        primaryActionForeground: Colors.white,
        primaryActionDisabledBackground: const Color(0xFF223048),
        primaryActionDisabledForeground: const Color(0xFF7B8AA0),
      );
    }

    return _GeneratePdfDialogPalette(
      surface: tokens.surfaceElevated,
      outline: tokens.cardBorder,
      accent: tokens.info,
      accentSoft: tokens.info.withValues(alpha: 0.12),
      successSoft: tokens.success.withValues(alpha: 0.12),
      secondaryActionForeground: tokens.info,
      primaryActionBackground: tokens.info,
      primaryActionForeground: Colors.white,
      primaryActionDisabledBackground: tokens.disabledBackground,
      primaryActionDisabledForeground: tokens.disabledForeground,
    );
  }
}

String _localizedDialogText(
  BuildContext context, {
  required String key,
  required String pt,
  required String en,
  required String es,
}) {
  final String language = Localizations.localeOf(context).languageCode;
  final String fallback = switch (language) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
  return context.t(key, fallback: fallback);
}
