import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';

Future<bool> showSixMobileLogoutSheet(BuildContext context) async {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final bool? confirmed = await showCupertinoModalPopup<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.40),
    barrierDismissible: true,
    semanticsDismissible: true,
    builder: (BuildContext popupContext) {
      return _SixMobileLogoutSheet(
        title: context.t(
          'account.settings.logout.confirmTitle',
          fallback: 'Sair da conta?',
        ),
        subtitle: context.t(
          'account.settings.logout.confirmSubtitle',
          fallback: 'Deslize para encerrar sua sessão neste aparelho.',
        ),
        cancelLabel: context.t('common.cancel', fallback: 'Cancelar'),
        swipeLabel: context.t(
          'account.settings.logout.swipeHint',
          fallback: 'Deslize para sair',
        ),
        swipeSemantics: context.t(
          'account.settings.logout.swipeSemantics',
          fallback: 'Deslize para confirmar a saída da conta',
        ),
        onConfirmed: () => Navigator.of(popupContext).pop(true),
        onCancel: () => Navigator.of(popupContext).pop(false),
      );
    },
  );

  return confirmed ?? false;
}

class _SixMobileLogoutSheet extends StatelessWidget {
  const _SixMobileLogoutSheet({
    required this.title,
    required this.subtitle,
    required this.cancelLabel,
    required this.swipeLabel,
    required this.swipeSemantics,
    required this.onConfirmed,
    required this.onCancel,
  });

  final String title;
  final String subtitle;
  final String cancelLabel;
  final String swipeLabel;
  final String swipeSemantics;
  final VoidCallback onConfirmed;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.navigationShadow.withValues(alpha: 0.72),
                        blurRadius: 34,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: colors.strongBorder.withValues(alpha: 0.58),
                            width: 0.7,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 36,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: colors.strongBorder.withValues(
                                    alpha: 0.72,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.error.withValues(alpha: 0.10),
                                  border: Border.all(
                                    color: colors.error.withValues(alpha: 0.24),
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.power,
                                  color: colors.error,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.titleText,
                                  fontSize: 20,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.mutedText,
                                  fontSize: 13,
                                  height: 1.38,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _SixMobileLogoutSlider(
                                label: swipeLabel,
                                semanticsLabel: swipeSemantics,
                                onConfirmed: onConfirmed,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  key: const ValueKey<String>('six-mobile-logout-cancel'),
                  minSize: 0,
                  padding: EdgeInsets.zero,
                  pressedOpacity: 0.68,
                  onPressed: onCancel,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.strongBorder.withValues(alpha: 0.52),
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      cancelLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
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

class _SixMobileLogoutSlider extends StatefulWidget {
  const _SixMobileLogoutSlider({
    required this.label,
    required this.semanticsLabel,
    required this.onConfirmed,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback onConfirmed;

  @override
  State<_SixMobileLogoutSlider> createState() => _SixMobileLogoutSliderState();
}

class _SixMobileLogoutSliderState extends State<_SixMobileLogoutSlider>
    with SingleTickerProviderStateMixin {
  static const double _height = 62;
  static const double _inset = 5;
  static const double _thumbSize = 52;
  static const double _confirmationThreshold = 0.84;

  late final AnimationController _progressController;
  bool _dragging = false;
  bool _confirmed = false;
  bool _midpointFeedbackSent = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
      value: 0,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startDrag() {
    if (_confirmed) return;
    _progressController.stop();
    setState(() => _dragging = true);
    HapticFeedback.selectionClick();
  }

  void _updateDrag(DragUpdateDetails details, double maxTravel) {
    if (_confirmed || maxTravel <= 0) return;
    final double next = (_progressController.value +
            details.delta.dx / maxTravel)
        .clamp(0.0, 1.0);
    _progressController.value = next;

    if (next >= 0.52 && !_midpointFeedbackSent) {
      _midpointFeedbackSent = true;
      HapticFeedback.selectionClick();
    } else if (next < 0.42) {
      _midpointFeedbackSent = false;
    }
  }

  Future<void> _finishDrag(DragEndDetails details, double maxTravel) async {
    if (_confirmed) return;
    final double velocity = details.primaryVelocity ?? 0;
    final bool fastForward =
        maxTravel > 0 && velocity > 850 && _progressController.value >= 0.48;
    final bool shouldConfirm =
        _progressController.value >= _confirmationThreshold || fastForward;

    if (mounted) setState(() => _dragging = false);
    if (shouldConfirm) {
      await _confirm();
      return;
    }
    await _returnToStart();
  }

  Future<void> _returnToStart() async {
    if (_confirmed) return;
    _midpointFeedbackSent = false;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    await _progressController.animateTo(
      0,
      duration:
          reduceMotion
              ? Duration.zero
              : Duration(
                milliseconds: 210 + (_progressController.value * 130).round(),
              ),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirm() async {
    if (_confirmed) return;
    setState(() {
      _confirmed = true;
      _dragging = false;
    });
    HapticFeedback.heavyImpact();

    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    await _progressController.animateTo(
      1,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxTravel = (constraints.maxWidth -
                _thumbSize -
                (_inset * 2))
            .clamp(0, double.infinity);

        return Semantics(
          key: const ValueKey<String>('six-mobile-logout-slider'),
          button: true,
          enabled: !_confirmed,
          label: widget.semanticsLabel,
          hint: widget.label,
          onTap: _confirmed ? null : _confirm,
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _startDrag(),
              onHorizontalDragUpdate:
                  (DragUpdateDetails details) =>
                      _updateDrag(details, maxTravel),
              onHorizontalDragEnd:
                  (DragEndDetails details) => _finishDrag(details, maxTravel),
              onHorizontalDragCancel: () {
                if (mounted) setState(() => _dragging = false);
                _returnToStart();
              },
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (BuildContext context, Widget? child) {
                  final double progress = _progressController.value;
                  return SizedBox(
                    height: _height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(_height / 2),
                        border: Border.all(
                          color:
                              Color.lerp(
                                colors.border,
                                colors.errorBorder,
                                progress,
                              )!,
                          width: 0.8,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: colors.navigationShadow.withValues(
                              alpha: 0.24,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_height / 2),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Positioned.fill(
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        colors.error.withValues(alpha: 0.06),
                                        colors.error.withValues(alpha: 0.18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 64,
                              ),
                              child: Opacity(
                                opacity: (1 - (progress * 1.45)).clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text(
                                        widget.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.mutedText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: colors.mutedText.withValues(
                                        alpha: 0.74,
                                      ),
                                      size: 15,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: _inset + (progress * maxTravel),
                              top: _inset,
                              child: AnimatedScale(
                                scale: _dragging ? 1.035 : 1,
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  width: _thumbSize,
                                  height: _thumbSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.lerp(
                                      colors.surfaceElevated,
                                      colors.error,
                                      progress,
                                    ),
                                    border: Border.all(
                                      color: colors.error.withValues(
                                        alpha: 0.28 + (progress * 0.32),
                                      ),
                                      width: 0.9,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: colors.navigationShadow
                                            .withValues(alpha: 0.58),
                                        blurRadius: _dragging ? 16 : 11,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _confirmed
                                        ? CupertinoIcons.check_mark
                                        : CupertinoIcons.power,
                                    color:
                                        progress > 0.62
                                            ? colors.surface
                                            : colors.error,
                                    size: _confirmed ? 22 : 23,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
