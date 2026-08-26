import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

Future<bool> showSixWebPdvQuantityDialog({
  required BuildContext context,
  required String productName,
  required String productCode,
  required int currentQuantity,
  required Future<void> Function(int quantity) onConfirm,
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
      return _PdvQuantityRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: SixWebPdvQuantityDialog(
          productName: productName,
          productCode: productCode,
          currentQuantity: currentQuantity,
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

class SixWebPdvQuantityDialog extends StatefulWidget {
  const SixWebPdvQuantityDialog({
    super.key,
    required this.productName,
    required this.productCode,
    required this.currentQuantity,
    required this.onConfirm,
  });

  final String productName;
  final String productCode;
  final int currentQuantity;
  final Future<void> Function(int quantity) onConfirm;

  @override
  State<SixWebPdvQuantityDialog> createState() =>
      _SixWebPdvQuantityDialogState();
}

enum _PdvQuantityDialogState { review, processing, success, error }

class _SixWebPdvQuantityDialogState extends State<SixWebPdvQuantityDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final TextEditingController _quantityController;
  _PdvQuantityDialogState _state = _PdvQuantityDialogState.review;
  String? _validationError;

  bool get _isBusy =>
      _state == _PdvQuantityDialogState.processing ||
      _state == _PdvQuantityDialogState.success;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _quantityController = TextEditingController(
      text: widget.currentQuantity.toString(),
    );
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
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
    _quantityController.dispose();
    super.dispose();
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  int? _parseQuantity() {
    final int? parsed = int.tryParse(_quantityController.text.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  Future<void> _confirm() async {
    if (_isBusy) return;

    final int? quantity = _parseQuantity();
    if (quantity == null) {
      setState(() {
        _validationError = _txt(
          'pdv.quantityEditor.invalid',
          'Informe uma quantidade inteira maior que zero.',
        );
      });
      return;
    }

    setState(() {
      _validationError = null;
      _state = _PdvQuantityDialogState.processing;
    });

    try {
      await widget.onConfirm(quantity);
      if (!mounted) return;
      setState(() => _state = _PdvQuantityDialogState.success);
      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 320 : 780),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _PdvQuantityDialogState.error);
    }
  }

  void _cancel() {
    if (_isBusy) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _PdvQuantityDialogPalette palette = _PdvQuantityDialogPalette.resolve(
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
              label: _txt('pdv.quantityEditor.title', 'Editar quantidade'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
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
                                _state == _PdvQuantityDialogState.success
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
    _PdvQuantityDialogPalette palette,
  ) {
    return Padding(
      key: const ValueKey<String>('pdv-quantity-review'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PdvQuantityDialogIcon(
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
                      _txt('pdv.quantityEditor.title', 'Editar quantidade'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'pdv.quantityEditor.subtitle',
                        'Revise o item e aplique a nova quantidade. O subtotal e o total da venda serão recalculados imediatamente.',
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
              _PdvQuantitySummaryCard(
                title: _txt('common.product', 'Produto'),
                value: widget.productName.isEmpty ? '-' : widget.productName,
                subtitle:
                    widget.productCode.isEmpty
                        ? null
                        : '${_txt('pdv.quantityEditor.codeLabel', 'Código')}: ${widget.productCode}',
                palette: palette,
                tokens: tokens,
                width: 320,
              ),
              _PdvQuantitySummaryCard(
                title: _txt(
                  'pdv.quantityEditor.currentLabel',
                  'Quantidade atual',
                ),
                value: widget.currentQuantity.toString(),
                subtitle: _txt(
                  'pdv.quantityEditor.currentHint',
                  'Ajuste fino continua disponível nos botões laterais.',
                ),
                palette: palette,
                tokens: tokens,
                width: 220,
              ),
            ],
          ),
          if (_state == _PdvQuantityDialogState.error) ...<Widget>[
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
                        'pdv.quantityEditor.error',
                        'Não foi possível atualizar a quantidade agora. Tente novamente em alguns instantes.',
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
          const SizedBox(height: 18),
          Text(
            _txt('pdv.quantityEditor.fieldLabel', 'Nova quantidade'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey<String>('pdv-quantity-field'),
            controller: _quantityController,
            autofocus: true,
            enabled: !_isBusy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (_) {
              if (_validationError == null) {
                return;
              }
              setState(() => _validationError = null);
            },
            onSubmitted: (_) => _confirm(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: _txt(
                'pdv.quantityEditor.hint',
                'Digite a quantidade desejada para este item.',
              ),
              errorText: _validationError,
              prefixIcon: Icon(Icons.tag_rounded, color: palette.accent),
              filled: true,
              fillColor: palette.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.accent, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: tokens.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: tokens.danger, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.outlineSoft),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.flash_on_rounded, color: palette.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _txt(
                      'pdv.quantityEditor.effectHint',
                      'A alteração atualiza o subtotal do item e o total da venda imediatamente.',
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
                child: Text(_txt('common.cancel', 'Cancelar')),
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
                      _state == _PdvQuantityDialogState.processing
                          ? const SizedBox(
                            key: ValueKey<String>('pdv-quantity-progress'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.check_rounded,
                            key: ValueKey<String>('pdv-quantity-action-icon'),
                            size: 18,
                          ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _state == _PdvQuantityDialogState.processing
                        ? _txt(
                          'pdv.quantityEditor.processing',
                          'Aplicando quantidade...',
                        )
                        : _txt(
                          'pdv.quantityEditor.confirm',
                          'Aplicar quantidade',
                        ),
                    key: ValueKey<_PdvQuantityDialogState>(_state),
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
    _PdvQuantityDialogPalette palette,
  ) {
    return Padding(
      key: const ValueKey<String>('pdv-quantity-success'),
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
            _txt('pdv.quantityEditor.successTitle', 'Quantidade atualizada'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _txt(
              'pdv.quantityEditor.successMessage',
              'O item foi recalculado e a venda já reflete a nova quantidade.',
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

class _PdvQuantityRouteSurface extends StatelessWidget {
  const _PdvQuantityRouteSurface({
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

class _PdvQuantityDialogPalette {
  const _PdvQuantityDialogPalette({
    required this.surface,
    required this.outline,
    required this.outlineSoft,
    required this.accent,
    required this.accentSoft,
    required this.successSoft,
    required this.inputBackground,
    required this.inputBorder,
    required this.secondaryActionForeground,
    required this.primaryActionBackground,
    required this.primaryActionForeground,
    required this.primaryActionDisabledBackground,
    required this.primaryActionDisabledForeground,
  });

  final Color surface;
  final Color outline;
  final Color outlineSoft;
  final Color accent;
  final Color accentSoft;
  final Color successSoft;
  final Color inputBackground;
  final Color inputBorder;
  final Color secondaryActionForeground;
  final Color primaryActionBackground;
  final Color primaryActionForeground;
  final Color primaryActionDisabledBackground;
  final Color primaryActionDisabledForeground;

  static _PdvQuantityDialogPalette resolve(
    ThemeData theme,
    WebThemeTokens tokens,
  ) {
    if (theme.brightness == Brightness.dark) {
      const Color accent = Color(0xFF60A5FA);
      return _PdvQuantityDialogPalette(
        surface: const Color(0xFF17253A),
        outline: const Color(0xFF31507A),
        outlineSoft: const Color(0xFF355986),
        accent: accent,
        accentSoft: accent.withValues(alpha: 0.14),
        successSoft: tokens.success.withValues(alpha: 0.16),
        inputBackground: const Color(0xFF0C1930),
        inputBorder: const Color(0xFF4573A8),
        secondaryActionForeground: const Color(0xFF8DAAFD),
        primaryActionBackground: const Color(0xFF4151D9),
        primaryActionForeground: Colors.white,
        primaryActionDisabledBackground: const Color(0xFF24324B),
        primaryActionDisabledForeground: const Color(0xFF8FA0B8),
      );
    }

    return _PdvQuantityDialogPalette(
      surface: tokens.surfaceElevated,
      outline: tokens.cardBorder,
      outlineSoft: tokens.selectedBorder,
      accent: tokens.info,
      accentSoft: tokens.info.withValues(alpha: 0.10),
      successSoft: tokens.success.withValues(alpha: 0.13),
      inputBackground: tokens.inputBackground,
      inputBorder: tokens.selectedBorder,
      secondaryActionForeground: tokens.info,
      primaryActionBackground: theme.colorScheme.primary,
      primaryActionForeground: theme.colorScheme.onPrimary,
      primaryActionDisabledBackground: tokens.disabledBackground,
      primaryActionDisabledForeground: tokens.disabledForeground,
    );
  }
}

class _PdvQuantityDialogIcon extends StatelessWidget {
  const _PdvQuantityDialogIcon({
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
                child: Icon(Icons.format_list_numbered_rounded, color: accent),
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
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 13,
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

class _PdvQuantitySummaryCard extends StatelessWidget {
  const _PdvQuantitySummaryCard({
    required this.title,
    required this.value,
    required this.palette,
    required this.tokens,
    required this.width,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final _PdvQuantityDialogPalette palette;
  final WebThemeTokens tokens;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 180, maxWidth: width),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.outlineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
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
                height: 1.15,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.secondaryText,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
